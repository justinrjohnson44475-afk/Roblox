"""Blender previsualization of the exact Luau-built geometry, not a Roblox engine capture.
Run: blender -b -t 4 --python scripts/render-preview.py -- world
Modes: world, verdant, forms.
"""
import bpy
import json
import math
import sys
from pathlib import Path
from mathutils import Matrix, Vector

mode = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else 'world'
root = Path(__file__).resolve().parents[1]
geometry = json.loads((root / 'build' / ('rig-geometry.json' if mode == 'forms' else 'world-geometry.json')).read_text())
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 48
scene.cycles.use_denoising = False
scene.render.resolution_x = 1500
scene.render.resolution_y = 950 if mode != 'forms' else 720
scene.render.resolution_percentage = 100
scene.world.color = (0.12, 0.16, 0.24)
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.14, 0.22, 0.35, 1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.35
scene.view_settings.view_transform = 'AgX'
materials = {}
q = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))

def material(item):
    color = tuple(round(x, 3) for x in item['color'])
    key = (color, item['material'], round(item['alpha'], 2))
    if key in materials:
        return materials[key]
    mat = bpy.data.materials.new(item['material'] + str(color))
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    linear = tuple(x ** 2.2 for x in color)
    shader.inputs['Base Color'].default_value = (*linear, 1)
    shader.inputs['Roughness'].default_value = 0.72 if item['material'] != 'Metal' else 0.38
    shader.inputs['Metallic'].default_value = 0.55 if item['material'] == 'Metal' else 0.08
    if item['material'] == 'Neon':
        shader.inputs['Emission Color'].default_value = (*linear, 1)
        shader.inputs['Emission Strength'].default_value = 1.5
    if item['alpha'] < 0.9:
        shader.inputs['Alpha'].default_value = item['alpha']
        shader.inputs['Transmission Weight'].default_value = 0.2
    materials[key] = mat
    return mat

for item in geometry:
    s = item['size']
    cf = item['cf']
    mat_cf = Matrix(((cf[3], cf[4], cf[5], cf[0]), (cf[6], cf[7], cf[8], cf[1]), (cf[9], cf[10], cf[11], cf[2]), (0, 0, 0, 1)))
    if item['shape'] == 'Cylinder':
        bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=1, depth=2)
        scale = Matrix.Diagonal((s[2] / 2, s[1] / 2, s[0] / 2, 1))
        local = Matrix.Rotation(math.pi / 2, 4, 'Y') @ scale
    elif item['shape'] == 'Ball':
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1)
        local = Matrix.Diagonal((s[0] / 2, s[1] / 2, s[2] / 2, 1))
    else:
        bpy.ops.mesh.primitive_cube_add(size=1)
        local = Matrix.Diagonal((*s, 1))
    obj = bpy.context.object
    obj.name = item['name']
    obj.matrix_world = q @ mat_cf @ local
    obj.data.materials.append(material(item))
    if item['shape'] == 'Block' and max(s) < 25:
        bevel = obj.modifiers.new('Edge light', 'BEVEL')
        bevel.width = 0.035 if mode == 'forms' else 0.08
        bevel.segments = 1
        obj.modifiers.new('Weighted normals', 'WEIGHTED_NORMAL')


def light(name, location, energy, color, size):
    data = bpy.data.lights.new(name, 'AREA')
    data.energy = energy
    data.color = color
    data.shape = 'DISK'
    data.size = size
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector((0, 20, 0)) - obj.location).to_track_quat('-Z', 'Y').to_euler()

sun_data = bpy.data.lights.new('Dawn sun', 'SUN')
sun_data.energy = 3
sun_data.angle = 0.1
sun_data.color = (1, 0.83, 0.64)
sun = bpy.data.objects.new('Dawn sun', sun_data)
scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(28), math.radians(-22), math.radians(-30))
light('Soft sky', (0, -20, 180), 16000, (0.4, 0.68, 1), 200)

if mode == 'forms':
    bpy.ops.mesh.primitive_plane_add(size=200)
    floor = bpy.context.object
    floor.location.z = -0.08
    floor.data.materials.append(material({'color': [0.06, 0.09, 0.14], 'material': 'Slate', 'alpha': 1}))
    camera_location = (0, 35, 10)
    target = (0, 0, 2.4)
    lens = 40
    light('Rig softbox', (0, -7, 12), 1600, (0.62, 0.85, 1), 12)
    for i, title in enumerate(['FRACTURED', 'AWAKENED', 'ASCENDANT', 'STORMFORGED']):
        text = bpy.data.curves.new(title, 'FONT')
        text.body = title
        text.align_x = 'CENTER'
        text.size = 0.38
        obj = bpy.data.objects.new(title, text)
        scene.collection.objects.link(obj)
        obj.location = ((i - 1.5) * 6, 1.7, 0.04)
        obj.rotation_euler = (0, 0, math.pi)
        text.materials.append(material({'color': [0.8, 0.88, 0.95], 'material': 'Neon', 'alpha': 1}))
elif mode == 'verdant':
    # Coordinates here are Blender coordinates after X,-Z,Y conversion.
    camera_location = (-153, -24, 18)
    target = (-165, 44, 15)
    lens = 28
    light('Verdant fill', (-160, 40, 90), 18000, (0.6, 0.9, 0.8), 90)
else:
    camera_location = (280, -345, 300)
    target = (0, 70, 0)
    lens = 38

cam_data = bpy.data.cameras.new('Authored geometry camera')
cam = bpy.data.objects.new('Authored geometry camera', cam_data)
scene.collection.objects.link(cam)
cam.location = camera_location
cam.rotation_euler = (Vector(target) - cam.location).to_track_quat('-Z', 'Y').to_euler()
cam_data.lens = lens
cam_data.clip_end = 2000
scene.camera = cam
scene.use_nodes = True
nodes = scene.node_tree.nodes
nodes.clear()
render = nodes.new('CompositorNodeRLayers')
glare = nodes.new('CompositorNodeGlare')
glare.glare_type = 'FOG_GLOW'
glare.quality = 'MEDIUM'
glare.threshold = 1.4
out = nodes.new('CompositorNodeComposite')
scene.node_tree.links.new(render.outputs['Image'], glare.inputs['Image'])
scene.node_tree.links.new(glare.outputs['Image'], out.inputs['Image'])
path = root / 'assets' / 'previews' / ('riftwake-' + mode + '.png')
path.parent.mkdir(parents=True, exist_ok=True)
scene.render.filepath = str(path)
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'build' / ('preview-' + mode + '.blend')))
bpy.ops.render.render(write_still=True)
print('PREVIS_ONLY', path)
