import os


class Settings:
    JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
    JWT_ALG = "HS256"
    JWT_EXPIRE_HOURS = 24 * 30

    PLAID_CLIENT_ID = os.getenv("PLAID_CLIENT_ID", "")
    PLAID_SECRET = os.getenv("PLAID_SECRET", "")
    PLAID_ENV = os.getenv("PLAID_ENV", "sandbox")

    STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY", "")
    STRIPE_PRICE_ID = os.getenv("STRIPE_PRICE_ID", "")
    STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET", "")


settings = Settings()
