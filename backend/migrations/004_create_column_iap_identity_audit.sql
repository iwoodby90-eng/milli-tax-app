-- Column BaaS accounts, cards, transfers + Apple IAP + Identity + Audit log.
-- All amounts in signed cents (bigint). No floating-point money.

-- Column BaaS deposit accounts (checking, Tax Vault savings).
create table if not exists column_accounts (
    id uuid primary key,
    user_id uuid not null,
    column_account_id text not null unique,
    account_type text not null check (account_type in ('checking', 'tax_vault')),
    status text not null default 'pending' check (status in ('pending', 'active', 'frozen', 'closed')),
    available_balance_cents bigint not null default 0,
    pending_balance_cents bigint not null default 0,
    iso_currency_code text not null default 'USD',
    last_synced_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists column_accounts_user_idx on column_accounts(user_id);
create index if not exists column_accounts_type_idx on column_accounts(user_id, account_type);

-- Column debit cards (physical + virtual).
create table if not exists column_cards (
    id uuid primary key,
    user_id uuid not null,
    column_account_id uuid not null references column_accounts(id) on delete cascade,
    column_card_id text not null unique,
    card_type text not null check (card_type in ('physical', 'virtual')),
    status text not null default 'pending' check (status in ('pending', 'active', 'frozen', 'closed')),
    last_four text,
    -- Never store full PAN. Only last four and status from Column.
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists column_cards_user_idx on column_cards(user_id);
create index if not exists column_cards_account_idx on column_cards(column_account_id);

-- Column transfers (ACH, wires). State machine: pending -> processing -> settled | failed | reversed.
create table if not exists column_transfers (
    id uuid primary key,
    user_id uuid not null,
    column_account_id uuid not null references column_accounts(id) on delete cascade,
    column_transfer_id text unique,
    direction text not null check (direction in ('inbound', 'outbound')),
    transfer_type text not null check (transfer_type in ('ach', 'wire')),
    amount_cents bigint not null,
    iso_currency_code text not null default 'USD',
    status text not null default 'pending' check (status in ('pending', 'processing', 'settled', 'failed', 'reversed')),
    counterparty_name text,
    counterparty_routing_number text,
    counterparty_account_number_last_four text,
    description text,
    audit_id text not null,
    settled_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists column_transfers_user_idx on column_transfers(user_id, created_at desc);
create index if not exists column_transfers_status_idx on column_transfers(user_id, status);

-- Apple IAP transactions (server-side verified).
create table if not exists iap_transactions (
    id uuid primary key,
    user_id uuid not null,
    transaction_id text not null unique,
    original_transaction_id text not null,
    product_id text not null,
    purchase_date timestamptz not null,
    expires_date timestamptz,
    status text not null default 'verified' check (status in ('verified', 'expired', 'refunded', 'revoked')),
    environment text not null check (environment in ('sandbox', 'production')),
    raw_response jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists iap_transactions_user_idx on iap_transactions(user_id, created_at desc);
create index if not exists iap_transactions_original_idx on iap_transactions(original_transaction_id);

-- Identity verifications (Apple Verify + fallback KYC).
create table if not exists identity_verifications (
    id uuid primary key,
    user_id uuid not null,
    verification_method text not null check (verification_method in ('apple_wallet', 'column_kyc', 'third_party')),
    status text not null default 'pending' check (status in ('pending', 'verified', 'failed', 'expired')),
    -- Apple Wallet: the verified claims (name, DOB, etc.) stored as JSON.
    -- Column KYC: the KYC reference ID.
    -- Third party: the provider + reference.
    verified_claims jsonb,
    provider_reference text,
    verified_at timestamptz,
    expires_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists identity_verifications_user_idx on identity_verifications(user_id, created_at desc);

-- Audit log: append-only, every financial operation gets a row.
create table if not exists audit_log (
    id bigserial primary key,
    user_id uuid,
    action text not null,
    resource_type text not null,
    resource_id text,
    audit_id text not null unique,
    metadata jsonb,
    ip_address text,
    created_at timestamptz not null default now()
);

create index if not exists audit_log_user_idx on audit_log(user_id, created_at desc);
create index if not exists audit_log_audit_id_idx on audit_log(audit_id);
create index if not exists audit_log_action_idx on audit_log(action, created_at desc);