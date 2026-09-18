-- Server-authenticated user/session boundary.
-- No client-chosen UUID or app-embedded shared key can authorize financial data.

create table if not exists milli_users (
    id uuid primary key,
    apple_subject text not null unique,
    email text,
    email_verified boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists auth_challenges (
    id uuid primary key,
    nonce_hash text not null unique,
    expires_at timestamptz not null,
    used_at timestamptz,
    created_at timestamptz not null default now()
);

create index if not exists auth_challenges_expiry_idx
    on auth_challenges(expires_at) where used_at is null;

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

-- The database itself must never default a new reserve movement to settled.
alter table tax_vault_ledger alter column status set default 'requested';
