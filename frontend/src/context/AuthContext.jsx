import { createContext, useContext, useEffect, useState, useCallback } from "react";
import { api } from "@/lib/api";

const AuthContext = createContext(null);

// 5-second hard cap on the initial /auth/me check.
// If the backend is still waking up, the app renders immediately with
// the cached user (optimistic) rather than hanging on [ AUTHENTICATING... ].
const AUTH_CHECK_TIMEOUT_MS = 5000;

function readUserCache() {
  try {
    const raw = localStorage.getItem("milli_user_cache");
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function writeUserCache(u) {
  try {
    if (u) localStorage.setItem("milli_user_cache", JSON.stringify(u));
    else localStorage.removeItem("milli_user_cache");
  } catch (_) {}
}

export function AuthProvider({ children }) {
  // Seed user from the localStorage cache so ProtectedRoutes render
  // immediately on repeat visits — no server round-trip required.
  const [user, setUser] = useState(() => {
    const token = (() => { try { return localStorage.getItem("milli_token"); } catch { return null; } })();
    return token ? readUserCache() : null;
  });

  // Only show the "loading" gate if we have a token but no cache yet
  // (first-ever launch with an existing token, edge case).
  const [loading, setLoading] = useState(() => {
    try {
      return !!localStorage.getItem("milli_token") && !localStorage.getItem("milli_user_cache");
    } catch {
      return false;
    }
  });

  const refresh = useCallback(async () => {
    const token = (() => { try { return localStorage.getItem("milli_token"); } catch { return null; } })();
    if (!token) {
      setUser(null);
      setLoading(false);
      return;
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), AUTH_CHECK_TIMEOUT_MS);

    try {
      const { data } = await api.get("/auth/me", { signal: controller.signal });
      setUser(data);
      writeUserCache(data);
    } catch (err) {
      const wasCanceled =
        err.name === "CanceledError" ||
        err.name === "AbortError" ||
        err.code === "ERR_CANCELED";

      if (wasCanceled) {
        // Server slow to respond — keep the cached user so the UI stays usable.
        // The token is preserved; a later request will succeed once the backend wakes.
      } else {
        // Real auth failure (e.g. 401) — invalidate the session.
        try { localStorage.removeItem("milli_token"); } catch (_) {}
        writeUserCache(null);
        setUser(null);
      }
    } finally {
      clearTimeout(timeoutId);
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  function setSession(token, u) {
    try { localStorage.setItem("milli_token", token); } catch (_) {}
    writeUserCache(u);
    setUser(u);
  }

  function logout() {
    try { localStorage.removeItem("milli_token"); } catch (_) {}
    writeUserCache(null);
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, loading, setSession, logout, refresh }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
