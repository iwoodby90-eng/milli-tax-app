# Production authentication note

The current FastAPI Plaid routes require a UUID user header and optionally a shared client key. The native iOS repair keeps that contract for sandbox/runtime validation, deriving a stable opaque UUID namespace from the signed-in Apple subject when available.

This UUID is an identifier, not authentication. Before enabling production financial data, the backend should validate the Sign in with Apple identity token server-side and issue an authenticated Milli session. A shared client key embedded in a shipped app must not be treated as a user credential.
