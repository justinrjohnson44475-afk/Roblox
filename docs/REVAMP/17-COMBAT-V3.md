# Combat v3 — landing, default speed, attacks and Warden

This revision implements the owner's screenshot/feedback after movement v2. The owner liked the ninja run and glitch dash, but reported a deformed landing, weak attack/ability presentation and a stiff monster. This is owner-reported engine evidence for the previous build; it is not agent-observed verification of this revision.

## Controls and behavior

- Default running is **60 studs/second**, twice v2's30-stud sprint and greater than twice its17-stud default. It needs no Shift and does not drain stamina. Shift/controller L3 remains the wall-run intent modifier. A server-only bounded speed-bonus function prepares future earned upgrades; no speed progression or paid boost is sold/awarded here.
- Land/HeavyLand now use a small backward knee flex, counterbalanced torso/head, level feet and an upright idle endpoint. DoubleJump uses a compact tuck and neutral recovery rather than rotating the waist360 degrees. Landing immediately clears airborne tracks before selecting recovery. Pose tests check both lower legs throughout landing and a neutral pelvis/leg endpoint.
- **Mouse1/controller R2/Strike** starts a quick light immediately on press. Version2 light windows (anticipation/active/recovery):.06/.09/.13,.07/.10/.14,.10/.12/.20 seconds. Input buffering and one hit per target remain server-controlled.
- **Hold T/right mouse/controller R1/Heavy, then release** for a charged overhead attack. Minimum charge350ms; full charge at1s adds up to25% damage. Auto-release at1.2s prevents a stuck hold. Early release cancels without stamina cost. The server owns charge start/time, resources and release acceptance. The Heavy clip advances to its release phase rather than replaying its windup. Release active/recovery windows are.16/.40; movement slows while committed. Dash cancels a held charge; guard cannot overlay it.
- **E/X/Coreburst** costs the path's Focus amount (normally60), unlocks at level2, and releases an actual server-timed radial gauntlet shockwave with obstruction/membership checks. It reliably interrupts a marked core charge. It is a special area ability, not request-time radial melee. The expanding cyan wave is presentation only; only the server grants damage/interrupts.
- **R/Y/Overdrive** costs100 Focus and unlocks at level5. Its activation pulse is followed by8s of25% stronger light/Heavy hits and faster stamina recovery. A timed gold outline and status countdown identify the mode. Cooldown remains14s. Buffs end on expiry/respawn; no permanent profile change.
- Unavailable E/R actions show level, Focus or cooldown feedback before playing an animation. Visible controls explain every key. **TEST E/R · REFILL** unlocks these abilities/refills Focus only for the current life in an unsaved Studio session. It does not grant XP, balances, clears, equipment or a persistent unlock, and is rejected when Studio persistence is enabled or outside Studio.

## Warden movement and expression

Original source now includes a fuller sixteen-key gait with folded knees, shoulder counter-motion and breathing/head movement; roar/phase expression; separate sweep, aimed lance and ground slam; exposed-core recovery; partial upper-body hit recoil; and a defeat pose.38 clips and55 asset records are exported. No outside animation asset was bought, copied or published.

Humanoid navigation remains server-owned. Facing turns use a bounded AlignOrientation instead of snapping root CFrame at each telegraph. Walk speed16/phase-two18 and animation cadence adapt to actual velocity. Idle/locomotion/attack channels are separated; a looping exposure pose is explicitly stopped when navigation resumes. Damage contact is aligned to each authored impact marker (.82s sweep,1.02s lance,1.57s slam), with distinct lance presentation. Intro/phase roars retain player control. The defeat presentation retains joints until encounter cleanup rather than breaking the rig before its animation plays.

These are source implementations and source pose inspections. They do not establish realistic foot placement, final monster art, smooth Roblox replication or four-client combat quality. Those still require the next Studio check.

## Environment scope correction

The small sand patch, jungle tree/vine and urban facade material samples were removed. Only plain ruin-style walls remain as traversal practice. The liked central slate ground is preserved. The eventual world needs **whole** dune, jungle (including proper trees/vines), and urban regions, not decorative samples in a small combat arena.

For planning, interpreting100–500 times larger as **area** gives roughly1560–3490 studs per side compared with this156-stud arena. That is a provisional planning interpretation, not a built-world claim or a commitment to multiplying every dimension500 times. Existing progression IDs remain; the first validated region is a sector of that longer-term streamed world. No full-world construction or gate-B acceptance is implied by this prototype.

## Next Studio regression pass

Open `build/Riftwake-Combat-v3.rbxl`. Verify60-stud running with Shift untouched, repeated jump/double-jump landings from multiple heights, idle/stop/walk after landing, rapid light-chain input, early/full Heavy release, guard/dash charge cancellation, E/R locked/empty/cooldown feedback, and actual enemy-health/interrupt/mode outcomes. Use TEST E/R for ability inspection without grinding or altering saves.

For the Warden, inspect approach/turns, roar, phase transition, each warning/contact, heavy recoil, exposed recovery back into walking and defeat cleanup. Compare solo/four-client behavior under latency and verify effect pools, ownership, resources and memory over repeated cycles. Source pose renders in `assets/ascension/previews` are Blender inspections, not Roblox screenshots. No flawless-animation or release-readiness claim is made.
