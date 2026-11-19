#!/bin/bash
# Build a raw HFS+ volume image (case-sensitive) with the tree in rootfs/tree.
# Runs on the macOS CI runner. Output: rootfs/out/root-hfs.img.gz
#
# hdiutil always produces a whole-disk image (GPT + Apple_HFS slice), so we
# populate the slice and then dd the *partition* bytes out to get a plain
# volume, which is what the XNU ramdisk (--ramdisk + rd=md0) must contain.
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

# Newer hdiutil escapes the slashes in device paths (\/dev\/disk5s1).
INFO=$(hdiutil attach -nomount "$DMG" | tr -d '\\')
echo "$INFO"
WHOLE=$(echo "$INFO" | awk '/^\/dev\/disk/ {print $1}' | head -1)
SLICE=$(echo "$INFO" | awk '/^\/dev\/disk/ && /s[0-9]+/ {print $1}' | tail -1)
[ -n "$SLICE" ] || { echo "no partition slice found" >&2; exit 1; }

mount -t hfs "$SLICE" "$PWD/mnt"
rsync -aH "$PWD/tree/" "$PWD/mnt/"
sudo chown -R 0:0 "$PWD/mnt/"
# exec bits: everything in this bring-up tree must be runnable (EACCES on
# /sbin/launchd killed the first HFS-root boot).
sudo chmod -R 755 "$PWD/mnt/"
# skeleton dirs (git cannot carry empty directories; devfs needs /dev).
for d in dev tmp private private/etc private/var private/var/tmp \
         private/var/log private/var/root private/var/mobile \
         usr usr/lib usr/bin usr/sbin usr/libexec usr/share \
         System System/Library Library Applications; do
    sudo mkdir -p "$PWD/mnt/$d"
done
sudo chown -R 0:0 "$PWD/mnt/"
sudo chmod -R 755 "$PWD/mnt/"
sync
ls -la "$PWD/mnt" "$PWD/mnt/sbin" || true
df -h "$PWD/mnt" || true
umount "$PWD/mnt"

RAWDEV="/dev/rdisk${SLICE##*disk}"
dd if="$RAWDEV" of="$RAW" bs=1m
hdiutil detach "$WHOLE" || true
ls -la "$RAW"
test -s "$RAW"
gzip -9 -c "$RAW" > out/root-hfs.img.gz
ls -la out/
