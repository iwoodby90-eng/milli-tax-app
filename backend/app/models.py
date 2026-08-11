from typing import Optional
from pydantic import BaseModel


class RegisterRequest(BaseModel):
    full_name: str
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


class UserOut(BaseModel):
    id: str
    full_name: str
    email: str
    tier: Optional[str] = "Milli Pro"


class AuthResponse(BaseModel):
    token: str
    user: UserOut


class PublicTokenRequest(BaseModel):
    public_token: str
