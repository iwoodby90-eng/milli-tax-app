# Milli — Tax Autopilot for Gig Workers

Milli is an iOS + iPad + Apple Watch app that automates tax tracking, estimation, and filing for gig economy workers. Built with React (Capacitor) on the frontend and a Python (Flask) backend with a full tax calculation engine.

## Features

- **Tax Autopilot**: Automatic quarterly tax estimation and payment reminders
- **Mileage Tracking**: GPS-based mileage logging for deductible miles
- **Tax Vault**: Secure document storage with Face ID protection
- **1099 & Schedule C**: Import and generate tax forms
- **Investing Dashboard**: Track retirement projections and investment accounts
- **Milli VISA Elite**: Virtual card integration for tax-aware spending
- **State-by-State Tax Engine**: Full 2025 IRS tax brackets and state tax calculations

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React + Tailwind CSS + Capacitor (iOS) |
| Backend | Python / Flask |
| Tax Engine | Custom Python module (2025 IRS constants, state brackets, quarterly planning) |
| iOS | Native Capacitor bridge, Storyboard launch screen, PrivacyInfo.xcprivacy |
| Design | Dark theme, neon cyan (#00E5FF), glassmorphism, carbon-fiber pattern |

## Project Structure

```
milli-tax-app/
├── frontend/          # React app + Capacitor iOS wrapper
│   ├── src/            # React components and pages
│   ├── ios/            # Xcode project (Capacitor)
│   ├── capacitor.config.json
│   └── tailwind.config.js
├── backend/           # Python Flask API + tax engine
│   ├── server.py       # Main API server
│   ├── tax_engine.py   # Tax calculation engine
│   ├── autopilot.py    # Automated tax planning
│   ├── integrations.py # Third-party integrations
│   ├── apns.py         # Apple Push Notifications
│   └── tests/          # Backend test suite
├── marketing_site/    # Marketing landing page
├── marketing_videos/  # Promotional video assets
├── scripts/           # Build and utility scripts
└── tests/             # Integration tests
```

## Getting Started

### Prerequisites

- Node.js 18+
- Python 3.10+
- Xcode 15+ (for iOS builds)

### Frontend

```bash
cd frontend
npm install
npm start          # Development server
npm run build      # Production build
npx cap sync ios   # Sync to Xcode project
```

### Backend

```bash
cd backend
pip install -r requirements.txt
python server.py   # Starts Flask API
```

### Tests

```bash
cd backend
pytest
```

## iOS Build & App Store

1. Build the web app: `cd frontend && npm run build && npx cap sync ios`
2. Open in Xcode: `cd frontend/ios && open App.xcworkspace`
3. Configure signing (Apple Developer account required)
4. Archive and upload to App Store Connect

See `IOS_BUILD_GUIDE.md` and `APP_STORE_METADATA.md` for detailed instructions.

## License

Proprietary. All rights reserved.