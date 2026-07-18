import "@/App.css";
import { useState } from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider, useAuth } from "@/context/AuthContext";
import { Toaster } from "@/components/ui/sonner";
import ProtectedRoute from "@/components/ProtectedRoute";
import AppLayout from "@/components/AppLayout";
import Splash from "@/components/SplashScreen";
import OnboardingCarousel from "@/components/OnboardingCarousel";

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

function OnboardingGate({ children }) {
  const { user } = useAuth();
  if (user && user.onboarding_complete === false) return <Navigate to="/onboarding" replace />;
  return children;
}

function App() {
  // Show splash only on first session entry (per browser session)
  const [splashDone, setSplashDone] = useState(() => {
    try { return sessionStorage.getItem("milli_splash_seen") === "1"; } catch { return false; }
  });
  // Onboarding: persistent across sessions — only shown once ever
  const [onboardingDone, setOnboardingDone] = useState(() => {
    try { return localStorage.getItem("milli_onboarding_complete") === "true"; } catch { return true; }
  });
  const onSplashDone = () => {
    try { sessionStorage.setItem("milli_splash_seen", "1"); } catch (_) { /* noop */ }
    setSplashDone(true);
  };
  const onOnboardingDone = () => {
    try { localStorage.setItem("milli_onboarding_complete", "true"); } catch (_) { /* noop */ }
    setOnboardingDone(true);
  };
  return (
    <div className="App">
      {!splashDone && <Splash onDone={onSplashDone} />}
      {splashDone && !onboardingDone && <OnboardingCarousel onFinish={onOnboardingDone} />}
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
            <Route path="/app/more" element={<ProtectedRoute><AppLayout><More /></AppLayout></ProtectedRoute>} />
            <Route path="/app/retirement" element={<ProtectedRoute><OnboardingGate><AppLayout><Retirement /></AppLayout></OnboardingGate></ProtectedRoute>} />
            <Route path="/app/investing" element={<ProtectedRoute><OnboardingGate><AppLayout><Investing /></AppLayout></OnboardingGate></ProtectedRoute>} />
          </Routes>
          <Toaster theme="dark" />
        </AuthProvider>
      </BrowserRouter>
    </div>
  );
}

export default App;
