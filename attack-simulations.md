# Attack Simulations

Each simulated attack chain below was run from the Kali box against the lab's own targets, mapped to MITRE ATT&CK, and used to validate the detection content in this repo. None of this is run against anything outside the isolated lab network — see [scripts/README.md](../scripts/README.md).

## 1. Brute-force access

| | |
|---|---|
| **MITRE ATT&CK** | T1110 (Brute Force) — Sub-techniques T1110.001 (Password Guessing), T1110.003 (Password Spraying) |
| **Tooling** | Hydra, CrowBar (RDP), Medusa |
| **Targets** | SSH on `lin-srv01`, RDP on `win-ws01` |
| **Script** | [scripts/simulate_bruteforce.sh](../scripts/simulate_bruteforce.sh) |

**What happens:** a wordlist-based credential attack is run against SSH and RDP, generating a burst of authentication failures followed by a single success (the "success after many failures" pattern most brute-force detections key off).

**Detections exercised:**
- `sigma-rules/brute_force_ssh.yml`
- `sigma-rules/brute_force_rdp.yml`
- Wazuh default auth rules + `wazuh/local_rules.xml`

## 2. Lateral movement

| | |
|---|---|
| **MITRE ATT&CK** | T1021.002 (SMB/Windows Admin Shares), T1047 (WMI), T1569.002 (Service Execution — PsExec) |
| **Tooling** | Impacket (`psexec.py`, `wmiexec.py`), native `PsExec.exe` |
| **Targets** | `win-dc01` → `win-ws01` using credentials harvested in the brute-force stage |
| **Script** | [scripts/simulate_lateral_movement.sh](../scripts/simulate_lateral_movement.sh) |

**What happens:** having obtained valid credentials, the attacker moves from the first compromised host to a second, using both PsExec-style remote service creation and WMI process creation — the two most common lateral-movement techniques in real intrusions.

**Detections exercised:**
- `sigma-rules/lateral_movement_psexec.yml`
- `sigma-rules/lateral_movement_wmi.yml`
- `elastic/detection_rules/lateral_movement_wmi.toml`

## 3. Data exfiltration

| | |
|---|---|
| **MITRE ATT&CK** | T1048 (Exfiltration Over Alternative Protocol), T1071.004 (DNS), T1560 (Archive Collected Data) |
| **Tooling** | `dnscat2` (DNS tunneling), `tar` + `curl` (staged archive + outbound transfer) |
| **Targets** | `win-ws01` → external Kali listener |
| **Script** | [scripts/simulate_exfiltration.py](../scripts/simulate_exfiltration.py) |

**What happens:** data on the compromised workstation is archived, then exfiltrated two ways to validate different detection logic: a slow DNS-tunneling channel (small, encoded TXT/CNAME-style queries) and a large single outbound HTTP transfer.

**Detections exercised:**
- `sigma-rules/exfiltration_dns_tunneling.yml`
- `sigma-rules/exfiltration_large_outbound_transfer.yml`

## Attack chain, end to end

```
Brute-force (T1110) → Valid Accounts (T1078) → Lateral Movement (T1021/T1047) → Collection (T1560) → Exfiltration (T1048/T1071.004)
```

Running the full chain back-to-back (rather than each technique in isolation) is what the correlation-based Sigma rules and Splunk saved searches in this repo are built around — single-event detections caught the obvious failures, but it took chaining events across hosts and time windows to catch the full attack path reliably. That gap is what the tuning pass in [docs/detection-accuracy-results.md](detection-accuracy-results.md) was aimed at closing.
