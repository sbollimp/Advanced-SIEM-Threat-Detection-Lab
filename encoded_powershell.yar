rule Suspicious_Encoded_PowerShell_Command
{
    meta:
        description = "Flags scripts/logs containing a PowerShell invocation with an encoded command, commonly used to obscure a dropper or stager payload"
        author = "Detection Engineering Lab"
        date = "2026-09-15"
        reference = "https://attack.mitre.org/techniques/T1027/"
        mitre_attack = "T1027, T1059.001"

    strings:
        $enc1 = "-EncodedCommand" ascii wide nocase
        $enc2 = "-enc " ascii wide nocase
        $enc3 = "-e " ascii wide nocase
        $bypass = "-ExecutionPolicy Bypass" ascii wide nocase
        $hidden = "-WindowStyle Hidden" ascii wide nocase
        $noprofile = "-NoProfile" ascii wide nocase

    condition:
        ($enc1 or $enc2 or $enc3) and 2 of ($bypass, $hidden, $noprofile)
}
