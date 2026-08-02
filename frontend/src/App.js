import "@/styles/glass-polish.css";
import "@/styles/wealth-polish.css";
import "@/styles/milli-cents-dashboard.css";
import ErrorBoundary from "@/components/ErrorBoundary";
import ConnectionIndicator from "@/components/ServerStatus";
import "@/App.css";
import { useState } from "react";
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
import MilliCentsDashboard from "@/pages/MilliCentsDashboard";
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
import Wealth from "@/pages/Wealth";
import Referral from "@/pages/Referral";
import Onboarding from "@/pages/Onboarding";
import MarketingStudio from "@/pages/MarketingStudio";
import Paywall from "@/pages/Paywall";
import WealthHub from "@/pages/WealthHub";
import ActivityHub from "@/pages/ActivityHub";
import CockpitHub from "@/pages/CockpitHub";

function OnboardingGate({ children }) {
  const { user } = useAuth();
  if (user && user.onboarding_complete === false) return <Navigate to="/onboarding" replace />;
  return children;
}

function SplashWrapper({ onDone }) {
  const { user } = useAuth();
  const userName = user?.name || user?.first_name || user?.full_name || "";
  return <SplashScreen onDone={onDone} userName={userName} />;
}

function ProtectedAppScreen({ children, requireOnboarding = true }) {
  const content = requireOnboarding ? <OnboardingGate>{children}</OnboardingGate> : children;
  return <ProtectedRoute><AppLayout>{content}</AppLayout></ProtectedRoute>;
}

function App() {
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
          {!splashDone && <SplashWrapper onDone={onSplashDone} />}
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

            <Route path="/app" element={<ProtectedAppScreen><MilliCentsDashboard /></ProtectedAppScreen>} />
            <Route path="/app/overview" element={<ProtectedAppScreen><Dashboard /></ProtectedAppScreen>} />
            <Route path="/app/income" element={<ProtectedAppScreen><Income /></ProtectedAppScreen>} />
            <Route path="/app/mileage" element={<ProtectedAppScreen><Mileage /></ProtectedAppScreen>} />
            <Route path="/app/expenses" element={<ProtectedAppScreen><Expenses /></ProtectedAppScreen>} />
            <Route path="/app/ai" element={<ProtectedAppScreen><AIAssistant /></ProtectedAppScreen>} />
            <Route path="/app/reports" element={<ProtectedAppScreen><Reports /></ProtectedAppScreen>} />
            <Route path="/app/pricing" element={<ProtectedAppScreen requireOnboarding={false}><Pricing /></ProtectedAppScreen>} />
            <Route path="/app/settings" element={<ProtectedAppScreen requireOnboarding={false}><Settings /></ProtectedAppScreen>} />
            <Route path="/app/vault" element={<ProtectedAppScreen><Vault /></ProtectedAppScreen>} />
            <Route path="/app/quarterly" element={<ProtectedAppScreen><Quarterly /></ProtectedAppScreen>} />
            <Route path="/app/more" element={<ProtectedAppScreen requireOnboarding={false}><More /></ProtectedAppScreen>} />
            <Route path="/app/wealth" element={<ProtectedAppScreen><WealthHub /></ProtectedAppScreen>} />
            <Route path="/app/retirement" element={<ProtectedAppScreen><Retirement /></ProtectedAppScreen>} />
            <Route path="/app/investing" element={<ProtectedAppScreen><Investing /></ProtectedAppScreen>} />
            <Route path="/app/referral" element={<ProtectedAppScreen><Referral /></ProtectedAppScreen>} />
            <Route path="/app/activity" element={<ProtectedAppScreen><ActivityHub /></ProtectedAppScreen>} />
            <Route path="/app/cockpit" element={<ProtectedAppScreen><CockpitHub /></ProtectedAppScreen>} />
          </Routes>
          <Toaster theme="dark" />
        </AuthProvider>
      </BrowserRouter>
    </ErrorBoundary>
  );
}

export default App;
