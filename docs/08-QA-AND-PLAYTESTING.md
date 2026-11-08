# QA and playtesting plan

## Verified cloud coverage
Run `bash scripts/check.sh`. Lune covers profile normalization, economy conservation, repeat purchase protection, participant deduplication, full loop/replay, malformed cosmetic requests, rate limits, mocked storage lock/outage/schema behavior, Luau compilation and generated-world structure. Python tests cover publisher target/hash/secret guards, dry-run behavior, operation validation and truthful success handling. Rojo builds binary/XML places; Lune deserializes both to check expected services, scripts, floor and spawn. StyLua checks formatting. These are not Roblox engine tests, full Luau type analysis, visual tests, live DataStore tests or Marketplace tests.

## Required engine and integration matrix (all pending)
| Area | Procedure | Acceptance |
|---|---|---|
| Core loop | Solo recover/deposit all three projects; run timer expiry and replay | Correct active station, visible completion, repeatable shifts |
| Concurrency | Two clients deposit final units almost simultaneously | No overfill, duplicate completion, double reward or negative carried values |
| Authority | Trigger pickup/deposit from far away, dead character, inactive station and during cooldown | No unauthorized reward; no server error |
| Remotes | Send unknown action/item, tables, huge strings, repeated requests and fake ownership flags | Requests ignored/rejected with bounded work |
| Movement abuse | Teleport/speed exploit in authorized test environment | Identify production hardening needs; distance checks alone are insufficient |
| Capacity | Fill five, try sixth; deposit with excess remaining; die/respawn | Cap respected, leftovers retained, respawn carry cleared |
| Progression | Buy exact-cost color, re-equip, insufficient funds, rapid double request | Single debit, persistent ownership, no negative balance |
| Save load | Earn, leave, rejoin; delayed/outage/invalid/future data | Retain valid progress, refuse unsafe defaults, show failures |
| Save close | Concurrent autosave/leave/shutdown, budget exhaustion and lock takeover | No older-session overwrite; record any unsaved loss and recovery |
| Purchase | Disabled ID; private test pass cancel, success, failure and existing owner | No charge or grant when disabled; native price and verified cosmetic entitlement |
| Replication | Join mid-shift, leave mid-repair, reconnect and change lantern | Consistent shared state; personal data sent only to its owner |
| Mobile | Small portrait, landscape, safe areas and keyboard overlap | Readable HUD, touch targets, scrollable menus, reachable native prompts |
| Gamepad | Select guide, shop, close, world prompts and native purchase cancel | Navigation without mouse |
| Accessibility | Muted sound, reduced effects, grayscale, low vision and text comprehension | All objectives readable without sound or color alone |
| Performance | Profile low-end phone and multi-client test; measure server frame time, memory, bandwidth | Set budgets from measurements; no invented FPS results |
| Optional faith content | Ignore garden for full loop; deliberately read, close and compare rewards | No automatic opening, force, tracking, declaration or economy difference |
| Policy | Review full text, classification, ads, assets and store | Owner completes actual questionnaire and resolves uncertainties |

Record results in QA-RESULTS.md with commit/hash, device, Studio version, account/universe scope, steps, expected/actual result and evidence path. Keep credentials and player PII out of reports. Mark tests blocked/pending honestly. No real player feedback exists yet.

## Structured actual-player study
Recruit 12–20 willing participants through age-appropriate, platform-compliant channels. Do not solicit private contact details from minors or invent feedback. Observe five minutes without coaching, then one full session; invite voluntary later returns. Record anonymous aggregate observations and sample sizes. Explain voluntary participation and avoid religious profiling. Obtain appropriate guardian/research consent where applicable.

Ask: What did you think the first goal was? Which moment was enjoyable or frustrating? Did collecting and contributing feel useful? Was progression fair? Would you choose to return and why? Would you recommend it? What would a cosmetic need to offer to feel worth buying? If you encountered the garden, was the Christian label clear and was ignoring/closing it easy? Do not ask anyone to disclose beliefs.

Stop/go: fix blockers and destructive save issues first. If fewer than 80% understand contributing without coaching, redesign onboarding before acquisition spend. If experienced players describe collection as chores, prototype a more active recovery interaction before new art. Return intent does not establish D1/D7 retention; wait for real cohort behavior. Include nonreturners when interpreting feedback.
