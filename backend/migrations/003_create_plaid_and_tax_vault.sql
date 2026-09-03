-- Milli bank-connect (Plaid) + Tax Vault reserve ledger contract.
-- Plaid access tokens are backend-only secrets: the iOS app never receives one.

create table if not exists plaid_items (
    id uuid primary key,
    user_id uuid not null,
    item_id text not null unique,
    access_token text not null,
    institution_id text,
    institution_name text,
    status text not null default 'active' check (status in ('active', 'login_required', 'revoked', 'error')),
    last_error text,
    consent_expiration_time timestamptz,
    last_synced_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists plaid_items_user_idx on plaid_items(user_id, created_at desc);

create table if not exists plaid_accounts (
    id uuid primary key,
    user_id uuid not null,
    plaid_item_id uuid not null references plaid_items(id) on delete cascade,
    account_id text not null unique,
    name text,
    official_name text,
    mask text,
    type text,
    subtype text,
    -- Balances are a CACHED snapshot of what Plaid last returned. The API must
    -- expose balance_as_of so the client can label the value correctly
    -- (LIVE / CACHED LIVE / UNAVAILABLE). Never render a stale value as live.
    available_balance numeric(14,2),
    current_balance numeric(14,2),
    iso_currency_code text,
    balance_as_of timestamptz,
    is_payout_source boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists plaid_accounts_user_idx on plaid_accounts(user_id);

create table if not exists plaid_transactions (
    id uuid primary key,
    user_id uuid not null,
    plaid_account_id uuid not null references plaid_accounts(id) on delete cascade,
    transaction_id text not null unique,
    pending boolean not null default false,
    amount numeric(14,2) not null,
    iso_currency_code text,
    date date not null,
    authorized_date date,
    name text,
    merchant_name text,
    category text,
    is_gig_payout boolean not null default false,
    payout_platform text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists plaid_transactions_user_date_idx
    on plaid_transactions(user_id, date desc);

create index if not exists plaid_transactions_payout_idx
    on plaid_transactions(user_id, date desc) where is_gig_payout;

-- Tax Vault reserve: an append-only, auditable ledger. The vault balance is
-- ALWAYS derived by summing this ledger. No column anywhere stores a
-- convenience balance that could drift from the entries.
create table if not exists tax_vault_ledger (
    id uuid primary key,
    user_id uuid not null,
    entry_type text not null check (entry_type in ('reserve', 'withdrawal', 'adjustment', 'interest')),
    -- Signed cents: positive increases the reserve, negative decreases it.
    amount_cents bigint not null,
    iso_currency_code text not null default 'USD',
    status text not null default 'settled' check (status in ('requested', 'processing', 'settled', 'failed', 'reversed')),
    source_transaction_id uuid references plaid_transactions(id),
    reserve_rate numeric(6,4),
    tax_year integer,
    quarter smallint check (quarter between 1 and 4),
    memo text,
    audit_id text not null,
    settled_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists tax_vault_ledger_user_idx
    on tax_vault_ledger(user_id, created_at desc);

create index if not exists tax_vault_ledger_settled_idx
    on tax_vault_ledger(user_id, tax_year, quarter) where status = 'settled';

create unique index if not exists tax_vault_ledger_audit_id_idx
    on tax_vault_ledger(audit_id);

-- Per-user autopilot reserve configuration (USER ENTERED data).
create table if not exists tax_vault_settings (
    user_id uuid primary key,
    reserve_rate numeric(6,4) not null default 0.2500 check (reserve_rate >= 0 and reserve_rate <= 1),
    autopilot_enabled boolean not null default false,
    updated_at timestamptz not null default now()
);
