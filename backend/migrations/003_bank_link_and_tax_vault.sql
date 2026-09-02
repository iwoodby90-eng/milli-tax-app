-- 003: Bank link sessions + Tax Vault reserve ledger
-- Authoritative store for Stripe Financial Connections sessions, detected
-- gig payouts, and the per-user Tax Vault reserve (tax held from each payout
-- until quarterly/annual filing).

CREATE TABLE IF NOT EXISTS bank_link_sessions (
    id TEXT PRIMARY KEY,
    stripe_session_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',   -- pending | completed | failed
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS connected_bank_accounts (
    id TEXT PRIMARY KEY,                      -- Stripe FC account id
    user_id TEXT NOT NULL,
    institution_name TEXT NOT NULL,
    account_name TEXT NOT NULL,
    account_mask TEXT NOT NULL,
    account_type TEXT NOT NULL,
    balance_cents BIGINT NOT NULL DEFAULT 0,
    is_live BOOLEAN NOT NULL DEFAULT true,
    last_synced_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS detected_payouts (
    id TEXT PRIMARY KEY,                      -- Stripe FC transaction id (idempotent)
    user_id TEXT NOT NULL,
    account_id TEXT NOT NULL,
    platform TEXT NOT NULL,                   -- DoorDash, Uber, ...
    gross_cents BIGINT NOT NULL,
    detected_at TIMESTAMPTZ NOT NULL,
    tax_hold_cents BIGINT NOT NULL,
    tax_hold_state TEXT NOT NULL DEFAULT 'processing'  -- processing | confirmed
);

CREATE TABLE IF NOT EXISTS tax_vault_reserve (
    user_id TEXT PRIMARY KEY,
    reserve_cents BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tax_vault_ledger (
    id BIGSERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    payout_id TEXT NOT NULL REFERENCES detected_payouts(id),
    amount_cents BIGINT NOT NULL,
    direction TEXT NOT NULL,                 -- hold | release | filed
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_detected_payouts_user ON detected_payouts(user_id, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_ledger_user ON tax_vault_ledger(user_id, created_at DESC);