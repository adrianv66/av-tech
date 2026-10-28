---
title: "NetScaler's Run of CVEs: What's Happened and What to Do Now"
summary: "Six exploited NetScaler flaws in 2026 so far, two of them zero-days. The pattern, the builds you need, and a checklist for patching, hunting and reducing exposure."
tags: [citrix, netscaler, security, powershell]
---

If you run NetScaler ADC or Gateway, 2026 has been exhausting. Six NetScaler vulnerabilities have been added to
CISA's Known Exploited Vulnerabilities list so far this year, two of them exploited before Citrix had a fix. The
most recent was added on 4 October.

This isn't new. NetScaler has a long history of flaws attackers move on quickly: CVE-2019-19781 in 2019,
CVE-2022-27518 in 2022, CVE-2023-3519 and CitrixBleed (CVE-2023-4966) in 2023, and CitrixBleed 2
(CVE-2025-5777), CVE-2025-6543 and CVE-2025-7775 in 2025. But the pace has picked up.

## 2026 so far

![Timeline of six NetScaler flaws exploited in 2026: CVE-2026-3055 added to CISA's list 7 days after its fix in March; CVE-2026-8452 57 days after its June fix; CVE-2026-19490 21 days after its August fix; CVE-2026-88771 and CVE-2026-88772 exploited as zero-days on 27 September; CVE-2026-88779 added on 4 October.](/images/netscaler-2026-exploited-cves.svg)

| CVE | What it is | Applies when | Fixed in |
| --- | --- | --- | --- |
| CVE-2026-3055 | Memory overread | Configured as a SAML IdP | 14.1-66.59, 13.1-62.23 |
| CVE-2026-8452 | Heap overflow; public exploit showed RCE | Gateway or AAA with SAML | 14.1-72.61, 13.1-63.18 |
| CVE-2026-19490 | Authentication bypass | Gateway or AAA vserver (SAML on newer builds) | 14.1-73.32, 13.1-63.21 |
| CVE-2026-88771 | Unauthenticated RCE (zero-day) | All deployments, default configuration | 14.1-73.37, 13.1-64.23 |
| CVE-2026-88772 | Memory overflow, RCE (zero-day) | DTLS enabled, the default on VPN vservers | 14.1-73.37, 13.1-64.23 |
| CVE-2026-88779 | Memory overflow; attacks crash appliances | SAML with Gateway or AAA | 14.1-73.41, 13.1-64.28 |

FIPS and NDcPP builds have their own fixed versions; check the Citrix bulletin for each.

## The pattern

- **The gateway is the target.** Almost every one of these needs a Gateway or AAA virtual server, which is exactly
  what's on the internet.
- **SAML keeps coming up.** Four of the six involve SAML. If you don't use it on a NetScaler, don't configure it.
- **Patching isn't the end.** Mandiant's write-up of the September zero-days describes web shells, a root
  backdoor, a tunnelling tool into the internal network and credential theft. A patched appliance can still be
  compromised.
- **Old branches fall behind.** The 13.1 branch reached End of Maintenance on 15 September 2026. Plan your move to
  14.1 now.
- **Citrix-managed services are patched for you.** The bulletins only apply to customer-managed NetScalers. The
  Citrix Gateway service used with DaaS is patched by Citrix.

## What to do now

1. **Get to the latest build.** At the time of writing that's 14.1-73.41 or 13.1-64.28 or later, which covers
   everything in the table. If you're on an older branch, move to 14.1.
2. **If an appliance was exposed and unpatched, assume compromise.** Preserve evidence first (a VM snapshot with
   memory, logs and a support bundle), then run Citrix's IOC scanner and hunt using the published indicators.
3. **Kill existing sessions after upgrading.** Stolen session tokens survive a patch. See the commands below.
4. **Rotate credentials.** Admin accounts, LDAP bind accounts, RADIUS secrets, certificates and keys, and passwords
   for users who signed in through a compromised appliance.
5. **Shrink the attack surface.** Keep management interfaces (NSIP, SSH, the GUI and NITRO API) off the internet.
   Turn off SAML, DTLS and other features you don't use.
6. **Send the logs somewhere.** NetScaler doesn't forward the useful logs by default. Send `ns.log`,
   `/var/log/messages` and HTTP logs to your SIEM, and alert on NSPPE crashes and new core files.
7. **Consider whether you still need it.** For HDX-only access with Citrix DaaS, the Gateway service moves the
   patching to Citrix.

## From the field: which build is each NetScaler on?

This PowerShell 7 script asks each appliance for its version through the NITRO API and flags anything below the
latest fixed build. Use a read-only NetScaler account.

```powershell
$appliances = 'ns01.contoso.local', 'ns02.contoso.local'
$cred       = Get-Credential   # read-only NetScaler account
$minimum    = @{ '14.1' = [version]'73.41'; '13.1' = [version]'64.28' }

foreach ($ns in $appliances) {
    $headers = @{
        'X-NITRO-USER' = $cred.UserName
        'X-NITRO-PASS' = $cred.GetNetworkCredential().Password
    }
    $v = (Invoke-RestMethod "https://$ns/nitro/v1/config/nsversion" -Headers $headers -SkipCertificateCheck).nsversion.version

    if ($v -match 'NS(\d+\.\d+): Build (\d+\.\d+)') {
        $branch = $Matches[1]; $build = [version]$Matches[2]
        [pscustomobject]@{
            Appliance = $ns
            Branch    = $branch
            Build     = $build
            Status    = if (-not $minimum[$branch]) { 'Unsupported branch: upgrade to 14.1' }
                        elseif ($build -lt $minimum[$branch]) { 'Needs patching' }
                        else { 'OK' }
        }
    }
}
```

`-SkipCertificateCheck` is only there for appliances with self-signed management certificates; remove it if yours
are trusted. FIPS builds use different numbers, so check those against the bulletin by hand.

**After upgrading, end every existing session** from the NetScaler CLI, so stolen session tokens stop working:

```text
kill icaconnection -all
kill rdp connection -all
kill pcoipConnection -all
kill aaa session -all
clear lb persistentSessions
```

**Quick hunting checks** from the appliance shell, taken from Mandiant's September write-up:

```bash
# Unexpected PHP handlers or aliases in httpd.conf
grep -En -i "application/x-httpd-php|php_flag|AliasMatch" /etc/httpd.conf

# The shell should be -rwxr-xr-x, not -rwsr-xr-x
ls -l /bin/sh
```

Anything unexpected means treating the appliance as compromised: isolate it, preserve evidence and rebuild.

## Bottom line

NetScaler is a high-value target because it sits on the internet, in front of everything, and holds sessions and
credentials. Patch fast, kill sessions, hunt rather than assume, and switch off what you don't use. And if a
Citrix-managed gateway would do the job, let Citrix carry the patching.

### Sources

- [Security bulletin for CVE-2026-88771 to CVE-2026-88778 (Citrix)](https://support.citrix.com/external/article/CTX697096/citrix-netscaler-adc-and-citrix-netscale.html)
- [Security bulletin for CVE-2026-3055 and CVE-2026-4368 (Citrix)](https://support.citrix.com/external/article/CTX696300/netscaler-adc-and-netscaler-gateway-secu.html)
- [Defending against active exploitation of NetScaler (Google Threat Intelligence)](https://cloud.google.com/blog/topics/threat-intelligence/defending-against-active-exploitation-of-citrix-netscaler-adc-and-gateway-appliances)
- [Exploitation of vulnerabilities affecting NetScaler (UK NCSC)](https://www.ncsc.gov.uk/news/exploitation-of-vulnerabilities-affecting-citrix-netscaler-adc-and-citrix-netscaler-gateway)
- [CISA flags new exploited NetScaler flaw, CVE-2026-88779 (Help Net Security)](https://helpnetsecurity.com/2026/10/05/cisa-flags-new-exploited-netscaler-flaw-as-attackers-crash-appliances-cve-2026-88779)
- [CVE-2026-8452 research note (Cloud Security Alliance)](https://labs.cloudsecurityalliance.org/research/csa-research-note-citrix-netscaler-cve-2026-8452-exploited-2/)
- [Critical NetScaler vulnerability exploited, CVE-2026-19490 (SecurityWeek)](https://www.securityweek.com/critical-netscaler-vulnerability-exploited-in-attacks/)
- [Two unpatched NetScaler zero-days under active exploitation (The Hacker News)](https://thehackernews.com/2026/09/warning-two-unpatched-citrix-netscaler.html)
