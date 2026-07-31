import axios from "axios";

/**
 * BACKEND URL — HARDCODED.
 *
 * The FastAPI backend mounts routes at the ROOT level (e.g. /health,
 * /auth/login) — NOT under /api/*. The Capacitor iOS webview runs at
 * capacitor://localhost so no dynamic resolution is possible.
 *
 * DO NOT add "/api" suffix. DO NOT use env vars or window.location.
 */
export const BACKEND_URL = "https://driver-tax-mileage.preview.emergentagent.com";
export const API_BASE = BACKEND_URL;  // routes are at root, NOT /api

export const api = axios.create({
  baseURL: API_BASE,
  timeout: 15000,
  headers: { "Content-Type": "application/json" },
});

// Attach JWT
api.interceptors.request.use((cfg) => {
  try {
    const t = localStorage.getItem("milli_token");
    if (t) cfg.headers.Authorization = `Bearer ${t}`;
  } catch (_) {}
  return cfg;
});

// On 401 → clear token, redirect to login
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      try {
        localStorage.removeItem("milli_token");
        localStorage.removeItem("milli_user");
      } catch (_) {}
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }
    return Promise.reject(err);
  }
);

/**
 * Health check — verify backend is reachable.
 */
export async function checkBackendHealth() {
  try {
    const res = await axios.get(`${BACKEND_URL}/health`, { timeout: 8000 });
    return { ok: true, data: res.data };
  } catch (e) {
    return { ok: false, reason: e.message || "Backend unreachable" };
  }
}

export function formatApiError(e) {
  if (!e) return "Something went wrong.";
  if (e.code === "ERR_NETWORK" || e.code === "ECONNABORTED") {
    return "Cannot reach Milli servers. Check your connection.";
  }
  const d = e?.response?.data?.detail;
  if (!d) return e?.message || "Something went wrong.";
  if (typeof d === "string") return d;
  if (Array.isArray(d)) return d.map((x) => x?.msg || JSON.stringify(x)).join(" ");
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

export default api;
