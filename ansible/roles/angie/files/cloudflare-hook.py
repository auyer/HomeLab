#!/usr/bin/env python3
import base64
import hashlib
import json
import os
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone

CF_API_BASE = "https://api.cloudflare.com/client/v4"
CREDENTIALS_PATH = "/etc/angie/cloudflare.ini"
LOG_PATH = "/var/log/angie/acme-hook.log"


def log(msg):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    try:
        with open(LOG_PATH, "a") as f:
            f.write(f"{ts} {msg}\n")
    except Exception:
        pass


def load_api_token():
    try:
        with open(CREDENTIALS_PATH) as f:
            for line in f:
                line = line.strip()
                if line.startswith("CF_API_TOKEN="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
    except (FileNotFoundError, PermissionError) as e:
        log(f"ERROR reading {CREDENTIALS_PATH}: {e}")
    return os.environ.get("CF_API_TOKEN", "")


def cf_request(method, path, token, data=None):
    url = f"{CF_API_BASE}{path}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    log(f"API {method} {url}")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read().decode()
            result = json.loads(raw)
            log(f"API response: success={result.get('success')} errors={result.get('errors')}")
            return result
    except urllib.error.HTTPError as e:
        err_body = e.read().decode() if e.fp else str(e)
        log(f"API HTTP error {e.code}: {err_body}")
        return {"success": False, "errors": [{"message": f"HTTP {e.code}: {err_body}"}]}
    except Exception as e:
        log(f"API exception: {e}")
        return {"success": False, "errors": [{"message": str(e)}]}


def get_zone(token, domain):
    parts = domain.split(".")
    for i in range(len(parts) - 1):
        candidate = ".".join(parts[i:])
        resp = cf_request("GET", f"/zones?name={candidate}", token)
        if resp.get("success") and resp.get("result"):
            zone = resp["result"][0]
            log(f"Found zone id={zone['id']} name={zone['name']} via candidate={candidate}")
            return zone["id"], zone["name"], None
    log(f"No zone found for domain={domain}")
    return None, None, [{"message": f"No Cloudflare zone found for domain: {domain}"}]


def find_txt_record(token, zone_id, record_name):
    resp = cf_request(
        "GET",
        f"/zones/{zone_id}/dns_records?type=TXT&name={record_name}",
        token,
    )
    if not resp.get("success"):
        return None, resp.get("errors", [])
    records = resp.get("result", [])
    return records[0]["id"] if records else None, None


def create_txt_record(token, zone_id, record_name, content):
    data = {
        "type": "TXT",
        "name": record_name,
        "content": content,
        "ttl": 120,
    }
    resp = cf_request("POST", f"/zones/{zone_id}/dns_records", token, data)
    success = resp.get("success", False)
    if success and resp.get("result"):
        created = resp["result"]
        log(f"Created TXT: id={created.get('id')} name={created.get('name')} content={created.get('content')}")
    return success, resp.get("errors", [])


def delete_txt_record(token, zone_id, record_id):
    resp = cf_request("DELETE", f"/zones/{zone_id}/dns_records/{record_id}", token)
    return resp.get("success", False), resp.get("errors", [])


def write_response(status, message):
    status_text = {200: "OK", 500: "Internal Server Error"}
    print(f"Status: {status} {status_text.get(status, '')}")
    print("Content-Type: text/plain")
    print()
    print(message)


def main():
    hook = os.environ.get("ACME_HOOK", "")
    domain = os.environ.get("ACME_DOMAIN", "")
    keyauth = os.environ.get("ACME_KEYAUTH", "")
    challenge = os.environ.get("ACME_CHALLENGE", "")
    token_name = os.environ.get("ACME_TOKEN", "")

    log(f"HOOK={hook} DOMAIN={domain} CHALLENGE={challenge} TOKEN={token_name} KEYAUTH_PRESENT={'yes' if keyauth else 'no'}")

    if not hook or not domain:
        log("ERROR: Missing ACME_HOOK or ACME_DOMAIN")
        write_response(500, "Missing ACME_HOOK or ACME_DOMAIN environment variable")
        return

    cf_token = load_api_token()
    if not cf_token:
        log("ERROR: Cloudflare API token not configured")
        write_response(500, "Cloudflare API token not configured")
        return

    zone_id, zone_name, errors = get_zone(cf_token, domain)
    if errors:
        log(f"ERROR: Failed to find zone: {errors}")
        write_response(500, f"Failed to find zone for {domain}: {errors}")
        return

    fqdn_record = f"_acme-challenge.{domain}"
    log(f"Record: FQDN={fqdn_record} zone={zone_name}")

    if hook == "add":
        if not keyauth:
            log("ERROR: Missing ACME_KEYAUTH for add hook")
            write_response(500, "Missing ACME_KEYAUTH for add hook")
            return

        log(f"DNS-01: keyauth_len={len(keyauth)} value={keyauth}")

        success, errors = create_txt_record(cf_token, zone_id, fqdn_record, keyauth)
        if not success:
            log(f"ERROR: Failed to create TXT record: {errors}")
            write_response(500, f"Failed to create TXT record: {errors}")
            return

        record_id, verify_errors = find_txt_record(cf_token, zone_id, fqdn_record)
        if verify_errors:
            log(f"ERROR: Verification lookup failed: {verify_errors}")
            write_response(500, f"TXT record created but verification failed: {verify_errors}")
            return
        if not record_id:
            log("ERROR: TXT record not found after creation")
            write_response(500, "TXT record created but not found in verification lookup")
            return

        log(f"SUCCESS: TXT record {fqdn_record} created and verified (id={record_id})")
        dns_delay = int(os.environ.get("ACME_DNS_DELAY", "30"))
        log(f"Waiting {dns_delay}s for DNS propagation")
        time.sleep(dns_delay)
        write_response(200, f"TXT record {fqdn_record} created and verified")

    elif hook == "remove":
        record_id, errors = find_txt_record(cf_token, zone_id, fqdn_record)
        if errors:
            log(f"ERROR: Failed to find TXT record for removal: {errors}")
            write_response(500, f"Failed to find TXT record: {errors}")
            return

        if not record_id:
            log(f"TXT record {fqdn_record} already removed")
            write_response(200, f"TXT record {fqdn_record} already removed")
            return

        success, errors = delete_txt_record(cf_token, zone_id, record_id)
        if not success:
            log(f"ERROR: Failed to delete TXT record: {errors}")
            write_response(500, f"Failed to delete TXT record: {errors}")
            return

        log(f"SUCCESS: TXT record {fqdn_record} removed (id={record_id})")
        write_response(200, f"TXT record {fqdn_record} removed successfully")

    else:
        log(f"ERROR: Unknown ACME_HOOK action: {hook}")
        write_response(500, f"Unknown ACME_HOOK action: {hook}")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        log(f"UNHANDLED EXCEPTION: {e}")
        write_response(500, f"Internal error: {e}")
