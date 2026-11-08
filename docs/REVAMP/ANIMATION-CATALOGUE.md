# Animation catalogue

Original source drafts;30 named R15 clips. All are **exported**, none imported/engine-validated or backed by an owned published ID. Source poses and trajectories: `assets/ascension/animations/choreography.json`; preview sequences: `SourceClips.rbxmx`; authoring: `scripts/ascension/author_assets.py`. Markers never authorize server damage.

| Clip | Duration seconds | Loop | Priority | Markers (seconds) |
|---|---:|---|---|---|
| Idle | 2.000 | True | Idle |  |
| CombatIdle | 1.400 | True | Idle |  |
| Walk | 0.850 | True | Movement | FootLeft 0.000, FootRight 0.425 |
| Run | 0.650 | True | Movement | FootLeft 0.000, FootRight 0.325 |
| Sprint | 0.500 | True | Movement | FootLeft 0.000, FootRight 0.250 |
| StrafeLeft | 0.750 | True | Movement | FootLeft 0.000, FootRight 0.375 |
| StrafeRight | 0.750 | True | Movement | FootLeft 0.000, FootRight 0.375 |
| Jump | 0.450 | False | Movement | Takeoff 0.000 |
| Fall | 0.800 | True | Movement |  |
| Land | 0.350 | False | Action | GroundImpact 0.000 |
| HeavyLand | 0.600 | False | Action | GroundImpact 0.000 |
| Light1 | 0.420 | False | Action | TrailOn 0.100, HitStart 0.100, HitEnd 0.220, TrailOff 0.220, Recovery 0.220 |
| Light2 | 0.460 | False | Action | TrailOn 0.120, HitStart 0.120, HitEnd 0.240, TrailOff 0.240, Recovery 0.240 |
| Light3 | 0.610 | False | Action | TrailOn 0.170, HitStart 0.170, HitEnd 0.320, TrailOff 0.320, Recovery 0.320 |
| Heavy | 0.900 | False | Action | TrailOn 0.350, HitStart 0.350, GroundImpact 0.400, HitEnd 0.470, TrailOff 0.470, Recovery 0.470 |
| DashForward | 0.400 | False | Action | DashStart 0.000, DashEnd 0.220 |
| DashBack | 0.400 | False | Action | DashStart 0.000, DashEnd 0.220 |
| DashLeft | 0.400 | False | Action | DashStart 0.000, DashEnd 0.220 |
| DashRight | 0.400 | False | Action | DashStart 0.000, DashEnd 0.220 |
| Guard | 1.000 | True | Action |  |
| Parry | 0.400 | False | Action | Parry 0.080 |
| GuardBreak | 0.700 | False | Action |  |
| Hurt | 0.350 | False | Action |  |
| Coreburst | 0.480 | False | Action | Charge 0.000, HitStart 0.120, GroundImpact 0.120, HitEnd 0.180, Recovery 0.180 |
| Overdrive | 1.000 | False | Action | Charge 0.000, HitStart 0.250, GroundImpact 0.250, HitEnd 0.400, Recovery 0.400 |
| WardenIdle | 2.000 | True | Action |  |
| WardenWalk | 1.200 | True | Action | FootLeft 0.000, FootRight 0.600 |
| WardenSlam | 2.200 | False | Action | Charge 0.000, HitStart 1.150, GroundImpact 1.350, Recovery 1.400 |
| WardenLance | 1.900 | False | Action | Charge 0.000, HitStart 1.150, GroundImpact 1.350, Recovery 1.400 |
| WardenExposed | 2.400 | True | Action |  |

Clip existence does not establish animation quality or runtime state integration. Review anticipation, contact, follow-through, recovery, planted feet, weapon orientation and transition blends in Studio. Warden phase selection and attack timings must be aligned to these takes during its engine gate; current Warden source windups and timeline are independently authored and may need retiming.
