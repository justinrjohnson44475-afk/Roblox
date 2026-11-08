# Riftwake Studio handoff

## Open and run
Download the latest Riftwake binary/XML artifact. Open it through File → Open from File in supported Roblox Studio. Four authored islands, forge, gates and scenery are already present in edit mode. Press Play to initialize constructs, rig, menus and encounter logic. Output must have no errors; record commit, artifact hash and Studio version.

Enter the green Verdant Reach gate. Native movement/jump remains available. Mouse1 / Q / E / R correspond to Strike / Dash / Coreburst / Overdrive. Controller: R2 / B / X / Y. Touch: four action buttons. Coreburst unlocks at level 2 and requires Focus; strikes build it. Use Coreburst during an orange charge to expose a core. Dash clears danger and gives a brief server-controlled defensive window.

Return to Dawn Sanctuary to heal and use the forge. Spend earned shards on known upgrades, evolve the visible rig with warden cores, and choose a build for free at level 3. Ember requires level 3 plus the Verdant Warden clear; Astral requires level 6 plus the Cinder Colossus clear. Later abilities/forms are earned. Verify actual solo pacing rather than assuming the arithmetic test proves an enjoyable route.

## Engine and service verification
Use Server & Clients with at least two clients, then real/emulated mobile and controller tests. Follow document 08 for attack timing, boss patterns, gate bypass, co-op reward, save and accessibility tests. Geometry renders are not substitute evidence.

Studio defaults to temporary memory profiles. For real DataStore tests, the owner creates a separate private test experience, enables Studio API access there, and deliberately enables `EnableStudioDataStore` in a test config. Never point an editable preview at production player data. Existing schema-1 cosmetic fields migrate safely; future schemas must refuse load. Validate actual UpdateAsync/session/shutdown behavior, version recovery and throttling.

Robux pass ID is zero and analytics are off. Create/configure the real cosmetic pass only after owner authorization; verify native regional pricing, ownership, cancellation and service failure using current Roblox test tools. A real purchase may charge Robux. There are no consumable developer products. Actual published-game analytics should show only allowed gameplay events, never reading behavior.

## Source synchronization
Install official matching tools/plugin on the Studio host. Clone the desired Git commit, run `lune run scripts/bake-world.luau`, then `rojo serve default.project.json`; connect to localhost:34872 and review the sync. Rebake after World.luau changes. Rojo is not a general two-way exporter; save source-owned changes into Luau/config and commit them. All rigs/scenery are procedural original parts; future imported assets need rights/moderation records.

You can keep Codex in Cloud. A supported Windows/macOS Studio host is needed only for engine/visual tests, and a future authorized remote host could supply it without the owner’s laptop. No Studio host is connected here, and no engine tests or publication have occurred.
