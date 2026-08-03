-- Milli Tax Vault Database Schema
-- PostgreSQL migrations

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    plan VARCHAR(20) DEFAULT 'basic',
    ssn_encrypted TEXT,
    kyc_status VARCHAR(20) DEFAULT 'unverified',
    biometric_enabled BOOLEAN DEFAULT FALSE,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    totp_secret_encrypted TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bank accounts
CREATE TABLE IF NOT EXISTS bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL,
    nickname VARCHAR(100),
    account_number_encrypted TEXT,
    routing_number VARCHAR(9),
    balance DECIMAL(12, 2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Debit cards
CREATE TABLE IF NOT EXISTS debit_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    account_id UUID REFERENCES bank_accounts(id),
    card_number_last4 VARCHAR(4),
    card_token TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    locked BOOLEAN DEFAULT FALSE,
    daily_limit DECIMAL(10, 2) DEFAULT 5000,
    monthly_limit DECIMAL(10, 2) DEFAULT 25000,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tax payments
CREATE TABLE IF NOT EXISTS tax_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    tax_year VARCHAR(4) NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    quarter VARCHAR(2),
    status VARCHAR(20) DEFAULT 'pending',
    confirmation_number VARCHAR(50),
    scheduled_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- E-file submissions
CREATE TABLE IF NOT EXISTS efile_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tax_year VARCHAR(4) NOT NULL,
    return_data JSONB,
    status VARCHAR(20) DEFAULT 'submitted',
    irs_submission_id VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Brokerage accounts
CREATE TABLE IF NOT EXISTS brokerage_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) DEFAULT 'alpaca',
    account_id_external VARCHAR(100),
    api_key_encrypted TEXT,
    drip_enabled BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(50),
    file_type VARCHAR(10),
    file_size BIGINT,
    storage_url TEXT,
    tax_year VARCHAR(4),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Receipts (OCR processed)
CREATE TABLE IF NOT EXISTS receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    merchant VARCHAR(255),
    transaction_date DATE,
    total DECIMAL(10, 2),
    items JSONB,
    raw_text TEXT,
    schedule_c_category VARCHAR(100),
    deductible BOOLEAN DEFAULT FALSE,
    deductible_percentage INT DEFAULT 100,
    image_url TEXT,
    tax_year VARCHAR(4),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    account_id UUID REFERENCES bank_accounts(id),
    amount DECIMAL(12, 2) NOT NULL,
    type VARCHAR(20) NOT NULL,
    description VARCHAR(255),
    merchant VARCHAR(255),
    category VARCHAR(50),
    is_tax_deductible BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscriptions
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plan VARCHAR(20) NOT NULL,
    billing_cycle VARCHAR(10) DEFAULT 'monthly',
    amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    stripe_subscription_id VARCHAR(100),
    current_period_end TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_user_id ON bank_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_tax_payments_user_id ON tax_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_efile_submissions_user_id ON efile_submissions(user_id);
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);
CREATE INDEX IF NOT EXISTS idx_receipts_user_id ON receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);