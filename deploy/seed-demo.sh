#!/usr/bin/env bash
#
# Seed demo data on the live server via the public API (idempotent).
# Creates an approved doctor, a patient, enrols the patient, and gives them an
# active plan with one device-assisted set. Doctor approval is done via the DB
# (doctors sign up PENDING).
#
#   ./deploy/seed-demo.sh
#
set -euo pipefail

BASE="${KNEVO_BASE:-https://knevo.appscorner.com}"
SERVER="${KNEVO_SERVER:-root@157.245.33.241}"

DOC_EMAIL="dr.demo@knevo.test";       DOC_PW="Demo1234!"
PAT_EMAIL="patient.demo@knevo.test";  PAT_PW="Demo1234!"

j() { jq -r "$1" 2>/dev/null; }

echo "==> [1] doctor signup (PENDING; 409 if already there)"
curl -s -o /dev/null -w "    signup/doctor -> %{http_code}\n" -X POST "$BASE/api/auth/signup/doctor" \
  -H 'Content-Type: application/json' -d "{
    \"username\":\"drdemo\",\"email\":\"$DOC_EMAIL\",\"password\":\"$DOC_PW\",
    \"name\":\"Dr. Demo\",\"phone\":\"+10000000001\",\"clinicName\":\"Knevo Demo Clinic\",
    \"specialization\":\"Physiotherapy\",\"professionalLicense\":\"LIC-DEMO-001\",\"yearsExperience\":8 }"

echo "==> [2] approve doctor (DB)"
ssh -o BatchMode=yes "$SERVER" "sudo -u postgres psql -d knevo -tAc \"UPDATE users SET doctor_status='APPROVED' WHERE email='$DOC_EMAIL'\""

echo "==> [3] doctor login"
DOC_TOKEN="$(curl -s -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$DOC_EMAIL\",\"password\":\"$DOC_PW\"}" | j '.accessToken')"
[ -n "$DOC_TOKEN" ] && [ "$DOC_TOKEN" != null ] || { echo "ERROR: doctor login failed"; exit 1; }
echo "    doctor token acquired"

echo "==> [4] patient signup (or login if exists)"
PAT_RESP="$(curl -s -X POST "$BASE/api/auth/signup" -H 'Content-Type: application/json' -d "{
    \"username\":\"patientdemo\",\"email\":\"$PAT_EMAIL\",\"password\":\"$PAT_PW\",
    \"name\":\"Demo Patient\",\"phone\":\"+10000000002\",\"gender\":\"OTHER\",
    \"birthDate\":\"1990-05-15\",\"emergencyContactName\":\"Next Of Kin\",
    \"emergencyContactPhone\":\"+10000000003\",\"consentGiven\":true }")"
PAT_ID="$(echo "$PAT_RESP" | j '.userId')"
PAT_CODE="$(echo "$PAT_RESP" | j '.enrollmentCode')"
if [ -z "$PAT_CODE" ] || [ "$PAT_CODE" = null ]; then
  echo "    patient exists; logging in"
  PAT_LOGIN="$(curl -s -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' \
    -d "{\"email\":\"$PAT_EMAIL\",\"password\":\"$PAT_PW\"}")"
  PAT_ID="$(echo "$PAT_LOGIN" | j '.userId')"
  PAT_TOKEN="$(echo "$PAT_LOGIN" | j '.accessToken')"
  PAT_CODE="$(curl -s "$BASE/api/patient/enrollment-code" -H "Authorization: Bearer $PAT_TOKEN" | j '.enrollmentCode')"
fi
echo "    patientId=$PAT_ID  enrollmentCode=$PAT_CODE"

echo "==> [5] doctor enrols patient (409 if already enrolled)"
curl -s -o /dev/null -w "    enroll -> %{http_code}\n" -X POST "$BASE/api/doctor/enroll-patient" \
  -H "Authorization: Bearer $DOC_TOKEN" -H 'Content-Type: application/json' \
  -d "{\"enrollmentCode\":\"$PAT_CODE\"}"

echo "==> [6] pick an exercise"
EX_ID="$(curl -s "$BASE/api/exercises" -H "Authorization: Bearer $DOC_TOKEN" | j '.[0].id')"
[ -n "$EX_ID" ] && [ "$EX_ID" != null ] || { echo "ERROR: no exercises found"; exit 1; }
echo "    exerciseId=$EX_ID"

echo "==> [7] create an active plan"
START="$(date +%F)"; END="$(date -v+30d +%F 2>/dev/null || date -d '+30 days' +%F)"
PLAN_CODE="$(curl -s -o /tmp/plan_resp.json -w '%{http_code}' -X POST "$BASE/api/doctor/patients/$PAT_ID/plans" \
  -H "Authorization: Bearer $DOC_TOKEN" -H 'Content-Type: application/json' -d "{
    \"title\":\"Knee Recovery — Demo\",\"goal\":\"Restore range of motion\",
    \"startDate\":\"$START\",\"endDate\":\"$END\",\"notes\":\"Demo plan\",
    \"maxSpeed\":6,\"maxExtensionAngleDeg\":5,\"maxFlexionAngleDeg\":60,
    \"sessionsPerWeek\":3,\"schedule\":\"MON,WED,FRI\",\"totalSessionsNum\":12,
    \"comment\":\"Auto-seeded demo plan\",\"patientId\":\"$PAT_ID\",
    \"sets\":[{\"exerciseId\":\"$EX_ID\",\"deviceAssisted\":true,\"durationMin\":5,\"restDurationMin\":2,\"setOrder\":0}] }")"
echo "    create plan -> HTTP $PLAN_CODE"
[ "$PLAN_CODE" = 200 ] || [ "$PLAN_CODE" = 201 ] || { echo "    plan body: $(cat /tmp/plan_resp.json)"; }
rm -f /tmp/plan_resp.json

echo "==> demo seed complete"
echo "    doctor:  $DOC_EMAIL / $DOC_PW"
echo "    patient: $PAT_EMAIL / $PAT_PW"
echo "    admin:   admin@knevo.com / Admin1234!"
