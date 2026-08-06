# Milli — Tax Autopilot for Gig Workers

Milli is an iOS + iPad + Apple Watch app that automates tax tracking, estimation, and filing for gig economy workers. Built with React (Capacitor) on the frontend and a Python (FastAPI) backend with a full tax calculation engine.

## Features

### Core Tax Features
- **Tax Autopilot**: Automatic quarterly tax estimation and payment reminders
- **Mileage Tracking**: GPS-based mileage logging for deductible miles
- **Tax Vault**: Secure document storage with Face ID protection
- **1099 & Schedule C**: Import and generate tax forms
- **Annual Taxes**: Full annual tax filing preview and preparation
- **State-by-State Tax Engine**: Full 2025/2026 IRS tax brackets and state tax calculations
- **Tax Payment**: IRS Direct Pay and card-based tax payments
- **E-Filing**: IRS Modernized e-File API integration (via TaxBandits)

### Financial Features
- **Income Tracking**: Real-time income dashboard with multiple income sources
- **Expense Tracking**: Categorized expense logging with receipt OCR (Google Vision)
- **Investing Dashboard**: Track retirement projections and investment accounts
- **Retirement Planning**: IRA/Solo 401(k) projections with contribution tracking
- **Savings Goals**: Goal-based savings with progress tracking and auto-allocation
- **Banking (Elite only)**: Checking accounts and Visa debit card via banking partner
- **Brokerage**: Stock/ETF trading via Alpaca API integration
- **Plaid Integration**: Auto-pull bank transactions for real-time tax calculations

### Milli Visa Elite Card
- **Card Opt-in Flow**: 4-step ordering workflow (material selection, shipping/KYC, review, confirmation)
- **Material Options**: Brushed metal (included) or aerospace titanium (+$49)
- **Stripe Issuing Integration**: Real card production, printing, and shipping via Stripe Issuing API
- **Delivery Tracking**: Webhook-based card shipping status updates

### Subscription Tiers
- **Basic ($19.99/mo)**: Core tax tracking, mileage, vault, quarterly estimates
- **Pro ($29.99/mo)**: Everything in Basic + investing dashboard, retirement planning, reports
- **Elite ($49.99/mo)**: Everything in Pro + checking accounts, Visa card, brokerage, e-filing

### Security & Auth
- **Biometric Authentication**: Face ID / Touch ID for app access
- **MFA (TOTP)**: Time-based one-time password multi-factor authentication
- **Social Login**: Google and Apple Sign-In
- **KYC Verification**: Identity verification via Persona/Stripe Identity
- **JWT Auth**: Token-based authentication with refresh tokens

### Admin
- **Admin Dashboard**: User management, revenue analytics, plan distribution
- **Security Settings**: Biometric, MFA, and social login configuration

## Tech Stack

| Layer | Technology |
|------|-----------|
| Frontend | React 18 + Tailwind CSS 3 + Capacitor 7 (iOS) |
| Backend | Python 3.11 / FastAPI |
| Database | MongoDB (via Motor async driver) |
| Tax Engine | Custom Python module (2025/2026 IRS constants, state brackets, quarterly planning) |
| iOS | Native Capacitor bridge, Storyboard launch screen, PrivacyInfo.xcprivacy, UIScene lifecycle |
| Design | Dark theme, neon cyan (#00E5FF), Volt Yellow (#D4FF00) CTA, glassmorphism, carbon-fiber pattern |
| Fonts | Outfit (headings), IBM Plex Sans (body), JetBrains Mono (monospace) |
| Payments | Stripe (subscriptions + Issuing for card fulfillment) |
| Banking | Plaid (bank connections, transaction sync) |
| Brokerage | Alpaca API (stocks/ETFs) |
| KYC | Persona / Stripe Identity |
| OCR | Google Cloud Vision |
| E-Filing | TaxBandits API |
| Notifications | Apple Push Notification Service (APNs) |
| Testing | Jest + React Testing Library (frontend), pytest (backend) |
| CI/CD | GitHub Actions (frontend build + ESLint + tests, backend install + engine tests, iOS sync + CocoaPods + Xcode build) |
| Infra | Docker Compose (MongoDB, backend, frontend) |

## Project Structure

```
milli-tax-app/
├── frontend/                    # React app + Capacitor iOS wrapper
│   ├── src/
│   │   ├── App.js               # Routes, ErrorBoundary, app entry
│   │   ├── pages/               # 28 page components
│   │   │   ├── Dashboard.jsx
│   │   │   ├── Income.jsx
│   │   │   ├── Expenses.jsx
│   │   │   ├── Mileage.jsx
│   │   │   ├── Vault.jsx
│   │   │   ├── MilliCents.jsx
│   │   │   ├── Investing.jsx
│   │   │   ├── Retirement.jsx
│   │   │   ├── Savings.jsx
│   │   │   ├── Accounts.jsx     # Elite-gated
│   │   │   ├── Vehicles.jsx
│   │   │   ├── CardOrder.jsx    # Elite Visa Card opt-in
│   │   │   ├── Documents.jsx
│   │   │   ├── AnnualTaxes.jsx
│   │   │   ├── Subscription.jsx
│   │   │   ├── Quarterly.jsx
│   │   │   ├── Reports.jsx
│   │   │   ├── AdminDashboard.jsx
│   │   │   ├── SecuritySettings.jsx
│   │   │   ├── AIAssistant.jsx
│   │   │   ├── MarketingStudio.jsx
│   │   │   ├── Referral.jsx
│   │   │   ├── Onboarding.jsx
│   │   │   ├── Landing.jsx
│   │   │   ├── Login.jsx
│   │   │   ├── Register.jsx
│   │   │   ├── PayPal.jsx
│   │   │   ├── Pricing.jsx
│   │   │   └── ...
│   │   ├── components/          # Shared UI components
│   │   │   ├── AppLayout.jsx    # Drawer nav + bottom tab bar
│   │   │   ├── TierGate.jsx     # Subscription tier gating
│   │   │   ├── MilliCard.jsx    # Animated card visual
│   │   │   ├── SplashScreen.jsx # Production splash
│   │   │   ├── ProtectedRoute.jsx
│   │   │   ├── BankConnections.jsx
│   │   │   ├── SmartAccount.jsx
│   │   │   └── ...
│   │   ├── styles/              # design-system.css with brand tokens
│   │   ├── tests/               # Frontend unit tests
│   ├── ios/                     # Xcode project (Capacitor)
│   │   ├── capacitor.config.json
│   ├── backend/                  # Python FastAPI + tax engine
│   ├── server.py                # Main API server (auth, users, tax, expenses, etc.)
│   ├── tax_engine.py            # Tax calculation engine (2025/2026 IRS + state)
│   ├── autopilot.py             # Automated tax planning
│   ├── integrations.py          # Stripe, Plaid, Alpaca, banking, KYC, OCR, e-filing
│   ├── card_issuer.py           # Stripe Issuing card fulfillment
│   ├── card_routes.py           # Card order + webhook endpoints
│   ├── plaid_client.py          # Plaid bank connection client
│   ├── plaid_webhook.py         # Plaid transaction webhook receiver
│   ├── apns.py                  # Apple Push Notifications
│   ├── notifications.py        # Notification service
│   ├── taxbandits.py            # TaxBandits e-filing integration
│   ├── schedule_c_pdf.py       # Schedule C PDF generation
│   ├── market.py                # Market data service
│   ├── main.py                  # App factory + route registration
│   ├── migrations/              # Database migrations
│   ├── tests/                   # Backend test suite
│   ├── Dockerfile
│   ├── requirements.txt
├── docker-compose.yml           # MongoDB + backend + frontend
├── .env.example                 # All environment variables
├── design_guidelines.json       # Brand design system spec
├── APP_STORE_METADATA.md        # App Store listing metadata
├── IOS_BUILD_GUIDE.md           # Xcode build instructions
└── scripts/                     # Build and utility scripts
```

## Getting Started

### Prerequisites

- Node.js 22+ (see `.nvmrc`)
- Python 3.11+
- Xcode 15+ (for iOS builds)
- Docker & Docker Compose (for local infra)

### Frontend

```bash
cd frontend
npm install
npm start                 # Development server
npm run build            # Production build
npx cap sync ios         # Sync to Xcode project
```

### Backend

```bash
cd backend
pip install -r requirements.txt
python server.py         # Starts FastAPI server on :5000
```

### Full Stack with Docker

```bash
docker-compose up -d     # MongoDB, backend, frontend
```

### Tests

```bash
# Frontend
cd frontend
npm test

# Backend
cd backend
pytest
```

### CI/CD

The repo includes a [GitHub Actions workflow](.github/workflows/validate.yml) that runs on every push to `main` and every PR:

- **Frontend**: npm install → ESLint → production build → native startup HTML verification → Jest tests
- **Backend**: pip install → Python compilation → production API import → MongoDB-backed engine tests → 2025/2026 tax tests
- **iOS**: npm install → production build → Capacitor sync → CocoaPods install → Xcode simulator compilation

## Environment Variables

Copy `.env.example` to `.env` and fill in your values. Key variables:

| Variable | Purpose |
|---------|---------|
| `MONGO_URL` | MongoDB connection string |
| `JWT_SECRET` | JWT token signing secret |
| `STRIPE_API_KEY` / `STRIPE_SECRET_KEY` | Stripe API keys (subscriptions + Issuing) |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signature verification |
| `PLAID_CLIENT_ID` / `PLAID_SECRET` | Plaid bank integration |
| `PLAID_WEBHOOK_URL` | Plaid transaction webhook endpoint |
| `APNS_TEAM_ID` / `APNS_KEY_ID` | Apple Push Notifications |
| `TAXBANDITS_CLIENT_ID` / `TAXBANDITS_CLIENT_SECRET` | TaxBandits e-filing |
| `ALPACA_API_KEY` / `ALPACA_SECRET_KEY` | Alpaca brokerage |
| `GOOGLE_APPLICATION_CREDENTIALS` | Google Cloud Vision (OCR) |
| `PERSONA_API_KEY` / `PERSONA_TEMPLATE_ID` | KYC verification |
| `REACT_APP_API_URL` | Frontend API base URL |
| `DEMO_MODE_ENABLED` | Demo data seeding (disabled by default, never in production) |
| `ALLOW_UNVERIFIED_STOREKIT` | Unverified StoreKit fallback (false for production) |

## iOS Build & App Store

1. Build the web app: `cd frontend && npm run build && npx cap sync ios`
2. Open in Xcode: `cd frontend/ios && open App.xcworkspace`
3. Configure signing (Apple Developer account required)
4. Archive and upload to App Store Connect

See `IOS_BUILD_GUIDE.md` and `APP_STORE_METADATA.md` for detailed instructions.

## License

Proprietary. All rights reserved.