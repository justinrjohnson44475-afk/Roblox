# Riftwake: Ascend

A Roblox PvE action RPG about becoming a visibly different, more capable character. Start with a fractured relic gauntlet, break constructs’ charged attacks, earn abilities and boss cores, forge an evolving combat rig, and unlock harder regions.

**Harborlight has been replaced.** The owner's criticism was valid: its chore loop lacked meaningful character growth and its appearance had not been inspected. The old implementation remains in Git history. Read [the research correction](docs/10-GAMEPLAY-AND-COMMUNITY-RESEARCH.md) and [replacement decision](docs/11-REPLACEMENT-CONCEPT-DECISION.md).

## What is implemented
- Strike combos, a timed defensive dash, Focus-powered Coreburst, and earned Overdrive.
- Charged enemy attacks, interrupt/exposed-core windows, boss phases and region-specific phase-two attacks.
- Three combat regions and a safe forge hub, with authored geometry baked into the place for edit-mode visibility.
- XP/levels, deterministic stat upgrades, boss-first-clear gates and four visible rig forms.
- Vanguard, Strider and Arcanist build paths with different tradeoffs; free forge changes after level 3.
- Contribution rewards, profile persistence protections, keyboard/gamepad/touch bindings, HUD, forge cards and settings.
- Clearly labeled optional Christian reading, unrelated to power, rewards, progression or analytics.

**Verification status:** cloud logic/mock/DOM checks and Rojo builds pass. No Roblox Studio execution, visual playtest, real-player feedback or live-service verification has occurred. Video playback was attempted but blocked by the cloud browser network. Neither an attractive render nor a test suite establishes combat feel or commercial success.

## Inspect the authored visual work
[World layout](assets/previews/riftwake-world.png), [Verdant region](assets/previews/riftwake-verdant.png) and [rig evolution](assets/previews/riftwake-forms.png) are Blender previsualizations exported from the actual Luau geometry/appearance builders. They are **not Roblox engine screenshots**. The character in those previews is a neutral R6 mannequin; actual players use their own Roblox avatar with the generated rig attached. UI, engine lighting, animation, collisions and multiplayer are not validated by these renders.

## Cloud-first development and builds
Your laptop can remain off. Codex Cloud and GitHub handle source work, research, tests and place generation.

Linux x86_64:

```bash
bash scripts/bootstrap.sh
bash scripts/check.sh
```

Pinned official tools: Rojo 7.7.1, Lune 0.11.1, StyLua 2.6.0. Bootstrap verifies committed archive hashes. Requires Bash, curl, unzip, sha256sum and Python 3. On Windows/macOS use official Aftman and `aftman install`, then `lune run scripts/bake-world.luau`, `rojo build default.project.json -o Riftwake.rbxl` and the equivalent test commands; the Bash installer is Linux-only. No Wally/Node dependency is required.

Build outputs: `build/Riftwake.rbxl`, `build/Riftwake.rbxlx`, verification logs and SHA256SUMS. GitHub Actions produces `Riftwake-Studio-<commit>` artifacts. The committed generated world is `assets/world.rbxmx`; its source is `src/server/World.luau`. The cloud check rebakes it before building. Inspect the actual workflow result before claiming remote CI success.

## Open in Roblox Studio
1. Download the latest **Riftwake** artifact from GitHub Actions or this chat. Older Harborlight files are superseded.
2. Open `Riftwake.rbxl` or `Riftwake.rbxlx` with **File → Open from File** on a supported Studio host. The complete authored static world is visible in edit mode.
3. Press **Play**. Enemy constructs, your character rig and UI initialize at runtime.
4. Enter the green **Verdant Reach** gate. Face the camera toward enemies. Mouse1 strikes; Q dashes; E uses Coreburst at level 2; R uses Overdrive at level 5. Gamepad: R2/B/X/Y. Touch: four combat buttons with native movement/jump controls.
5. Successful strikes build Focus. Watch orange warnings; dash clear or interrupt a charge with Coreburst, then punish its exposed core. Contributions earn rewards even without the final hit.
6. Return through the dawn gate. Interact with the forge to upgrade Power/Vitality/Flow, evolve the rig or change build paths. Defeat wardens to open Ember Scar and Astral Crown.

Studio previews use memory-only profiles by default and say so. Stopping Play discards preview progress. Real persistence tests need a separate private test universe. See [Studio setup](docs/STUDIO-SETUP.md) and [QA](docs/08-QA-AND-PLAYTESTING.md).

## Rojo synchronization
On a supported Studio machine, clone this repo, install matching tools and the official Rojo plugin, run `rojo serve default.project.json`, then connect the plugin to localhost:34872 and review the sync. When World.luau changes, rebake with `lune run scripts/bake-world.luau` so the model updates. Do not expose an unauthenticated cloud Rojo server publicly. Artifact handoff avoids any need for a continuous cloud-to-Studio connection. Codex does not need to switch to Local mode for you to open a build.

## Architecture and services
`src/shared` owns profile migration, progression, combat calculations, enemy states and request gates. `src/server` owns world/appearance builders, authority, encounters, persistence, and purchase/analytics adapters. `src/client` owns HUD, menus, input and cosmetic feedback. `tests`, `scripts`, `assets` and `docs` contain verification, build tooling, generated assets and project evidence.

`Config.EnableStudioDataStore`, `Config.EnableAnalytics` are false; `SupporterPassId` is zero. Keep purchases off until real ownership/price/service tests pass. No paid power, paid resets, developer products or receipt handler exists. Existing schema-1 cosmetic fields migrate into schema 2 without becoming combat power. The old DataStore name is intentionally retained for safe migration; Roblox DataStores remain scoped to the owning experience.

[Publishing helper](docs/PUBLISHING.md) defaults to a no-network dry run and requires an authorized existing target, reviewed hash and scoped environment key for execution. No Roblox upload/publication occurred. Never commit credentials.

## Current limits and next gate
See [project status](docs/PROJECT-STATUS.md). Combat balance, responsiveness, UI on real devices, enemy animation quality, save shutdown/concurrency, performance and actual enjoyment need Studio/player tests. The art is original primitive geometry and requires production polish. Current religious-content classification must be answered accurately for the whole experience; optionality does not exempt it. Commercial validation is outstanding; no claim of superiority to top games or guaranteed profitability is made.
