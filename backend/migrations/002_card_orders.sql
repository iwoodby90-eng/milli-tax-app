-- Card orders table for Milli Visa Elite Card fulfillment via Stripe Issuing
CREATE TABLE IF NOT EXISTS card_orders (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    material VARCHAR(20) NOT NULL,
    material_name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    shipping_name VARCHAR(255) NOT NULL,
    shipping_address1 VARCHAR(255) NOT NULL,
    shipping_address2 VARCHAR(255),
    shipping_city VARCHAR(100) NOT NULL,
    shipping_state VARCHAR(10) NOT NULL,
    shipping_zip VARCHAR(20) NOT NULL,
    shipping_phone VARCHAR(30) NOT NULL,
    ssn_last4_encrypted VARCHAR(255),
    stripe_cardholder_id VARCHAR(255),
    stripe_card_id VARCHAR(255),
    tracking_number VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Index for looking up orders by user
CREATE INDEX IF NOT EXISTS idx_card_orders_user_id ON card_orders(user_id);
-- Index for status-based queries (background job processing)
CREATE INDEX IF NOT EXISTS idx_card_orders_status ON card_orders(status);
-- Index for Stripe card ID lookups (webhook updates)
CREATE INDEX IF NOT EXISTS idx_card_orders_stripe_card_id ON card_orders(stripe_card_id);