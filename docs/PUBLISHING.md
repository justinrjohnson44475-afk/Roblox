# Publishing runbook — prepared, not executed

## Current state
There is no Roblox place/universe configuration or Open Cloud key in this project. Building a file does not create or publish an experience. The cloud network currently allows GitHub/tool downloads but direct Roblox HTTP access was denied (403 CONNECT); the web research tool could read official documentation. Future publishing additionally needs an approved outbound route to apis.roblox.com. Never bypass destination policy.

## Release gates
- Record a reviewed Git commit and built SHA256.
- Pass cloud checks, then record actual Studio solo/multiplayer, device, persistence and purchase tests.
- Complete the Maturity & Compliance questionnaire accurately, including optional Christian material; resolve uncertainty with Roblox. Do not presume an unrestricted audience.
- Confirm all assets’ rights, moderation status, actual store prices and full experience description.
- The owner configures the target private test experience/place, scoped API credentials and release authorization. Store credentials only in environment/GitHub secrets. Keep the initial release private until launch readiness is established.
- For a future GitHub publish workflow, require a protected Environment with required reviewers, restricted branches and only the specific place credentials. CI build success alone must never trigger publication.

## Dry run
After a build:

```bash
python3 scripts/publish.py --place-id YOUR_EXISTING_PLACE_ID --file build/Harborlight.rbxl
```

This inspects the binary header and prints bytes/hash/target without accessing credentials or making an API call. The place ID `1` in cloud checks is a dummy dry-run target, not this project’s Roblox place.

## Future authorized update
Use current [official Assets API publishing guidance](https://create.roblox.com/docs/cloud/guides/usage-place-publishing), reviewed November 7, 2026. The API updates an existing place and returns an asynchronous operation; acceptance alone is not verified publication. This project’s helper uploads the binary file using PATCH to assets/v1/assets/{placeId}, polls the returned operation, and checks its completed published revision and target. Unexpected redirects and operation paths are rejected to protect credentials. No network integration test has been performed.

Configure in environment settings/secrets (never in chat or source):

- `ROBLOX_OPEN_CLOUD_API_KEY`: scoped Assets read/write access to the intended experience, with appropriate expiry/network restrictions.
- `ROBLOX_ALLOWED_PLACE_ID`: exact authorized place ID.
- `ROBLOX_APPROVED_SHA256`: exact reviewed artifact digest from the dry run.

Only after the concrete artifact and target are authorized:

```bash
python3 scripts/publish.py --place-id YOUR_EXISTING_PLACE_ID --file build/Harborlight.rbxl --execute
```

Success must include a verified revision identifier. An operation timeout means status is unresolved: inspect the operation/dashboard before retrying. Do not claim an upload was rolled back by reverting Git. Rollback requires a prior verified artifact/revision and a separately authorized place update; record the resulting new revision. Some Roblox instance types require Studio publication; see official limitations before adding advanced assets. Current world uses basic Parts/scripts.

The helper does not create experiences, configure permissions, change public visibility, complete policy questionnaires or buy advertisements. No publishing workflow is installed that can run unattended. Publishing support is prepared for future authorized use.
