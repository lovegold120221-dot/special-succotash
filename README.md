# Voxx-Zero: The High-End AI Agent for Belgium

Voxx-Zero is a powerful, highly specialized voice AI assistant tailored specifically for the Belgian market. Powered by Gemini Live (native bidirectional audio), React 19, Vite, and an Express backend, Voxx-Zero is designed to eliminate high-friction administrative burdens ("Belgian Paperwork") and serve as an indispensable business tool rather than just a generic voice assistant.

## Features & Capabilities

### 🇧🇪 Belgian Administrative & Business Tools
Voxx-Zero comes pre-integrated with 10 high-value, market-specific skills:
1. **KBO/CBE Company Intelligence:** Retrieve official registered office, legal form, and active status using enterprise numbers.
2. **VIES VAT Validation:** Instant verification of Belgian and EU VAT numbers.
3. **Peppol E-Invoicing Generator:** Draft UBL/XML-compliant e-invoices for B2G and B2B transactions.
4. **Registration Tax Calculator (Registratierechten):** Calculate complex property purchase taxes across Flanders, Wallonia, and Brussels.
5. **Tax & VAT Calendar Alerts:** Fetch crucial deadlines for VAT returns, corporate tax, and social contributions.
6. **"Itsme" Integration Navigator:** Provide step-by-step guidance for authenticating with government portals via Itsme.
7. **Bilingual Business Bridge:** Seamless, real-time contextual translation between Dutch and French (FR ↔ NL) maintaining professional tone.
8. **Social Security Navigator (RSZ/ONSS):** Decode complex social security rules for employers and freelancers.
9. **Labor Law Simplifier (Arbeidswetgeving):** Interpret and simplify standard employment contract clauses (e.g., non-compete, notice periods).
10. **Belgian Mobility Planner:** Navigate NMBS/SNCB and De Lijn/STIB schedules to optimize commuting and travel across regions.

### 🧠 Core Architecture
*   **Frontend:** React 19 Single Page Application built with Vite and styled via Tailwind CSS v4 and Framer Motion.
*   **Backend:** Express API server bridging Voxx-Zero with WhatsApp (via Baileys) and the Belgian business tools.
*   **Authentication & Database:** Firebase Auth (Google OAuth) for identity, and Supabase for persisting user settings, knowledge files, and document storage.
*   **Audio Pipeline:** Real-time PCM16 mono 24kHz audio streaming, utilizing custom `AudioStreamer` and `AudioRecorder` logic to communicate directly with the Gemini Live API.

## Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/lovegold120221-dot/voxx-zero.git
   cd voxx-zero
   ```
2. **Install dependencies:**
   ```bash
   npm install
   ```
3. **Environment Variables:**
   Copy `.env.example` to `.env` and fill in your keys (Gemini API, Firebase, Supabase, etc).
4. **Run the Application:**
   Start both the Vite frontend and the backend API concurrently:
   ```bash
   npm run dev:full
   ```

## Deployment

Voxx-Zero is pre-configured to be deployed easily using **Vercel**. 
The repository includes a `vercel.json` file for proper Single-Page Application (SPA) routing. 

When deploying the frontend to Vercel, the app automatically detects the production environment and routes backend API requests (for WhatsApp and Belgian Tools) to the designated production backend API url: `https://whatsapp.eburon.ai`. 

*No manual environment variable configuration is required for the API URL in production.*

## WhatsApp Backend Server

Voxx-Zero includes an advanced WhatsApp integration using `@whiskeysockets/baileys`. 

*   **Local Backend:** Run `npm run dev:api` to start the local API on `http://localhost:4200`.
*   **Pairing:** Open the `/adminportal` route, scan the QR code via WhatsApp Linked Devices, and securely pair your session.
*   **Permissions:** Enable specific permissions (Read, Send, Groups) to let Voxx-Zero act autonomously on your behalf.
*   **Security:** All WhatsApp sessions are isolated per user in the `.baileys_auth` directory and never exposed to the client browser.

## Document Generation

Voxx-Zero dynamically generates complete, beautifully formatted business documents (invoices, NDAs, contracts, memos) directly via the Gemini model, requiring zero external PDF/HTML generation services. The UI displays these dynamically generated HTML documents instantly in the workspace.

## System Design Reference
Please refer to `AGENTS.md` and `walkthrough.md` for deeper architectural overviews, system invariants, and state management details.
