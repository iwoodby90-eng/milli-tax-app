-- Milli brokerage trading storage contract
-- Real securities orders must be submitted by the authenticated backend to an
-- approved broker-dealer integration. Never store broker API secrets in iOS.

create table if not exists brokerage_accounts (
    id uuid primary key,
    user_id uuid not null,
    provider text not null,
    provider_account_id text not null,
    status text not null,
    trading_enabled boolean not null default false,
    fractional_trading_enabled boolean not null default false,
    opened_at timestamptz,
    closed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (provider, provider_account_id)
);

create index if not exists brokerage_accounts_user_id_idx
    on brokerage_accounts(user_id);

create table if not exists brokerage_orders (
    id uuid primary key,
    user_id uuid not null,
    brokerage_account_id uuid not null references brokerage_accounts(id),
    provider_order_id text,
    client_order_id text not null,
    symbol text not null,
    side text not null check (side in ('buy', 'sell')),
    order_type text not null check (order_type in ('market', 'limit')),
    quantity_mode text not null check (quantity_mode in ('dollars', 'shares')),
    requested_amount numeric(20,8) not null,
    limit_price numeric(20,8),
    filled_quantity numeric(20,8),
    filled_average_price numeric(20,8),
    status text not null,
    rejection_reason text,
    submitted_at timestamptz,
    filled_at timestamptz,
    canceled_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, client_order_id)
);

create index if not exists brokerage_orders_user_id_idx
    on brokerage_orders(user_id, created_at desc);

create index if not exists brokerage_orders_account_id_idx
    on brokerage_orders(brokerage_account_id, created_at desc);

create table if not exists brokerage_positions (
    id uuid primary key,
    user_id uuid not null,
    brokerage_account_id uuid not null references brokerage_accounts(id),
    symbol text not null,
    quantity numeric(20,8) not null,
    average_entry_price numeric(20,8),
    market_value numeric(20,8),
    cost_basis numeric(20,8),
    provider_updated_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (brokerage_account_id, symbol)
);

create index if not exists brokerage_positions_user_id_idx
    on brokerage_positions(user_id);
