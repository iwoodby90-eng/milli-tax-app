# CI simulator destination fix (issue #69, item 4)

Branch: fix/ci-simulator-destination

## Status
BLOCKED: the API token cannot write `.github/workflows/*` (HTTP 404 on every
attempt; new-file commits elsewhere succeed). GitHub requires the `workflow`
scope to modify workflow files. The prepared fix is documented below; applying
it needs a token with workflow scope or a manual commit.

## Intended change
`.github/workflows/validate.yml` — unit-tests job: replace the hard-pinned
`-destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` with a
run-time resolution of the first available iPhone simulator UDID via
`xcrun simctl list devices available`, passed by `id=`. Fails loudly only when
no simulator exists at all.

## Why
A runner image update that drops the "iPhone 17" device name breaks the job
despite its fail-safe intent (issue #69, item 4).
