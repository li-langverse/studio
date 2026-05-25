# Sync studio from lic PH-HW

## Summary

Org **studio** package tree matches lic `packages/li-studio` at `6ca38be9b2b236eb92f7e3b54f61d39d0abf7675` (`feat/ph-hw-multi-vendor`).

## Agent continuation

1. Read `lic` `feat/ph-hw-multi-vendor` if drift suspected; re-run `git archive origin/feat/ph-hw-multi-vendor packages/li-studio` → rsync into this repo.
2. Run package smokes when `lic` + sibling `li-gui`/`li-ui`/`li-sim` are on PATH or in monorepo layout.
3. Next: wire host `import lig` present path (WP3); do not add trusted axioms here.
4. Blocked: full viewport GPU CI until `lig` package lands in org repos.

## Changed

- `src/lib.li`, `src/main.li`, `li-tests/**`, `li.toml`, `examples/`, `fixtures/`, `bench/`
- `README.md` — `import lig` syntax line (PH-HW)
- Branch: `feat/sync-from-lic-ph-hw`

## Not changed

- `docs/demo/**`, `scripts/**`, `.github/**` — org-only assets retained.

## Breaking

N/A — source sync; import surface unchanged (`import studio`).

## Security

N/A — no new FFI or trusted surface in this PR.

## Performance

N/A — IR-only compose/paint; no bench threshold changes.

## Downstream

Consumers pin studio after merge; align `ui` PR from same lic SHA.
