"""Rebuild asset provenance from original source. Never promotes import/validation state."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2]
assets=root/'assets/ascension'
old=json.loads((assets/'manifest.json').read_text()) if (assets/'manifest.json').exists() else {'Assets':{}}
entries={}
def add(key,path,kind,required=True):
 previous=old['Assets'].get(key,{})
 digest=hashlib.sha256((root/path).read_bytes()).hexdigest()
 same=previous.get('SHA256')==digest
 entries[key]={'Source':path,'Kind':kind,'Rights':'Original project-authored work; no external mesh, animation or sound samples','CommercialUse':True,'Attribution':'Project Ascension source contributors','LicenseVerified':True,'SHA256':digest,'Owner':'UNASSIGNED_ROBLOX_CREATOR','RobloxId':previous.get('RobloxId',0) if same else 0,'Status':previous.get('Status','exported') if same else 'exported','Required':required,'EngineEvidence':previous.get('EngineEvidence','') if same else ''}
for name in ['DawnHero','RelicBlade','VerdantWarden']:add('model:'+name,f'assets/ascension/exports/{name}.fbx','mesh')
clips=json.loads((assets/'animations/choreography.json').read_text())['clips']
for name in clips:add('animation:'+name,'assets/ascension/animations/choreography.json','animation')
for path in sorted((assets/'audio').glob('*.wav')):add('audio:'+path.stem,str(path.relative_to(root)),'audio')
manifest={'Version':1,'Assets':entries,'SourceAuthoring':'scripts/ascension/author_assets.py','Validation':'Exported source only; no Roblox imports or published animation IDs verified.'}
(assets/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
# JSON is embedded so Rojo produces a real ModuleScript with no runtime filesystem dependency.
(root/'src/shared/Ascension/AssetManifest.luau').write_text('--!strict\n-- Generated asset provenance; regenerate with scripts/ascension/manifest.py.\nreturn game:GetService("HttpService"):JSONDecode([=['+json.dumps(manifest,separators=(',',':'))+']=])\n')
print(f'{len(entries)} original asset records; '+str(sum(e['RobloxId']==0 for e in entries.values()))+' awaiting Roblox import/publication')
