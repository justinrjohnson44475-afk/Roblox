# Project status

Updated November 7, 2026 client date; cloud execution crossed into November 8 UTC.

## Current phase
First cloud-first vertical slice implemented and automatically checked. Pre-Studio verification and commercial validation remain. The full product is not complete or launch-ready.

## Completed
- Initial dated, source-backed twenty-game market dossier, five-concept comparison and Harborlight selection.
- Design, player journey, architecture, biblical integration, financial scenarios, QA and launch strategy documents (00–09).
- Luau/Rojo client/server/shared project; generated harbor world with eight supply points and three shared repairs.
- Repeatable shift loop, contribution tokens, cosmetic ownership/equipping, player HUD, guide and session settings.
- DataStore adapter using UpdateAsync, session leases, failed-load protection, save warnings and bounded retries.
- Explicit optional Christian reading without progression, tracking or economic ties.
- Cosmetic pass adapter and custom analytics adapter, both disabled by default.
- Pinned tooling, GitHub Actions artifact workflow, binary/XML builds, Studio setup and guarded future publishing helper.

## Research findings and uncertainties
Collection, visible progression and shared play recur across the sampled games. Third-party snapshots show historical leaders are not a sufficient current ranking. Competitor revenue, retention, release histories, sustained growth and many detailed UX/store metrics remain unverified. Anecdotal grind/loss feedback suggests a hypothesis, not a proven underserved market. The selected restoration loop needs actual-player evidence. Financial scenarios remain assumptions; the base case loses money.

Current Roblox policy guidance covers sensitive religious themes under 16+ content. Optional reading does not establish a rating exemption. The complete experience needs an accurate questionnaire and clarification where necessary before distribution.

## Verified in this cloud workspace
- Rojo 7.7.1, Lune 0.11.1, StyLua 2.6.0 executed.
- 52 Luau checks passed: domain behavior, mocked persistence faults/leases, source compilation and generated-world structure.
- 9 Python publisher guard tests passed, without API requests.
- StyLua formatting check passed.
- Binary `build/Harborlight.rbxl` and XML `build/Harborlight.rbxlx` built successfully.
- Both places deserialized with twelve expected nonempty scripts, service mappings, floor and spawn.
- Publishing helper dry run succeeded; no network upload or publication occurred.
- Logs and SHA256 hashes generated in build/. GitHub Actions status is separate from these local cloud results.

## Not performed
Roblox Studio execution; visual or real-device playtests; engine multiplayer/physics/performance tests; actual player feedback; live DataStore/Marketplace/analytics verification; theological expert review; maturity questionnaire; Roblox upload/publication. No target place/universe or Roblox API secret is configured. Do not infer these results from the build.

## Next priority work
1. Run the generated artifact in Studio and record solo/two-client/device results against QA document 08.
2. Validate actual save/lease/shutdown behavior in a separate private test universe.
3. Observe real testers and improve recovery variety/onboarding before commissioning extensive content.
4. Expand official metric snapshots, close-competitor research, release histories and store/feedback audits.
5. Resolve content classification and review theological summaries/asset rights.
6. Only then configure fair cosmetic offers, analytics and an owner-authorized private release.

## User/account involvement
No laptop or Local mode is required for ongoing cloud source work, research, automated checks and builds. Studio verification needs a supported Windows/macOS Studio host when scheduled; no such host is configured for this task. The owner must eventually supply/authorize private experience ownership, real place/pass IDs, account settings, content declaration and scoped publishing credentials via settings/secrets. No secrets should be pasted in chat. These prerequisites do not prevent further cloud coding.

See KNOWN-ISSUES-AND-RISKS.md, QA-RESULTS.md, STUDIO-SETUP.md and PUBLISHING.md. GitHub delivery and remote CI results are recorded after push rather than assumed here.
