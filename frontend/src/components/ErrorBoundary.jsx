import { Component } from "react";

const CYAN = "#00E5FF";

/**
 * ErrorBoundary — catches React render crashes and shows a styled
 * fallback instead of a white screen with blue links.
 */
export default class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, info) {
    console.error("[Milli ErrorBoundary]", error, info?.componentStack);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            minHeight: "100vh",
            background: "#050607",
            color: "#FFFFFF",
            fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif',
            padding: 32,
            textAlign: "center",
          }}
        >
          <div
            style={{
              width: 64,
              height: 64,
              borderRadius: "50%",
              border: `2px solid ${CYAN}`,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              marginBottom: 24,
              boxShadow: `0 0 20px rgba(0, 229, 255, 0.3)`,
            }}
          >
            <span style={{ fontSize: 28, fontWeight: 700, color: CYAN }}>M</span>
          </div>
          <h2 style={{ fontSize: 20, fontWeight: 600, marginBottom: 8 }}>
            Something went wrong
          </h2>
          <p style={{ fontSize: 14, color: "#8B9DAF", maxWidth: 280, marginBottom: 24 }}>
            Milli hit an unexpected error. Pull down to refresh or tap below to restart.
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              background: CYAN,
              color: "#050607",
              border: "none",
              borderRadius: 12,
              padding: "14px 32px",
              fontSize: 15,
              fontWeight: 600,
              cursor: "pointer",
            }}
          >
            Restart Milli
          </button>
          {this.props.showError && (
            <pre
              style={{
                marginTop: 24,
                fontSize: 10,
                color: "#8B9DAF",
                maxWidth: "90vw",
                overflow: "auto",
                textAlign: "left",
                background: "rgba(13,17,23,0.6)",
                padding: 12,
                borderRadius: 8,
              }}
            >
              {this.state.error?.message || "Unknown error"}
            </pre>
          )}
        </div>
      );
    }
    return this.props.children;
  }
}
