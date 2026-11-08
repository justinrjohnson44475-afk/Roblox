"""Original Ascension character, blade, Warden and choreographed source clips.
Run with Blender -b -t 4 --python scripts/ascension/author_assets.py.
Exports are source assets, not proof of Roblox import, animation ownership or playtesting.
"""
import bpy, json, math, random, sys
from pathlib import Path
from mathutils import Matrix, Vector, Euler
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/ascension'
for d in ['source','exports','animations','previews']: (OUT/d).mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene; scene.render.fps=60
materials={}
for name,color,metal,rough,glow in [
 ('Midnight',(0.025,0.055,0.085),.15,.65,0),('Ivory',(.62,.66,.59),.6,.32,0),
 ('Bronze',(.42,.23,.075),.75,.3,0),('Leather',(.065,.045,.035),.05,.85,0),
 ('Skin',(.34,.18,.10),0,.6,0),('Hair',(.025,.018,.014),0,.7,0),
 ('Relic',(.02,.7,.52),.5,.3,1.5),('Obsidian',(.035,.055,.065),.4,.5,0),
 ('Moss',(.085,.2,.13),.05,.9,0)]:
 m=bpy.data.materials.new(name);m.use_nodes=True;s=m.node_tree.nodes.get('Principled BSDF')
 s.inputs['Base Color'].default_value=(*color,1);s.inputs['Metallic'].default_value=metal;s.inputs['Roughness'].default_value=rough
 if glow:s.inputs['Emission Color'].default_value=(*color,1);s.inputs['Emission Strength'].default_value=glow
 materials[name]=m
# Original R15-named skeleton. Positions are Blender units; +Y is forward, +Z up.
bones={
 'HumanoidRootPart':(None,(0,0,2.9),(0,0,3.2)),
 'LowerTorso':('HumanoidRootPart',(0,0,2.65),(0,0,3.15)),
 'UpperTorso':('LowerTorso',(0,0,3.15),(0,0,4.25)),
 'Head':('UpperTorso',(0,0,4.3),(0,0,5.55)),
 'RightUpperArm':('UpperTorso',(1.05,0,4.05),(1.25,0,3.25)),
 'RightLowerArm':('RightUpperArm',(1.25,0,3.25),(1.25,.02,2.55)),
 'RightHand':('RightLowerArm',(1.25,.02,2.55),(1.25,.12,2.25)),
 'LeftUpperArm':('UpperTorso',(-1.05,0,4.05),(-1.25,0,3.25)),
 'LeftLowerArm':('LeftUpperArm',(-1.25,0,3.25),(-1.25,.02,2.55)),
 'LeftHand':('LeftLowerArm',(-1.25,.02,2.55),(-1.25,.12,2.25)),
 'RightUpperLeg':('LowerTorso',(.48,0,2.65),(.5,0,1.55)),
 'RightLowerLeg':('RightUpperLeg',(.5,0,1.55),(.5,0,.48)),
 'RightFoot':('RightLowerLeg',(.5,0,.48),(.5,.55,.18)),
 'LeftUpperLeg':('LowerTorso',(-.48,0,2.65),(-.5,0,1.55)),
 'LeftLowerLeg':('LeftUpperLeg',(-.5,0,1.55),(-.5,0,.48)),
 'LeftFoot':('LeftLowerLeg',(-.5,0,.48),(-.5,.55,.18)),
}
arm_data=bpy.data.armatures.new('Ascension_R15');arm=bpy.data.objects.new('Ascension_R15',arm_data);scene.collection.objects.link(arm)
bpy.context.view_layer.objects.active=arm;arm.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
for name,(parent,head,tail) in bones.items():
 b=arm_data.edit_bones.new(name);b.head=head;b.tail=tail
 if parent:b.parent=arm_data.edit_bones[parent]
bpy.ops.object.mode_set(mode='OBJECT')
hero=[]; blade=[]; warden=[]
def finish(obj,name,mat,bone=None,group=None):
 obj.name=name;obj.data.materials.append(materials[mat])
 if bone:
  vg=obj.vertex_groups.new(name=bone);vg.add(range(len(obj.data.vertices)),1,'REPLACE')
  modifier=obj.modifiers.new('R15 skin','ARMATURE');modifier.object=arm;obj.parent=arm
 if group is not None:group.append(obj)
 return obj

def ellipsoid(name,pos,scale,mat,bone=None,group=None,segments=12):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=8,location=pos);obj=bpy.context.object
 obj.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return finish(obj,name,mat,bone,group)

def plate(name,pos,scale,mat,bone=None,group=None,rotation=(0,0,0)):
 bpy.ops.mesh.primitive_cube_add(size=1,location=pos,rotation=rotation);obj=bpy.context.object;obj.scale=scale
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bevel=obj.modifiers.new('Forged bevel','BEVEL');bevel.width=.07;bevel.segments=2;bpy.ops.object.modifier_apply(modifier=bevel.name)
 return finish(obj,name,mat,bone,group)

def taper(name,a,b,r1,r2,mat,bone=None,group=None,vertices=8):
 delta=Vector(b)-Vector(a);bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=r1,radius2=r2,depth=delta.length,location=(Vector(a)+Vector(b))/2)
 obj=bpy.context.object;obj.rotation_euler=delta.to_track_quat('Z','Y').to_euler()
 return finish(obj,name,mat,bone,group)
# Anatomical volumes, overlapping armor plates and a deliberately asymmetrical gauntlet.
ellipsoid('Waist',(0,0,2.95),(.69,.35,.45),'Midnight','LowerTorso',hero)
ellipsoid('Cuirass',(0,0,3.7),(.91,.4,.77),'Midnight','UpperTorso',hero)
plate('Breastplate',(0,.34,3.82),(1.35,.24,.8),'Ivory','UpperTorso',hero,rotation=(.08,0,0))
plate('Breastplate_inset',(0,.49,3.83),(.24,.1,.46),'Relic','UpperTorso',hero,rotation=(0,.1,.65))
for side,prefix in [(1,'Right'),(-1,'Left')]:
 taper(prefix+'_arm', (side*1.05,0,4.05),(side*1.25,0,3.25),.29,.34,'Midnight',prefix+'UpperArm',hero)
 taper(prefix+'_sleeve',(side*1.25,0,3.25),(side*1.25,.02,2.55),.23,.3,'Leather',prefix+'LowerArm',hero)
 ellipsoid(prefix+'_glove',(side*1.25,.08,2.42),(.25,.25,.3),'Leather',prefix+'Hand',hero)
 ellipsoid(prefix+'_pauldron',(side*.99,-.02,4.08),(.49,.46,.37),'Ivory',prefix+'UpperArm',hero)
 taper(prefix+'_thigh',(side*.48,0,2.65),(side*.5,0,1.55),.3,.38,'Midnight',prefix+'UpperLeg',hero)
 taper(prefix+'_greave',(side*.5,0,1.55),(side*.5,0,.48),.24,.32,'Ivory',prefix+'LowerLeg',hero)
 plate(prefix+'_knee',(side*.5,.27,1.6),(.45,.2,.48),'Bronze',prefix+'LowerLeg',hero)
 ellipsoid(prefix+'_boot',(side*.5,.18,.3),(.29,.49,.28),'Leather',prefix+'Foot',hero)
for i in range(4):
 plate('Belt_plate_'+str(i),((i-1.5)*.34,.35,2.95),(.31,.16,.25),'Bronze','LowerTorso',hero)
ellipsoid('Face',(0,.02,4.95),(.46,.4,.62),'Skin','Head',hero,16)
ellipsoid('Hair_mass',(0,-.04,5.34),(.51,.43,.37),'Hair','Head',hero)
for i in range(7):
 x=(i-3)*.135
 taper('Hair_lock_'+str(i),(x,.28,5.45),(x+.12,.39,5.08+.07*math.sin(i)),.1,.025,'Hair','Head',hero,5)
for side in [-1,1]:
 plate('Eye', (side*.18,.393,5.02),(.14,.035,.055),'Relic','Head',hero)
 plate('Brow',(side*.18,.4,5.12),(.21,.055,.055),'Hair','Head',hero,rotation=(0,side*.1,side*-.15))
plate('Nose',(0,.42,4.94),(.1,.11,.17),'Skin','Head',hero)
plate('Gauntlet',(-1.25,.08,2.65),(.68,.75,.65),'Obsidian','LeftHand',hero)
plate('Gauntlet_core',(-1.25,.49,2.65),(.26,.08,.28),'Relic','LeftHand',hero,rotation=(0,0,.7))
for i in [-1,0,1]:
 plate('Gauntlet_finger',(-1.25+i*.18,.54,2.4),(.13,.3,.18),'Ivory','LeftHand',hero)
# Original broad tapered relic blade, with a non-rectangular forged silhouette.
hand=Vector((1.25,.1,2.42))
profile=[(-.13,0),(-.28,.5),(-.24,2.65),(-.12,3.7),(0,4.1),(.31,3.5),(.34,1.0),(.15,.4)]
verts=[]
for z in [-.065,.065]:
 for x,y in profile:verts.append(tuple(hand+Vector((x,y,z))))
n=len(profile);faces=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
mesh=bpy.data.meshes.new('RelicBlade_geometry');mesh.from_pydata(verts,[],faces);mesh.update();obj=bpy.data.objects.new('RelicBlade',mesh);scene.collection.objects.link(obj)
finish(obj,'RelicBlade','Ivory','RightHand',blade)
plate('Blade_guard',hand+Vector((0,.1,0)),(1.1,.22,.18),'Bronze','RightHand',blade)
plate('Blade_energy',hand+Vector((.1,1.8,.08)),(.07,2.7,.035),'Relic','RightHand',blade)
# Anatomical stone Warden: articulated R15 counterpart, not a scaled default box NPC.
# Shares the source skeleton at import; segmented shell can be retargeted after its engine gate.
for bone,(_,head,tail) in bones.items():
 if bone=='HumanoidRootPart':continue
 mid=(Vector(head)+Vector(tail))/2
 scale=1.7
 pos=Vector((mid.x*scale,mid.y*scale,mid.z*scale))
 if bone in ['UpperTorso','LowerTorso']:shape=(1.5,.75,1.2)
 elif bone=='Head':shape=(.72,.65,.8)
 else:shape=(.45,.5,max(.4,(Vector(tail)-Vector(head)).length*.8))
 ellipsoid('Warden_'+bone,pos,shape,'Obsidian',None,warden)
for side in [-1,1]:
 taper('Warden_horn',(side*.65,0,9),(side*1.15,-.1,10.4),.35,.03,'Ivory',None,warden,7)
 ellipsoid('Warden_shoulder',(side*1.8,0,7.0),(.9,.85,.7),'Ivory',None,warden)
 for i in range(3):taper('Warden_branch',(side*(1.5+i*.25),-.3,7.2),(side*(2+i*.4),-.25,8+i*.2),.18,.025,'Moss',None,warden,6)
ellipsoid('Warden_core',(0,1.1,6.2),(.55,.25,.7),'Relic',None,warden)
# Bind Warden segments to an independent scaled R15 armature with the same joint names.
ward_arm=arm.copy();ward_arm.data=arm.data.copy();ward_arm.name='VerdantWarden_R15';scene.collection.objects.link(ward_arm);ward_arm.scale=(1.7,1.7,1.7)
bpy.context.view_layer.update()
for obj in warden:
 key=obj.name.removeprefix('Warden_').split('.')[0]
 bone=key if key in bones else 'Head' if 'horn' in key else 'UpperTorso'
 vg=obj.vertex_groups.new(name=bone);vg.add(range(len(obj.data.vertices)),1,'REPLACE');m=obj.modifiers.new('Warden skin','ARMATURE');m.object=ward_arm;obj.parent=ward_arm;obj.matrix_parent_inverse=ward_arm.matrix_world.inverted()
# Poses are authored in world-aligned joint axes, then projected into each bone rest basis.
def pose(**joints):return joints
idle={'LowerTorso':(0,0,0),'UpperTorso':(.04,0,0),'Head':(-.02,0,0),'RightUpperArm':(.2,.05,-.12),'LeftUpperArm':(.15,-.05,.12)}
ready={**idle,'UpperTorso':(.14,0,-.18),'RightUpperArm':(.65,-.1,-.25),'RightLowerArm':(.5,0,0),'LeftUpperArm':(.6,0,.3),'LeftLowerArm':(.7,0,0),'RightUpperLeg':(.12,0,0),'LeftUpperLeg':(-.12,0,0)}
def strike(kind):
 direction= -1 if kind==2 else 1
 wind={**ready,'LowerTorso':(0,0,-.3*direction),'UpperTorso':(.05,0,-.45*direction),'RightUpperArm':(1.15,.15,-.75*direction),'RightLowerArm':(.35,0,.2)}
 contact={**ready,'LowerTorso':(.1,0,.25*direction),'UpperTorso':(.22,0,.5*direction),'RightUpperArm':(1.4,0,.65*direction),'RightLowerArm':(.12,0,0),'LeftUpperArm':(.35,0,-.45*direction)}
 follow={**contact,'UpperTorso':(.18,0,.7*direction),'RightUpperArm':(.85,0,.95*direction)}
 if kind==3:
  wind={**ready,'RightUpperArm':(.25,0,-.5),'RightLowerArm':(.8,0,0),'UpperTorso':(.25,0,-.45)}
  contact={**ready,'RightUpperArm':(1.9,0,.45),'RightLowerArm':(.15,0,0),'UpperTorso':(-.15,0,.5)}
  follow={**contact,'RightUpperArm':(2.2,0,.7)}
 return wind,contact,follow
clips={}
def clip(name,duration,keys,markers=None,loop=False,priority='Action'):
 clips[name]={'duration':duration,'keys':keys,'markers':markers or {},'loop':loop,'priority':priority}
clip('Idle',2,[(0,idle),(1,{**idle,'UpperTorso':(.065,0,0),'Head':(-.03,0,.015)}),(2,idle)],loop=True,priority='Idle')
clip('CombatIdle',1.4,[(0,ready),(.7,{**ready,'UpperTorso':(.17,0,-.15)}),(1.4,ready)],loop=True,priority='Idle')
# Athletic gait: hips lead, knees fold backward, quiet trailing arms for ninja run.
for name,dur,amp in [('Walk',.85,.42),('Run',.60,.82),('Sprint',.46,1.05)]:
 keys=[]
 for i in range(17):
  phase=i/16*math.tau;swing=math.sin(phase)*amp
  ninja=name!='Walk';lean=-.38 if name=='Run' else -.62 if name=='Sprint' else -.07
  p={**idle,'LowerTorso':(-.08 if ninja else 0,0,math.sin(phase)*.035),
   'UpperTorso':(lean,0,math.sin(phase)*(.02 if ninja else .06)),
   'Head':(-lean*.8,0,0),
   'LeftUpperLeg':(swing,0,0),'RightUpperLeg':(-swing,0,0),
   'LeftLowerLeg':(-max(0,swing)*1.5,0,0),'RightLowerLeg':(-max(0,-swing)*1.5,0,0),
   'LeftFoot':(-swing*.2,0,0),'RightFoot':(swing*.2,0,0),
   'LeftUpperArm':(-.45 if ninja else -swing*.65,0,.12),
   'RightUpperArm':(-.48 if ninja else swing*.65,0,-.12),
   'LeftLowerArm':(-.08 if ninja else .1,0,0),'RightLowerArm':(-.06 if ninja else .1,0,0),
   'RightHand':(0,0,math.pi if ninja else 0)}
  keys.append((i/16*dur,p))
 clip(name,dur,keys,{'FootLeft':dur*.25,'FootRight':dur*.75},True,'Movement')
for name,dir in [('StrafeLeft',-1),('StrafeRight',1)]:
 clip(name,.75,[(0,{**ready,'LeftUpperLeg':(0,0,.15*dir),'RightUpperLeg':(0,0,-.15*dir)}),(.375,{**ready,'LeftUpperLeg':(0,0,-.2*dir),'RightUpperLeg':(0,0,.2*dir)}),(.75,ready)],{'FootLeft':0,'FootRight':.375},True,'Movement')
clip('Jump',.45,[(0,ready),(.12,{**ready,'LeftUpperLeg':(.8,0,0),'RightUpperLeg':(-.35,0,0),'LeftLowerLeg':(.8,0,0)}),(.45,ready)],{'Takeoff':0},False,'Movement')
clip('Fall',.8,[(0,{**ready,'LeftUpperArm':(.3,0,.6),'RightUpperArm':(.3,0,-.6)}),(.8,ready)],loop=True,priority='Movement')
for name,dur,bend in [('Land',.35,.35),('HeavyLand',.6,.7)]:
 clip(name,dur,[(0,{**ready,'UpperTorso':(bend,0,0),'LeftUpperLeg':(-bend,0,0),'RightUpperLeg':(-bend,0,0),'LeftLowerLeg':(bend*1.5,0,0),'RightLowerLeg':(bend*1.5,0,0)}),(dur,ready)],{'GroundImpact':0})
for i,timing in enumerate([(.1,.12,.2),(.12,.12,.22),(.17,.15,.29)],1):
 w,a,r=timing;wind,contact,follow=strike(i)
 # Start coil in the hips; the shoulder/blade catches up, then follows through.
 hip_lead={**ready,'LowerTorso':(0,0,wind['LowerTorso'][2] if 'LowerTorso' in wind else -.25),
  'UpperTorso':(-.08,0,-.12 if i!=2 else .12),'LeftUpperLeg':(.16,0,0),'LeftLowerLeg':(-.2,0,0)}
 contact={**contact,'UpperTorso':(-.18,0,contact['UpperTorso'][2]),'LeftUpperLeg':(.30,0,0),'LeftLowerLeg':(-.35,0,0),'RightUpperLeg':(-.18,0,0)}
 follow={**follow,'UpperTorso':(-.12,0,follow['UpperTorso'][2]),'LeftUpperLeg':(.2,0,0),'LeftLowerLeg':(-.18,0,0)}
 settle={**ready,'LowerTorso':(0,0,.10 if i!=2 else -.10),'RightUpperArm':(.72,0,.2 if i!=2 else -.2)}
 clip('Light'+str(i),w+a+r,[(0,ready),(w*.35,hip_lead),(w,wind),(w+a*.45,contact),(w+a,follow),(w+a+r*.55,settle),(w+a+r,ready)],{'TrailOn':w,'HitStart':w,'HitEnd':w+a,'TrailOff':w+a,'Recovery':w+a})
heavy_w={**ready,'UpperTorso':(.18,0,-.25),'RightUpperArm':(2.65,0,-.1),'RightLowerArm':(-.3,0,0),'LeftUpperArm':(1.9,0,.2)}
heavy_c={**ready,'UpperTorso':(-.48,0,.2),'RightUpperArm':(.85,0,.1),'RightLowerArm':(.15,0,0),'LeftUpperLeg':(.3,0,0),'LeftLowerLeg':(-.65,0,0)}
clip('Heavy',.9,[(0,ready),(.22,heavy_w),(.35,heavy_w),(.42,heavy_c),(.52,{**heavy_c,'UpperTorso':(-.35,0,.35)}),(.72,{**ready,'UpperTorso':(-.08,0,.12)}),(.9,ready)],{'TrailOn':.35,'HitStart':.35,'GroundImpact':.4,'HitEnd':.47,'TrailOff':.47,'Recovery':.47})
for name in ['DashForward','DashBack','DashLeft','DashRight']:
 tilt={'DashForward':(-.65,0,0),'DashBack':(.22,0,0),'DashLeft':(-.3,-.2,0),'DashRight':(-.3,.2,0)}[name]
 tuck={**ready,'UpperTorso':tilt,'Head':(.35,0,0),'LeftUpperLeg':(.9,0,0),'RightUpperLeg':(-.55,0,0),'LeftLowerLeg':(-1.3,0,0),'RightLowerLeg':(-.45,0,0),'LeftUpperArm':(-.45,0,.18),'RightUpperArm':(-.5,0,-.18),'RightHand':(0,0,math.pi)}
 clip(name,.28,[(0,tuck),(.07,{**tuck,'LeftUpperLeg':(.65,0,0)}),(.18,{**tuck,'UpperTorso':tuple(v*.6 for v in tilt)}),(.28,ready)],{'DashStart':0,'DashEnd':.18})
# Tucked air flip and five-step lateral wall-run; physics stays server-controlled.
clip('DoubleJump',.48,[(0,{**ready,'LowerTorso':(0,0,0)}),(.1,{**ready,'LowerTorso':(-1.2,0,0),'LeftUpperLeg':(1.25,0,0),'RightUpperLeg':(1.1,0,0),'LeftLowerLeg':(-1.6,0,0),'RightLowerLeg':(-1.6,0,0)}),(.3,{**ready,'LowerTorso':(-4.8,0,0),'LeftUpperLeg':(1.1,0,0),'RightUpperLeg':(.8,0,0),'LeftLowerLeg':(-1.5,0,0),'RightLowerLeg':(-1.5,0,0)}),(.48,{**ready,'LowerTorso':(-math.tau,0,0)})],{'AirStep':0,'Unfold':.36})
for name,side in [('WallRunLeft',1),('WallRunRight',-1)]:
 keys=[]
 for i in range(17):
  phase=i/16*math.tau;swing=math.sin(phase)*.65
  p={**ready,'UpperTorso':(-.28,side*.22,0),'Head':(.22,-side*.15,0),
   'LeftUpperLeg':(swing,side*.32,0),'RightUpperLeg':(-swing,side*.32,0),
   'LeftLowerLeg':(-max(0,swing)*1.6,0,0),'RightLowerLeg':(-max(0,-swing)*1.6,0,0),
   'LeftUpperArm':(.2,.85 if side==1 else -.2,0),'RightUpperArm':(.2,-.85 if side==-1 else .2,0),
   'RightHand':(0,0,math.pi)}
  keys.append((i/16*.28,p))
 clip(name,.28,keys,{'WallFootLeft':.07,'WallFootRight':.21},True)
clip('Guard',1,[(0,{**ready,'RightUpperArm':(1.3,0,.6),'RightLowerArm':(.9,0,.1),'LeftUpperArm':(1.3,0,-.6),'LeftLowerArm':(.9,0,-.1)}),(1,{**ready,'RightUpperArm':(1.3,0,.6),'RightLowerArm':(.9,0,.1),'LeftUpperArm':(1.3,0,-.6),'LeftLowerArm':(.9,0,-.1)})],loop=True)
clip('Parry',.4,[(0,ready),(.08,{**ready,'LeftUpperArm':(1.6,0,-.5),'LeftLowerArm':(.3,0,0),'UpperTorso':(0,0,.3)}),(.4,ready)],{'Parry':.08})
clip('GuardBreak',.7,[(0,ready),(.12,{**idle,'UpperTorso':(-.4,0,0),'LeftUpperArm':(.2,0,1),'RightUpperArm':(.2,0,-1)}),(.7,ready)])
clip('Hurt',.35,[(0,ready),(.08,{**ready,'UpperTorso':(-.2,0,-.2),'Head':(.15,0,0)}),(.35,ready)])
for name,w,a,r in [('Coreburst',.12,.06,.3),('Overdrive',.25,.15,.6)]:
 wind={**ready,'LeftUpperArm':(.7,0,-.7),'LeftLowerArm':(1,0,0),'UpperTorso':(.1,0,-.3)}
 hit={**ready,'LeftUpperArm':(1.6,0,-.05),'LeftLowerArm':(.05,0,0),'UpperTorso':(.25,0,.3)}
 clip(name,w+a+r,[(0,ready),(w*.8,wind),(w,wind),(w+a,hit),(w+a+r,ready)],{'Charge':0,'HitStart':w,'GroundImpact':w,'HitEnd':w+a,'Recovery':w+a})
for name,dur in [('WardenIdle',2),('WardenWalk',1.2),('WardenSlam',2.2),('WardenLance',1.9),('WardenExposed',2.4)]:
 if name=='WardenIdle':keys=[(0,idle),(1,{**idle,'UpperTorso':(.12,0,0)}),(2,idle)];markers={}
 elif name=='WardenWalk':keys=[(0,{**idle,'LeftUpperLeg':(.35,0,0),'RightUpperLeg':(-.35,0,0)}),(.6,{**idle,'LeftUpperLeg':(-.35,0,0),'RightUpperLeg':(.35,0,0)}),(1.2,idle)];markers={'FootLeft':0,'FootRight':.6}
 elif name=='WardenExposed':keys=[(0,{**idle,'UpperTorso':(.65,0,0),'Head':(.25,0,0)}),(dur,{**idle,'UpperTorso':(.6,0,0)})];markers={}
 else:
  keys=[(0,ready),(.85,heavy_w),(1.15,heavy_w),(1.35,heavy_c),(dur,ready)];markers={'Charge':0,'HitStart':1.15,'GroundImpact':1.35,'Recovery':1.4}
 clip(name,dur,keys,markers,name in ['WardenIdle','WardenWalk','WardenExposed'])
# Linear baked keys sample continuous authored Hermite motion at 60 Hz.
def interpolate(keys,t,loop=False):
 for i in range(len(keys)-1):
  ta,pa=keys[i];tb,pb=keys[i+1]
  if t<=tb+1e-7:
   u=max(0,min(1,(t-ta)/max(.00001,tb-ta)));dt=tb-ta
   tp,pp=keys[i-1] if i>0 else ((keys[-2][0]-keys[-1][0],keys[-2][1]) if loop else (ta,pa))
   tn,pn=keys[i+2] if i+2<len(keys) else ((keys[1][0]+keys[-1][0],keys[1][1]) if loop else (tb,pb))
   def component(name,j):
    a=pa.get(name,(0,0,0))[j];b=pb.get(name,(0,0,0))[j];delta=(b-a)/max(dt,.00001)
    m0=(b-pp.get(name,(0,0,0))[j])/max(tb-tp,.00001);m1=(pn.get(name,(0,0,0))[j]-a)/max(tn-ta,.00001)
    # Monotone Hermite keeps continuous contact momentum without overshoot/limb snaps.
    m0=0 if m0*delta<=0 else math.copysign(min(abs(m0),3*abs(delta)),m0)
    m1=0 if m1*delta<=0 else math.copysign(min(abs(m1),3*abs(delta)),m1)
    return (2*u**3-3*u*u+1)*a+(u**3-2*u*u+u)*dt*m0+(-2*u**3+3*u*u)*b+(u**3-u*u)*dt*m1
   return {name:tuple(component(name,j) for j in range(3)) for name in bones}
 return {name:keys[-1][1].get(name,(0,0,0)) for name in bones}
q=Matrix(((1,0,0,0),(0,0,1,0),(0,-1,0,0),(0,0,0,1)))
centers={name:(Vector(head)+Vector(tail))/2 for name,(_,head,tail) in bones.items()}
centers['HumanoidRootPart']=Vector((0,0,2.9))
def cf(m):
 m=q@m@q.inverted();return [m[0][3],m[1][3],m[2][3]]+[m[row][col] for row in range(3) for col in range(3)]
exported={'version':1,'fps':60,'bones':{},'clips':{}}
for name,(parent,head,tail) in bones.items():
 exported['bones'][name]={'parent':parent,'center':list(q.to_3x3()@centers[name]),'joint':list(q.to_3x3()@Vector(head))}
for name,c in clips.items():
 action=bpy.data.actions.new(name);action.use_fake_user=True;arm.animation_data_create();arm.animation_data.action=action
 times=sorted(set([round(i/60,6) for i in range(math.ceil(c['duration']*60)+1) if i/60<=c['duration']]+[c['duration']]+list(c['markers'].values())))
 frames=[];sweep=[]
 for t in times:
  p=interpolate(c['keys'],t,c['loop'])
  # Keep the blade oriented through the forward contact plane. Shoulder lift alone
  # otherwise points a forward-gripped blade upward, outside its intended hit corridor.
  pitch=0
  if name=='Heavy':
   pitch=1.0 if t<c['markers']['HitStart'] else -.35 if t<=c['markers']['HitEnd'] else 0
  total=sum(p.get(j,(0,0,0))[0] for j in ['LowerTorso','UpperTorso','RightUpperArm','RightLowerArm'])
  wrist=p.get('RightHand',(0,0,0));trailing=abs(wrist[2])>math.pi*.5
  p['RightHand']=((total if trailing else -total)+pitch,wrist[1],wrist[2])
  for bone,angles in p.items():
   pb=arm.pose.bones[bone];pb.location=(0,0,0);rest=arm.data.bones[bone].matrix_local.to_3x3()
   rotation=rest.inverted()@Euler(angles,'XYZ').to_matrix()@rest
   pb.rotation_mode='QUATERNION';pb.rotation_quaternion=rotation.to_quaternion();pb.keyframe_insert('rotation_quaternion',frame=1+t*60,group=bone)
  frame=1+t*60;scene.frame_set(int(frame),subframe=frame-int(frame));bpy.context.view_layer.update()
  transforms={};worlds={}
  for bone,(parent,head,tail) in bones.items():
   rest=Matrix.Translation(centers[bone]);deform=arm.pose.bones[bone].matrix@arm.data.bones[bone].matrix_local.inverted()
   worlds[bone]=deform@rest
   if parent:
    c0=Matrix.Translation(Vector(head)-centers[parent]);c1=Matrix.Translation(Vector(head)-centers[bone])
    transforms[bone]=cf(c0.inverted()@worlds[parent].inverted()@worlds[bone]@c1)
  frames.append({'time':round(t,6),'poses':transforms})
  deform=arm.pose.bones['RightHand'].matrix@arm.data.bones['RightHand'].matrix_local.inverted()
  base=q@(deform@(hand+Vector((0,.4,0))).to_4d());tip=q@(deform@(hand+Vector((0,4.1,0))).to_4d())
  # Character root is centered at 2.9 studs above the ground.
  sweep.append({'time':round(t,6),'base':[base.x,base.y-2.9,base.z],'tip':[tip.x,tip.y-2.9,tip.z]})
 for fc in action.fcurves:
  for k in fc.keyframe_points:k.interpolation='LINEAR'
 for marker,t in c['markers'].items():action.pose_markers.new(marker).frame=round(t*60+1)
 exported['clips'][name]={'duration':c['duration'],'loop':c['loop'],'priority':c['priority'],'markers':c['markers'],'frames':frames,'sweep':sweep}
# Export one asset file per model, plus the hero skeleton and full action library.
def export_fbx(path,objects,animation=False):
 bpy.ops.object.select_all(action='DESELECT')
 for obj in objects:obj.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.export_scene.fbx(filepath=str(path),use_selection=True,add_leaf_bones=False,apply_unit_scale=True,
  axis_forward='-Z',axis_up='Y',bake_anim=animation,bake_anim_use_all_actions=animation,bake_anim_use_nla_strips=False,
  bake_anim_simplify_factor=0,object_types={'ARMATURE','MESH'},use_mesh_modifiers=True)
arm.animation_data.action=bpy.data.actions['CombatIdle'];scene.frame_set(1)
export_fbx(OUT/'exports/DawnHero.fbx',[arm]+hero,True)
export_fbx(OUT/'exports/RelicBlade.fbx',[arm]+blade,False)
export_fbx(OUT/'exports/VerdantWarden.fbx',[ward_arm]+warden,False)
(OUT/'animations/choreography.json').write_text(json.dumps(exported,separators=(',',':'))+'\n')
# Keep source objects organized and move the Warden for source-scene inspection only, after exports.
ward_arm.location.x=-8
scene.frame_set(1);bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source/Ascension.blend'))
print('ASCENSION_EXPORTED',len(clips),'clips;',sum(len(o.data.polygons) for o in hero+blade+warden),'source faces')

# Labeled source render: useful for asset inspection, never a Roblox engine capture.
for obj in hero+blade:
 obj.hide_render=False
ward_arm.location.x=-8
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=False
scene.render.resolution_x=1440;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
world=scene.world or bpy.data.worlds.new('SourceWorld');scene.world=world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.055,.075,.10,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.4
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.05));floor=bpy.context.object;floor.data.materials.append(materials['Midnight'])
for pos,power,size in [((4,6,10),1800,7),((-10,2,10),2400,6),((0,-5,8),2000,5)]:
 bpy.ops.object.light_add(type='AREA',location=pos);lamp=bpy.context.object;lamp.data.energy=power;lamp.data.shape='DISK';lamp.data.size=size
 lamp.rotation_euler=(Vector((-3,0,3))-lamp.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(12,19,11));camera=bpy.context.object
camera.rotation_euler=(Vector((-3,0,4.8))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.type='ORTHO';camera.data.ortho_scale=19;scene.camera=camera
scene.render.filepath=str(OUT/'previews/Source-Models.png');bpy.ops.render.render(write_still=True)
