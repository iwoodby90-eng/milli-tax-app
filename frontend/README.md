# Milli Frontend

React 18 + Capacitor 7 iOS app with Tailwind CSS 3, CRACO build system, and Phosphor Icons.

## Prerequisites

- Node.js 22+ (see `.nvmrc`)
- npm 9+

## Quick Start

```bash
cd frontend
npm install
npm start              # Development server on http://localhost:3000
```

## Available Scripts

| Command | Description |
|---------|-------------|
| `npm start` | Start development server (CRACO) |
| `npm run build` | Production build to `build/` |
| `npm test` | Run Jest test suite |
| `npm run test:watch` | Run tests in watch mode |
| `npm run test:coverage` | Run tests with coverage |
| `npm run lint` | Run ESLint (zero-warnings gate) |
| `npx cap sync ios` | Sync web build to Capacitor iOS project |
| `npx cap open ios` | Open Xcode project |

## Build Pipeline

The production build uses CRACO (Create React App Configuration Override) with:

- **Tailwind CSS 3** via PostCSS
- **Path aliases** (`@/` → `src/`) via `craco.config.js`
- **ESLint** error gate (build fails on lint errors)
- **Jest** with React Testing Library

### Rebuild from scratch

```bash
rm -rf node_modules package-lock.json build
npm install
npm run build
```

## iOS Integration

The Capacitor iOS project lives in `ios/App/`. After a web build:

```bash
npx cap sync ios        # Sync web assets to Xcode project
cd ios/App
pod install             # Install CocoaPods dependencies
```

Then open `App.xcworkspace` in Xcode to build and run on simulator or device.

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `react` / `react-dom` 18 | UI framework |
| `tailwindcss` 3 | Utility-first CSS |
| `@phosphor-icons/react` 2.x | Icon library |
| `@radix-ui/react-*` | Accessible UI primitives |
| `framer-motion` | Animations |
| `recharts` | Charts and graphs |
| `@stripe/stripe-js` | Stripe payments |
| `react-plaid-link` | Plaid bank linking |
| `@react-oauth/google` | Google Sign-In |
| `@capacitor/*` 7.x | Native iOS bridge |
| `@capgo/capacitor-native-biometric` | Face ID / Touch ID |
| `embla-carousel-react` | Carousel component |
| `react-router-dom` 6 | Client-side routing |
| `@tanstack/react-query` | Server state management |
| `axios` | HTTP client |
| `zustand` | State management |
| `date-fns` | Date utilities |
| `sonner` | Toast notifications |
| `lucide-react` | Secondary icon library |

## Design System

- **Theme**: Dark (#050607 background)
- **Primary**: Neon Cyan (#00E5FF)
- **CTA**: Volt Yellow (#D4FF00)
- **Fonts**: Outfit (headings), IBM Plex Sans (body), JetBrains Mono (monospace)
- **Style**: Glassmorphism, carbon-fiber patterns, cinematic dark UI

## Testing

```bash
npm test                         # Run all tests
npm run test:watch               # Watch mode
npm run test:coverage            # With coverage report
```

Tests use Jest + React Testing Library. Test files live alongside components in `src/__tests__/` or as `*.test.js` files.

## Linting

```bash
npm run lint                     # ESLint with zero-warnings gate
```

ESLint extends `react-app` with `no-unused-vars` set to `"warn"`.