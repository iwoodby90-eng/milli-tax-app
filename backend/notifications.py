"""
Quarterly + payout reminder cron. Wires into APScheduler.
"""
from datetime import date, datetime, timedelta, timezone
from typing import Any

# IRS quarterly estimated tax deadlines (rolled to next business day is out of scope for MVP)
IRS_QUARTERLY_DUE = [
    (4, 15, "Q1"),
    (6, 15, "Q2"),
    (9, 15, "Q3"),
    (1, 15, "Q4"),   # January of next year for prior year's Q4
]


def next_quarterly_deadline(today: date | None = None) -> tuple[date, str]:
    today = today or date.today()
    year = today.year
    candidates: list[tuple[date, str]] = []
    for m, d, label in IRS_QUARTERLY_DUE:
        y = year if (m, d) >= (today.month, today.day) else year + 1
        candidates.append((date(y, m, d), label))
    candidates.sort()
    return candidates[0]


async def run_quarterly_reminders(db, apns) -> dict[str, Any]:
    """
    For every user with a registered push token, if the next quarterly deadline
    is 14, 7, 3, 1, or 0 days away, ping them with the reserved amount.
    """
    due_date, label = next_quarterly_deadline()
    days = (due_date - date.today()).days
    if days not in (14, 7, 3, 1, 0):
        return {"sent": 0, "reason": f"not-a-trigger-day (days={days})"}

    sent = failed = 0
    async for u in db.users.find({"push.device_token": {"$exists": True, "$ne": None}}):
        tok = u.get("push", {}).get("device_token")
        if not tok:
            continue
        try:
            summary = await db.tax_summaries.find_one({"user_id": u["id"]})
            reserved = (summary or {}).get("next_quarterly", {}).get("amount") or 0
            if days == 0:
                title = f"{label} tax due today"
                body  = f"Milli has ${reserved:,.2f} reserved — tap to pay from your Tax Vault."
            elif days == 1:
                title = f"{label} tax due tomorrow"
                body  = f"${reserved:,.2f} ready to go. Review your quarterly."
            else:
                title = f"{label} estimated tax due in {days} days"
                body  = f"${reserved:,.2f} protected. Tap to review before {due_date:%b %d}."
            res = await apns.send_push(tok, title, body, thread_id="quarterly", category="QUARTERLY")
            (sent := sent + 1) if res.get("ok") else (failed := failed + 1)
        except Exception:
            failed += 1
    return {"sent": sent, "failed": failed, "days": days, "label": label}
