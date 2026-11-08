# Technical architecture

Rojo maps src/shared to ReplicatedStorage.Shared, src/server to ServerScriptService.Server and src/client to StarterPlayerScripts.Client. Shared modules are pure Luau wherever possible and run under Lune tests. Roblox adapters own services, Instances and networking. No Wally packages are needed yet.

Server-generated anchored geometry forms the harbor at runtime. The built file includes a static floor/spawn and scripts; generated repair geometry appears when Play starts. The client renders HUD/settings/shop and a purely local Christian reading panel. Server snapshots contain only the receiving player’s profile and public project state.

## Authority and networking
Players express intent, never token amounts, supply counts, prices, completion IDs or ownership. Pickup/deposit use server-created ProximityPrompts, with server distance, alive-character, cooldown, capacity and active-project checks. Shop RemoteEvent accepts only a short configured action/item string and is rate limited. A state request is also limited. Server timestamps and domain logic control project transitions. Anchored world avoids client physics ownership of reward objects. Spatial checks are a first barrier, not a complete movement anticheat; speed/teleport abuse remains a production review item.

Domain modules define rewards, cosmetic purchases, input normalization and shared project progression. All state transitions occur without yielding. Complete/reward once, then publish snapshots. Retry-safe profile writes use UpdateAsync, a per-session lease and session ownership checks. Never replace unknown/future-schema or failed-load data with defaults. Studio uses memory-only profiles by default; live storage failures deny entry rather than silently discard progress. Keep periodic backups via Roblox version history and exercise recovery in a test universe. Session lock expiry and budget behavior need real Roblox testing.

## Persistence
Persist schema version, tokens, lifetime donated supply, participated repairs, owned cosmetic IDs and equipped color. No religious data. Held supplies and active shared projects are server-session state. Autosave every 45 seconds; refresh lease, save on leave and during BindToClose. Save/close serialization prevents racing saves; expired leases reduce crash-lock duration. A failed save is surfaced; lock loss ends that session. Do not enable paid transactions until persistence and shutdown tests pass.

## Purchase and analytics boundaries
Only a cosmetic game pass adapter is included, disabled until its ID is configured. Roblox ownership is queried server-side; never grant from a client success message. No developer products or ProcessReceipt handler are installed because no consumable is sold. If added later, durable receipt deduplication and replay/refund tests are mandatory first. Configured purchases use Roblox’s own displayed price, not a hardcoded regional price.

AnalyticsService custom events record server-validated first contribution and completed repairs, behind a disabled-by-default flag. No arbitrary client event names, free text, beliefs or reading events. Roblox dashboards supply DAU, session length and retention. Client effects are non-authoritative and can be muted/reduced locally. Aggregate snapshots at one-second timer cadence, plus validated actions; profile payloads remain small.

## Cloud / Studio split
Cloud: research, code, domain tests, format checks, place builds, artifact inspection, Git review, future authorized API publishing. Studio: engine execution, visual inspection, mobile/controller emulation, multi-client behavior, actual DataStore/Marketplace integration and performance. A Linux cloud build is not an engine playtest. Publishing via current Open Cloud can update an existing place remotely; account/experience creation, IDs, credentials, policy classification and explicit release authorization are prerequisites. See publishing runbook.
