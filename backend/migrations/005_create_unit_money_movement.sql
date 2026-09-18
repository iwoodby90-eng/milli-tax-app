-- Unit money-movement security foundation.
-- The provider owns lifecycle truth. Mobile clients never set provider statuses.

create table if not exists ach_debit_authorizations (
    id uuid primary key,
    user_id uuid not null references milli_users(id) on delete cascade,
    linked_account_id text not null,
    authorization_text_version text not null,
    authorized_at timestamptz not null,
    revoked_at timestamptz,
    retain_until timestamptz not null,
    created_at timestamptz not null default now(),
    check (retain_until >= authorized_at + interval '2 years')
);

create index if not exists ach_debit_authorizations_user_idx
    on ach_debit_authorizations(user_id, authorized_at desc);

create table if not exists unit_money_movements (
    id uuid primary key,
    user_id uuid not null references milli_users(id) on delete cascade,
    client_request_id uuid not null,
    idempotency_key uuid not null,
    provider_payment_id text unique,
    source_account_id text not null,
    linked_account_id text not null,
    debit_authorization_id uuid references ach_debit_authorizations(id),
    amount_cents bigint not null check (amount_cents > 0),
    direction text not null check (direction in ('Credit', 'Debit')),
    status text not null default 'requested'
        check (status in (
            'requested', 'pending', 'pending_review', 'clearing', 'sent',
            'canceled', 'rejected', 'returned', 'unavailable'
        )),
    last_provider_event_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, client_request_id),
    unique (idempotency_key),
    check (direction <> 'Debit' or debit_authorization_id is not null)
);

create index if not exists unit_money_movements_user_idx
    on unit_money_movements(user_id, created_at desc);

create table if not exists unit_webhook_events (
    provider_event_id text primary key,
    event_type text not null,
    provider_payment_id text,
    payload_sha256 text not null,
    received_at timestamptz not null default now()
);

create index if not exists unit_webhook_payment_idx
    on unit_webhook_events(provider_payment_id, received_at desc)
    where provider_payment_id is not null;
