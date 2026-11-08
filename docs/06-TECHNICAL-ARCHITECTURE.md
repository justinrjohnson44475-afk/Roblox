# Riftwake technical architecture

## Data and build flow
Rojo maps shared/client/server Luau to Roblox services. `scripts/bake-world.luau` executes the actual World builder under Lune’s Roblox DOM and serializes `assets/world.rbxmx`; Rojo embeds it under Workspace.RiftwakeWorld. World geometry is visible before Play. Runtime Main binds its forge/gate prompts and creates enemies, telegraphs and player rigs. The bake also exports geometry for optional Blender previsualization. Those renders are not engine execution.

Shared pure modules: Profile, Progression, Combat, EnemyAI, Authority, RateLimit and cosmetic Economy. Config contains concrete region, encounter, upgrade, form and path definitions. Server modules apply Roblox services/Instances. Client modules render UI, input and non-authoritative effects. No external gameplay package dependency.

## Authority
Clients send action intent and a finite aim vector. Server selects targets, computes damage, validates level/Focus/cooldown, checks alive character and region, and owns rewards. No client amount, target death or purchase-success event is accepted. Forge actions also require proximity to the physical sanctuary forge. Region membership is assigned through validated portal use; displacement/bounds checks reject obvious teleport bypasses. This is not a complete movement anticheat or latency-compensated combat implementation.

Enemy states update at a capped 10 Hz: idle/chase/windup/recovery/exposed/dead. Orange telegraph geometry is server-owned. An impact checks current validated positions and the server’s dash window. Cinder phase two schedules a repeated impact with incarnation checks; Crownless phase two creates a three-zone pattern. Basic attacks are directional, with a bounded two-target cleave; bursts are area attacks. Enemy models are anchored authored constructs and use server pivots; actual replication smoothness requires engine tests.

Reward recipients are recent contributors above a small participation threshold. Set dead/rewarded state before any yielding service work. Per-incarnation receipts prevent repeated kill grants. The server additionally requires live participants in the correct nearby region. First-clear bonuses use persisted milestone flags, so a respawn does not mint repeated first-clear bonuses.

## Persistence
Keep the existing experience-scoped `Harborlight_Profile_v1` DataStore key name for continuity. Profile schema 2 safely accepts schema 1, preserves earned legacy cosmetic fields, initializes new RPG progress and refuses unknown future schemas. Persist XP, shards, cores, upgrade ranks, rig form, build path, boss clears, kill count and cosmetic ownership. Legacy tokens remain cosmetic-only. No religious behavior, reading completion or belief is stored.

UpdateAsync envelopes retain per-session owner and expiring lease. Failed loads never become writable defaults. Autosave every 45 seconds, bounded retry, save warning, leave/close writes, ownership-loss rejection and lease expiry protection remain. Mock tests do not cover Roblox budgets, timing or every shutdown race. Studio is memory-only unless deliberately enabled in a separate private test universe. Paid transactions stay disabled until live save tests pass.

## UI, feedback and service boundaries
Client ContextActionService bindings support keyboard/mouse and gamepad; four explicit touch-capable buttons mirror actions. Server snapshots expose the receiving player’s stats/progression plus public encounter state via replicated models. Client effects are limited by distance and count and can be reduced/muted. No forced camera shake or screen-wide white flash. Responsive layout and gamepad selection need real devices.

Analytics adapter allows CoreBroken and WardenDefeated, disabled by default. Never instrument sanctuary reading. Cosmetic game-pass ownership is queried on the server; no consumable products are sold and no ProcessReceipt handler is installed. Future developer products require durable idempotent receipts first. Publishing is a separate guarded operation, not a build side effect.

## Verification boundary
Cloud: pure domain/mock adapter tests, syntax compilation, formatting, DOM baking/deserialization, file builds, Blender layout inspection and GitHub CI. Studio: actual engine API behavior, combat feel, controls, replication, collisions, animation, lighting, device layout, profiling and real services. The cloud geometry preview is evidence of authored composition only.
