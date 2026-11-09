"""Original synthesized cues and layered tonal sketches; no samples or third-party melodies.
These are review drafts. Roblox upload/ownership and engine mix validation remain required.
"""
import math,random,struct,wave
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets/ascension/audio'
root.mkdir(parents=True,exist_ok=True)
rate=22050
cues={'miss':(.12,180,.12),'block':(.2,320,.4),'parry':(.4,920,.12),'light':(.15,240,.5),'heavy':(.45,85,.75),'exposed':(.45,640,.35),'corebreak':(.8,520,.55),'ground':(.65,55,.8),'foot_stone':(.1,140,.45),'foot_grass':(.13,75,.7),'warden':(.8,65,.3)}
def write(name,values):
 peak=max(abs(x) for x in values) or 1
 # Peak headroom leaves room for overlapping voices; no hard clipping.
 values=[int(max(-1,min(1,x/peak*.42))*32767) for x in values]
 with wave.open(str(root/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(values),*values))
for index,(name,(duration,hz,noise)) in enumerate(cues.items()):
 rng=random.Random(4100+index);values=[];filtered=0
 for i in range(int(duration*rate)):
  t=i/rate;filtered=.65*filtered+.35*rng.uniform(-1,1)
  env=min(1,t/.005)*math.exp(-t/(duration*.22))
  tone=math.sin(2*math.pi*(hz*t+hz*.08*(1-math.exp(-t*12))))+.2*math.sin(2*math.pi*hz*2.71*t)
  values.append(env*((1-noise)*tone+noise*filtered))
 write(name,values)
for name,tempo,notes in [('exploration',72,[146.83,174.61,220,261.63]),('combat',108,[146.83,164.81,220,293.66]),('boss',120,[73.42,87.31,110,146.83])]:
 duration=16*60/tempo;values=[]
 for i in range(round(duration*rate)):
  t=i/rate;beat=t*tempo/60;index=int(beat)%len(notes);f=notes[index];pulse=math.exp(-(beat%1)*7)
  fade=min(1,t/.1,(duration-t)/.1)
  chord=sum(math.sin(2*math.pi*n*t)*.06 for n in notes)
  values.append(fade*(chord+.12*pulse*math.sin(2*math.pi*f*t)))
 write(name,values)
print('14 original WAV sketches exported; no audio upload or engine mixing verified')
