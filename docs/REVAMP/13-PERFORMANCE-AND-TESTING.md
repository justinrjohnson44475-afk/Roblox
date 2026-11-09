# Performance and acceptance testing

Cloud checks: `bash scripts/check.sh` runs formatting, Luau domain/mock/DOM/compilation checks, publisher unit tests, baseline/staging Rojo builds, structural inspections and asset integrity. `python3 scripts/ascension/verify.py --release` must fail at this checkpoint. No frame-rate, live DataStore, Marketplace, actual animation replication or engine behavior is established by these checks.

## Engine matrix — all pending

| Area | Required cases | Evidence |
|---|---|---|
| Combat | Every window/combo/cancel, frontal/back parry, dash obstruction/slopes, interrupt/exposed multiplier, duplicate hits, death/reset | Server timestamps + synchronized captures |
| Networking | Four clients at0/100/200ms, rejected prediction, malformed/replayed/distant/dead/wrong-encounter requests | Client/server capture and logs |
| Persistence | v1/v2/v3 migration copies, failed loads, concurrent sessions, lease loss, shutdown races, reward retry/save failure | Private test universe with nonproduction keys and fault log |
| Effects/audio | Simultaneous heavy impacts, pool exhaustion, streaming-out, restoration, disconnect,100 encounter cycles | Instance/memory counters and captures |
| Inputs/accessibility | Keyboard/controller/touch portrait+landscape, remapping, UI scale, reduced motion/flash, independent buses, shape/text warnings | Physical-device recordings; full gameplay parity |
| Workload |1/2/4/8 players, including concurrent solo encounters | Actual server profile; release cap stays4 until8 passes |

Desktop target:1080p60 FPS, i5-10400/GTX1660/16GB. Mobile target:30 FPS GalaxyA52/Snapdragon720G/6GB mobile preset. Record actual hardware, engine/version/settings, resolution, temperature and frame samples; emulation does not validate physical mobile. Target p95 frame time≤16.7/33.3ms, bounded server work and no sustained instance/memory growth over30min. Capture initial/warm/peak/end counts; compare repeated encounter cycles after cleanup, not only a single idle frame.

At least12 independent testers: ≥10 understand Corebreak without verbal coaching; median combat-enjoyment≥4/5. Include negative feedback and device/experience distribution. These are targets, not achieved findings. All nine rubric categories require independently supported≥4/5 before production readiness.

Current caps: fragment256 desktop/96 touch; positional audio32/16; new paths4/sec globally,1/sec/actor. Touch detection is a provisional preset heuristic, not hardware classification. Actual LOD/texture/streaming budgets and adaptive quality still require engine profiles.
