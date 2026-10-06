# AWS Detection Notes

The lab includes a single low-privilege AWS account used only to practice cloud-side detection — it is not wired into the on-prem attack chain simulations.

## Log sources

- **CloudTrail** (management + S3 data events) — written to an S3 bucket, pulled into Splunk via the Splunk Add-on for AWS (S3 input, SQS-based).
- **VPC Flow Logs** — published to the same S3 bucket, ingested the same way, used for network-level visibility inside the VPC.

## Detections practiced

| Detection | Logic |
|---|---|
| Console login without MFA | `eventName=ConsoleLogin AND responseElements.ConsoleLogin=Success AND additionalEventData.MFAUsed=No` |
| Unusual `AssumeRole` activity | `eventName=AssumeRole` grouped by `userIdentity.arn` and `requestParameters.roleArn`, alerting on a role assumed from a source IP/ASN not seen in the prior 30 days |
| IAM policy/permission changes | `eventName IN (PutUserPolicy, AttachUserPolicy, CreateAccessKey, CreatePolicyVersion)` outside of a known change window |
| Security group opened to `0.0.0.0/0` | `eventName=AuthorizeSecurityGroupIngress AND requestParameters.cidrIp=0.0.0.0/0` |

## Splunk search examples

```spl
# Console login without MFA
index=aws sourcetype=aws:cloudtrail eventName=ConsoleLogin
| spath responseElements.ConsoleLogin
| spath additionalEventData.MFAUsed
| where 'responseElements.ConsoleLogin'="Success" AND 'additionalEventData.MFAUsed'="No"
| table _time, userIdentity.arn, sourceIPAddress

# IAM policy changes outside business hours
index=aws sourcetype=aws:cloudtrail
    (eventName=PutUserPolicy OR eventName=AttachUserPolicy OR eventName=CreateAccessKey OR eventName=CreatePolicyVersion)
| eval hour=strftime(_time, "%H")
| where hour < 8 OR hour > 20
| table _time, eventName, userIdentity.arn, sourceIPAddress
```

## Notes

This part of the lab was kept intentionally small — the goal was to confirm the same detection-engineering workflow (log source → correlation search → tuning against false positives) applies in a cloud context, not to build a full cloud SOC. A natural next step noted for future work: extend the Sigma rules in `../sigma-rules/` to cloud log sources using Sigma's `cloud` log source category, so CloudTrail detections can be authored and converted the same way as the endpoint/network ones.
