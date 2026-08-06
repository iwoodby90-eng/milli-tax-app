"""One-time follow-up patch for backend/server.py.

The first hardening pass has already landed. This pass closes the final
StoreKit product fallback and makes optional providers non-fatal at startup.
"""
from pathlib import Path

PATH = Path(__file__).resolve().parents[1] / "backend" / "server.py"
text = PATH.read_text(encoding="utf-8")


def replace_once(old: str, new: str) -> None:
    global text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected exactly one match, found {count}: {old[:120]!r}")
    text = text.replace(old, new, 1)


replace_once(
    "PLAID_CLIENT_ID = os.environ['PLAID_CLIENT_ID']\n"
    "PLAID_SECRET = os.environ['PLAID_SECRET']\n",
    "PLAID_CLIENT_ID = os.environ.get('PLAID_CLIENT_ID', 'not-configured')\n"
    "PLAID_SECRET = os.environ.get('PLAID_SECRET', 'not-configured')\n",
)
replace_once(
    "EMERGENT_LLM_KEY = os.environ['EMERGENT_LLM_KEY']\n"
    "STRIPE_API_KEY = os.environ['STRIPE_API_KEY']\n",
    "EMERGENT_LLM_KEY = os.environ.get('EMERGENT_LLM_KEY', 'not-configured')\n"
    "STRIPE_API_KEY = os.environ.get('STRIPE_API_KEY', 'not-configured')\n",
)
replace_once(
    "    plan = IAP_PRODUCT_TO_PLAN.get(product_id, \"pro\")\n",
    "    plan = IAP_PRODUCT_TO_PLAN.get(product_id)\n"
    "    if not plan:\n"
    "        raise HTTPException(status_code=400, detail=\"Apple returned an unknown StoreKit product\")\n",
)

PATH.write_text(text, encoding="utf-8")
print(f"Applied follow-up hardening to {PATH}")
