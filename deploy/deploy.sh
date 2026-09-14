#!/usr/bin/env bash
#
# Knevo server-side deploy — runs ON the droplet. Pushed + invoked by
# build-and-push.sh. Picks up artifacts from /opt/knevo/incoming, backs up the
# DB, swaps jar + web, restarts the backend (Flyway migrates on startup).
#
set -euo pipefail

APP=/opt/knevo
WEB=/var/www/knevo
INC="$APP/incoming"
BK="$APP/backups"
TS="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$BK"
echo "[deploy] backing up database"
sudo -u postgres pg_dump knevo | gzip > "$BK/knevo-$TS.sql.gz" \
  || echo "[deploy] WARN: pg_dump failed (ok on the very first deploy)"
# keep only the last 10 backups
ls -1t "$BK"/knevo-*.sql.gz 2>/dev/null | tail -n +11 | xargs -r rm -f

if [ -f "$INC/knevo-backend.jar" ]; then
  sz="$(stat -c%s "$INC/knevo-backend.jar" 2>/dev/null || echo 0)"
  # Guard against a truncated upload (the fat jar is ~58MB). Refuse anything
  # implausibly small rather than installing a corrupt jar.
  if [ "$sz" -lt 52428800 ]; then
    echo "[deploy] ERROR: incoming jar is only $sz bytes (<50MB) — truncated upload; aborting (keeping current jar)"
    exit 1
  fi
  echo "[deploy] installing backend jar ($sz bytes)"
  mv "$INC/knevo-backend.jar" "$APP/knevo-backend.jar"
  chown knevo:knevo "$APP/knevo-backend.jar"
fi

if [ -f "$INC/web.tar.gz" ]; then
  echo "[deploy] installing web files"
  rm -rf "${WEB:?}/"*
  tar -xzf "$INC/web.tar.gz" -C "$WEB"
  rm -f "$INC/web.tar.gz"
fi

echo "[deploy] restarting backend (Flyway runs migrations on startup)"
systemctl restart knevo-backend

echo "[deploy] waiting for backend on :8080"
ok=0
for _ in $(seq 1 45); do
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 4 -X POST http://127.0.0.1:8080/api/auth/login 2>/dev/null)"
  if [ -n "$code" ] && [ "$code" != "000" ]; then ok=1; echo "[deploy] backend up (HTTP $code)"; break; fi
  sleep 2
done
if [ "$ok" != 1 ]; then
  echo "[deploy] ERROR: backend did not come up. Recent logs:"
  journalctl -u knevo-backend -n 50 --no-pager
  exit 1
fi

nginx -t && systemctl reload nginx
echo "[deploy] OK -> https://knevo.appscorner.com"
