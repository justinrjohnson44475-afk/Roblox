# Riftwake asset provenance

World geometry is original Luau-authored anchored primitive architecture in src/server/World.luau, baked by scripts/bake-world.luau into world.rbxmx. Rigs and constructs are original primitive models in Appearance.luau. No copied competitor meshes, anime characters, marketplace scripts or downloaded game assets are included. Roblox built-in fonts/materials and a built-in feedback sound path are used; audio/device behavior remains unverified.

Previews are Blender renders exported from these builders, with original lighting/composition. They are not engine captures, gameplay videos, playtests or evidence that the UI works. The avatar is a neutral mannequin representing rig attachment, not a promised replacement for players’ actual Roblox avatars. World preview includes runtime-style wardens for scale; those enemies are created by server code during Play. The baked static map has 686 anchored parts; active enemy/rig/effect counts add runtime cost, which must be profiled.

Optional regeneration: after the bake, run `blender -b -t 4 --python scripts/render-preview.py -- world`, `-- verdant` or `-- forms`. Blender is optional and not needed to build/open the game. The current cloud build lacks OpenImageDenoise, so renders use ordinary samples without denoising. Generated .blend working files live in ignored build/.

Production art still needs cohesive animation, material/detail passes, custom sound/music, VFX tuning, device testing, genuine Studio screenshots and reviewed icon/thumbnail art. Do not present these previsualizations as real gameplay advertisements. Record creator, source, commercial rights, attribution, moderation ID and approval date for any future external asset.
