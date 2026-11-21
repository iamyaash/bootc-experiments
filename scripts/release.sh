#!/usr/bin/env bash
# Ship a new scout build: pin its checksum, upload it, build and push the image.
# Usage: scripts/release.sh [path to scout-linux-arm64]
# Default source is jobwish's dist/. Fails if any step ends up with a different file.
set -euo pipefail

cd "$(dirname "$0")/.."
SRC="${1:-../../gitlab/jobwish/dist/scout-linux-arm64}"
REPO=iamyaash/bootc-experiments

test -f "$SRC" || { echo "missing $SRC" >&2; exit 1; }
file "$SRC" | grep -q 'ARM aarch64' || { echo "$SRC is not an arm64 binary" >&2; exit 1; }

mkdir -p bin
cp "$SRC" bin/scout-linux-arm64
(cd bin && sha256sum scout-linux-arm64) > scout.sha256
want=$(cut -d' ' -f1 scout.sha256)
echo "scout $want"

if git diff --quiet -- scout.sha256 && git ls-files --error-unmatch scout.sha256 >/dev/null 2>&1; then
    echo "scout.sha256 unchanged: this build is already pinned" >&2
else
    git add scout.sha256
    git commit -qm "bump scout to ${want:0:12}"
fi
git push -q "https://github.com/$REPO.git" HEAD:main

gh release upload binaries bin/scout-linux-arm64 --clobber -R "$REPO"
got=$(gh release download binaries -p scout-linux-arm64 -R "$REPO" -O - | sha256sum | cut -d' ' -f1)
[ "$got" = "$want" ] || { echo "release asset is $got, expected $want" >&2; exit 1; }

gh workflow run build.yml -R "$REPO" -f sd_image=false
sleep 8
id=$(gh run list -R "$REPO" --workflow build.yml -L1 --json databaseId --jq '.[0].databaseId')
echo "watching run $id"
gh run watch "$id" -R "$REPO" --exit-status >/dev/null

label=$(skopeo inspect "docker://ghcr.io/iamyaash/bootc-experiments-rpi5:unstable" \
    --format '{{index .Labels "io.github.iamyaash.scout.sha256"}}')
[ "$label" = "$want" ] || { echo "ghcr :unstable has scout $label, expected $want" >&2; exit 1; }
echo "ghcr.io/iamyaash/bootc-experiments-rpi5:unstable has scout $want. Ready for bootc upgrade."
