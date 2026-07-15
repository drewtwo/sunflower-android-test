#!/usr/bin/env bash
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# check_coverage.sh
#
# Runs Flutter tests with coverage collection, generates an lcov report,
# and checks that the coverage meets the minimum threshold (default: 60%).
#
# Usage:
#   ./scripts/check_coverage.sh [--threshold <percent>] [--open]
#
# Options:
#   --threshold <percent>   Minimum coverage percentage (default: 60)
#   --open                  Open the HTML report in a browser after generation
#   --help                  Show this help message
#
# Examples:
#   ./scripts/check_coverage.sh
#   ./scripts/check_coverage.sh --threshold 70
#   ./scripts/check_coverage.sh --open

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
THRESHOLD=60
OPEN_REPORT=false
COVERAGE_DIR="coverage"
LCOV_FILE="${COVERAGE_DIR}/lcov.info"
FILTERED_LCOV_FILE="${COVERAGE_DIR}/lcov_filtered.info"
HTML_DIR="${COVERAGE_DIR}/html"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    --open)
      OPEN_REPORT=true
      shift
      ;;
    --help)
      head -n 35 "$0" | grep "^#" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
check_dependency() {
  if ! command -v "$1" &>/dev/null; then
    echo "❌ Required tool '$1' not found."
    echo "   Install with: $2"
    exit 1
  fi
}

check_dependency flutter "See https://flutter.dev/docs/get-started/install"
check_dependency lcov    "sudo apt-get install lcov  OR  brew install lcov"
check_dependency genhtml "Included with lcov package"

# ---------------------------------------------------------------------------
# Step 1: Run tests with coverage
# ---------------------------------------------------------------------------
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧪 Running Flutter tests with coverage..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "${COVERAGE_DIR}"

flutter test \
  --coverage \
  --coverage-path="${LCOV_FILE}" \
  --reporter=expanded

echo ""
echo "✅ Tests completed. Coverage data written to ${LCOV_FILE}"

# ---------------------------------------------------------------------------
# Step 2: Filter out generated files
# ---------------------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔧 Filtering generated files from coverage..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

lcov \
  --remove "${LCOV_FILE}" \
  '**/*.g.dart' \
  '**/*.freezed.dart' \
  '**/generated/**' \
  --output-file "${FILTERED_LCOV_FILE}" \
  --quiet

echo "✅ Filtered coverage written to ${FILTERED_LCOV_FILE}"

# ---------------------------------------------------------------------------
# Step 3: Generate HTML report
# ---------------------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📊 Generating HTML coverage report..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

genhtml \
  "${FILTERED_LCOV_FILE}" \
  --output-directory "${HTML_DIR}" \
  --title "Sunflower Flutter Coverage" \
  --quiet

echo "✅ HTML report generated at ${HTML_DIR}/index.html"

# ---------------------------------------------------------------------------
# Step 4: Print summary
# ---------------------------------------------------------------------------
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📈 Coverage Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

lcov --summary "${FILTERED_LCOV_FILE}" 2>&1

# ---------------------------------------------------------------------------
# Step 5: Check threshold
# ---------------------------------------------------------------------------
COVERAGE=$(lcov --summary "${FILTERED_LCOV_FILE}" 2>&1 \
  | grep "lines" \
  | grep -oP '\d+\.\d+(?=%)' \
  | head -1)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🎯 Coverage Gate: ${COVERAGE}% (threshold: ${THRESHOLD}%)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if (( $(echo "${COVERAGE} < ${THRESHOLD}" | bc -l) )); then
  echo "❌ FAILED: Coverage ${COVERAGE}% is below the ${THRESHOLD}% threshold."
  echo ""
  echo "   To improve coverage:"
  echo "   1. Run: flutter test --coverage"
  echo "   2. Open: ${HTML_DIR}/index.html"
  echo "   3. Identify uncovered lines (shown in red)"
  echo "   4. Add tests for uncovered code"
  EXIT_CODE=1
else
  echo "✅ PASSED: Coverage ${COVERAGE}% meets the ${THRESHOLD}% threshold."
  EXIT_CODE=0
fi

# ---------------------------------------------------------------------------
# Step 6: Optionally open the report
# ---------------------------------------------------------------------------
if [[ "${OPEN_REPORT}" == "true" ]]; then
  echo ""
  echo "🌐 Opening coverage report..."
  if command -v xdg-open &>/dev/null; then
    xdg-open "${HTML_DIR}/index.html"
  elif command -v open &>/dev/null; then
    open "${HTML_DIR}/index.html"
  else
    echo "   Cannot open browser automatically. Open manually: ${HTML_DIR}/index.html"
  fi
fi

exit "${EXIT_CODE}"
