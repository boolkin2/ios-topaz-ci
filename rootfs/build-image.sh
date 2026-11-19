#!/bin/bash
# Build a raw HFS+ image (case-sensitive, journaled) with the tree in rootfs/tree.
# Runs on the macOS CI runner (newfs_hfs / hdiutil are native there).
# Usage: build-image.sh [SIZEMB] [VOLNAME]
# Output: rootfs/out/root-hfs.img.gz
set -euo pipefail
cd "$(dirname "$0")"
SIZEMB="${1:-24}"
VOL="${2:-iOSRoot}"

rm -rf out build; mkdir -p out build mnt
IMG="$PWD/build/root-hfs.img"

dd if=/dev/zero of="$IMG" bs=1m count="$SIZEMB"
newfs_hfs -s -J -v "$VOL" "$IMG"
hdiutil attach -imagekey diskimage-class=CRawDiskImage "$IMG" -mountpoint "$PWD/mnt" -nobrowse
rsync -aH "$PWD/tree/" "$PWD/mnt/"
sudo chown -R 0:0 "$PWD/mnt/"
sync
ls -la "$PWD/mnt" "$PWD/mnt/sbin" || true
hdiutil detach "$PWD/mnt"
ls -la "$IMG"
gzip -9 -c "$IMG" > out/root-hfs.img.gz
ls -la out/
