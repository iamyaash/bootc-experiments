#!/usr/bin/env bash
# Build the image and an SD card image from it. Run on an arm64 host.
# Usage: scripts/build.sh [path to hummingbird-rpi5 checkout]
set -euo pipefail

cd "$(dirname "$0")/.."
UPSTREAM="${1:-../hummingbird-rpi5}"
TAG=localhost/bootc-experiments-rpi5:latest

for b in scout applier; do
    test -f "bin/$b-linux-arm64" || { echo "missing bin/$b-linux-arm64" >&2; exit 1; }
done
test -x "$UPSTREAM/scripts/build-sd-image.sh" \
    || { echo "clone https://github.com/iamyaash/hummingbird-rpi5 to $UPSTREAM" >&2; exit 1; }

sudo podman build -t "$TAG" -f Containerfile .
sudo "$UPSTREAM/scripts/build-sd-image.sh" "$TAG" "$TAG" bootc-experiments-rpi5.raw
