# Simulation Scripts

These scripts generate the attack telemetry used to validate the detection content in this repo. They wrap well-known, publicly documented security-testing tools (Hydra, Impacket, dnscat2) — nothing here is custom exploit code.

## Safety requirements — read before running anything

- **Lab-only.** Run these only inside an isolated, non-production network you own (see [../docs/architecture.md](../docs/architecture.md)), against hosts you control, with credentials you created for that purpose.
- **Never** point these at any host, account, or network you do not own or do not have explicit written authorization to test.
- Treat every target IP/hostname/credential in these scripts as a placeholder — replace with your own lab values before running.
- Disable Wazuh active response (or any auto-blocking) before a run if you want the full attack sequence to complete and generate telemetry; re-enable it afterward.

## Requirements

- `hydra` (brute-force script)
- `impacket` (`pip install impacket`) for `psexec.py` / `wmiexec.py` (lateral-movement script)
- `dnscat2` (`gem install dnscat2` or build from source) for the DNS-tunneling portion of the exfiltration script

## Scripts

| Script | Purpose |
|---|---|
| `simulate_bruteforce.sh` | Runs an SSH and RDP credential attack against lab targets using a small test wordlist |
| `simulate_lateral_movement.sh` | Uses Impacket's `wmiexec.py`/`psexec.py` to move from one compromised lab host to another |
| `simulate_exfiltration.py` | Archives a test file and exfiltrates it via a DNS-tunneling channel and a large HTTP upload |
