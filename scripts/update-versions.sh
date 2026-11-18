#!/usr/bin/env bash
# Updates the release version across user-facing references. Run with the new
# version WITHOUT the v prefix, e.g. scripts/update-versions.sh 3.1.0
# The release workflow runs this after creating the GitHub Release.
set -euo pipefail

NEW="${1:-}"
if [ -z "$NEW" ] || ! [[ "$NEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: scripts/update-versions.sh <version>   # e.g. 3.1.0" >&2
  exit 1
fi
OLD=$(grep -m1 -oE 'release-v[0-9]+\.[0-9]+\.[0-9]+' README.md | sed 's/release-v//' || true)
if [ -z "$OLD" ]; then OLD=$(grep -m1 -oE '\-\-version [0-9]+\.[0-9]+\.[0-9]+' README.md | awk '{print $2}'); fi
if [ -z "$OLD" ]; then
  echo "could not detect the current version" >&2
  exit 1
fi
if [ "$OLD" = "$NEW" ]; then
  echo "already at $NEW; nothing to update"
  exit 0
fi

FILES=(README.md compose/README.md docs/src/content/docs/installation/docker.md docs/src/content/docs/id/installation/docker.md docs/src/content/docs/installation/kubernetes.md docs/src/content/docs/id/installation/kubernetes.md)

for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    sed -i \
      -e "s/--branch v${OLD}/--branch v${NEW}/g" \
      -e "s/--version ${OLD}/--version ${NEW}/g" \
      -e "s/release-v${OLD}/release-v${NEW}/g" \
      -e "s/Release \*\*v${OLD}\*\*/Release **v${NEW}**/g" \
      -e "s/kang-${OLD}\.tgz/kang-${NEW}.tgz/g" \
      -e "s|oci://ghcr.io/zaidanm16/kang:${OLD}|oci://ghcr.io/zaidanm16/kang:${NEW}|g" \
      -e "s/\`git tag v${OLD}\`/\`git tag v${NEW}\`/g" \
      -e "s/git push origin v${OLD}/git push origin v${NEW}/g" \
      "$f"
    echo "updated $f"
  fi
done

echo "version references updated: ${OLD} -> ${NEW}"
echo "Commit the changes, merge via PR, then push the matching v${NEW} tag to publish the release."
