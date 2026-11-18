#!/usr/bin/env bash
# Syncs the chart with the latest releases of kang-frontend and kang-backend.
# Prints the new chart version when a bump was applied; prints nothing and
# exits 0 when everything is up to date. Requires gh and GH_TOKEN when run in
# CI; locally the gh CLI credentials are used.
set -euo pipefail

OWNER="${GITHUB_REPOSITORY_OWNER:-zaidanm16}"
FE=$(gh api "repos/$OWNER/kang-frontend/releases/latest" --jq '.tag_name' 2>/dev/null | sed 's/^v//') || FE=""
BE=$(gh api "repos/$OWNER/kang-backend/releases/latest" --jq '.tag_name' 2>/dev/null | sed 's/^v//') || BE=""
if [ -z "$FE" ] || [ -z "$BE" ]; then
  echo "could not read latest component releases; skipping sync" >&2
  exit 0
fi

CHART=$(awk '/^version:/ {print $2}' charts/kang/Chart.yaml)
APP=$(awk '/^appVersion:/ {print $2}' charts/kang/Chart.yaml | tr -d '"')
BE_TAG=$(sed -n '/repository: ghcr.io\/zaidanm16\/kang-backend/,+2 s/.*tag: v\([0-9.]*\).*/\1/p' charts/kang/values.yaml | head -1)

FE_CHANGED=$([ "$FE" != "$APP" ] && echo yes || echo no)
BE_CHANGED=$([ "$BE" != "$BE_TAG" ] && echo yes || echo no)
if [ "$FE_CHANGED" = no ] && [ "$BE_CHANGED" = no ]; then
  echo "up to date (frontend $FE, backend $BE)"
  exit 0
fi

if [ "$FE_CHANGED" = yes ]; then
  NEW="$FE"
else
  # Backend-only change: ship it as a patch bump of the current chart version.
  NEW=$(echo "$CHART" | awk -F. '{print $1"."$2"."$3+1}')
fi
echo "syncing: frontend $APP -> $FE, backend $BE_TAG -> $BE, chart $CHART -> $NEW"

sed -i "s/^version: .*/version: $NEW/" charts/kang/Chart.yaml
if [ "$FE_CHANGED" = yes ]; then
  sed -i "s/^appVersion: .*/appVersion: \"$FE\"/" charts/kang/Chart.yaml
fi
sed -i "/repository: ghcr.io\/zaidanm16\/kang-frontend/,+2 s/tag: v[0-9.]*/tag: v$FE/" charts/kang/values.yaml
sed -i "s/kang-frontend:v[0-9.]*/kang-frontend:v$FE/; s/kang-frontend:[0-9][0-9.]*/kang-frontend:$FE/" \
  compose/.env.example compose/compose.yaml docs/src/content/docs/installation/docker.md docs/src/content/docs/id/installation/docker.md
sed -i "s/frontend version \`[0-9.]*\`/frontend version \`$FE\`/" README.md
sed -i "s/AppVersion: [0-9.]*/AppVersion: $FE/; s/badge\/AppVersion-[0-9.]*/badge\/AppVersion-$FE/" charts/kang/README.md
sed -i "/repository: ghcr.io\/zaidanm16\/kang-backend/,+2 s/tag: v[0-9.]*/tag: v$BE/" charts/kang/values.yaml
sed -i "s/kang-backend:v[0-9.]*/kang-backend:v$BE/; s/kang-backend:[0-9][0-9.]*/kang-backend:$BE/" \
  compose/.env.example compose/compose.yaml docs/src/content/docs/installation/docker.md docs/src/content/docs/id/installation/docker.md README.md

# Align install instructions and badge with the new chart version.
bash scripts/update-versions.sh "$NEW"
