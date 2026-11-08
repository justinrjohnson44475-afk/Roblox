# Verification record

Research/development session: November 7, 2026 client date; cloud commands ran November 8 UTC.

| Check | Observed result | Limit |
|---|---|---|
| Pinned tools | Rojo 7.7.1, Lune 0.11.1, StyLua 2.6.0 executed | Official release binaries; archive hashes recorded locally |
| Lune suite | 52 checks passed | Includes domain, mocked adapter, syntax and generated DOM; not engine behavior |
| Python publisher suite | 9 tests passed | No Roblox network requests |
| Formatting | StyLua check passed | No full Roblox type/API checking |
| Rojo binary build | Success | Not opened in Studio |
| Rojo XML build | Success | Not opened in Studio |
| Place deserialization | Both files contain 12 nonempty expected scripts and required services/floor/spawn | Structural only |
| Publisher dry run | Target/hash/bytes printed; no upload | No API credentials or live integration |
| GitHub Actions | Workflow prepared; status tracked separately | Local checks do not establish remote CI success |
| Roblox Studio / real devices | NOT RUN | Engine/visual/mobile/controller tests pending |
| Actual player study | NOT RUN | No feedback or retention data |
| Live DataStore / Marketplace | NOT RUN | Mock tests only; purchases disabled |
| Roblox publication | NOT PERFORMED | No target place or scoped key configured |

Reproduce: `bash scripts/bootstrap.sh` then `bash scripts/check.sh`. Logs are generated into build/. Hashes are in build/SHA256SUMS and GitHub build artifacts. Actual Studio results must be appended with commit, artifact hash, device and evidence; never replace pending rows with inferred success.
