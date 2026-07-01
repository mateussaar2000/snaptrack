#!/usr/bin/env python3
"""
Poll App Store Connect for the latest SnapTrack build status.

Usage:
    python3 asc_check.py [bundle_id] [timeout_minutes]

Looks for the private key at:
    ./AuthKey_<KEY_ID>.p8

Configure ISSUER_ID and KEY_ID below.
"""
import sys
import time
import jwt
import json
import urllib.request
from pathlib import Path
from datetime import datetime, timezone, timedelta

# SnapTrack app configuration
ISSUER_ID = "f613e8e5-2c0a-45c5-9a56-3299c11d3213"
KEY_ID = "5LQRVUPX2C"
BUNDLE_ID = "com.mateussaar2000.snaptrack"
BASE_URL = "https://api.appstoreconnect.apple.com/v1"


def load_private_key():
    key_path = Path(__file__).parent / f"AuthKey_{KEY_ID}.p8"
    if not key_path.exists():
        # Fall back to common altool search paths
        candidates = [
            Path.home() / f"AuthKey_{KEY_ID}.p8",
            Path.home() / "Downloads" / f"AuthKey_{KEY_ID}.p8",
            Path.home() / ".appstoreconnect" / "private_keys" / f"AuthKey_{KEY_ID}.p8",
            Path.home() / ".private_keys" / f"AuthKey_{KEY_ID}.p8",
        ]
        for c in candidates:
            if c.exists():
                key_path = c
                break
    if not key_path.exists():
        print(f"ERROR: Could not find AuthKey_{KEY_ID}.p8", file=sys.stderr)
        sys.exit(1)
    return key_path.read_text()


def make_token():
    now = datetime.now(timezone.utc)
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": now + timedelta(minutes=19),
        "aud": "appstoreconnect-v1",
    }
    headers = {"kid": KEY_ID, "typ": "JWT", "alg": "ES256"}
    return jwt.encode(payload, load_private_key(), algorithm="ES256", headers=headers)


def api_request(path):
    url = f"{BASE_URL}{path}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {make_token()}"})
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8")
        print(f"\nAPI request failed: {url}\nStatus {e.code}: {body[:500]}", file=sys.stderr)
        sys.exit(1)


def find_app_id(bundle_id):
    data = api_request(f"/apps?filter[bundleId]={bundle_id}&limit=1")
    apps = data.get("data", [])
    if not apps:
        print(f"ERROR: No app found for bundle ID {bundle_id}", file=sys.stderr)
        sys.exit(1)
    return apps[0]["id"]


def get_latest_build(app_id):
    # API doesn't support sort on /builds, so fetch several and pick the most recent.
    data = api_request(f"/apps/{app_id}/builds?limit=20")
    builds = data.get("data", [])
    if not builds:
        return None
    builds.sort(key=lambda b: b["attributes"].get("uploadedDate", ""), reverse=True)
    return builds[0]


def format_build(build):
    attr = build["attributes"]
    version = attr.get("version", "?")
    build_number = attr.get("version", "?")
    # 'version' is the build number (CFBundleVersion); 'appStoreVersion' is marketing version
    marketing = attr.get("appStoreVersion", "?")
    state = attr.get("processingState", "UNKNOWN")
    uploaded = attr.get("uploadedDate", "?")
    return f"Version {marketing} ({version}) – state: {state} – uploaded: {uploaded}"


def main():
    bundle_id = sys.argv[1] if len(sys.argv) > 1 else BUNDLE_ID
    timeout_min = int(sys.argv[2]) if len(sys.argv) > 2 else 10

    app_id = find_app_id(bundle_id)
    print(f"Monitoring latest build for {bundle_id}...")

    deadline = datetime.now(timezone.utc) + timedelta(minutes=timeout_min)
    while datetime.now(timezone.utc) < deadline:
        build = get_latest_build(app_id)
        if build is None:
            print("No builds found yet. Waiting...")
        else:
            print(format_build(build))
            state = build["attributes"].get("processingState", "")
            if state in ("VALID", "INVALID_BINARY"):
                if state == "VALID":
                    print("✅ Build is valid and ready for TestFlight / review.")
                else:
                    print("❌ Build was rejected/invalid. Check the decline email in Gmail for exact errors.")
                return
        time.sleep(30)

    print(f"⏱ Timed out after {timeout_min} minutes. Build may still be processing.")


if __name__ == "__main__":
    main()
