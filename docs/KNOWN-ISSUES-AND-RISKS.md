# Known issues and risk register

| Priority | Issue/risk | Mitigation / next verification |
|---|---|---|
| P0 release gate | No Roblox engine execution or visual playtest | Open generated place in Studio; run full QA matrix |
| P0 release gate | Content classification for optional Christian reading unresolved | Accurate questionnaire and Roblox clarification if needed; do not assume under-16 distribution |
| P0 release gate | Live save/session/shutdown behavior unverified | Separate private universe; concurrent sessions, budgets, outages and recovery tests |
| P1 | Distance/cooldown checks do not detect all speed/teleport abuse | Add measured movement plausibility and server replay tests before competitive/economic stakes increase |
| P1 | Failed final save can lose recent progress; lease may block quick rejoin | Bounded retries, warning, 180-second lease; validate recovery and dashboard monitoring |
| P1 | Runtime-generated geometry and GUI have not been visually inspected | Device, collision, text, controller and safe-area tests |
| P1 | Only three projects; repeated gathering may become a chore | Actual-player study before content expansion |
| P1 | Crates are shared and may create contention | Eight crate positions, cooldown; test group size and consider per-player availability |
| P1 | Concept demand, cosmetics conversion and profit unproven | Small observed cohorts and measured financial decisions |
| P1 | Competitor histories, favorites, sustained growth and detailed store audits incomplete | Expand initial source-backed dossier; direct Roblox API access currently denied |
| P2 | Placeholder art and built-in feedback sound | Original production assets, rights ledger, engine verification |
| P2 | No full Luau type analysis with Roblox definitions | Add maintained Roblox type environment before expanding codebase |
| P2 | Sound/effects settings last only for the current session | Add non-sensitive settings persistence if testers request it |
| P2 | Supporter pass adapter has no configured ID or real test | Keep disabled until private ownership/price/service tests pass |
| P2 | Custom analytics disabled; dashboard behavior unverified | Published private test, inspect actual events; never instrument religious reading |
| P2 | Shutdown and yielding save concurrency only code-reviewed, not fully simulated | Add scheduler/fault tests and actual two-server tests before release |

Theological summaries are original, not translation quotations; qualified contextual review is pending. No credentials, player research data or religious participation records belong in Git.
