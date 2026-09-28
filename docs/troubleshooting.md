# Troubleshooting Cases

[Back to README](../README.md)

The completed lab notes describe four controlled faults and their recovery. The existing screenshots capture parts of the working end state; there are no separate before/after images for every fault. The commands below are a repeatable diagnostic runbook, not a claim that the virtual machines were retested during repository preparation.

## 1. Internal DNS resolution fails

**Symptom:** `nslookup corp.atlas.test` returned NXDOMAIN, while direct IP connectivity to the lab still worked.

**Recorded cause:** CLIENT01 had been configured to use public DNS `8.8.8.8` instead of DC01 at `192.168.134.10`.

Inspect on CLIENT01:

```powershell
ipconfig /all
nslookup corp.atlas.test
nslookup corp.atlas.test 192.168.134.10
Test-NetConnection 192.168.134.10 -Port 53
```

Compare the configured resolver with the explicit DC01 query. The port check tests TCP reachability only; the DNS query is the functional resolution check.

**Recovery:** Restore DC01 as the client DNS server. In the final DHCP-based setup, check option 006 and remove any unintended manual DNS override. Clear a stale client resolver cache if needed.

**Recorded result:** Internal name resolution succeeded again through DC01. The [forward-zone screenshot](../screenshots/04-dns-forward-zone.png.png) shows the domain and host records, but does not show the earlier NXDOMAIN response.

**Lesson:** Successful IP connectivity does not prove the client can discover domain services. Verify resolver selection before changing the domain or rejoining a workstation.

## 2. Finance share returns access denied

**Symptom:** A Finance user could not access `\\DC01\Finance`.

**Recorded cause:** The user had been removed from `GG-FINANCE`, interrupting the access chain through `DL_FINANCE_Modify`.

Inspect from the affected user's CLIENT01 session:

```powershell
whoami
whoami /groups
Test-NetConnection DC01 -Port 445
Get-ChildItem -LiteralPath '\\DC01\Finance'
```

On DC01, compare `Get-ADGroupMember GG-FINANCE`, `Get-ADGroupMember DL_FINANCE_Modify`, `Get-SmbShareAccess Finance`, and the NTFS ACL on `C:\shares\Finance`. The share's existence and a reachable SMB port do not prove authorization.

**Recovery:** Restore the intended Finance membership. Before retesting, sign out and back in as the affected user and establish a new SMB session so old membership/session state does not distort the result.

**Recorded result:** Finance access returned after membership was restored. [Group evidence](../screenshots/02-security-groups.png.png) and [share evidence](../screenshots/08-file-shares.png.png) support the surrounding configuration; the original access-denied dialog is not retained.

**Lesson:** Trace account → global group → domain local group → resource ACL. Test with the user's standard account; an administrator can conceal a permission error.

## 3. Workstation GPO disappears

**Symptom:** CLIENT01 reported `Default Domain Policy` but no longer listed `ATLAS - Workstation Security`.

**Recorded cause:** The computer object had been moved from `ATLAS/computers` into the default `Computers` container, outside the workstation GPO's OU link.

On CLIENT01, inspect `gpresult /r /scope computer` from an elevated prompt. On DC01, inspect the computer's distinguished name:

```powershell
Get-ADComputer CLIENT01 | Select-Object Name, DistinguishedName
```

Compare its location with `OU=computers,OU=ATLAS,DC=corp,DC=atlas,DC=test` and inspect the GPO link in Group Policy Management.

**Recovery:** Return CLIENT01 to the intended OU. Run `gpupdate /force` on CLIENT01, follow any restart requirement, and inspect the computer policy result again.

**Recorded result:** Both the workstation GPO and Default Domain Policy appeared. The [retained gpresult image](../screenshots/07-gpresult.png.png) shows this recovered state and the correct OU.

**Lesson:** Check object placement, link state, and policy scope before editing policy settings. User drive mapping requires a separate user-scope check.

## 4. DHCP outage and APIPA

**Symptom:** CLIENT01 acquired a `169.254.x.x` address and lost normal connectivity to DC01, the gateway, and the Internet.

**Recorded cause:** The DHCP Server service on DC01 had been stopped, leaving the client unable to obtain a usable lease. The notes do not retain the precise lease-release/expiry sequence. Stopping DHCP alone does not immediately remove an existing valid lease.

Inspect on CLIENT01:

```powershell
ipconfig /all
```

Inspect on DC01:

```powershell
Get-Service DHCPServer
Get-DhcpServerv4Scope
Get-DhcpServerv4Lease -ScopeId 192.168.134.0
```

**Recovery:** Start the DHCP Server service on DC01 if it is stopped. From the CLIENT01 VM console, renew its lease with `ipconfig /renew`. If a valid address still does not arrive, check the virtual network attachment, scope state, authorization, and available addresses.

**Recorded result:** CLIENT01 received `192.168.134.50`, DNS and DHCP server `192.168.134.10`, and gateway `192.168.134.2`; connectivity returned. The [retained lease image](../screenshots/05-dhcp-lease.png.png) confirms `.50` for CLIENT01, while the option values and connectivity result come from the lab notes.

**Lesson:** Inspect address configuration and lease state before treating an APIPA failure as a routing or firewall problem. A later valid DHCP lease may use a different address.

## Diagnostic order

Work from the failed dependency: address and route → DNS and domain discovery → authentication/session → policy scope → resource permission. Record the symptom, make one corrective change, and verify the original user operation as well as the administrative configuration.
