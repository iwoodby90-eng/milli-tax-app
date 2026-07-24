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

// Track whether a network-error banner is currently active so we only
// emit "milli:network-ok" when recovering from a real error, not on
// every successful request.
let _networkErrorActive = false;

function _emit(name, detail) {
  try { window.dispatchEvent(new CustomEvent(name, detail ? { detail } : undefined)); } catch (_) {}
}

// Response interceptor:
//   • Success  → clear error flag and signal recovery if needed
//   • Network / 5xx  → raise "milli:network-error" banner event
//   • 401  → clear session and redirect to login
//   • Deliberate cancels (AbortController) → passthrough, no banner
api.interceptors.response.use(
  (res) => {
    if (_networkErrorActive) {
      _networkErrorActive = false;
      _emit("milli:network-ok");
    }
    return res;
  },
  (err) => {
    const isCanceled = err.code === "ERR_CANCELED" || err.name === "CanceledError";
    const isNetworkDown = !err.response && !isCanceled;
    const isServerError = err.response && err.response.status >= 500;

    if (isNetworkDown || isServerError) {
      _networkErrorActive = true;
      const message = isServerError
        ? "Milli server is temporarily unavailable."
        : "Unable to reach Milli servers. Check your connection.";
      _emit("milli:network-error", { message });
    }

    if (err.response?.status === 401) {
      try {
        localStorage.removeItem("milli_token");
        localStorage.removeItem("milli_user_cache");
      } catch (_) {}
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }

    return Promise.reject(err);
  }
);

/**
 * Health check — kept for explicit use (e.g. diagnostic screens).
 * No longer called on app mount.
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
