-- Column money rail, bound to server-authenticated Milli users.
-- No client-supplied user UUID can own or mutate these rows.
-- Sensitive account/routing numbers are never persisted.

create table if not exists column_bank_accounts (
    id uuid primary key,
    user_id uuid not null references milli_users(id) on delete cascade,
    client_request_id uuid not null,
    column_bank_account_id text not null unique,
    column_entity_id text not null,
    account_type text not null check (account_type in ('checking', 'tax_vault')),
    provider_status text not null,
    available_balance_cents bigint,
    pending_balance_cents bigint,
    currency_code text not null default 'USD',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, client_request_id)
);

create index if not exists column_bank_accounts_user_idx
    on column_bank_accounts(user_id, created_at desc);

create table if not exists column_counterparties (
    id uuid primary key,
    user_id uuid not null references milli_users(id) on delete cascade,
    client_request_id uuid not null,
    column_counterparty_id text not null unique,
    display_name text,
    account_type text not null check (account_type in ('checking', 'savings')),
    account_last_four text not null,
    routing_last_four text not null,
    created_at timestamptz not null default now(),
    unique (user_id, client_request_id)
);

create index if not exists column_counterparties_user_idx
    on column_counterparties(user_id, created_at desc);

create table if not exists column_ach_transfers (
    id uuid primary key,
    user_id uuid not null references milli_users(id) on delete cascade,
    client_request_id uuid not null,
    column_bank_account_id uuid not null references column_bank_accounts(id),
    column_counterparty_id uuid not null references column_counterparties(id),
    column_ach_transfer_id text not null unique,
    idempotency_key text not null unique,
    transfer_type text not null check (transfer_type in ('CREDIT', 'DEBIT')),
    amount_cents bigint not null check (amount_cents > 0),
    currency_code text not null default 'USD',
    provider_status text not null,
    local_status text not null check (
        local_status in ('requested', 'processing', 'settled', 'returned', 'canceled', 'failed')
    ),
    audit_id text not null unique,
    settled_at timestamptz,
    returned_at timestamptz,
    completed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, client_request_id)
);

create index if not exists column_ach_transfers_user_idx
    on column_ach_transfers(user_id, created_at desc);

create index if not exists column_ach_transfers_status_idx
    on column_ach_transfers(user_id, local_status, created_at desc);

create table if not exists financial_audit_log (
    id bigserial primary key,
    audit_id text not null unique,
    user_id uuid references milli_users(id) on delete set null,
    action text not null,
    resource_type text not null,
    resource_id uuid,
    amount_cents bigint,
    provider_reference text,
    metadata jsonb,
    created_at timestamptz not null default now()
);

create index if not exists financial_audit_log_user_idx
    on financial_audit_log(user_id, created_at desc);
