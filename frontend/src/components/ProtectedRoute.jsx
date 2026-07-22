import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";

export default function ProtectedRoute({ children }) {
  const { user, loading } = useAuth();
  const loc = useLocation();
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-obsidian text-volt font-mono">
        <span className="animate-pulse">[ AUTHENTICATING... ]</span>
      </div>
    );
  }
  if (!user) return <Navigate to="/login" state={{ from: loc.pathname }} replace />;
  return children;
}
