from __future__ import annotations
"""MILLI server-verified Sign in with Apple and rotating sessions."""
import hashlib, logging, secrets, uuid
from datetime import datetime, timedelta, timezone
import jwt
from fastapi import APIRouter, Depends, HTTPException, Request, status
from pydantic import BaseModel, Field
from .. import db
from ..config import get_settings
from ..plaid_client import get_client
from ..secret_store import decrypt_provider_secret
from ..security import require_user

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger("milli.security")
apple_jwks = jwt.PyJWKClient("https://appleid.apple.com/auth/keys")

class AppleAuthRequest(BaseModel):
    identity_token: str = Field(min_length=20)
    raw_nonce: str = Field(min_length=16, max_length=256)
    display_name: str | None = Field(default=None, max_length=160)

class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=40)

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: uuid.UUID
    email: str | None = None
    display_name: str | None = None

def require_auth():
    s = get_settings()
    if not s.auth_configured:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "secure authentication unavailable")
    return s

def verify_apple(identity_token, raw_nonce):
    s = require_auth()
    try:
        header = jwt.get_unverified_header(identity_token)
        if header.get("alg") != "RS256":
            raise HTTPException(401, "unsupported Apple token algorithm")
        key = apple_jwks.get_signing_key_from_jwt(identity_token).key
        claims = jwt.decode(
            identity_token, key, algorithms=["RS256"],
            audience=s.apple_client_id, issuer="https://appleid.apple.com",
            options={"require":["exp","iat","iss","aud","sub"]},
        )
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(401, "Apple identity verification failed")
    expected = hashlib.sha256(raw_nonce.encode()).hexdigest()
    if not secrets.compare_digest(str(claims.get("nonce","")), expected):
        raise HTTPException(401, "Apple nonce verification failed")
    return claims

def hash_refresh(token): return hashlib.sha256(token.encode()).hexdigest()
def new_refresh(sid): return f"{sid}.{secrets.token_urlsafe(48)}"

def access_token(user_id, session_id):
    s = require_auth()
    now = datetime.now(timezone.utc)
    ttl = timedelta(minutes=s.auth_access_token_minutes)
    payload = {
        "sub":str(user_id), "sid":str(session_id), "typ":"access",
        "iat":now, "exp":now+ttl, "iss":s.auth_issuer, "aud":s.auth_audience
    }
    return jwt.encode(payload, s.auth_jwt_secret, algorithm="HS256"), int(ttl.total_seconds())

def issue_session(user_id, email, display_name):
    s = require_auth()
    sid = uuid.uuid4()
    refresh = new_refresh(sid)
    expires = datetime.now(timezone.utc) + timedelta(days=s.auth_refresh_token_days)
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""insert into auth_sessions
                (id,user_id,refresh_token_hash,expires_at) values (%s,%s,%s,%s)""",
                (sid,user_id,hash_refresh(refresh),expires))
        conn.commit()
    access, ttl = access_token(user_id, sid)
    return TokenResponse(access_token=access,refresh_token=refresh,expires_in=ttl,
                         user_id=user_id,email=email,display_name=display_name)

@router.post("/apple", response_model=TokenResponse)
def apple_sign_in(body: AppleAuthRequest):
    claims = verify_apple(body.identity_token, body.raw_nonce)
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                insert into users (id,apple_subject,email,display_name,last_login_at)
                values (%s,%s,%s,%s,now())
                on conflict (apple_subject) do update set
                  email=coalesce(excluded.email,users.email),
                  display_name=coalesce(excluded.display_name,users.display_name),
                  last_login_at=now(), updated_at=now()
                returning id,email,display_name,account_status,deleted_at
            """,(uuid.uuid4(),claims["sub"],claims.get("email"),body.display_name))
            row=cur.fetchone()
        conn.commit()
    if row[3]!="active" or row[4] is not None:
        raise HTTPException(403,"account unavailable")
    logger.info("auth.apple.success user_id=%s", row[0])
    return issue_session(row[0],row[1],row[2])

@router.post("/refresh", response_model=TokenResponse)
def refresh(body: RefreshRequest):
    try: sid=uuid.UUID(body.refresh_token.split(".",1)[0])
    except (ValueError,IndexError): raise HTTPException(401,"invalid refresh credential")
    supplied=hash_refresh(body.refresh_token)
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""select s.user_id,s.refresh_token_hash,s.expires_at,s.revoked_at,
                                  u.email,u.display_name,u.account_status,u.deleted_at
                           from auth_sessions s join users u on u.id=s.user_id
                           where s.id=%s for update""",(sid,))
            row=cur.fetchone()
            if not row: raise HTTPException(401,"unknown refresh session")
            uid,stored,exp,revoked,email,name,status_,deleted=row
            if revoked or exp<=datetime.now(timezone.utc) or status_!="active" or deleted:
                raise HTTPException(401,"refresh session unavailable")
            if not secrets.compare_digest(stored,supplied):
                cur.execute("update auth_sessions set revoked_at=now() where id=%s",(sid,))
                conn.commit()
                logger.warning("auth.refresh.replay session_id=%s",sid)
                raise HTTPException(401,"refresh credential replay detected")
            rotated=new_refresh(sid)
            cur.execute("""update auth_sessions set refresh_token_hash=%s,
                         token_generation=token_generation+1,last_used_at=now() where id=%s""",
                        (hash_refresh(rotated),sid))
        conn.commit()
    access,ttl=access_token(uid,sid)
    return TokenResponse(access_token=access,refresh_token=rotated,expires_in=ttl,
                         user_id=uid,email=email,display_name=name)

@router.get("/me")
def me(user_id: uuid.UUID=Depends(require_user)):
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("select id,email,display_name,account_status,created_at from users where id=%s",(user_id,))
            row=cur.fetchone()
    if not row: raise HTTPException(404,"account not found")
    return {"id":str(row[0]),"email":row[1],"display_name":row[2],
            "account_status":row[3],"created_at":row[4].isoformat()}

@router.post("/logout", status_code=204)
def logout(request: Request, user_id: uuid.UUID=Depends(require_user)):
    token=request.headers["authorization"].split(" ",1)[1]
    claims=jwt.decode(token,get_settings().auth_jwt_secret,algorithms=["HS256"],
                      audience=get_settings().auth_audience,issuer=get_settings().auth_issuer)
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("update auth_sessions set revoked_at=now() where id=%s and user_id=%s",
                        (uuid.UUID(claims["sid"]),user_id))
        conn.commit()

@router.delete("/account", status_code=204)
def delete_account(user_id: uuid.UUID=Depends(require_user)):
    # Provider access is revoked BEFORE local deletion.
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("select access_token from plaid_items where user_id=%s",(user_id,))
            tokens=[r[0] for r in cur.fetchall()]
    if tokens:
        client=get_client()
        if client is None:
            raise HTTPException(503,"bank provider unavailable for account deletion")
        from plaid.model.item_remove_request import ItemRemoveRequest
        for stored in tokens:
            try:
                client.item_remove(ItemRemoveRequest(access_token=decrypt_provider_secret(stored)))
            except Exception:
                logger.exception("account.delete.provider_revoke_failed user_id=%s",user_id)
                raise HTTPException(503,"bank access could not be revoked; deletion stopped")
    with db.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("update auth_sessions set revoked_at=now() where user_id=%s",(user_id,))
            cur.execute("delete from plaid_items where user_id=%s",(user_id,))
            cur.execute("delete from tax_vault_settings where user_id=%s",(user_id,))
            cur.execute("""update users set email=null,display_name=null,account_status='deleted',
                           deleted_at=now(),updated_at=now() where id=%s""",(user_id,))
        conn.commit()
    logger.info("account.deleted user_id=%s",user_id)
