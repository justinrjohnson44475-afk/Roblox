#!/usr/bin/env python3
"""Prepare an existing-place update; network writes require --execute and configured authorization."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.request

API = "https://apis.roblox.com/assets/v1/"


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise RuntimeError("Unexpected redirect; refusing to forward publishing credentials")


def inspect_artifact(path, place_id):
    if not re.fullmatch(r"[1-9][0-9]*", place_id):
        raise ValueError("Place ID must be a positive decimal integer")
    data = Path(path).read_bytes()
    if not data.startswith(b"<roblox!\x89\xff\r\n\x1a\n"):
        raise ValueError("Expected a Rojo-built binary .rbxl file")
    if len(data) > 32 * 1024 * 1024:
        raise ValueError("Artifact exceeds this publisher's 32 MiB review limit")
    return data, hashlib.sha256(data).hexdigest()


def authorize(place_id, digest, env):
    if env.get("ROBLOX_ALLOWED_PLACE_ID") != place_id:
        raise ValueError("Place ID does not match the configured authorized target")
    if env.get("ROBLOX_APPROVED_SHA256") != digest:
        raise ValueError("Artifact digest does not match the reviewed artifact")
    if not env.get("ROBLOX_OPEN_CLOUD_API_KEY"):
        raise ValueError("Open Cloud API key is not configured; use environment secrets")


def operation_path(response):
    path = response.get("path", "")
    if not isinstance(path, str) or not re.fullmatch(r"operations/[A-Za-z0-9_-]+", path):
        raise ValueError("Unrecognized operation path; publishing status is unverified")
    return path


def published_revision(response, place_id):
    if response.get("error"):
        raise RuntimeError("Roblox reported an operation error; publish did not verify")
    if response.get("done") is not True:
        return None
    asset = response.get("response", {})
    if asset.get("path") != "assets/" + place_id or asset.get("isPublished") is not True:
        raise RuntimeError("Operation did not confirm the requested published place")
    revision = asset.get("revisionId")
    if not isinstance(revision, (str, int)) or not str(revision):
        raise RuntimeError("Published response has no revision identifier")
    return str(revision)


def publish(data, place_id, api_key):
    boundary = "Riftwake" + hashlib.sha256(data).hexdigest()
    request_json = json.dumps({"assetId": int(place_id), "assetType": "Place", "published": True})
    body = (
        f'--{boundary}\r\nContent-Disposition: form-data; name="request"\r\n\r\n{request_json}\r\n'
        f'--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="Riftwake.rbxl"\r\n'
        'Content-Type: application/octet-stream\r\n\r\n'
    ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
    opener = urllib.request.build_opener(NoRedirect())

    def call(path, payload=None):
        req = urllib.request.Request(
            API + path,
            data=payload,
            method="PATCH" if payload is not None else "GET",
            headers={"x-api-key": api_key, "Content-Type": "multipart/form-data; boundary=" + boundary},
        )
        try:
            with opener.open(req, timeout=30) as result:
                return json.load(result)
        except urllib.error.HTTPError as exc:
            # Do not print request headers or API bodies into CI logs.
            raise RuntimeError(f"Roblox API HTTP {exc.code}; publish status is unverified") from None

    operation = operation_path(call("assets/" + place_id, body))
    for _ in range(20):
        revision = published_revision(call(operation), place_id)
        if revision is not None:
            return revision
        time.sleep(3)
    raise RuntimeError("Operation still pending; inspect Creator Dashboard before any retry")


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--file", required=True)
    parser.add_argument("--place-id", required=True)
    parser.add_argument("--execute", action="store_true", help="Perform the authorized update (default: dry run)")
    args = parser.parse_args(argv)
    data, digest = inspect_artifact(args.file, args.place_id)
    print(json.dumps({"place_id": args.place_id, "sha256": digest, "bytes": len(data), "mode": "execute" if args.execute else "dry-run"}))
    if not args.execute:
        print("Dry run only: no API call, upload or publication occurred.")
        return 0
    authorize(args.place_id, digest, os.environ)
    revision = publish(data, args.place_id, os.environ["ROBLOX_OPEN_CLOUD_API_KEY"])
    print(json.dumps({"verified_published_place": args.place_id, "revision": revision, "sha256": digest}))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (ValueError, RuntimeError, OSError, urllib.error.URLError) as error:
        print(f"Publishing stopped: {error}", file=sys.stderr)
        sys.exit(1)
