"""Byte-accurate request body ceiling.

A declared `Content-Length` is only a claim, and a chunked request omits it
entirely, so the header check alone can be walked past. This middleware buffers
a header-less body up to the ceiling and refuses it the moment the real byte
count exceeds the limit, before any route sees the request.
"""

from __future__ import annotations

from collections.abc import Awaitable, Callable, MutableMapping
from typing import Any

from fastapi.responses import JSONResponse

Scope = MutableMapping[str, Any]
Message = MutableMapping[str, Any]
Receive = Callable[[], Awaitable[Message]]
Send = Callable[[Message], Awaitable[None]]

MAX_REQUEST_BYTES = 256 * 1024


class BodySizeLimitMiddleware:
    def __init__(self, app: Any, max_bytes: int = MAX_REQUEST_BYTES) -> None:
        self.app = app
        self.max_bytes = max_bytes

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http" or _declares_length(scope):
            await self.app(scope, receive, send)
            return

        body = bytearray()
        while True:
            message = await receive()
            if message["type"] != "http.request":
                await self.app(scope, _replay(message, receive), send)
                return
            body += message.get("body", b"")
            if len(body) > self.max_bytes:
                await _too_large()(scope, receive, send)
                return
            if not message.get("more_body", False):
                break

        buffered: Message = {
            "type": "http.request",
            "body": bytes(body),
            "more_body": False,
        }
        await self.app(scope, _replay(buffered, receive), send)


def _declares_length(scope: Scope) -> bool:
    return any(name == b"content-length" for name, _ in scope.get("headers", []))


def _replay(message: Message, receive: Receive) -> Receive:
    """Hand the buffered message to the app once, then defer to the real stream."""
    delivered = False

    async def replayed() -> Message:
        nonlocal delivered
        if not delivered:
            delivered = True
            return message
        return await receive()

    return replayed


def _too_large() -> JSONResponse:
    return JSONResponse({"detail": "request body too large"}, status_code=413)
