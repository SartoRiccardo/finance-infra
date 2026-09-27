#!/usr/bin/env bash
# Downloads the dist.zip attached to a tagged GitHub release of finance-front
# (built by its release workflow on every tag push), unpacks it into
# ./frontend-dist, and - if CADDY_DIR is set (see .env) - copies it straight into
# the central Caddy's roots/finance, plus copies Caddyfile into its sites/,
# and reloads Caddy. No symlinks: Caddy runs in its own container and can only
# see paths actually bind-mounted into it, so anything it needs has to be a real
# file inside its own directory tree, not a symlink pointing elsewhere on the host.
#
# Usage: ./update-frontend.sh 1.0.0
#    or: FRONTEND_TAG=1.0.0 ./update-frontend.sh
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
[ -f .env ] && source .env

TAG="${1:-${FRONTEND_TAG:-}}"
if [ -z "$TAG" ]; then
	echo "usage: $0 <tag>  (or set FRONTEND_TAG)" >&2
	exit 1
fi

REPO="SartoRiccardo/finance-front"
OUT_DIR="frontend-dist"
ASSET_URL="https://github.com/${REPO}/releases/download/${TAG}/dist.zip"

TMP_ZIP="$(mktemp)"
trap 'rm -f "$TMP_ZIP"' EXIT

curl -fL -o "$TMP_ZIP" "$ASSET_URL"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
unzip -q "$TMP_ZIP" -d "$OUT_DIR"

echo "frontend-dist updated to tag $TAG"

if [ -n "${CADDY_DIR:-}" ]; then
	mkdir -p "$CADDY_DIR/roots/finance"
	rsync -a --delete "$OUT_DIR/" "$CADDY_DIR/roots/finance/"
	cp Caddyfile "$CADDY_DIR/sites/finance.Caddyfile"
	echo "copied into $CADDY_DIR (roots/finance, sites/finance.Caddyfile)"

	if docker inspect caddy >/dev/null 2>&1; then
		docker exec caddy caddy reload --config /etc/caddy/Caddyfile
		echo "caddy reloaded"
	fi
else
	echo "CADDY_DIR not set in .env - skipping copy into the central Caddy dir"
fi
