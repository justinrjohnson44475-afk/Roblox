# Harborlight — Restore Together

A cloud-developed Roblox restoration game written in Luau. Recover supplies, help other players rebuild a harbor, and earn lasting cosmetic lantern colors. An explicitly labeled Garden of Hope offers optional Christian reading without rewards or required participation.

**Status:** first implemented vertical slice. Cloud tests and Rojo place builds pass. Roblox Studio execution, visual playtesting, live service testing and publication have not occurred. This is not launch-ready or commercially validated.

Commercial objective: test whether understandable, cooperative restoration can support repeat play and ethical cosmetic sales. See [market research](docs/01-MARKET-RESEARCH.md), [concept decision](docs/02-MARKET-GAP-AND-OPPORTUNITY.md), [financial assumptions](docs/07-MONETIZATION-AND-FINANCIAL-STRATEGY.md) and [current status](docs/PROJECT-STATUS.md). Revenue is not guaranteed.

## Cloud workflow
Development runs in Codex Cloud with GitHub as the source of truth. Your personal laptop can be off while research, code, tests, documentation and place builds run. No Local mode is needed for these steps.

On Linux x86_64, from this repository:

```bash
bash scripts/bootstrap.sh
bash scripts/check.sh
```

Bootstrap downloads pinned official Rojo 7.7.1, Lune 0.11.1 and StyLua 2.6.0 releases and verifies the committed archive checksums. Requires Bash, curl, unzip, sha256sum and Python 3. On macOS/Windows, install the official Aftman tool manager and run `aftman install` using the pinned `aftman.toml`; use `rojo`, `lune` and `stylua` directly or adapt paths from `.tools/`. Do not run the Linux installer on Windows/macOS. No Wally dependencies or Node packages are needed.

Outputs:

- `build/Harborlight.rbxl` — binary Roblox place.
- `build/Harborlight.rbxlx` — inspectable XML place.
- `build/test-results.txt`, `build/place-inspection.txt`, `build/SHA256SUMS`.

The GitHub Actions workflow builds these artifacts on pushes and pull requests. Once a run succeeds, download `Harborlight-Studio-<commit>` from its Artifacts section. Generated artifacts are ignored by Git; source and build instructions are versioned. GitHub Actions execution must be checked independently; a local cloud check is not a passing GitHub run.

## Open the game in Roblox Studio
1. Download the built binary or XML artifact from this chat or a successful GitHub Actions run and unzip the artifact if necessary.
2. On any supported Windows/macOS machine with Roblox Studio, choose **File → Open from File** and select `Harborlight.rbxl` or `Harborlight.rbxlx`. You can remain in this Codex Cloud chat; switching Codex to Local mode is not required to open an artifact yourself.
3. Press **Play**. The source-generated harbor, supply crates, repair stations, menus and garden appear at runtime. In edit mode, the initial floor and spawn are visible; runtime-generated objects are not missing assets.
4. Use native movement. Walk to a teal crate and use its prompt. Carry up to five supplies, then contribute at the current repair station. Complete the pier, greenhouse and beacon, then replay the next shift.
5. Open **Lantern colors** to spend earned tokens. Robux purchases are disabled by default. **Guide / settings** explains controls and has local sound/effects settings.
6. For multiplayer tests use Studio’s **Server & Clients** / local server testing with at least two clients. Capture actual results using [the QA plan](docs/08-QA-AND-PLAYTESTING.md).

Studio preview is intentionally memory-only: stopping Play loses progress. In-game messaging says so. Do not interpret this as a broken production save.

## Optional Rojo live synchronization
The built place is the simplest handoff; no connection to the running cloud environment is needed. For active Studio iteration, clone the same GitHub commit onto the Studio machine, install the matching official Rojo Studio plugin, run `rojo serve default.project.json` in that clone, and connect the plugin to `localhost:34872`. Review the proposed sync before accepting it. Save source-owned edits in Luau/JSON and commit them back to GitHub. Rojo is not a general two-way Studio-to-source exporter.

Do not expose an unauthenticated Rojo server publicly. A Studio machine cannot reach the cloud workspace using `localhost`; use artifact handoffs or an explicitly configured secure tunnel when needed. The cloud development workflow does not depend on a continuously connected Studio client.

## Repository structure

```text
src/shared/          Config, profile normalization, economy, shifts, rate limits
src/server/          World, persistence, authority, purchase/analytics adapters
src/client/          HUD, workshop, guide/settings, optional reading
 tests/              Lune domain/mocked-adapter checks and publisher guard tests
scripts/             Pinned tooling, checks, place inspection, guarded publisher
 docs/               Research, design, theology, business, QA, launch, runbooks
assets/              Placeholder inventory and replacement/rights requirements
.github/workflows/   Cloud verification and downloadable Studio artifacts
```

## Services and publishing preparation
Configure `src/shared/Config.luau` deliberately:

- `EnableStudioDataStore = false`: keep this default for ordinary file previews. To test real saves, create a separate private test experience in Studio, enable Studio API service access there, and use a test-only configuration. Never connect an editable local preview to production player data.
- Live servers use `Harborlight_Profile_v1` with session leases and UpdateAsync. Failed loads do not become writable defaults. Exercise outage, shutdown and rejoin behavior in the test universe.
- `SupporterPassId = 0`: no Robux prompts. A future configured pass grants cosmetic ocean trim only; ownership is verified on the server. Create and review the real pass in Creator Dashboard before testing.
- `EnableAnalytics = false`: enable after private validation; Roblox custom events require published games. No reading/faith data is recorded.

See [Studio setup](docs/STUDIO-SETUP.md) and [publishing runbook](docs/PUBLISHING.md). The publisher defaults to a no-network dry run and requires an existing place, matching reviewed artifact hash, allowed target and environment API key for an explicit execution. No Roblox credentials are in this repository. No place has been uploaded or published by this task.

## What still requires Studio or account access
Cloud checks cover pure logic, mocked persistence behaviors, syntax compilation, formatting and structural place inspection. They do **not** execute the Roblox engine. Studio and devices are needed for visuals, gameplay feel, touch/controller layouts, multi-client replication, physics, performance, actual persistence and purchase behavior. Creator Dashboard/account access is needed for experience ownership, content classification, assets, pass IDs, analytics and scoped publishing credentials. Publication needs actual authorization and evidence from the release checklist.

Current Roblox guidance addresses sensitive religious themes under 16+ content. Complete the real maturity questionnaire for this experience; optionality alone does not establish an age rating. See [biblical integration and platform review](docs/03-BIBLICAL-INTEGRATION-STRATEGY.md).
