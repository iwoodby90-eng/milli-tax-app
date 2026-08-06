"""Public, repository-owned compatibility layer for legacy Emergent imports.

The original project depended on a private ``emergentintegrations`` package
that cannot be installed on a clean machine. Milli now owns the small adapter
surface it actually uses so builds are reproducible and providers remain
replaceable.
"""
