-- Plaid /transactions/sync is cursor-based. Persisting the per-item cursor
-- keeps each sync incremental instead of replaying the full history, and keeps
-- Plaid's removed-transaction deliveries applicable to the correct owner.

alter table plaid_items
    add column if not exists transactions_cursor text;
