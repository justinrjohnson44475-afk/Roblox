# Animation and movement specification

`AttackDefinitions.luau` version 1 owns light timing (windup/active/recovery): .10/.12/.20, .12/.12/.22, .17/.15/.29 seconds; Heavy .35/.12/.43. Source clips include the exact boundaries. Flow modifies recovery only; it must not move the server active window relative to the animation. Tune only with dated engine evidence and a versioned change log.

Initial dash retained18 studs/.4s defense over.22s. Following owner feedback, movement tuning v2 uses a sine velocity profile over.18s with the same distance/defense; see16-MOVEMENT-V2.md. MovementService temporarily gives the server dash ownership, sweeps a body box against collision, stops at obstruction/end/distance, destroys force/attachment and restores ownership. This API integration is untested in engine. Run17, sprint30, guard8 are provisional tuning. Server accepts bounded aim/sequence and limits movement during attack; current plausibility checks are not a complete anti-teleport system.

Source authoring exports33 R15 clips from original Blender joint poses. Named actions have anticipation, contact and recovery keys. `ANIMATION-CATALOGUE.md` records each duration/marker. KeyframeSequence library and exact measured blade samples are reproducibly baked from choreography JSON. Runtime uses server-created Animators. Studio can register source KeyframeSequences for diagnostic playback; production needs correctly owned published IDs. Missing IDs cannot satisfy readiness.

Movement v2 selects idle/combat idle, walk, ninja Run/Sprint, directional dash, guard/parry/hurt, jump/fall, weighted landings, extra-jump flip and lateral wall runs. Action/locomotion/mobility channels crossfade and an180ms recovery buffer reduces discarded follow-up input. Additive lateral lean resets around Animator evaluation; full foot placement, remapping and robust in-engine latency validation remain pending. No claim of flawless/weighted feel is established by source checks.


Studio validation: inspect joint axes and contact silhouettes; verify blade attachments against actual imported mesh; slow playback around HitStart/HitEnd; capture transitions, stop/start, strafe, jump/fall/land and cancellation; compare actual server hit timestamps. Fix any import-axis or retargeting mismatch before replacing proxy characters. Use one normalized R15 gameplay skeleton across cosmetics.
