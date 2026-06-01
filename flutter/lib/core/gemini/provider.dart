import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client.dart';
import '../audio/provider.dart';
import '../config.dart';
import '../../services/firebase_service.dart';
import '../../services/http_service.dart';

final firebaseServiceProvider = Provider((ref) => FirebaseService());
final httpServiceProvider = Provider((ref) => HttpService());
final activeWebsiteUrlProvider = StateProvider<String?>((ref) => null);

class GeminiLiveClientState {
  final bool isConnected;
  final bool isSetupComplete;
  final bool isAgentSpeaking;
  final String userTranscript;
  final String modelTranscript;
  final List<String> messages;

  GeminiLiveClientState({
    this.isConnected = false,
    this.isSetupComplete = false,
    this.isAgentSpeaking = false,
    this.userTranscript = '',
    this.modelTranscript = '',
    this.messages = const [],
  });

  GeminiLiveClientState copyWith({
    bool? isConnected,
    bool? isSetupComplete,
    bool? isAgentSpeaking,
    String? userTranscript,
    String? modelTranscript,
    List<String>? messages,
  }) {
    return GeminiLiveClientState(
      isConnected: isConnected ?? this.isConnected,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      isAgentSpeaking: isAgentSpeaking ?? this.isAgentSpeaking,
      userTranscript: userTranscript ?? this.userTranscript,
      modelTranscript: modelTranscript ?? this.modelTranscript,
      messages: messages ?? this.messages,
    );
  }
}

class GeminiLiveClientNotifier extends Notifier<GeminiLiveClientState> implements GeminiLiveClientDelegate {
  late GeminiLiveClient _client;

  @override
  GeminiLiveClientState build() {
    _client = GeminiLiveClient(
      apiKey: AppConfig.geminiApiKey,
      delegate: this,
    );
    return GeminiLiveClientState();
  }

  Future<void> startSession({
    String voiceName = 'Aoede',
    String? systemInstruction,
    List<Map<String, dynamic>>? tools,
  }) async {
    await ref.read(audioStreamerProvider).start();
    await ref.read(audioRecorderProvider).start();
    await ref.read(ambientAudioProvider).start();
    
    const String cafeInstruction = "Start naturally like the conversation is already happening at a cafe. Do not introduce yourself. Do not mention your name. Do not offer help. Use a small human beat if it fits, like 'Mm...' or 'Yeah...', then begin with a casual observation, small-talk thought, back-to-reality moment, or light current-topic style comment. Keep it calm and normal. Do not overuse fillers.";

    await _client.connect(
      voiceName: voiceName,
      systemInstruction: systemInstruction ?? cafeInstruction,
      tools: tools,
    );
    
    state = state.copyWith(isConnected: true);
  }

  Future<void> stopSession() async {
    await _client.disconnect();
    await ref.read(audioRecorderProvider).stop();
    await ref.read(audioStreamerProvider).stop();
    await ref.read(ambientAudioProvider).stop();
    
    state = GeminiLiveClientState();
  }

  void sendAudio(String base64) => _client.sendAudio(base64);
  void sendText(String text) => _client.sendText(text);

  @override
  void onSetupComplete() {
    state = state.copyWith(isSetupComplete: true);
  }

  @override
  void onAudioData(String base64) {
    ref.read(audioStreamerProvider).addPCM16(base64);
    state = state.copyWith(isAgentSpeaking: true);
    
    // Reset speaking state after a short delay if no more audio arrives
    Future.delayed(const Duration(milliseconds: 400), () {
      if (ref.exists(geminiLiveProvider)) {
        state = state.copyWith(isAgentSpeaking: false);
      }
    });
  }

  @override
  void onTranscript(String text) {
    state = state.copyWith(modelTranscript: text);
  }

  @override
  void onInterrupted() {
    ref.read(audioStreamerProvider).stopWithFade();
    state = state.copyWith(isAgentSpeaking: false);
  }

  @override
  void onTurnComplete() {
    if (state.modelTranscript.isNotEmpty) {
      state = state.copyWith(
        messages: [...state.messages, 'ASSISTANT: ${state.modelTranscript}'],
        modelTranscript: '',
      );
    }
  }
@override
void onToolCall(List<Map<String, dynamic>> functionCalls) {
  print('Tool Call received: $functionCalls');

  for (var call in functionCalls) {
    if (call['name'] == 'create_website') {
      _handleCreateWebsite(call);
    }
  }

  // Placeholder response
  final responses = functionCalls.map((call) => {
    'id': call['id'],
    'name': call['name'],
    'response': {'result': 'Tool ${call['name']} execution started'}
  }).toList();

  _client.sendToolResponse(responses);
}

Future<void> _handleCreateWebsite(Map<String, dynamic> call) async {
  final args = call['args'];
  final title = args['title'] ?? 'Website';
  final prompt = args['prompt'] ?? '';
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  final userId = ref.read(firebaseServiceProvider).currentUser?.uid ?? 'anon';

  try {
    final response = await ref.read(httpServiceProvider).post(
      '${AppConfig.backendUrl}/api/website/generate',
      body: {
        'userId': userId,
        'title': title,
        'prompt': prompt,
        'timestamp': timestamp,
      },
    );

    if (response['ok'] == true) {
      final url = '${AppConfig.backendUrl}${response['slug']}';
      // Notify UI to show website viewer (we'll add a provider for this)
      ref.read(activeWebsiteUrlProvider.notifier).state = url;
    }
  } catch (e) {
    print('Website generation error in Flutter: $e');
  }
}

  @override
  void onError(dynamic error) {
    print('Gemini Error: $error');
    stopSession();
  }

  @override
  void onDone() {
    stopSession();
  }
}

final geminiLiveProvider = NotifierProvider<GeminiLiveClientNotifier, GeminiLiveClientState>(() {
  return GeminiLiveClientNotifier();
});
