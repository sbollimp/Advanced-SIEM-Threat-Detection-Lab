#!/usr/bin/env bash
#
# simulate_bruteforce.sh
#
# Generates brute-force attack telemetry against SSH and RDP targets in an
# ISOLATED LAB NETWORK ONLY. See scripts/README.md before running this.
#
# Usage: ./simulate_bruteforce.sh <ssh_target_ip> <rdp_target_ip>

set -euo pipefail

SSH_TARGET="${1:-}"
RDP_TARGET="${2:-}"
WORDLIST="./wordlists/lab_test_wordlist.txt"   # small, lab-only test wordlist you provide
VALID_USER="labuser"                           # account created for this lab, with a known valid password in the wordlist

if [[ -z "$SSH_TARGET" || -z "$RDP_TARGET" ]]; then
    echo "Usage: $0 <ssh_target_ip> <rdp_target_ip>"
    echo "Only run against hosts in your own isolated lab network."
    exit 1
fi

echo "[*] Confirm this target is in your isolated lab network before continuing."
read -r -p "Type 'yes' to continue: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

echo "[*] Running SSH brute-force simulation against ${SSH_TARGET}"
hydra -l "$VALID_USER" -P "$WORDLIST" -t 4 -f "ssh://${SSH_TARGET}"

echo "[*] Running RDP brute-force simulation against ${RDP_TARGET}"
hydra -l "$VALID_USER" -P "$WORDLIST" -t 4 -f "rdp://${RDP_TARGET}"

echo "[*] Done. Check Splunk/Elastic/Wazuh for the resulting auth-failure + success telemetry."
