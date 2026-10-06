rule Mimikatz_Generic_Strings
{
    meta:
        description = "Generic string/export indicators associated with the Mimikatz credential-dumping tool family"
        author = "Detection Engineering Lab"
        date = "2026-09-15"
        reference = "https://attack.mitre.org/software/S0002/"
        mitre_attack = "T1003.001"

    strings:
        $s1 = "sekurlsa::logonpasswords" ascii wide nocase
        $s2 = "mimikatz" ascii wide nocase
        $s3 = "gentilkiwi" ascii wide nocase
        $s4 = "privilege::debug" ascii wide nocase
        $s5 = "lsadump::sam" ascii wide nocase
        $hex1 = { 6D 69 6D 69 6B 61 74 7A }  // "mimikatz" in hex

    condition:
        2 of ($s1, $s2, $s3, $s4, $s5) or $hex1
}
