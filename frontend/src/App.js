import "@/styles/glass-polish.css";
import ErrorBoundary from "@/components/ErrorBoundary";
import ConnectionIndicator from "@/components/ServerStatus";
import "@/App.css";
import { useState, useEffect } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, useAuth } from "@/context/AuthContext";
import { Toaster } from "@/components/ui/sonner";
import ProtectedRoute from "@/components/ProtectedRoute";
import AppLayout from "@/components/AppLayout";
import SplashScreen from "@/components/SplashScreen";

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
import Referral from "@/pages/Referral";
import Onboarding from "@/pages/Onboarding";
import MarketingStudio from "@/pages/MarketingStudio";
import Paywall from "@/pages/Paywall";

/**
 * App v2.2 — ZERO-SCROLL Startup Flow.
 *
 * Returning user flow (zero-touch):
 *   1. SplashScreen plays the 'Perfect' car video full-screen.
 *   2. Video ends → crossfade into 'Welcome back, [Name]'.
 *   3. 2-second hold → auto-fade into Dashboard.
 *
 * NO onboarding carousel, NO paywall gate blocks the view.
 * NO manual scrolling required at any point.
 *
 * First-time users still see /login → /register flow via routing.
 */

function OnboardingGate({ children }) {
  const { user } = useAuth();
  if (user && user.onboarding_complete === false) return <Navigate to="/onboarding" replace />;
  return children;
}

/**
 * SplashWrapper — reads user name from AuthContext for the welcome screen.
 * Fixed-position overlay that auto-dismisses. Zero scroll involvement.
 */
function SplashWrapper({ onDone }) {
  const { user } = useAuth();
  const userName = user?.name || user?.first_name || user?.full_name || "";
  return <SplashScreen onDone={onDone} userName={userName} />;
}

function App() {
  // Show splash only once per browser session
  const [splashDone, setSplashDone] = useState(() => {
    try { return sessionStorage.getItem("milli_splash_seen") === "1"; } catch { return false; }
  });

  const onSplashDone = () => {
    try { sessionStorage.setItem("milli_splash_seen", "1"); } catch (_) {}
    setSplashDone(true);
  };

  return (
    <ErrorBoundary>
      <BrowserRouter>
        <AuthProvider>
          {/* 
            SPLASH: Fixed-position overlay, z-index 100000.
            Sits ABOVE everything. No scroll needed — it's viewport-locked.
            Auto-dismisses after video + 2s welcome hold.
          */}
          {!splashDone && <SplashWrapper onDone={onSplashDone} />}

          {/* Non-blocking connection indicator */}
          <ConnectionIndicator />

          <Routes>
            <Route path="/" element={<Landing />} />
            <Route path="/marketing" element={<MarketingStudio />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/billing/success" element={<BillingSuccess />} />
            <Route path="/onboarding" element={<ProtectedRoute><Onboarding /></ProtectedRoute>} />
            <Route path="/paywall" element={<ProtectedRoute><Paywall /></ProtectedRoute>} />
            <Route path="/app/paywall" element={<ProtectedRoute><Paywall /></ProtectedRoute>} />

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
            <Route path="/app/more" element={<ProtectedRoute><AppLayout><More /></AppLayout></ProtectedRoute>} />
            <Route path="/app/retirement" element={<ProtectedRoute><OnboardingGate><AppLayout><Retirement /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/investing" element={<ProtectedRoute><OnboardingGate><AppLayout><Investing /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/referral" element={<ProtectedRoute><OnboardingGate><AppLayout><Referral /></AppLayout></OnboardingGate></ProtectedRoute>} />
          </Routes>
          <Toaster theme="dark" />
        </AuthProvider>
      </BrowserRouter>
    </ErrorBoundary>
  );
}

export default App;
