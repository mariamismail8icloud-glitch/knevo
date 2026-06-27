#!/usr/bin/env bash
#
# Seed ONE completed session with sensor data for the demo patient, so the
# doctor's sensor graphs have content (independent of any live device). Drives
# the real patient API end-to-end. Safe to run more than once (adds sessions).
#
#   ./deploy/seed-session.sh
#
set -euo pipefail
BASE="${KNEVO_BASE:-https://knevo.appscorner.com}"
PAT_EMAIL="patient.demo@knevo.test"; PAT_PW="Demo1234!"
j() { jq -r "$1"; }

TOK="$(curl -s -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$PAT_EMAIL\",\"password\":\"$PAT_PW\"}" | j '.accessToken')"
[ -n "$TOK" ] && [ "$TOK" != null ] || { echo "ERROR: patient login failed"; exit 1; }

PLAN="$(curl -s "$BASE/api/patient/active-plan" -H "Authorization: Bearer $TOK")"
CONFIG_ID="$(echo "$PLAN" | j '.id')"
SET_CFG_ID="$(echo "$PLAN" | j '.sets[0].id')"
echo "config=$CONFIG_ID set-config=$SET_CFG_ID"

SID="$(curl -s -X POST "$BASE/api/sessions/start" -H "Authorization: Bearer $TOK" \
  -H 'Content-Type: application/json' -d "{\"configId\":\"$CONFIG_ID\",\"painBefore\":2}" | j '.id')"
REC="$(curl -s -X POST "$BASE/api/sessions/$SID/start-set" -H "Authorization: Bearer $TOK" \
  -H 'Content-Type: application/json' -d "{\"therapySetConfigId\":\"$SET_CFG_ID\"}" | j '.id')"
echo "session=$SID set-record=$REC"

python3 - > /tmp/knevo_readings.json <<'PY'
import json, math, sys
n = 150
out = []
for i in range(n):
    ph = (i % 30) / 30.0                                  # ~3s gait cycle at 10ms/sample
    heel = 300 + 2600 * max(0.0, math.sin(ph * math.pi))            # heel-strike peak
    mid  = 250 + 2200 * max(0.0, math.sin((ph - 0.25) * math.pi))   # midfoot, phase-shifted
    out.append({"timestampUs": i*10000, "sampleId": i,
                "heelFsrRaw": min(4095, max(0, int(heel))),
                "midfootFsrRaw": min(4095, max(0, int(mid)))})
json.dump(out, sys.stdout)
PY

CODE="$(curl -s -o /tmp/knevo_sr.out -w '%{http_code}' -X POST \
  "$BASE/api/sessions/$SID/sets/$REC/sensor-readings" -H "Authorization: Bearer $TOK" \
  -H 'Content-Type: application/json' --data @/tmp/knevo_readings.json)"
echo "upload 150 readings -> HTTP $CODE $(head -c 200 /tmp/knevo_sr.out)"

curl -s -o /dev/null -w "stop-set -> %{http_code}\n" -X POST "$BASE/api/sessions/$SID/stop-set" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' \
  -d "{\"therapySetRecordId\":\"$REC\",\"painLevel\":3,\"feedback\":\"Felt good\"}"
curl -s -o /dev/null -w "complete -> %{http_code}\n" -X POST "$BASE/api/sessions/$SID/complete" \
  -H "Authorization: Bearer $TOK" -H 'Content-Type: application/json' -d "{\"painAfter\":2}"

rm -f /tmp/knevo_readings.json /tmp/knevo_sr.out
echo "seeded completed session $SID with 150 sensor readings"
