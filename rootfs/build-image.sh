#!/bin/bash
# Build an HFS+ image (case-sensitive) containing the tree in rootfs/tree.
# Runs on the macOS CI runner: hdiutil/newfs_hfs are native there.
# Output: out/root-hfs.img.gz
set -euo pipefail
cd "$(dirname "$0")"
SIZE="${1:-64m}"
VOL="${2:-iOSRoot}"
rm -rf out build; mkdir -p out build
IMG="$PWD/build/root-hfs.img"
hdiutil create -size "$SIZE" -fs 'Case-sensitive HFS+' -volname "$VOL" -o "$PWD/build/root" "$IMG" >/dev/null
MNT="$PWD/build/mnt"
mkdir -p "$MNT"
hdiutil attach "$IMG" -mountpoint "$MNT" -nobrowse >/dev/null
# copy preserving modes, ownership and symlinks as root
sudo rsync -aH --numeric-ids "$PWD/tree/" "$MNT/"
sync
sudo chown -R 0:0 "$MNT/" 2>/dev/null || true
hdiutil detach "$MNT" >/dev/null
ls -la "$IMG"
gzip -9 -c "$IMG" > out/root-hfs.img.gz
ls -la out/
