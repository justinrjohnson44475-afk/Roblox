# Movement v2 — owner feedback implementation

November 8, 2026. The owner reported liking the surrounding/ground textures, but described running and sword attacks as stiff and the dash as an external pull. Requested ninja running, anime-style burst movement, double jump, a few wall-running steps and future biome diversity. This is owner-reported feedback, not agent-observed Studio evidence or a completed solo/four-client acceptance gate.

## Changes delivered in source

- Reauthored Run/Sprint with forward torso pitch, a counterbalanced head, trailing arms/blade, folding knees and quicker leg cadence. Sprint target30 studs/sec, with smoothed speed changes and speed-adjusted animation playback. Small additive lateral lean is applied around Animator evaluation and removed before the next evaluation to avoid accumulation.
- Continuous monotone Hermite pose curves sampled60Hz replace easing to a halt at every sword contact. Added hip-leading preparation, a stepping lead leg, follow-through and a settling guard. The approved light/heavy anticipation/active/recovery windows and damage authority remain unchanged.
- Owning clients now continue accepted attack predictions on the server-created Animator. Confirmation no longer stops the local strike. Action/locomotion/mobility channels crossfade previous tracks, and a180ms input buffer accepts near-recovery follow-ups. Rejection still stops presentation and clears pending attack input. Markers never authorize damage.
- Dash tuning v2:18 studs over approximately180ms, sine-shaped acceleration/deceleration, brief vertical hold, body-hull obstruction casts, directional tuck poses and small fading pose echoes. The .4s defensive window, stamina cost and path cooldown remain preserved. No teleport, collision disabling, permanent destruction, screen flash or licensed anime assets were introduced. Direction follows movement input when present, otherwise facing.
- One extra airborne jump:48-stud/sec upward impulse and original tucked flip. Server tracks the airborne budget, validates takeoff/ground contact and rejects repeats. Brief contact cannot replenish the allowance. Keyboard/controller use a second jump press; native touch jump receives press-edge handling, with an additional Air Jump button. Holding jump alone must not consume the extra jump.
- Wall run: hold sprint while airborne and moving along an anchored, collidable, near-vertical wall within3.4 studs.28 studs/sec, max700ms/five steps, one run per airborne period,12 stamina to start. Continuous contact validation, timed expiry, sprint-release and jump/dash cancellation. An unused air jump can kick away; spending the extra jump first does not grant another. NPCs/moving objects are not valid walls. Forces, attachments and ownership are restored on exit/death/removal.
- A side practice lane, a small sand material study, trees with a segmented hanging vine and concrete/metal urban facade pieces were added. Central slate ground and the Warden battle space remain. These are small material/traversal studies, not completed dune/jungle/urban regions.
- All33 original Blender animation actions now have retained users so they survive reopening the `.blend`. Source pose renders inspect the source assets only; they are not Roblox captures or proof of a flawless animation.

## Reference evidence

[Official Naruto running analysis](https://naruto-official.com/en/news/01_1479), published June8,2023, retrieved November8,2026: used the forward upper-body and trailing-arm silhouette as a broad pose reference. The game retains original characters, equipment, clips, effects and naming.

[C.B.T. Stunt Alliance's sword choreography lesson/transcript](https://cbtstunts.com/movie-sword-training-tip-5-of-6-choreography-techniques/), retrieved November8,2026: used its discussion of alternating cutting angles, readable exchanges and guard transitions to guide original light-chain arcs and recovery. Attempted the embedded [choreography video](https://www.youtube.com/embed/6ibJKA4GCIc); the web fetch returned “Online fetch throttled.” The transcript was read; the video was **not watched**. Dragon Ball-style speed bursts inform the requested visual direction, not a claim of reviewed footage or copied animation.

## Reproducible delivery

`bash scripts/check.sh` builds `build/Riftwake-Movement-v2.rbxl` (a named copy of the signature build), XML/binary signature/baseline builds, checksums and inspections. Reauthoring: Blender4.3.2 with `scripts/ascension/author_assets.py`, then Lune `scripts/ascension/bake.luau`, Python `scripts/ascension/manifest.py`, and StyLua. Optional source pose inspection: Blender `scripts/ascension/render_motion.py`. Registry has50 exported records:3 models,33 animations,14 audio drafts. No owned/imported/engine-validated IDs are verified.

## Next Studio checks

1. Run, stop, strafe and hold Shift; inspect torso/arms, cadence, sliding feet and blending into sword attacks.
2. Tap light attacks near recovery, then heavy; verify no confirmation hitch, wrong combo pose, lingering guard or accumulating marker callbacks. Test0/100/200ms latency.
3. Dash forward/back/sideways, into a wall, along slopes and over a gap. Check bounded distance, no wall penetration, controlled vertical hold and correct force/ownership cleanup.
4. Jump, press jump again, try a third press and hold jump. Test low ceilings, landing grazes, respawn and controller/native touch presses. There must be one extra jump per real airborne period.
5. Jump alongside the two practice walls on the right of arrival while holding sprint and moving parallel to the wall. Check five steps maximum, loss of wall contact, corners, sprint release, spent/unused air-jump exit, stamina failure and death cleanup. Ordinary basic guard/parry/Corebreak rules must still work.
6. Inspect afterimages with reduced motion, simultaneous four-player dashes and repeated encounters; check part counts/transparency/constraints return to baseline. Run physical-device and multiplayer performance tests before quality claims.

Cloud checks exercise pure state, source integrity and mocked adapter behavior. They do not simulate Roblox physics, prove replication/animation smoothness, establish physical-device performance or complete the production gate. No publication or merge is authorized by this change.
