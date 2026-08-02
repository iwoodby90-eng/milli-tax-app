import axios from "axios";

/**
 * BACKEND URL — HARDCODED.
 *
 * The FastAPI backend mounts all routes under /api/* prefix:
 *   api = APIRouter(prefix="/api")  →  /api/health, /api/auth/login, etc.
 *
 * Capacitor iOS webview runs at capacitor://localhost, so no dynamic
 * URL resolution is possible. This literal string is the ONLY correct value.
 *
 * NOTE: During cold-start (pod waking from sleep), the backend takes 5-8s
 * to bind. During this window, /api/* routes may 502/404 via Cloudflare.
 * The ServerStatus overlay handles this gracefully.
 */
export const BACKEND_URL = "https://worker-finance-api.preview.emergentagent.com";
export const API_BASE = BACKEND_URL;

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
 * Hits /api/health (the actual backend route).
 */
export async function checkBackendHealth() {
  try {
    const res = await axios.get(`${API_BASE}/health`, { timeout: 8000 });
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
