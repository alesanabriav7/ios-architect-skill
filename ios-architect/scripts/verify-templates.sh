#!/usr/bin/env bash
# Proves the templates build and pass tests, in both default and MainActor-default isolation.
# Usage: scripts/verify-templates.sh [simulator name]   (default: iPhone 17 Pro)
set -euo pipefail

cd "$(dirname "$0")/../templates"
destination="platform=iOS Simulator,name=${1:-iPhone 17 Pro}"
derived="Derived/Verify"

tuist install
tuist generate --no-open

echo "== test (default isolation)"
xcodebuild test -workspace SampleApp.xcworkspace -scheme SampleApp \
  -destination "$destination" -derivedDataPath "$derived" -quiet

echo "== test (MainActor default isolation, approachable concurrency)"
TUIST_MAIN_ACTOR_DEFAULT=1 tuist generate --no-open
xcodebuild test -workspace SampleApp.xcworkspace -scheme SampleApp \
  -destination "$destination" -derivedDataPath "$derived-mainactor" -quiet

tuist generate --no-open
echo "templates verified"
