# Launch readiness and rollback

**Production blocked.** This is a draft milestone checkpoint; do not merge, publish Roblox revisions, purchase assets or run paid acquisition. No target credentials or publication operation were used. The existing publishing script remains dry-run by default and its unit tests do not establish a deployed game.

Readiness requires: gate B solo/four-client approval with engine evidence; gate C actual imported asset/device captures; completed party/inventory/cosmetic workflows; security and schema3/live-session recovery tests; all9 categories≥4 with independent evidence;12-tester targets;30min soak on stated devices; content declarations and optional-Christian-material policy review; reviewed private-test build and explicit release authorization.

Reproducible cloud build: `bash scripts/bootstrap.sh` if tools missing, then `bash scripts/check.sh`. SHA256SUMS covers baseline and signature places. CI attaches `.rbxl/.rbxlx`, readiness report, inspections and previews. Re-author source assets only with Blender4.3.2 and the committed scripts; asset re-export can change FBX binary hashes and must invalidate import readiness. The runtime build itself uses committed exports, so normal CI does not need Blender or an owner's laptop.

Rollback: main remains unchanged; use `baseline/riftwake-pre-revamp-e1cae97` to reproduce the original source, or use default.project.json for the legacy adapter. Do not send schema3 profiles to an old schema2 writer: it correctly refuses unknown versions. A future production rollback must keep the additive schema3 decoder or migrate compatible writes before changing deployed gameplay. Never restore an old profile snapshot over new earned balances. No production data migration was executed here.

For a future authorized Roblox release, configure an existing private target/owner and scoped secret outside Git; verify content declarations/asset permissions, approved exact build hash, private canary operation completion and recovery evidence. Upload acceptance alone is not verified publication. See the existing publisher's explicit authorization controls; no new automatic deployment workflow is enabled.
