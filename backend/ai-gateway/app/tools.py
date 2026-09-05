"""Typed tool contract registry — deny-by-default.

Sun's §6.3/§7: the LLM has no database/SQL access and can only invoke
explicitly defined typed tools, each with a strict input schema, a permission
scope, and a consequential classification.

Phase 0: the registry exists, permission checks are enforced, and NO tools
are registered. Every tool request is therefore denied by default. Tool
contracts (starting with non-consequential read-only tools) land in Phase 1.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum


class ToolClass(str, Enum):
    READ_ONLY = "read_only"
    CONSEQUENTIAL = "consequential"


@dataclass(frozen=True)
class ToolContract:
    name: str
    description: str
    permission_scope: str
    tool_class: ToolClass
    input_schema: dict = field(default_factory=dict)
    step_up_auth_required: bool = False
    idempotency_required: bool = False
    enabled: bool = False  # deny-by-default: tools ship disabled


class ToolPermissionDenied(Exception):
    """Raised when a tool invocation is not permitted."""


class ToolRegistry:
    """Registry of typed tool contracts with deny-by-default permissions."""

    def __init__(self, contracts: list[ToolContract] | None = None) -> None:
        self._contracts: dict[str, ToolContract] = {}
        for c in contracts or []:
            self._contracts[c.name] = c

    def register(self, contract: ToolContract) -> None:
        self._contracts[contract.name] = contract

    def get(self, name: str) -> ToolContract | None:
        return self._contracts.get(name)

    def permitted_tools(self, scopes: frozenset[str]) -> list[str]:
        """Tools this permission set may invoke (enabled + scope-matched)."""
        return [
            c.name
            for c in self._contracts.values()
            if c.enabled and c.permission_scope in scopes
        ]

    def authorize_tool(self, name: str, scopes: frozenset[str]) -> ToolContract:
        """Authorize a tool invocation. Raises ToolPermissionDenied.

        Deny-by-default chain: unknown tool -> denied; disabled tool ->
        denied; missing scope -> denied.
        """
        contract = self._contracts.get(name)
        if contract is None:
            raise ToolPermissionDenied(f"unknown tool: {name}")
        if not contract.enabled:
            raise ToolPermissionDenied(f"tool disabled: {name}")
        if contract.permission_scope not in scopes:
            raise ToolPermissionDenied(f"missing scope for tool {name}: {contract.permission_scope}")
        if contract.tool_class is ToolClass.CONSEQUENTIAL:
            # Consequential tools are not executable in Phase 0 at all.
            raise ToolPermissionDenied(
                f"consequential tool not executable in phase 0: {name}"
            )
        return contract
