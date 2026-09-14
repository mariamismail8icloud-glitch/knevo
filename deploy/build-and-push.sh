#!/usr/bin/env bash
#
# Knevo local build + push — run from your Mac. Builds the backend jar and the
# web bundle, ships them to the droplet, and runs the server-side deploy.
# No GitHub Actions involved.
#
#   ./deploy/build-and-push.sh
#
# Override the target with: KNEVO_SERVER=root@1.2.3.4 ./deploy/build-and-push.sh
#
set -euo pipefail

SERVER="${KNEVO_SERVER:-root@157.245.33.241}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> [1/5] build backend jar"
( cd "$ROOT/knevo-backend" && ./gradlew clean bootJar -q )
JAR="$(ls "$ROOT"/knevo-backend/build/libs/*.jar | grep -v -- '-plain' | head -1)"
[ -f "$JAR" ] || { echo "ERROR: bootJar not found under knevo-backend/build/libs"; exit 1; }
echo "    $JAR"

echo "==> [2/5] build web (same-origin /api base)"
(
  cd "$ROOT/knevo-web"
  npm ci
  printf 'VITE_API_BASE_URL=\n' > .env.production.local   # empty -> relative /api via nginx
  npm run build
  rm -f .env.production.local
)
if grep -rq "localhost:8080" "$ROOT/knevo-web/dist" 2>/dev/null; then
  echo "ERROR: web build still references localhost:8080 — aborting"; exit 1
fi
tar -czf /tmp/knevo-web.tar.gz -C "$ROOT/knevo-web/dist" .

echo "==> [3/5] push artifacts to $SERVER (resilient — uplink can reset large transfers)"
SSH_KA='ssh -o ServerAliveInterval=10 -o ServerAliveCountMax=6'
ssh "$SERVER" 'mkdir -p /opt/knevo/incoming && rm -f /opt/knevo/incoming/knevo-backend.jar'
LOCAL_SZ="$(stat -f%z "$JAR" 2>/dev/null || stat -c%s "$JAR")"
jar_ok=0
for i in $(seq 1 30); do
  # --append-verify resumes where a reset left off, so the loop completes even on a flaky link
  rsync --partial --append-verify --timeout=40 --bwlimit=4000 -e "$SSH_KA" \
    "$JAR" "$SERVER:/opt/knevo/incoming/knevo-backend.jar" && { jar_ok=1; break; }
  echo "    jar transfer reset (attempt $i) — resuming..."; sleep 2
done
REMOTE_SZ="$(ssh "$SERVER" 'stat -c%s /opt/knevo/incoming/knevo-backend.jar 2>/dev/null || echo 0')"
[ "$jar_ok" = 1 ] && [ "$REMOTE_SZ" = "$LOCAL_SZ" ] || { echo "ERROR: jar upload incomplete ($REMOTE_SZ/$LOCAL_SZ)"; exit 1; }
echo "    jar uploaded + verified ($REMOTE_SZ bytes)"
$SSH_KA "$SERVER" 'cat > /opt/knevo/incoming/web.tar.gz' < /tmp/knevo-web.tar.gz
rm -f /tmp/knevo-web.tar.gz

echo "==> [4/5] push deploy script"
$SSH_KA "$SERVER" 'cat > /opt/knevo/deploy.sh' < "$ROOT/deploy/deploy.sh"

echo "==> [5/5] run server deploy"
$SSH_KA "$SERVER" 'bash /opt/knevo/deploy.sh'

echo "==> done -> https://knevo.appscorner.com"
