# Active Directory

[Back to README](../README.md)

## Domain and organizational units

DC01 hosts the `corp.atlas.test` domain, with NetBIOS name `CORP`. The ATLAS hierarchy separates users, workstation computer accounts, and security groups.

```text
corp.atlas.test
└── ATLAS
    ├── users
    │   ├── it
    │   ├── HR
    │   └── FINANCE
    ├── computers
    └── groups
```

![ATLAS OU hierarchy](../screenshots/01-active-directory-structure.png)

CLIENT01 is joined to the domain and placed in `OU=computers,OU=ATLAS,DC=corp,DC=atlas,DC=test`. Its [domain membership](../screenshots/03-domain-client.png.png) and [computer OU in policy results](../screenshots/07-gpresult.png.png) are captured separately. The default `Computers` container is distinct from this ATLAS OU.

## Security group model

| Global security group | Domain local resource group | Resource |
| --- | --- | --- |
| `GG-IT` | `DL_IT_Modify` | `\\DC01\IT` |
| `GG-HR` | `DL_HR_Modify` | `\\DC01\HR` |
| `GG-FINANCE` | `DL_FINANCE_Modify` | `\\DC01\Finance` |
| Shared-access membership | `DL_Public_Modify` | `\\DC01\Public` |

The lab notes describe an AGDLP-style chain: **Accounts → Global groups → Domain Local groups → Permissions**. The [group screenshot](../screenshots/02-security-groups.png.png) confirms all seven names and their scopes; it does not display their nested memberships. Exact membership of the Public resource group should be checked on DC01.

The recorded Finance example is Omar Hassan → `GG-FINANCE` → `DL_FINANCE_Modify` → Finance share. Department membership belongs in global groups, while resource permissions belong on the domain local groups. This keeps user changes separate from file ACL maintenance.

## Account lifecycle

The lab notes describe `seyed` as the standard account and `adm.seyed` as the separate administrative account with Domain Admins membership. A test account, `former.employee`, was disabled for the offboarding exercise. These account states are not shown in the retained screenshots.

Disabling an account demonstrates one part of offboarding. Existing sessions, group memberships, and file ownership require separate consideration; the lab does not claim a complete offboarding process.

## CSV-based provisioning

[New-ATLASUsers.ps1](../scripts/New-ATLASUsers.ps1) reads `C:\ATLAS-Scripts\users.csv`. The supplied [input CSV](../data/users.csv) contains Alice Nordmann, Jonas Berg, and Fatima Khan with department values matching the OU names and corresponding global groups.

The script prompts for an initial password, creates enabled accounts with a required password change at next logon, and adds group membership. Existing usernames are skipped. OUs and groups must already exist. User creation and group assignment are separate operations, so a failed assignment can leave a newly created user without the intended membership. Verify both results before treating a provisioning run as complete.

## Repeatable checks

Run these read-only checks on DC01 or a management machine with the Active Directory module and suitable directory access:

```powershell
Get-ADDomain | Select-Object DNSRoot, NetBIOSName
Get-ADComputer CLIENT01 -Properties DNSHostName |
    Select-Object Name, DNSHostName, DistinguishedName
Get-ADOrganizationalUnit -Filter * -SearchBase 'OU=ATLAS,DC=corp,DC=atlas,DC=test' |
    Select-Object Name, DistinguishedName
Get-ADGroupMember -Identity 'DL_FINANCE_Modify'
Get-ADGroupMember -Identity 'DL_FINANCE_Modify' -Recursive
Get-ADGroupMember -Identity 'Domain Admins' -Recursive
Get-ADUser -Identity 'former.employee' -Properties Enabled |
    Select-Object SamAccountName, Enabled
```

Compare direct and recursive memberships to verify the nesting chain. Confirm the standard account is absent from the privileged membership list and that the offboarding account reports `Enabled: False`. These are verification targets from the lab notes, not fresh query results.

The supplied [group membership report](../scripts/Get-GroupMembership.ps1) uses direct membership only. See [file services](file-services.md) for resource permissions and [hardening](hardening.md) for privilege separation.
