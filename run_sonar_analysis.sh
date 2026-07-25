#!/usr/bin/env bash
# Script to run Flutter tests with coverage and SonarQube Scanner

HOST_URL="${1:-http://localhost:9000}"
TOKEN="${2:-$SONAR_TOKEN}"

echo "=========================================="
echo " 1. Running Flutter Tests with Coverage... "
echo "=========================================="
flutter test --coverage

echo ""
echo "=========================================="
echo " 2. Running SonarQube Scanner...           "
echo "=========================================="

SONAR_CMD="sonar-scanner -Dsonar.host.url=${HOST_URL}"
if [ -n "$TOKEN" ]; then
    SONAR_CMD="${SONAR_CMD} -Dsonar.token=${TOKEN}"
fi

eval $SONAR_CMD
