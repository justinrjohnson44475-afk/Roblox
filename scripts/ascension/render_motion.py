"""Blender pose review only. Does not capture Roblox or establish gameplay quality."""
import bpy,math
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(root/'assets/ascension/source/Ascension.blend'))
scene=bpy.context.scene
for obj in scene.objects:
 if obj.name.startswith('Warden_') or obj.name=='VerdantWarden_R15':obj.hide_render=True
arm=bpy.data.objects['Ascension_R15']
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=False
scene.render.resolution_x=720;scene.render.resolution_y=720;scene.render.resolution_percentage=100
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.045,.065,.085,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
for pos,power in [((4,7,9),1400),((-4,-2,7),1800)]:
 bpy.ops.object.light_add(type='AREA',location=pos);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.size=6
 lamp.rotation_euler=(Vector((0,0,3))-lamp.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(10,9,5));camera=bpy.context.object
camera.rotation_euler=(Vector((0,0,3))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=11;scene.camera=camera
for name,t in [('Land',.12),('HeavyLand',.38),('DoubleJump',.36),('Light1',.11),('HeavyCharge',.35)]:
 arm.animation_data.action=bpy.data.actions[name];scene.frame_set(int(1+t*60),subframe=(1+t*60)%1)
 scene.render.filepath=str(root/f'assets/ascension/previews/Motion-{name}.png');bpy.ops.render.render(write_still=True)
print('Rendered five source poses. Not Roblox captures or a verified animation demonstration.')

# Separate original Warden source pose inspection, never an engine capture.
ward=bpy.data.objects['VerdantWarden_R15'];ward.location.x=0;ward.animation_data_create()
for obj in scene.objects:
 if obj.type=='MESH':obj.hide_render=obj.parent!=ward
camera.location=(13,16,9);camera.rotation_euler=(Vector((0,0,5.5))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=16
for name,t in [('WardenWalk',.22),('WardenSlam',1.57),('WardenRoar',.35)]:
 ward.animation_data.action=bpy.data.actions[name];scene.frame_set(int(1+t*60),subframe=(1+t*60)%1)
 scene.render.filepath=str(root/f'assets/ascension/previews/Motion-{name}.png');bpy.ops.render.render(write_still=True)
