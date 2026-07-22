import axios from "axios";

// HARDCODED — do NOT parameterize. The iOS Capacitor build loads at
// capacitor://localhost so relative URLs and window.location.origin cannot
// resolve to the backend. This constant guarantees every request goes to the
// production preview backend regardless of build target.
export const API_BASE = "https://driver-tax-mileage.preview.emergentagent.com/api";

export const api = axios.create({ baseURL: API_BASE });

api.interceptors.request.use((cfg) => {
  const t = localStorage.getItem("milli_token");
  if (t) cfg.headers.Authorization = `Bearer ${t}`;
  return cfg;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response && err.response.status === 401) {
      localStorage.removeItem("milli_token");
      localStorage.removeItem("milli_user");
      if (window.location.pathname !== "/login") {
        window.location.href = "/login";
      }
    }
    return Promise.reject(err);
  }
);

export default api;
