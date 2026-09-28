# Group Policy

[Back to README](../README.md)

## Workstation policy and scope

The primary computer policy is **ATLAS - Workstation Security**, linked to `OU=computers,OU=ATLAS,DC=corp,DC=atlas,DC=test`.

The [management screenshot](../screenshots/06-gpo-workstation-security.png.png) shows an enabled link, an enabled GPO, no WMI filter, and `Enforced: No`. The [client result](../screenshots/07-gpresult.png.png) shows CLIENT01 in that OU with both policies applied:

```text
ATLAS - Workstation Security
Default Domain Policy
```

## Controls described in the lab notes

| Control | Intended result | Verification point |
| --- | --- | --- |
| Windows Firewall | Domain, Private, and Public profiles enabled | Effective firewall profile state |
| Guest account disabled | Prevent Guest account use | Built-in Guest account state |
| PowerShell Script Block Logging | Record processed script blocks | Operational log and policy setting |
| PowerShell Module Logging | Record activity from configured modules | Module policy and emitted events |
| PowerShell Transcription | Write session transcripts | Configured output location and a new transcript |
| Successful and failed logon auditing | Record authentication activity | Effective audit settings and Security log |
| Remote Event Log Management rules | Permit authorized remote log queries | Rule scope and an authorized query |

The retained images prove the GPO link and application, not every setting above. No GPO backup or detailed settings export is included. In particular, the module list, transcription destination, firewall source scope, and exact audit subcategory settings were not captured.

## Computer policy verification

Run an elevated prompt on CLIENT01:

```powershell
gpresult /r /scope computer
Get-NetFirewallProfile | Select-Object Name, Enabled
auditpol /get /category:*
```

`gpresult /r` summarizes applied policy. Use a detailed report to inspect effective settings; a GPO appearing in the list does not by itself verify every configured control. The available scopes and reporting options are documented in [Microsoft's gpresult reference](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/gpresult).

After an intentional OU or policy correction, refresh policy with `gpupdate /force`, then check results again. Some changes require sign-out or restart; follow the client's prompt rather than assuming refresh alone is sufficient.

## User drive mappings

The lab notes describe Group Policy Preferences mappings for `I:` (IT), `H:` (HR), `F:` (Finance), and `P:` (Public), with departmental item-level targeting.

Drive Maps are user settings. The captured workstation computer-policy result does not prove the user-side drive policy or its targeting. The drive-map GPO name, user OU link, and any loopback configuration were not retained; do not assume the workstation GPO alone delivers these mappings.

Verify from the affected user's normal session:

```powershell
gpresult /r /scope user
whoami /groups
net use
```

Inspect the user-side policy link and each preference item's target group in Group Policy Management. A mapped drive is a convenience; access is enforced by share and NTFS permissions. See [file services](file-services.md).

## Recorded scope failure

Moving CLIENT01 to the default `Computers` container removed it from the workstation GPO's OU scope. Returning it to `ATLAS/computers` restored application in the recorded exercise. The [troubleshooting guide](troubleshooting.md) describes the diagnosis and recovery checks.
