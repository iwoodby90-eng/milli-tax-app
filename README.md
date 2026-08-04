# Milli — Tax Autopilot for Gig Workers

Milli is an iOS + iPad + Apple Watch app that automates tax tracking, estimation, and filing for gig economy workers. Built with React (Capacitor) on the frontend and a Python FastAPI backend with a full tax calculation engine.

## Features

### Core Tax
- **Tax Autopilot**: Automatic quarterly tax estimation and payment reminders
- **State-by-State Tax Engine**: Full 2025 IRS tax brackets and state tax calculations
- **1099 & Schedule C**: Import and generate tax forms; PDF export via Schedule C
- **Tax Payment**: IRS Direct Pay integration + card payment support
- **E-Filing**: IRS Modernized e-File API integration

### Banking & Cards
- **Plaid Integration**: Real bank account linking with transaction webhooks for auto tax pull
- **Milli Visa Elite Card**: Metal/titanium card opt-in, ordering, and fulfillment via Stripe Issuing API
- **Savings**: Goals, progress tracking, and auto-allocation
- **Accounts**: Elite-gated checking and Visa card management

### Security & Auth
- **Biometric Authentication**: Face ID / Touch ID via Capacitor
- **MFA**: TOTP-based multi-factor authentication
- **Social Login**: Apple, Google sign-in support
- **KYC Verification**: Persona / Stripe Identity integration

### Productivity
- **Mileage Tracking**: GPS-based mileage logging for deductible miles
- **Receipt OCR**: Google Vision / Textract with auto-categorization
- **Investing Dashboard**: Track retirement projects and investment accounts
- **Brokerage**: Alpaca API integration for stocks/ETFs
- **Vehicles**: CRUD, fuel types, primary vehicle, business use %

### App Management
- **Subscription Management**: Pro/Elite tier gating via TierGate component
- **Documents**: Secure document storage with Face ID protection
- **Annual Taxes**: Annual tax summary and filing flow
- **Admin Dashboard**: User management, revenue analytics, plan distribution
- **Security Settings**: Biometric, MFA, and social login configuration

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React + Tailwind CSS + Capacitor (iOS/iPad/Apple Watch) |
| Backend | Python / FastAPI |
| Database | PostgreSQL + Redis |
| Tax Engine | Custom Python module (2025 IRS constants, state brackets, quarterly planning) |
| iOS | Native Capacitor bridge, splash screen, PrivacyInfo.xcprivacy |
| Design | Dark theme, neon cyan (#00E5FF), Volt Yellow CTA (#D4FF00), glassmorphism |
| Typography | Outfit (headings) + IBM Plex Sans (body) + JetBrains Mono (monospace) |
| Testing | pytest (backend) + Jest + React Testing Library (frontend) |
| Infra | Docker Compose (PostgreSQL, Redis, backend, frontend) |

## Project Structure

```
milli-tax-app/
├── frontend/                # React app + Capacitor iOS wrapper
│   ├── src/
│   │   ├── pages/           # App screens (Dashboard, Savings, Accounts, etc.)
│   │   ├── components/      # Shared UI (TierGate, ErrorBoundary, etc.)
│   │   ├── services/        # Frontend service modules
│   │   ├── native/          # Capacitor native bridge modules
│   │   ├── context/         # React context providers
│   │   ├── hooks/           # Custom React hooks
│   │   ├── constants/       # App constants and config
│   │   ├── styles/          # Design system CSS
│   │   └── tests/           # Jest unit tests
│   ├── ios/                 # Xcode project (Capacitor)
│   ├── capacitor.config.json
│   └── tailwind.config.js
├── backend/                 # Python FastAPI + tax engine
│   ├── server.py            # Main API server (109KB monolith)
│   ├── main.py              # FastAPI app factory and route registration
│   ├── tax_engine.py        # Tax calculation engine (2025 IRS constants)
│   ├── autopilot.py         # Automated tax planning
│   ├── integrations.py      # Third-party integrations (Stripe, Alpaca, etc.)
│   ├── card_issuer.py       # Stripe Issuing card fulfillment
│   ├── card_routes.py       # Card order + webhook routes
│   ├── plaid_client.py      # Plaid bank integration
│   ├── plaid_webhook.py     # Plaid webhook receiver
│   ├── schedule_c_pdf.py    # Schedule C PDF generation
│   ├── taxbandits.py        # TaxBandits e-filing integration
│   ├── apns.py              # Apple Push Notification Service
│   ├── notifications.py     # Notification helpers
│   ├── market.py            # Market data module
│   ├── migrations/          # PostgreSQL migration scripts
│   ├── tests/               # Backend test suite
│   ├── pytest.ini
│   ├── requirements.txt
│   └── Dockerfile
├── docker-compose.yml       # PostgreSQL + Redis + backend + frontend
├── design_guidelines.json   # Brand design spec
├── .env.example             # Environment variable template
├── .nvmrc                   # Node version pin (18.20.4 LTS)
├── CODEOWNERS
├── IOS_BUILD_GUIDE.md
└── APP_STORE_METADATA.md
```

## Getting Started

### Prerequisites

- Node.js 18+ (pinned via `.nvmrc`)
- Python 3.10+
- Xcode 15+ (for iOS builds)
- Docker + Docker Compose (optional, for containerized dev)

### Frontend

```bash
cd frontend
npm install
npm start              # Development server
npm run build          # Production build
npx cap sync ios       # Sync to Xcode project
```

### Backend

```bash
cd backend
pip install -r requirements.txt
python server.py       # Starts FastAPI server
```

### Docker (all services)

```bash
docker-compose up      # PostgreSQL + Redis + backend + frontend
```

### Tests

```bash
# Backend
cd backend
pytest

# Frontend
cd frontend
npm test               # Jest + React Testing Library
```

## Environment Variables

See `.env.example` for the full list. Key variables:

- `STRIPE_SECRET_KEY` — Stripe API key (subscriptions + card issuing)
- `STRIPE_CARD_WEBHOOK_SECRET` — Stripe Issuing webhook signing secret
- `PLAID_CLIENT_ID` / `PLAID_SECRET` / `PLAID_ENV` — Plaid bank integration
- `DATABASE_URL` — PostgreSQL connection string
- `REDIS_URL` — Redis connection string
- `JWT_SECRET` — JWT auth signing secret
- `SSN_ENCRYPTION_KEY` — Encryption key for SSN last 4 at rest

## iOS Build & App Store

1. Build the web app: `cd frontend && npm run build && npx cap sync ios`
2. Open in Xcode: `cd frontend/ios && open App.xcworkspace`
3. Configure signing (Apple Developer account required)
4. Archive and upload to App Store Connect

See `IOS_BUILD_GUIDE.md` and `APP_STORE_METADATA.md` for detailed instructions.

## CI/CD

A GitHub Actions CI workflow is planned but not yet active (pending GitHub token scope configuration). The workflow will run backend tests, frontend tests, and build verification on push to main.

## License

Proprietary. All rights reserved.