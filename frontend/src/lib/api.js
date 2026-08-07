import axios from "axios";

// HARDCODED PRODUCTION LOCK — v4.9.
// Do NOT parameterize. The iOS Capacitor build loads at capacitor://localhost
// so relative URLs and window.location.origin cannot resolve to the backend.
// This constant guarantees every request goes to the production preview backend.
export const BACKEND_URL = "https://worker-finance-api.preview.emergentagent.com";
export const API_BASE = "https://milli-tax-app.onrender.com/api";

export const api = axios.create({ baseURL: API_BASE });

api.interceptors.request.use((cfg) => {
  const t = localStorage.getItem("milli_token");
  if (t) cfg.headers.Authorization = `Bearer ${t}`;
  return cfg;
});

export function formatApiError(e) {
  const d = e?.response?.data?.detail;
  if (!d) return e?.message || "Something went wrong.";
  if (typeof d === "string") return d;
  if (Array.isArray(d)) return d.map((x) => x?.msg || JSON.stringify(x)).join(" ");
  if (d?.msg) return d.msg;
  return String(d);
}

export function money(n) {
  if (n == null || isNaN(n)) return "$0.00";
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(n);
}

export function num(n, digits = 1) {
  if (n == null || isNaN(n)) return "0";
  return Number(n).toLocaleString("en-US", { minimumFractionDigits: 0, maximumFractionDigits: digits });
}
