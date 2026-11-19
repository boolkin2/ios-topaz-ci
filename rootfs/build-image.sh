#!/bin/bash
# Build a raw HFS+ image (case-sensitive) with the tree in rootfs/tree.
# Runs on the macOS CI runner. Output: rootfs/out/root-hfs.img.gz
# The final UDRW conversion is an uncompressed raw volume, usable directly as
# the XNU ramdisk (--ramdisk) together with rd=md0.
# Usage: build-image.sh [SIZEMB] [VOLNAME]
set -euo pipefail
cd "$(dirname "$0")"
SIZEMB="${1:-24}"
VOL="${2:-iOSRoot}"
DMG="$PWD/build/root-hfs.dmg"
RAW="$PWD/build/root-hfs.img"

rm -rf out build mnt; mkdir -p out build mnt
hdiutil create -size "${SIZEMB}m" -fs "Case-sensitive HFS+" -volname "$VOL" \
    -nospotlight "$DMG"
hdiutil attach "$DMG" -mountpoint "$PWD/mnt" -nobrowse
rsync -aH "$PWD/tree/" "$PWD/mnt/"
sudo chown -R 0:0 "$PWD/mnt/"
sync
ls -la "$PWD/mnt" "$PWD/mnt/sbin" || true
hdiutil detach "$PWD/mnt"
# hdiutil convert always appends .dmg to -o, even for UDRW (which is a raw,
# uncompressed volume). Use whichever file appeared.
hdiutil convert "$DMG" -format UDRW -o "$RAW"
[ -f "$RAW" ] || RAW="$RAW.dmg"
ls -la "$RAW"
test -s "$RAW"
gzip -9 -c "$RAW" > out/root-hfs.img.gz
ls -la out/
