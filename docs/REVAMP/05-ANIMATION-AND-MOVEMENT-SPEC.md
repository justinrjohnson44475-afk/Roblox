# Animation and movement specification

`AttackDefinitions.luau` version 1 owns light timing (windup/active/recovery): .10/.12/.20, .12/.12/.22, .17/.15/.29 seconds; Heavy .35/.12/.43. Source clips include the exact boundaries. Flow modifies recovery only; it must not move the server active window relative to the animation. Tune only with dated engine evidence and a versioned change log.

Dash retains 18 studs and .4s defense, with velocity over .22s. MovementService temporarily gives the server dash ownership, sweeps a body box against collision, stops at obstruction/end/distance, destroys force/attachment and restores ownership. This API integration is untested in engine. Walk17, sprint24, guard8 are provisional tuning. Server accepts bounded aim/sequence and limits movement during attack; current plausibility checks are not a complete anti-teleport system.

Source authoring exports 30 R15 clips from original Blender joint poses. Named actions have anticipation, contact and recovery keys. `ANIMATION-CATALOGUE.md` records each duration/marker. KeyframeSequence library and exact measured blade samples are reproducibly baked from choreography JSON. Runtime uses server-created Animators. Studio can register source KeyframeSequences for diagnostic playback; production needs correctly owned published IDs. Missing IDs cannot satisfy readiness.

Implemented diagnostic locomotion selects idle/combat idle/run/sprint/jump/fall. Walk, strafes, weighted landings, guard/parry/hurt and directional dash clips are authored but not all are selected or blended by the current controller. Procedural lean, foot placement, landing velocity selection, input remapping and robust reconciliation are pending. No claim of responsive/weighted feel has been verified.

Studio validation: inspect joint axes and contact silhouettes; verify blade attachments against actual imported mesh; slow playback around HitStart/HitEnd; capture transitions, stop/start, strafe, jump/fall/land and cancellation; compare actual server hit timestamps. Fix any import-axis or retargeting mismatch before replacing proxy characters. Use one normalized R15 gameplay skeleton across cosmetics.
