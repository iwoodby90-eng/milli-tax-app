-- Email + password credentials alongside Sign in with Apple.
-- Passwords are never stored or transmitted in recoverable form: only a
-- salted scrypt digest is persisted, and repeated failures lock the account.

alter table milli_users alter column apple_subject drop not null;

alter table milli_users
    add column if not exists password_hash text,
    add column if not exists password_updated_at timestamptz,
    add column if not exists failed_login_count integer not null default 0,
    add column if not exists locked_until timestamptz;

create unique index if not exists milli_users_email_credential_idx
    on milli_users (lower(email))
    where password_hash is not null;

alter table milli_users
    drop constraint if exists milli_users_credential_present;

alter table milli_users
    add constraint milli_users_credential_present
    check (apple_subject is not null or (email is not null and password_hash is not null));
