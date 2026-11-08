"""Cloud provenance/asset checks. --release fails until real imports and engine evidence exist."""
import argparse,hashlib,json,math,wave
from pathlib import Path
root=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--release',action='store_true');args=p.parse_args()
manifest=json.loads((root/'assets/ascension/manifest.json').read_text())
missing=[]
for key,item in manifest['Assets'].items():
 path=root/item['Source'];assert path.is_file(),key
 assert hashlib.sha256(path.read_bytes()).hexdigest()==item['SHA256'],f'Stale hash: {key}'
 assert item['LicenseVerified'] and item['CommercialUse'] and item['Rights'],key
 if not(item['RobloxId']>0 and item['Status']=='engine-validated' and item['EngineEvidence'] and item['Owner']!='UNASSIGNED_ROBLOX_CREATOR'):missing.append(key)
clips=json.loads((root/'assets/ascension/animations/choreography.json').read_text())['clips']
assert len(clips)==30
for name,clip in clips.items():
 assert clip['frames'][0]['time']==0 and abs(clip['frames'][-1]['time']-clip['duration'])<1e-6,name
 for frame in clip['frames']:
  assert len(frame['poses'])==15,name
  assert all(len(cf)==12 and all(math.isfinite(v) for v in cf) for cf in frame['poses'].values()),name
for path in (root/'assets/ascension/audio').glob('*.wav'):
 with wave.open(str(path)) as f:assert f.getframerate()==22050 and f.getnframes()>0 and f.getnchannels()==1
report={'asset_records':len(manifest['Assets']),'clips':len(clips),'missing_production_assets':missing,'engine_tested':False,'release_ready':False,'checkpoint':'A foundation / B diagnostic implementation; Studio gate pending'}
(root/'build').mkdir(exist_ok=True);(root/'build/ascension-readiness.json').write_text(json.dumps(report,indent=2)+'\n')
print(f'PASS source integrity: {len(manifest["Assets"])} records, 30 clips, 14 WAV drafts. Production BLOCKED: {len(missing)} assets lack owned IDs and engine evidence.')
if args.release:raise SystemExit('Release gate blocked: source checks cannot establish Studio, device, player-study or publishing readiness.')
