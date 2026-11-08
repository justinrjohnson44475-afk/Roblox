# Current verification — Riftwake replacement

November 8, 2026. Earlier Harborlight checks are historical and do not verify this new implementation.

| Check | Observed | Boundary |
|---|---|---|
| Lune suite | 77 checks passed | Domain, mocked persistence, syntax and DOM; no engine |
| Publisher Python suite | 9 tests passed | No API requests |
| Formatting | StyLua passed | Not full Roblox-aware type checking |
| Bake | Original world serialized successfully | Lune DOM does not simulate physics/engine |
| Binary/XML builds | Both succeeded | Not opened in Studio |
| Structural inspection | Both contain 17 nonempty source scripts and 686 anchored map parts | Four regions, spawn, services and no scripts embedded in generated map |
| Blender previsualization | Geometry exported and layout/rig previews inspected | Not Studio screenshots; preview avatar is a mannequin |
| Video playback | Attempt failed with DNS_PROBE_FINISHED_NO_INTERNET | No watched-footage claim |
| Roblox / devices / players | NOT TESTED | Combat feel, replication, UI, physics and enjoyment unknown |
| Live services | NOT TESTED | Purchases/analytics off; DataStore mock tests only |
| Roblox publishing | NOT PERFORMED | Dry run only |

Reproduce with `bash scripts/check.sh`. Current logs/hashes are in build/; latest GitHub replacement workflow results must be checked separately. Follow document 08 for actual test records with commit/hash, Studio version, device, steps, expected/actual outcome and evidence paths.

Remote verification: [GitHub Actions run 42503328511](https://github.com/justinrjohnson44475-afk/Roblox/actions/runs/42503328511) succeeded for game-source commit `f462be15726dc4302ae613f432e83dd882119248`. Artifact ID 13626795719 was present/unexpired when checked. Both this remote result and the cloud suite are build/domain evidence, not Roblox engine playtests.
