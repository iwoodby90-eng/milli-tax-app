create table if not exists users (
    id uuid primary key,
    apple_subject text not null unique,
    email text,
    display_name text,
    account_status text not null default 'active'
      check (account_status in ('active','locked','deleted')),
    last_login_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

create table if not exists auth_sessions (
    id uuid primary key,
    user_id uuid not null references users(id) on delete cascade,
    refresh_token_hash text not null,
    token_generation integer not null default 0,
    created_at timestamptz not null default now(),
    last_used_at timestamptz,
    expires_at timestamptz not null,
    revoked_at timestamptz
);
create index if not exists auth_sessions_user_active_idx
  on auth_sessions(user_id,expires_at desc) where revoked_at is null;

-- NOT VALID lets legacy sandbox rows remain quarantined while enforcing ownership on new writes.
alter table if exists plaid_items add constraint plaid_items_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
alter table if exists plaid_accounts add constraint plaid_accounts_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
alter table if exists plaid_transactions add constraint plaid_transactions_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
alter table if exists tax_vault_ledger add constraint tax_vault_ledger_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
alter table if exists tax_vault_settings add constraint tax_vault_settings_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
alter table if exists mileage_logs add constraint mileage_logs_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
alter table if exists brokerage_accounts add constraint brokerage_accounts_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
alter table if exists brokerage_orders add constraint brokerage_orders_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
alter table if exists brokerage_positions add constraint brokerage_positions_user_fk
  foreign key (user_id) references users(id) on delete cascade not valid;
