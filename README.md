# finance-infra

Deploy repo for finance: turns the prebuilt backend image and frontend dist into
a running service on the VPS, fronted by the central Caddy. Nothing is built
here — images come from GHCR, the frontend from GitHub release assets.

## Fresh-VPS setup

Prerequisites (shared with the other stacks on this box):

- Docker installed.
- The central Caddy container running, attached to an external Docker network
  named `reverse-proxy` (this compose file joins that network; see Caddyfile).
- A DNS record in Cloudflare for `finance.sarto.dev`, with the hostname's rule
  set to SSL mode "Full" (not Full strict — the origin serves a self-signed cert).
- A Google OAuth client whose authorized redirect URI includes
  `https://finance.sarto.dev/api/auth/google/callback`.

Then:

1. Clone this repo and `cd` into it.
2. `cp secrets/.env.api.example secrets/.env.api` and fill it in (session
   secret, Google OAuth credentials, LLM key, IMAP password).
3. `docker compose up -d` — starts the backend and its Postgres.
4. Once the first `finance-front` tag exists: `./update-frontend.sh X.Y.Z` to
   fetch the frontend into the central Caddy's web root and reload it.

## How releases work

- Push to `main` in `finance-back` or `finance-front` → CI builds and publishes
  the `:latest` image / attaches `dist.zip` to a `latest`-style release target.
- `git tag X.Y.Z && git push --tags` in either repo → a versioned image /
  versioned `dist.zip` release.
- This repo pins what runs: `BACKEND_IMAGE_TAG` in `.env` pins the backend
  image (default `latest`); the tag passed to `./update-frontend.sh` pins the
  frontend.
