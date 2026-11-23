#!/usr/bin/env bash
# Syncs the chart with the latest releases of kang-frontend and kang-backend.
# Prints the new chart version when a bump was applied; prints nothing and
# exits 0 when everything is up to date. Component repos are private, so the
# versions are read from the public GHCR image tags (one per release).
set -euo pipefail

OWNER="${GITHUB_REPOSITORY_OWNER:-zaidanm16}"
latest_version() {
  local repo="$1" token
  token=$(curl -fsSL "https://ghcr.io/token?scope=repository:$OWNER/$repo:pull" 2>/dev/null | jq -r '.token // empty') || return 0
  [ -n "$token" ] || return 0
  curl -fsSL -H "Authorization: Bearer $token" "https://ghcr.io/v2/$OWNER/$repo/tags/list" 2>/dev/null |
    jq -r '.tags[] // empty' | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | sed 's/^v//' | sort -V | tail -1
}
FE=$(latest_version kang-frontend) || FE=""
BE=$(latest_version kang-backend) || BE=""
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

if [ "$FE_CHANGED" = yes ] && [ "$(printf '%s\n' "$CHART" "$FE" | sort -V | head -1)" != "$FE" ]; then
  NEW="$FE"
else
  # Backend-only or lagging frontend release: never reuse a published chart version.
  NEW=$(echo "$CHART" | awk -F. '{print $1"."$2"."$3+1}')
fi
echo "syncing: frontend $APP -> $FE, backend $BE_TAG -> $BE, chart $CHART -> $NEW" >&2

sed -i "s/^version: .*/version: $NEW/" charts/kang/Chart.yaml
if [ "$FE_CHANGED" = yes ]; then
  sed -i "s/^appVersion: .*/appVersion: \"$FE\"/" charts/kang/Chart.yaml
fi
sed -i "/repository: ghcr.io\/zaidanm16\/kang-frontend/,+2 s/tag: v[0-9.]*/tag: v$FE/" charts/kang/values.yaml
sed -i "s/kang-frontend:v[0-9.]*/kang-frontend:v$FE/; s/kang-frontend:[0-9][0-9.]*/kang-frontend:$FE/" \
  compose/.env.example compose/compose.yaml kubernetes/kang.yaml kubernetes/README.md \
  docs/src/content/docs/installation/docker.md docs/src/content/docs/id/installation/docker.md
sed -i "s/frontend version \`[0-9.]*\`/frontend version \`$FE\`/" README.md
sed -i '/^| frontend\.image\.tag |/s/`"v[0-9.]*"`/`"v'"$FE"'"`/' charts/kang/README.md
sed -i "s/AppVersion: [0-9.]*/AppVersion: $FE/; s/badge\/AppVersion-[0-9.]*/badge\/AppVersion-$FE/" charts/kang/README.md
sed -i "/repository: ghcr.io\/zaidanm16\/kang-backend/,+2 s/tag: v[0-9.]*/tag: v$BE/" charts/kang/values.yaml
sed -i "s/kang-backend:v[0-9.]*/kang-backend:v$BE/; s/kang-backend:[0-9][0-9.]*/kang-backend:$BE/" \
  compose/.env.example compose/compose.yaml docs/src/content/docs/installation/docker.md docs/src/content/docs/id/installation/docker.md README.md

# Align install instructions and badge with the new chart version.
bash scripts/update-versions.sh "$NEW" 1>&2
echo "$NEW"
