# Harborlight — Restore Together

Status: first vertical slice specification, with expansion plans separated below. Alternatives: Tidemend Harbor; Lantern Quay. Names are not trademark-cleared.

Cooperative collection/restoration adventure for players seeking calm mastery and shared progress. Initial audience hypothesis: teens and adults who enjoy cozy collection; broader access depends on Roblox’s actual content classification. Fantasy: become part of the crew bringing a storm-worn harbor back to life. Warm timber, deep blue water, sea-glass green and amber lanterns create a recognizable silhouette. Original primitive geometry is a placeholder art direction, not final production art.

## Core loop
Explore a compact quay → recover supply crates with a short hold interaction → carry up to five supplies → contribute at the current repair site → see the shared project restored → earn personal tokens for contribution → select an earned lantern color → begin the next project. After all three projects, celebrate briefly and start a new four-minute shift. All contributors receive the same tokens per unit of work; participation does not require arriving first or winning a vote. A shift timeout resets shared construction, not personal tokens or completed-work counters. Disconnect loses unsaved carried supplies; carried supplies are deliberately ephemeral.

Three projects: mend the pier (8 units), restore the greenhouse (12), relight the beacon (16). World presentation must visibly distinguish unfinished and completed work. Supply crates replenish after eight seconds. Shared depletion can create competition: use sufficient crates, inspect contention in multiplayer and move toward personal pickup availability if necessary. No ships, animal rescue AI, procedural islands, combat or trading in this slice.

## Rewards and economy
One donated supply yields two tokens immediately. Three noncompetitive color choices: amber free, sea-glass 30, violet 60. No random rewards, streaks, currency purchase or scarcity countdown. Earned cosmetics are reusable and permanent. Each repair increments a personal participation milestone for players who contributed. Repeated shifts intentionally test the loop before deeper progression is developed.

## UI and accessibility
Use native movement/camera and ProximityPrompts for keyboard, touch and gamepad interaction. HUD displays carried amount, token balance, current repair need and time left. A help/settings menu explains controls; a reduced-effects toggle and local audio mute are provided. Do not rely solely on color: signs, text and geometry identify all stations. Shop buttons use touch-sized targets and scrolling. Show state loading and persistence errors explicitly. No menu opens a purchase prompt automatically.

## Feature decisions against adjacent games
Compared with opaque collection requirements, exact supply needs stay visible. Compared with theft economies, personal tokens cannot be taken. Compared with long survival runs, a bounded shift allows leaving without a streak penalty. Compared with voting competition, recognition follows contribution. These are design improvements for our target hypothesis, not claims that all competitor players prefer them.

## Expansion only after evidence
Authored route variants, personal cabin decoration, noncompetitive crew expeditions, accessibility polish, NPC stories and cosmetic packs. Do not combine unrelated pet hatching, rebirth, combat or paid luck systems. Each update must strengthen restoration and shared ownership.

## MVP acceptance
A solo player can complete all three projects and replay; multiple players can contribute without duplicate or negative rewards; leaving/rejoining retains tokens and cosmetics when storage is available; unknown or distant interactions grant nothing; Christian reading remains voluntary and unrewarded; the place builds from Git. Runtime and visual acceptance require Studio and remain unverified until recorded.
