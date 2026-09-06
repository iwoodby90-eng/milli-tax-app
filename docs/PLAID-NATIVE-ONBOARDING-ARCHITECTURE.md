# Plaid native onboarding architecture

`LaunchOnboardingFlowView` is intentionally isolated from the legacy placeholder `BankConnectionSetupView` so the release candidate can be validated without deleting the older setup surface in the same change.

Flow:

`iOS -> Render /plaid/link-token -> Plaid LinkKit -> iOS public_token -> Render /plaid/exchange-public-token -> Render /plaid/accounts -> connected UI`

Secrets and Plaid access tokens remain on Render. LinkKit receives only the short-lived Link token generated for the current user session.
