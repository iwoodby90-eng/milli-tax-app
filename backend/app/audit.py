"""Append-only audit log.

Every financial operation (ledger entry, transfer, card action, IAP
verification, identity verification) writes a row here. The audit_id
is the same ID surfaced to the user in the Financial Receipt, so the
chain of custody is traceable end-to-end.
"""

import uuid
from datetime import datetime, timezone
from typing import Any, Optional

from .config import get_settings
from . import db


def log(
    user_id: uuid.UUID,
    action: str,
    resource_type: str,
    resource_id: Optional[str] = None,
    metadata: Optional[dict[str, Any]] = None,
    ip_address: Optional[str] = None,
) -> str:
    """Write an audit row. Returns the audit_id.

    Safe to call inside an existing transaction (uses the same connection
    pool). If no database is configured, this is a no-op that still
    returns a generated audit_id so callers can use it in their responses.
    """
    audit_id = f"AUD-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:10].upper()}"

    settings = get_settings()
    if not settings.db_configured:
        return audit_id

    pool = db.pool()
    if pool is None:
        return audit_id

    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into audit_log
                    (user_id, action, resource_type, resource_id, audit_id, metadata, ip_address)
                values (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    user_id,
                    action,
                    resource_type,
                    resource_id,
                    audit_id,
                    _metadata_to_json(metadata),
                    ip_address,
                ),
            )
        conn.commit()

    return audit_id


def _metadata_to_json(metadata: Optional[dict[str, Any]]) -> Optional[str]:
    """Convert metadata dict to JSON string for the jsonb column."""
    if metadata is None:
        return None
    import json

    return json.dumps(metadata, default=str)