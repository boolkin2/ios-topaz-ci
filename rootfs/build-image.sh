#!/bin/bash
# Build a raw HFS+ image (case-sensitive) with the tree in rootfs/tree.
# Runs on the macOS CI runner. Output: rootfs/out/root-hfs.img.gz
# A UDRW hdiutil image is an uncompressed raw volume: usable directly as the
# XNU ramdisk (--ramdisk) with rd=md0.
# Usage: build-image.sh [SIZEMB] [VOLNAME]
set -euo pipefail
cd "$(dirname "$0")"
SIZEMB="${1:-24}"
VOL="${2:-iOSRoot}"
IMG="$PWD/build/root-hfs.img"

rm -rf out build mnt; mkdir -p out build mnt
hdiutil create -size "${SIZEMB}m" -fs "Case-sensitive HFS+" -volname "$VOL" \
    -format UDRW -nospotlight "$IMG"
hdiutil attach "$IMG" -mountpoint "$PWD/mnt" -nobrowse
rsync -aH "$PWD/tree/" "$PWD/mnt/"
sudo chown -R 0:0 "$PWD/mnt/"
sync
ls -la "$PWD/mnt" "$PWD/mnt/sbin" || true
hdiutil detach "$PWD/mnt"
ls -la "$IMG"
gzip -9 -c "$IMG" > out/root-hfs.img.gz
ls -la out/
