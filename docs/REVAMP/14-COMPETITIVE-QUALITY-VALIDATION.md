# Competitive-quality validation

Status: **Not Evaluated in every category**. No composite score. Source inspections, Blender drafts and cloud tests cannot substitute for Roblox captures, matched competitor observations or independent assessments. No claim of parity/superiority, masterpiece quality or commercial success is supported.

Use the exact categories/weights and anchors in `04-STUDIO-QUALITY-BENCHMARK.md`. For each assessment record build SHA, date, device/settings, evaluator, task/scene, reference game/build, evidence paths, observations, score rationale, defects and confidence. A4 requires all documented targets plus independent evidence. A5 requires a demonstrated matched-reference advantage, not a personal impression.

Gate B requires actual solo/four-client Warden tests before combat/world rollout. Gate C requires imported hero/environment captures, animation/collision/navigation/device comparisons. Gate E adds live services, independent studies and30min soak. Engine gates remain open even when code checks pass.

## Defect backlog at this checkpoint

| Priority | Defect / unfinished scope | Next resolution |
|---|---|---|
| P0 gate | No owned/published/engine-validated assets | Studio import and owner-backed animation/audio publication |
| P0 gate | No signature runtime execution evidence | Solo/four-client supported Studio host |
| P0 gate | Prediction uses rejection/sequence events and a timeout; latency correctness unverified | Add client cooldown/window simulation and test explicit rejection under latency |
| P1 | Diagnostic UI exceeds small portrait screens; remapping/production inventory missing | Responsive layouts and device study |
| P1 | Several authored states not wired: strafes/landing/guard/parry, lean/feet | Animator/controller integration and captures |
| P1 | Death/disconnect/party/results recovery incomplete | Explicit retry/rejoin/results flow tests |
| P1 | Audio IDs absent; loops/mix/surface/ambience unfinished | Owned imports, sound review and transitions |
| P1 | Effects lack authored cracks/dust/material distinctions | Asset pass after nonobscuring combat capture |
| P1 | Draft source rigs/FBX not tested in importer | Joint axes/scale/segmentation/skin-weight validation |
| P1 | Attack root plausibility checks are preliminary | Engine abuse/latency tests; complete movement authority |
| P1 | Live profile/reward durability unverified | Private-universe fault tests |

Do not close defects solely because their source compiles.
