import axios from "axios";

/**
 * HARDCODED BACKEND URL.
 *
 * DO NOT use process.env, window.location, or any dynamic resolution.
 * Capacitor iOS loads from capacitor://localhost — relative URLs and
 * env vars resolve to nothing. This literal string is the ONLY correct
 * value. Period.
 */
export const API_BASE = "https://driver-tax-mileage.preview.emergentagent.com/api";

export const api = axios.create({
  baseURL: API_BASE,
  timeout: 15000,
  headers: { "Content-Type": "application/json" },
});

// Attach JWT from localStorage on every request
api.interceptors.request.use((cfg) => {
  try {
    const t = localStorage.getItem("milli_token");
    if (t) cfg.headers.Authorization = `Bearer ${t}`;
  } catch (_) { /* localStorage unavailable */ }
  return cfg;
});

// On 401 → clear token and redirect to login
// On network error / 404 → surface a clean error, not a crash
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response) {
      if (err.response.status === 401) {
        try {
          localStorage.removeItem("milli_token");
          localStorage.removeItem("milli_user");
        } catch (_) {}
        if (window.location.pathname !== "/login") {
          window.location.href = "/login";
        }
      }
    }
    return Promise.reject(err);
  }
);

/**
 * Health check — call on app mount to verify backend is reachable.
 * Returns { ok: true } or { ok: false, reason: string }.
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

export default api;
