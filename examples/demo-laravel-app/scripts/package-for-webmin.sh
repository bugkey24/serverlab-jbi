#!/usr/bin/env bash
# ==============================================================================
# Package Script: Generate Deployment Artifacts for Track 1 (Webmin / No-SSH)
#
# Supports modes:
#   1. zip   : Standard ZIP archive (default)
#   2. targz : Standard .tar.gz archive (native Linux / Webmin)
#   3. dir   : Clean directory output (dist/serverlab-pulse)
#   4. all   : Generates all packaging formats
# ==============================================================================

set -euo pipefail

MODE="${1:-zip}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC_DIR="${APP_DIR}/src"
DIST_DIR="${APP_DIR}/dist"
TARGET_DIR="${DIST_DIR}/serverlab-pulse"
OUTPUT_ZIP="${APP_DIR}/serverlab-pulse.zip"
OUTPUT_TARGZ="${APP_DIR}/serverlab-pulse.tar.gz"

echo "=========================================================="
echo " ServerLab Pulse: Track 1 Deployment Packaging Utility"
echo " Mode   : ${MODE}"
echo " Source : ${SRC_DIR}"
echo "=========================================================="

echo -e "\n[1/3] Preparing clean distribution staging folder..."
rm -rf "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

# Stage clean files
if command -v rsync &>/dev/null; then
    rsync -a --exclude='.git*' \
             --exclude='tests/' \
             --exclude='node_modules/' \
             --exclude='storage/logs/*.log' \
             --exclude='storage/framework/cache/data/*' \
             --exclude='storage/framework/sessions/*' \
             --exclude='storage/framework/views/*' \
             --exclude='*.sqlite' \
             --exclude='.env' \
             "${SRC_DIR}/" "${TARGET_DIR}/"
else
    cp -r "${SRC_DIR}"/* "${TARGET_DIR}/"
    rm -rf "${TARGET_DIR}/.git" "${TARGET_DIR}/tests" "${TARGET_DIR}/node_modules" 2>/dev/null || true
    rm -f "${TARGET_DIR}/.env" "${TARGET_DIR}/storage/logs/"*.log 2>/dev/null || true
fi

if [[ -f "${SRC_DIR}/.env.example" ]]; then
    cp "${SRC_DIR}/.env.example" "${TARGET_DIR}/.env.example"
fi
echo " Clean directory ready at: ${TARGET_DIR}"

if [[ "${MODE}" == "zip" || "${MODE}" == "all" ]]; then
    echo -e "\n[2/3] Generating Webmin-compatible ZIP archive: ${OUTPUT_ZIP}"
    rm -f "${OUTPUT_ZIP}"
    tar -a -c -f "${OUTPUT_ZIP}" -C "${TARGET_DIR}" . 2>/dev/null || (cd "${TARGET_DIR}" && zip -rq "${OUTPUT_ZIP}" .)
    echo " ZIP archive created: ${OUTPUT_ZIP}"
fi

if [[ "${MODE}" == "targz" || "${MODE}" == "all" ]]; then
    echo -e "\n[3/3] Generating native Linux tar.gz archive: ${OUTPUT_TARGZ}"
    rm -f "${OUTPUT_TARGZ}"
    tar -czf "${OUTPUT_TARGZ}" -C "${TARGET_DIR}" .
    echo " tar.gz archive created: ${OUTPUT_TARGZ}"
fi

echo -e "\n=========================================================="
echo " Production Preparation Reminder:"
echo " 1. Generate your fresh production APP_KEY manually using:"
echo "    echo \"base64:\$(openssl rand -base64 32)\""
echo " 2. In Webmin File Manager, copy .env.example to .env and insert the generated key."
echo "=========================================================="
