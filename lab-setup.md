# Lab Setup

Build notes for standing the environment back up from scratch.

## 1. Virtualization layer

- Hypervisor: VMware Workstation / VirtualBox (either works; the lab was built on VMware Workstation Pro)
- 3 isolated virtual networks (host-only / internal):
  - `ATTACK_NET` — Kali Linux only
  - `TARGET_NET` — Windows + Linux targets
  - `MGMT_NET` — Splunk, Elastic, Wazuh manager, Security Onion
- A virtual switch/tap mirrors `TARGET_NET` traffic to Security Onion's monitor interface

## 2. Hosts

| Host | OS | Role | Agents installed |
|---|---|---|---|
| kali | Kali Linux | Attacker | — |
| win-dc01 | Windows Server | Domain controller + target | Sysmon, Wazuh agent, Splunk UF, Elastic Agent |
| win-ws01 | Windows 10 | Workstation target | Sysmon, Wazuh agent, Splunk UF, Elastic Agent |
| lin-srv01 | Ubuntu Server | Linux target | auditd, Wazuh agent, Splunk UF |
| seconion | Security Onion (standalone) | Network sensor | — |
| splunk | Linux | Splunk (single instance, indexer + search head) | — |
| elastic | Linux | Elasticsearch + Kibana + Fleet server | — |
| wazuh-mgr | Linux | Wazuh manager + indexer + dashboard | — |

## 3. Endpoint instrumentation

### Sysmon (Windows targets)

- Installed with the [SwiftOnSecurity Sysmon config](https://github.com/SwiftOnSecurity/sysmon-config) as a baseline, then tuned to reduce noise from normal domain traffic.
- Key event IDs used throughout the detections in this repo: `1` (process creation), `3` (network connection), `8` (CreateRemoteThread), `11` (file create), `13` (registry value set), `22` (DNS query).

### auditd (Linux targets)

- Rules added for `execve` syscalls, SSH auth log monitoring, and sudo usage, forwarded via `rsyslog` to Splunk.

### Wazuh agents

- Installed on all Windows and Linux targets, enrolled against the Wazuh manager.
- Active response disabled during simulations (so attack traffic isn't auto-blocked before telemetry is generated), re-enabled afterward.

## 4. SIEM onboarding

### Splunk

- Splunk Enterprise (single-instance lab deployment).
- Technology add-ons installed: Splunk Add-on for Sysmon, Splunk Add-on for Microsoft Windows, Splunk Add-on for Unix and Linux, Splunk Add-on for AWS.
- Universal Forwarders on each target point at the indexer; Wazuh and Security Onion alerts forwarded via syslog/HEC.

### Elastic SIEM

- Elastic Agent + Fleet used to onboard Windows/Linux hosts with the relevant integrations (Windows, System, Custom Logs).
- Elastic Security's detection engine enabled to run the rules in `elastic/detection_rules/` alongside Splunk's saved searches, for a side-by-side comparison.

### Wazuh

- Default ruleset left enabled; custom rules in `wazuh/local_rules.xml` added on top for the specific attack chains simulated here.

### Security Onion

- Deployed in "standalone" mode.
- Zeek enabled for connection/DNS/HTTP/SSL logs; Suricata enabled with the ET Open ruleset for signature-based network alerts.

## 5. AWS

- A single low-privilege AWS account with CloudTrail (management + data events) and VPC Flow Logs enabled.
- Logs shipped to an S3 bucket, pulled into Splunk with the AWS Add-on's S3 input (SQS-based).
- Used only to practice cloud-native detections (unusual `ConsoleLogin`, `AssumeRole`, and IAM changes) — not wired into the on-prem attack simulations.

## 6. Generating attack telemetry

See [docs/attack-simulations.md](docs/attack-simulations.md) and the scripts in [scripts/](../scripts/) for how each attack chain was run against this environment.
