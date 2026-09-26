-- Reconcile the original Render schema with the current authenticated-finance schema.
-- This migration is intentionally idempotent and preserves existing user/Plaid ownership IDs.
-- Legacy opaque sessions cannot be transformed into the current access+refresh token model,
-- so they are archived and users must sign in again after this release.

-- 1) Canonical user table. Preserve the UUIDs already referenced by Plaid/Tax Vault rows.
create table if not exists milli_users (
    id uuid primary key,
    apple_subject text unique,
    email text,
    email_verified boolean not null default false,
    password_hash text,
    password_updated_at timestamptz,
    failed_login_count integer not null default 0,
    locked_until timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table milli_users
    alter column apple_subject drop not null,
    add column if not exists email_verified boolean not null default false,
    add column if not exists password_hash text,
    add column if not exists password_updated_at timestamptz,
    add column if not exists failed_login_count integer not null default 0,
    add column if not exists locked_until timestamptz;

do $$
begin
    if to_regclass(current_schema() || '.users') is not null then
        insert into milli_users
            (id, apple_subject, email, email_verified, created_at, updated_at)
        select id, apple_subject, email, false, created_at, updated_at
          from users
        on conflict (id) do update
            set apple_subject = coalesce(milli_users.apple_subject, excluded.apple_subject),
                email = coalesce(milli_users.email, excluded.email),
                updated_at = greatest(milli_users.updated_at, excluded.updated_at);
    end if;
end
$$;

create unique index if not exists milli_users_email_credential_idx
    on milli_users (lower(email))
    where password_hash is not null;

alter table milli_users
    drop constraint if exists milli_users_credential_present;

alter table milli_users
    add constraint milli_users_credential_present
    check (apple_subject is not null or (email is not null and password_hash is not null));

-- 2) One-time auth challenges.
create table if not exists auth_challenges (
    id uuid primary key,
    nonce_hash text not null unique,
    expires_at timestamptz not null,
    used_at timestamptz,
    created_at timestamptz not null default now()
);

create index if not exists auth_challenges_expiry_idx
    on auth_challenges(expires_at) where used_at is null;

-- 3) Archive the incompatible legacy session table. Existing sessions are intentionally
-- invalidated because the old schema has no access-token digest or split expirations.
do $$
begin
    if to_regclass(current_schema() || '.auth_sessions') is not null
       and not exists (
            select 1
              from information_schema.columns
             where table_schema = current_schema()
               and table_name = 'auth_sessions'
               and column_name = 'access_token_hash'
       )
    then
        if to_regclass(current_schema() || '.auth_sessions_legacy_20260926') is null then
            alter table auth_sessions rename to auth_sessions_legacy_20260926;

            if exists (
                select 1 from pg_constraint
                 where conrelid = to_regclass(current_schema() || '.auth_sessions_legacy_20260926')
                   and conname = 'auth_sessions_pkey'
            ) then
                alter table auth_sessions_legacy_20260926
                    rename constraint auth_sessions_pkey
                    to auth_sessions_legacy_20260926_pkey;
            end if;

            if exists (
                select 1 from pg_constraint
                 where conrelid = 'public.auth_sessions_legacy_20260926'::regclass
                   and conname = 'auth_sessions_user_id_fkey'
            ) then
                alter table auth_sessions_legacy_20260926
                    rename constraint auth_sessions_user_id_fkey
                    to auth_sessions_legacy_20260926_user_id_fkey;
            end if;

            if to_regclass(current_schema() || '.auth_sessions_user_active_idx') is not null then
                alter index auth_sessions_user_active_idx
                    rename to auth_sessions_legacy_20260926_user_active_idx;
            end if;
        else
            -- A prior interrupted migration already preserved the legacy table.
            -- The incompatible duplicate can be discarded because sessions are ephemeral.
            drop table auth_sessions;
        end if;
    end if;
end
$$;

create table if not exists auth_sessions (
    id uuid primary key,
    user_id uuid not null references milli_users(id) on delete cascade,
    access_token_hash text not null unique,
    refresh_token_hash text not null unique,
    access_expires_at timestamptz not null,
    refresh_expires_at timestamptz not null,
    revoked_at timestamptz,
    last_seen_at timestamptz,
    created_at timestamptz not null default now()
);

create index if not exists auth_sessions_user_idx
    on auth_sessions(user_id, created_at desc);

create index if not exists auth_sessions_access_idx
    on auth_sessions(access_token_hash)
    where revoked_at is null;

-- 4) Bring Plaid sync state forward without disturbing existing linked accounts.
alter table plaid_items
    add column if not exists transactions_cursor text;

-- 5) Column banking/ACH authority boundary.
create table if not exists column_customer_profiles (
    user_id uuid primary key references milli_users(id) on delete cascade,
    column_entity_id text not null unique,
    kyc_status text not null check (
        kyc_status in ('pending', 'verified', 'restricted', 'rejected')
    ),
    verified_at timestamptz,
    provider_status text,
    last_reconciled_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

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
    plaid_account_id uuid not null references plaid_accounts(id) on delete restrict,
    column_counterparty_id text not null unique,
    display_name text,
    account_type text not null check (account_type in ('checking', 'savings')),
    account_last_four text not null,
    routing_last_four text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, client_request_id),
    unique (user_id, plaid_account_id)
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
    entry_class_code text not null check (entry_class_code in ('PPD', 'WEB')),
    amount_cents bigint not null check (amount_cents > 0),
    currency_code text not null default 'USD',
    provider_status text not null,
    local_status text not null check (
        local_status in ('processing', 'settled', 'returned', 'canceled')
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

-- 6) Column card-program persistence.
create table if not exists column_card_programs (
    id uuid primary key,
    environment text not null check (environment in ('sandbox', 'production')),
    column_card_program_id text not null unique,
    card_program_type text not null check (card_program_type = 'debit'),
    scheme text not null check (scheme in ('visa', 'mastercard')),
    description text not null,
    provider_status text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (environment, card_program_type)
);

create table if not exists column_card_accounts (
    id uuid primary key,
    user_id uuid not null references milli_users(id) on delete cascade,
    column_bank_account_local_id uuid not null
        references column_bank_accounts(id) on delete restrict,
    column_card_program_id text not null,
    column_card_account_id text not null unique,
    provider_status text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, column_bank_account_local_id)
);

create index if not exists column_card_accounts_user_idx
    on column_card_accounts(user_id, created_at desc);

create table if not exists column_cards (
    id uuid primary key,
    user_id uuid not null references milli_users(id) on delete cascade,
    column_card_account_local_id uuid not null
        references column_card_accounts(id) on delete restrict,
    column_card_id text not null unique,
    card_type text not null check (card_type in ('virtual', 'physical')),
    provider_status text not null,
    last_four text,
    expiration_month integer check (
        expiration_month is null or expiration_month between 1 and 12
    ),
    expiration_year integer,
    card_template_id text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, column_card_account_local_id, card_type)
);

create index if not exists column_cards_user_idx
    on column_cards(user_id, created_at desc);

-- Preserve the fail-safe ledger default even on upgraded databases.
alter table tax_vault_ledger alter column status set default 'requested';
