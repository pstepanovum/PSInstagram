#!/usr/bin/env bash

# Build PSInstagram, inject it into a decrypted Instagram IPA, sign it and install it on a device.
#
# Usage: ./dev.sh [--clean] [--no-install]
#
# Expects:
#   packages/com.burbn.instagram.ipa   decrypted Instagram IPA
#   certs/dev.p12                      signing certificate
#   certs/dev.mobileprovision          provisioning profile for that certificate
#   certs/p12-password                 certificate password (plain text, no newline)
#
# Overridable with environment variables: IPA, P12, PROFILE, P12_PASSWORD_FILE, DEVICE, BUNDLE_ID

set -e

IPA="${IPA:-packages/com.burbn.instagram.ipa}"
P12="${P12:-certs/dev.p12}"
PROFILE="${PROFILE:-certs/dev.mobileprovision}"
P12_PASSWORD_FILE="${P12_PASSWORD_FILE:-certs/p12-password}"
export THEOS="${THEOS:-$HOME/theos}"

UNSIGNED="packages/PSInstagram-unsigned.ipa"
SIGNED="packages/PSInstagram-signed.ipa"

CLEAN=0
INSTALL=1
for arg in "$@"; do
    case "$arg" in
        --clean) CLEAN=1 ;;
        --no-install) INSTALL=0 ;;
        *) echo "Unknown option: $arg"; exit 1 ;;
    esac
done

step() { echo -e "\033[1m\033[32m==> $1\033[0m"; }
fail() { echo -e "\033[1m\033[0;31m$1\033[0m"; exit 1; }

# Prerequisites
for tool in make cyan zsign xcrun; do
    command -v "$tool" >/dev/null || fail "$tool not found"
done
[ -d "$THEOS" ] || fail "Theos not found at $THEOS"
[ -n "$(ls -A modules/FLEXing)" ] || fail "FLEXing submodule missing, run: git submodule update --init --recursive"
for file in "$IPA" "$P12" "$PROFILE" "$P12_PASSWORD_FILE"; do
    [ -f "$file" ] || fail "$file not found"
done

# Own bundle ID, so it installs next to the official app and other sideloaded apps.
# The signature still uses the profile's app ID; iOS only requires that one to match.
BUNDLE_ID="${BUNDLE_ID:-com.pstepanovum.psinstagram}"

# Build
if [ "$CLEAN" == 1 ]; then
    step "Cleaning"
    make clean
    rm -rf .theos
fi

step "Building PSInstagram"
make SIDELOAD=1

# Inject (no ipapatch: PSInstagram's own sideload fixes replace it)
step "Injecting into Instagram"
rm -f "$UNSIGNED" "$SIGNED"
cyan -i "$IPA" -o "$UNSIGNED" -f .theos/obj/debug/PSInstagram.dylib .theos/obj/debug/FLEXing.dylib .theos/obj/debug/libflex.dylib -c 0 -m 15.0 -du

# App extensions would each need their own bundle ID in the profile
zip -q -d "$UNSIGNED" 'Payload/Instagram.app/PlugIns/*' 'Payload/Instagram.app/Extensions/*' || true

# Minimal entitlements from the profile. Some reseller profiles grant wildcards as plain strings
# (e.g. associated-domains = "*"), which crash system frameworks that expect arrays.
ENTITLEMENTS="$(mktemp -t entitlements).plist"
security cms -D -i "$PROFILE" | python3 -c '
import plistlib, sys
keep = {"application-identifier", "com.apple.developer.team-identifier", "keychain-access-groups", "get-task-allow", "aps-environment"}
entitlements = plistlib.loads(sys.stdin.buffer.read())["Entitlements"]
with open(sys.argv[1], "wb") as file:
    plistlib.dump({key: value for key, value in entitlements.items() if key in keep}, file)
' "$ENTITLEMENTS"

# Sign
step "Signing as $BUNDLE_ID"
zsign -k "$P12" -p "$(cat "$P12_PASSWORD_FILE")" -m "$PROFILE" -e "$ENTITLEMENTS" -b "$BUNDLE_ID" -o "$SIGNED" "$UNSIGNED"
rm -f "$ENTITLEMENTS"
rm -f "$UNSIGNED"

if [ "$INSTALL" == 0 ]; then
    step "Done: $SIGNED"
    exit
fi

# Install on the first connected physical iPhone, unless DEVICE is set
if [ -z "$DEVICE" ]; then
    DEVICE_JSON="$(mktemp)"
    xcrun devicectl list devices --json-output "$DEVICE_JSON" >/dev/null
    DEVICE="$(python3 -c '
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
for device in devices:
    hardware = device.get("hardwareProperties", {})
    if hardware.get("reality") == "physical" and hardware.get("deviceType") == "iPhone":
        print(hardware["udid"])
        break
' "$DEVICE_JSON")"
    rm -f "$DEVICE_JSON"
fi
[ -n "$DEVICE" ] || fail "No connected iPhone found (set DEVICE to choose one)"

step "Installing on $DEVICE"
if ! xcrun devicectl device install app --device "$DEVICE" "$SIGNED"; then
    # Upgrading over a previous sideloaded install can fail; a clean install works.
    # PSInstagram restores its settings from the keychain, but Instagram needs a new login.
    step "Upgrade failed, reinstalling"
    xcrun devicectl device uninstall app --device "$DEVICE" "$BUNDLE_ID"
    xcrun devicectl device install app --device "$DEVICE" "$SIGNED"
fi

step "Done"
