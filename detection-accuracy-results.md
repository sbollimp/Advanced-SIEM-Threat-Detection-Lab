# Detection Accuracy Results

## Methodology

1. **Baseline pass** — each of the three attack chains (brute-force, lateral movement, exfiltration) was run 25 times against the lab using only out-of-the-box detections (default Wazuh ruleset, a handful of single-event Splunk searches, no Sigma/YARA content).
2. **Logging and labeling** — every run was logged with a timestamp and technique label so each resulting alert (or non-alert) could be matched back to a known-true attack event. This gives a ground truth set for computing true positives, false negatives, and false positives.
3. **Tuning pass** — the Sigma rules, YARA signatures, and Wazuh/Elastic custom rules in this repo were written and iterated against the false negatives and false positives from the baseline, specifically:
   - Replacing single-event auth-failure alerts with threshold/correlation logic (N failures from one source within a time window, followed by a success)
   - Adding process-ancestry conditions to lateral-movement rules (e.g. `svchost.exe` spawning `cmd.exe` via a remote service) to cut noisy false positives from legitimate admin tooling
   - Adding DNS query-length/entropy and query-volume conditions for the tunneling detection, since a plain "DNS query seen" rule was far too noisy
   - Correlating network (Security Onion/Zeek) and endpoint (Sysmon) telemetry for the same event instead of relying on one source
4. **Validation pass** — the same 25-runs-per-technique test was repeated with the tuned rule set in place, and the two passes were compared.

## Results

| Attack chain | Baseline TP rate | Baseline FP count (per 25 runs) | Tuned TP rate | Tuned FP count (per 25 runs) |
|---|---|---|---|---|
| Brute-force access | 64% | 9 | 96% | 2 |
| Lateral movement | 48% | 14 | 88% | 3 |
| Data exfiltration | 40% | 11 | 84% | 2 |
| **Overall** | **~51%** | **34** | **~89%** | **7** |

**Detection accuracy** here is defined as `TP / (TP + FN)` — the share of true attack events that produced a correct, correctly-labeled alert — averaged across the three attack chains and weighted by run count.

- Baseline overall accuracy: **~51%**
- Tuned overall accuracy: **~89%**
- **Net improvement: ~52% relative increase** (`(0.89 - 0.51) / 0.51 ≈ 0.52`)
- False positives dropped from 34 to 7 across the same 75 total runs (25 × 3 techniques), an 80% reduction — the main lever for this was moving from single-event to correlation-based logic.

## Takeaways

- Most of the baseline's missed detections weren't missing log sources — they were single-event rules that couldn't tell a real multi-stage intrusion apart from one noisy admin action. Correlation and process-ancestry conditions closed most of that gap.
- The largest accuracy jump came from lateral movement (48% → 88%), which also had the noisiest baseline — legitimate remote administration (RDP, WinRM, scheduled tasks from the actual domain admin account) looks very similar to PsExec/WMI lateral movement unless you add ancestry and account-context conditions.
- DNS-tunneling detection needed query-entropy and per-source query-volume thresholds; a naive "alert on any TXT/CNAME query to an unusual domain" rule produced far too many false positives from normal background DNS traffic to be usable.
