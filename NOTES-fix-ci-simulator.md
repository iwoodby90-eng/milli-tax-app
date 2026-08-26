# CI simulator destination fix (issue #69, item 4)

Branch: fix/ci-simulator-destination

## Change
`.github/workflows/validate.yml` — unit-tests job: replace the hard-pinned
`-destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'` with a
run-time resolution of the first available iPhone simulator UDID via
`xcrun simctl list devices available`, passed by `id=`. Fails loudly only when
no simulator exists at all.

## Why
A runner image update that drops the "iPhone 17" device name breaks the job
despite its fail-safe intent (issue #69, item 4).

## Test plan
- [ ] `native-build` job still green (unchanged).
- [ ] `unit-tests` job resolves a UDID and runs the 21 MilliTaxVault tests.
- [ ] Workflow YAML validates (actionlint or `yamllint`).

## Rollout notes
Single-file CI change, no app code touched. Revert = restore previous
destination line.
