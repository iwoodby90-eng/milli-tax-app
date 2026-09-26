-- Column customer provisioning + Elite debit card issuing.
-- Sensitive KYC inputs (SSN, DOB, full address) are sent directly to Column
-- and are intentionally NOT persisted by Milli. Only provider IDs/statuses and
-- sanitized card metadata are stored locally.

alter table column_customer_profiles
    add column if not exists provider_status text,
    add column if not exists last_reconciled_at timestamptz;

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
    column_bank_account_local_id uuid not null references column_bank_accounts(id) on delete restrict,
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
    column_card_account_local_id uuid not null references column_card_accounts(id) on delete restrict,
    column_card_id text not null unique,
    card_type text not null check (card_type in ('virtual', 'physical')),
    provider_status text not null,
    last_four text,
    expiration_month integer check (expiration_month is null or expiration_month between 1 and 12),
    expiration_year integer,
    card_template_id text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, column_card_account_local_id, card_type)
);

create index if not exists column_cards_user_idx
    on column_cards(user_id, created_at desc);
