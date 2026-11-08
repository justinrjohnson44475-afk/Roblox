# Riftwake world-design bible

The world is an interrupted relic network overtaken by living environments. Every landmark should answer where the player can go next, what changed here, and which threat/upgrade awaits. Narrative is delivered in short environmental beats that do not require cutscenes or reading to progress. Faith reading remains a separate optional sanctuary experience, without story/encounter rewards or tracking.

| Region / retained identity | Shape/material/light | Threat/route language | Planned reveal |
|---|---|---|---|
| Dawn Sanctuary | Open horizon, pale stone, bronze forge, calm teal accents | Safe shared arrival/forge/party space; no combat-state pressure | Broken relic channels point toward Verdant |
| Verdant Reach |480×480 grove ruins, layered greens, warm ivory masonry, mint core | Overlook → short initial skirmish → intertwined courtyard/ridge → side root vault → return shortcut → Warden sanctuary | Overgrowth bends toward the chest-core; fractured murals imply a former guardian |
| Ember Scar | Soot stone, broken kiln silhouettes, ember fissures with cool route edges | Committed impacts and safe lanes; vertical slag bridges and optional foundry | Repeating forge marks link current upgrades to the ruins |
| Astral Crown | Sparse pale platforms, dark sky silhouettes, restrained violet/cyan | Aim/position patterns and ring traversal, clear fall boundaries | Relic network culmination; earned mastery, no religious progression reward |

## Verdant route plan (not yet constructed)

Overlook(0,0,210) frames Warden landmark(0,0,-150). Entry threat(~0,0,100) within15s. Grove loop turns west toward(-130,0,30), rises to ridge(-100,24,-50), then crosses ruins(20,12,-60). Optional vault(140,0,20) rejoins via shortcut(60,0,100). Boss threshold(0,0,-100) leads to sanctuary. These are provisional local coordinates and must be tested for traversable path length, interaction gaps, camera composition, collision and accessibility before approval. Do not fill long transitions with empty walking or repeat identical enemies as content padding.

Kit grammar:4/8/16-stud stone spans, modular arch halves, fractured capitals, root bridges, foliage sizes3/6/12, controlled bronze inset accents, dedicated low-complexity collision volumes. Combat floors remain readable; effects never modify structural collision. Stream boundaries use turns/arches and retain encounter ownership server-side. Future terrain/LOD/atlas work requires hardware profiles.

Current deliverable: separate compact signature arena only. Flagship/Ember/Astral construction is deferred until the signature Studio gate, per the dependency order.

## Owner-requested terrain/material diversity

Retain the liked slate ground in the signature encounter. Future Verdant production includes dense jungle pockets with actual hanging vine geometry, tree canopies, root bridges and muddy/shallow-water transitions. Ember's outskirts include wind-shaped sand dunes and dry channels before scorched foundry rock, preserving its progression ID. Astral's lower approach uses abandoned urban streets, layered concrete/masonry facades and metal structures before the crown ruins. These are planned biome transitions, not new progression IDs or completed maps.

The signature arena now has small edge material studies (sand, jungle trees/vine, urban wall-run facades) for visual/traversal feedback. They do not replace the gated flagship region or imply the large biomes are built.
