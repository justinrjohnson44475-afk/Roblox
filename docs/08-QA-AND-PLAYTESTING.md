# Riftwake QA and actual-player validation

Cloud checks cover domain arithmetic, state transitions, malformed input, recent-contributor reward eligibility, first-clear deduplication, progression gates, build tradeoffs, deterministic forging, rig-form geometry, profile migration, mocked save faults/leases, syntax compilation and baked place structure. Python tests cover the publisher’s no-network dry run, authorization and truthful success handling. These do not establish enjoyable or correct Roblox engine execution.

## Mandatory engine tests — all pending
| Area | Test | Acceptance |
|---|---|---|
| First action | Spawn without coaching, identify Verdant gate, strike an enemy | Objective and attack understandable |
| Charge break | Watch windup, use Coreburst, check exposed state | Visible warning, interrupted impact, meaningful reward for timing |
| Skill vs spam | Compare standing attack spam with dodging/breaking at same stats | Deliberate play clearly helps; avoid stat-only damage races |
| Combo and aim | Three strikes, pause reset, cone edge, vertical mismatch | Readable reach and combo; no remote-reported hit acceptance |
| Dash | Hit frame before/during/after window; dash toward wall/edge | Bounded invulnerability, no wall clipping or stuck state |
| Boss patterns | Verdant slam/lance, Cinder echo, Crownless phase-two zones | Distinct readable patterns; no invisible impacts |
| Abandoned fight | All players die/leave range for eight seconds | Encounter heals/resets; no death-chipping progression exploit |
| Co-op | Two clients damage/finish same enemy; late join and respawn | Eligible contributors paid once; no last-hit theft |
| Authority | Wrong-region action, teleport, forged damage/aim, dead player, remote forge use | No unauthorized power/reward; no unbounded work |
| Gates | Bypass physical portal, insufficient level, missing clear, valid unlock | Server enforces both gate conditions |
| Upgrades | Exact price, insufficient balance, double request, capped rank | Correct permanent effect and one debit |
| Evolution | Each form with correct/missing cores/level/clear | Earned silhouette change; deterministic costs |
| Paths | Switch Vanguard/Strider/Arcanist at forge, try remotely/in combat | Free allowed switch; actual stat/ability tradeoffs; no remote heal exploit |
| Save migration | Existing schema 1, current schema 2, corrupt/future schema, rapid rejoin | Preserve valid data and refuse unsafe overwrite |
| Save failure | Budget exhaustion, autosave+leave+shutdown, lease takeover | No stale-session overwrite; warning and documented loss/recovery |
| Controls | Keyboard/mouse, controller selection, touch + native thumbstick | All four actions and menus reachable without input conflicts |
| Device layout | Small portrait/landscape, notches, controller, safe-area UI | Health/Focus/XP, boss warning and buttons readable/reachable |
| Performance | Server/network profiling with all regions populated | Establish measured budgets; no invented FPS claim |
| Accessibility | Sound off, effects reduced, color differentiation | Text/shape/state makes objectives and danger legible |
| Faith optionality | Ignore reading for all progression; read then close | Zero rewards/tracking/declarations; cannot force another player's panel |
| Purchases | Disabled pass; authorized private ownership/cancel/failure tests later | No paid power; native price; server entitlement only |
| Publication | Rights, classification, verified build and scoped target | Owner authorization and actual completed operation, not build success |

## Player study
Observe 12–20 voluntary participants using appropriate consent/privacy practices and platform-safe channels. Record aggregate observations, device, build hash and whether players understand combat/next upgrades without coaching. Never solicit personal beliefs or private contact details from minors. No actual responses exist yet.

Ask: Which action felt satisfying? Why did you take damage? Did you notice a charge-break opportunity? What changed when you upgraded/evolved? Which build did you prefer and why? Did the next destination feel worth reaching? When did combat become repetitive? Would you voluntarily return? What would a cosmetic need to offer to feel worthwhile? If encountered, was the sanctuary content clearly optional and easy to ignore/close?

Decision gates: fix authority/save blockers first. Redesign if standing attack spam wins as reliably as reading patterns, players cannot explain Focus, the first evolution is not visually noticeable, or extra stats never change decisions. Record actual D1/D7/D30 cohorts; stated return intent is not retention. Do not produce a huge content catalogue before proving the combat loop.
