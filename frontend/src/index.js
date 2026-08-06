import React from "react";
import ReactDOM from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { SplashScreen } from "@capacitor/splash-screen";
import "@/index.css";
import App from "@/App";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60_000,
      refetchOnWindowFocus: false,
    },
  },
});

class StartupErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    console.error("Milli startup failed", error, info);
  }

  render() {
    if (!this.state.error) return this.props.children;

    return (
      <main
        style={{
          minHeight: "100vh",
          background: "#050607",
          color: "#fff",
          display: "grid",
          placeItems: "center",
          padding: "32px",
          fontFamily: "system-ui, sans-serif",
          textAlign: "center",
        }}
      >
        <section style={{ maxWidth: 560 }}>
          <h1 style={{ marginBottom: 12 }}>Milli could not finish loading.</h1>
          <p style={{ color: "#a1a1aa", lineHeight: 1.6 }}>
            Close and reopen the app. If this screen returns, reinstall the latest build.
          </p>
          {process.env.NODE_ENV !== "production" && (
            <pre
              style={{
                marginTop: 20,
                whiteSpace: "pre-wrap",
                textAlign: "left",
                background: "#111418",
                borderRadius: 12,
                padding: 16,
                overflow: "auto",
              }}
            >
              {String(this.state.error?.stack || this.state.error)}
            </pre>
          )}
        </section>
      </main>
    );
  }
}

const rootElement = document.getElementById("root");
if (!rootElement) {
  throw new Error("Missing #root application mount point");
}

const root = ReactDOM.createRoot(rootElement);
root.render(
  <StartupErrorBoundary>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </StartupErrorBoundary>,
);

const hideNativeSplash = () => {
  SplashScreen.hide().catch((error) => {
    console.warn("Unable to hide native splash screen", error);
  });
};

requestAnimationFrame(() => requestAnimationFrame(hideNativeSplash));
window.addEventListener("load", hideNativeSplash, { once: true });
