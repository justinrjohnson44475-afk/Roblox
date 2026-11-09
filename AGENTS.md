# Project instructions

Current game: Riftwake: Ascend. Harborlight is superseded; read docs/10-GAMEPLAY-AND-COMMUNITY-RESEARCH.md and docs/11-REPLACEMENT-CONCEPT-DECISION.md before making concept changes. Preserve the explicit limits: no watched footage or Roblox playtest has been verified.

Keep development cloud-first and Roblox Studio-compatible. Use Luau for game code and Rojo for place builds. Do not require a running personal laptop for source development. Read docs/PROJECT-STATUS.md and docs/KNOWN-ISSUES-AND-RISKS.md before continuing.

Run `bash scripts/check.sh` for changed gameplay/tooling. Bootstrap pinned tools with `bash scripts/bootstrap.sh` if needed. Format Luau with `.tools/stylua src tests scripts/inspect-place.luau scripts/bake-world.luau`. Cloud compilation/DOM tests are not Studio playtests or full Roblox type checking. Record observed results precisely.

Keep all economy authority on the server. Failed loads must never become writable default profiles. Preserve session ownership checks and bounded save retries. Robux purchases and custom analytics default off. Do not add developer products without durable idempotent receipt handling. Never log or persist religious reading/participation or beliefs. Christian reading must remain explicit, optional, unrewarded and respectful.

Never commit credentials, generated tool binaries, local environment files or private player information. Preserve artifact provenance and asset rights. Publishing requires an existing configured target, reviewed build, appropriate authorization and verified operation completion; do not claim it happened based on a build or upload acceptance. Keep status, known risks and setup instructions current. Do not classify the religious material as unrestricted without the actual Roblox policy review.

World.luau is baked into assets/world.rbxmx by scripts/bake-world.luau. Rebake before builds and after map changes. Preview renders are not Roblox engine screenshots; use a neutral mannequin only to represent the actual rig geometry and label that limitation. Preserve charge-break identity, build tradeoffs, deterministic upgrades and milestone gates. Test rewards/migration/authority when changing progression.

Owner feedback on November8: liked the arena textures, requested ninja running, smoother sword/dash movement, double jump, short wall runs and diverse future biomes. Movement v2 source/test build and verification limits are in docs/REVAMP/16-MOVEMENT-V2.md. Owner-reported feedback is distinct from agent-observed engine captures or completed multiplayer acceptance.

Combat v3 responds to the landing screenshot and later feedback: default run60, neutral landings, immediate light/held Heavy, meaningful E/R, original Warden states and no tiny biome samples. Read docs/REVAMP/17-COMBAT-V3.md. Preserve session-only ability preview guards; never grant its unlocks or Focus in persistent/live sessions.
