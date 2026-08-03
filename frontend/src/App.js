import "@App.css";
import { useState, Component } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, useAuth } from "@/context/AuthContext";
import { Toaster } from "@/components/ui/sonner";
import ProtectedRoute from "@/components/ProtectedRoute";
import AppLayout from "@/components/AppLayout";
import Splash from "@/components/SplashScreen";
import OnboardingCarousel from "@/components/OnboardingCarousel";
import WelcomePaywall from "@/components/WelcomePaywall";

import Landing from "@/pages/Landing";
import Login from "@/pages/Login";
import Register from "@/pages/Register";
import Dashboard from "@/pages/Dashboard";
import Income from "@/pages/Income";
import Mileage from "@/pages/Mileage";
import Expenses from "@/pages/Expenses";
import AIAssistant from "@/pages/AIAssistant";
import Reports from "@/pages/Reports";
import Pricing from "@/pages/Pricing";
import BillingSuccess from "@/pages/BillingSuccess";
import Settings from "@/pages/Settings";
import Vault from "@/pages/Vault";
import Quarterly from "@/pages/Quarterly";
import More from "@/pages/More";
import Retirement from "@/pages/Retirement";
import Investing from "@/pages/Investing";
import Onboarding from "@/pages/Onboarding";
import MarketingStudio from "@/pages/MarketingStudio";
import Paywall from "@/pages/Paywall";
import Wealth from "@/pages/Wealth";
import MilliCents from "@/pages/MilliCents";
import Savings from "@/pages/Savings";
import Accounts from "@/pages/Accounts";
import Vehicles from "@/pages/Vehicles";

/* ──────────────────────────────────────────────────────────────────────────
 * ErrorBoundary — prevents full white-screen crashes on iOS WKWebView.
 * If any page component throws, a branded fallback is shown instead of
 * a blank screen, with a retry button.
 * ────────────────────────────────────────────────────────────────────────── */
class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error, info) {
    console.error("[Milli] ErrorBoundary caught:", error, info);
  }

  handleRetry = () => {
    this.setState({ hasError: false });
    if (typeof window !== "undefined") window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      return (
        <div
          className="fixed inset-0 z-[9999] flex flex-col items-center justify-center bg-[#0A0A0A] px-6 text-center"
          data-testid="error-boundary-fallback"
        >
          <div
            className="mb-6 text-5xl font-bold tracking-tight"
            style={{ fontFamily: '"Outfit", system-ui, sans-serif' }}
          >
            <span className="text-white">M</span>
            <span className="text-volt">I</span>
            <span className="text-white">LL</span>
            <span className="text-volt">I</span>
          </div>
          <p className="mb-2 text-lg font-medium text-white">
            Something went wrong
          </p>
          <p className="mb-8 max-w-xs text-sm text-white/50">
            An unexpected error occurred. Try reloading the app.
          </p>
          <button
            onClick={this.handleRetry}
            data-testid="error-boundary-retry"
            className="rounded-lg bg-volt px-6 py-3 text-sm font-bold uppercase tracking-wide text-black transition-transform hover:-translate-y-0.5 active:translate-y-0"
            style={{ backgroundColor: '#D4FF00' }}
          >
            Reload App
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

function OnboardingGate({ children }) {
  const { user } = useAuth();
  if (user && user.onboarding_complete === false) return <Navigate to="/onboarding" replace />;
  return children;
}

function App() {
  // Show splash only on first session entry.
  // FIX: Use localStorage instead of sessionStorage — in Capacitor/iOS WKWebView,
  // sessionStorage gets cleared when the app is backgrounded or killed, causing
  // the splash to re-trigger on every app resume. localStorage persists correctly.
  const [splashDone, setSplashDone] = useState(() => {
    try { return localStorage.getItem("milli_splash_seen") === "1"; } catch { return false; }
  });
  // Tier must be selected before onboarding is unlocked (persistent).
  const [planSelected, setPlanSelected] = useState(() => {
    try { return !!localStorage.getItem("milli_selected_plan"); } catch { return true; }
  });
  // Onboarding: persistent across sessions — only shown once ever
  const [onboardingDone, setOnboardingDone] = useState(() => {
    try { return localStorage.getItem("milli_onboarding_complete") === "true"; } catch { return true; }
  });

  // First launch = user has never picked a plan. In that case the splash
  // auto-fades directly into the Welcome Paywall (no tap required).
  const firstLaunch = !planSelected;

  const onSplashDone = () => {
    try { localStorage.setItem("milli_splash_seen", "1"); } catch { /* noop */ }
    setSplashDone(true);
  };
  const onPlanSelected = () => { setPlanSelected(true); };
  const onOnboardingDone = () => {
    try { localStorage.setItem("milli_onboarding_complete", "true"); } catch { /* noop */ }
    setOnboardingDone(true);
  };

  return (
    <div className="App ios-frame-outer">
      <div className="ios-frame native-scroll">
        {!splashDone && <Splash onDone={onSplashDone} autoFade={firstLaunch} />}
        {splashDone && !planSelected && <WelcomePaywall onSelected={onPlanSelected} />}
        {splashDone && planSelected && !onboardingDone && (
          <OnboardingCarousel onFinish={onOnboardingDone} />
        )}
        <ErrorBoundary>
        <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route path="/" element={<Landing />} />
            <Route path="/marketing" element={<MarketingStudio />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/billing/success" element={<BillingSuccess />} />

            <Route path="/onboarding" element={<ProtectedRoute><Onboarding /></ProtectedRoute>} />

            <Route path="/app" element={<ProtectedRoute><OnboardingGate><AppLayout><Dashboard /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/income" element={<ProtectedRoute><OnboardingGate><AppLayout><Income /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/mileage" element={<ProtectedRoute><OnboardingGate><AppLayout><Mileage /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/expenses" element={<ProtectedRoute><OnboardingGate><AppLayout><Expenses /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/ai" element={<ProtectedRoute><OnboardingGate><AppLayout><AIAssistant /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/reports" element={<ProtectedRoute><OnboardingGate><AppLayout><Reports /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/pricing" element={<ProtectedRoute><AppLayout><Pricing /></AppLayout></ProtectedRoute>} />
            <Route path="/app/settings" element={<ProtectedRoute><AppLayout><Settings /></AppLayout></ProtectedRoute>} />
            <Route path="/app/vault" element={<ProtectedRoute><OnboardingGate><AppLayout><Vault /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/quarterly" element={<ProtectedRoute><OnboardingGate><AppLayout><Quarterly /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/more" element={<ProtectedRoute><OnboardingGate><AppLayout><More /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/retirement" element={<ProtectedRoute><OnboardingGate><AppLayout><Retirement /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/investing" element={<ProtectedRoute><OnboardingGate><AppLayout><Investing /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/referral" element={<ProtectedRoute><OnboardingGate><AppLayout><Referral /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/wealth" element={<ProtectedRoute><OnboardingGate><AppLayout><Wealth /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/milli-cents" element={<ProtectedRoute><OnboardingGate><AppLayout><MilliCents /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/savings" element={<ProtectedRoute><OnboardingGate><AppLayout><Savings /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/accounts" element={<ProtectedRoute><OnboardingGate><AppLayout><Accounts /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/vehicles" element={<ProtectedRoute><OnboardingGate><AppLayout><Vehicles /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/paywall" element={<ProtectedRoute><Paywall /></ProtectedRoute>} />
            <Route path="/app/paywall" element={<ProtectedRoute><Paywall /></ProtectedRoute>} />
          </Routes>
          <Toaster theme="dark" />
        </AuthProvider>
        </BrowserRouter>
        </ErrorBoundary>
      </div>
    </div>
  );
}

export default App;