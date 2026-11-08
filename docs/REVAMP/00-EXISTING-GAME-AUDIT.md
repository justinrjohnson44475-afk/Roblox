# Existing-game audit

Baseline: `e1cae97869e60ce59c7f6d4cf5668d71e2170fbb`. Branch `revamp/project-ascension`; rollback tag `baseline/riftwake-pre-revamp-e1cae97`. Audit by source inspection and cloud tests on November 8, 2026, not engine observation.

| System | Decision | Evidence and treatment |
|---|---|---|
| XP, shards, cores, clear flags, forms, paths | Preserve | `Progression.luau` deterministic arithmetic; retain IDs, thresholds and existing rewards |
| Profile ownership/leases | Preserve | `DataService.luau` refuses failed/future loads, uses UpdateAsync ownership and bounded save retries; existing mock race tests retained |
| Profile data | Expand | Additive schema 3 loadout, customization, settings and bounded reward history; same datastore/key; schema 1/2 migration tests |
| Main server request dispatch | Rebuild | Legacy Main applies damage at request time; new CombatService schedules authoritative windows; legacy remains adapter/default checkpoint |
| Radius/cone melee | Replace | `Combat.canHit` was immediate; signature HitboxService uses measured blade trajectory and obstruction/facing/range checks |
| Instant dash | Replace | Legacy root translation; new MovementService uses continuous .22s LinearVelocity, collision checks and server ownership during dash |
| Anchored enemy pivots | Replace | Signature Humanoid/Animator + bounded path requests; WardenState supplies deliberate charge/recovery/exposure |
| Solo/party encounters | Expand | Pure PartyState/EncounterState plus isolated signature arenas and frozen roster scale; no cross-party damage/reward route |
| Enemy rewards | Refine | Existing Progression grant behind bounded RewardLedger; snapshot includes balances and dedup ledger together |
| R6/R15 accessories | Rebuild | Original R15 source/FBX and clips authored; diagnostic collision proxy is not imported hero art |
| World | Rebuild after gate B | Baseline 686-part map preserved; compact signature arena supplied. 480×480 flagship not yet built |
| Generic pulse/ping | Replace | Blade-marker trails, event-specific fragment counts and original WAV drafts; cracks/dust/music crossfades still pending |
| UI/controls | Rebuild | Signature diagnostics, light/heavy, guard, parties, resources and local reading; production inventory, remapping and mobile polish pending |
| Purchases | Refine | Existing disabled adapter preserved; no shards/dev products added; cosmetic passes await ownership/service tests |
| Christian reading | Preserve | Optional local reading remains free, unrewarded and untracked; no related remote, profile flag or completion dependency |
| Custom analytics | Preserve disabled | No retention claims or religious telemetry added |
| Old Harborlight identity | Remove from presentation | Keep legacy data keys/balances to avoid destructive migration; history retained |

The new runtime is separately selectable through `ascension.project.json`; `default.project.json` retains legacy behavior. Legacy extraction is therefore transitional, not completed deletion of the monolith. A source test passing proves the asserted logic only. Studio effects, movement, navigation, import and replication remain unverified.
