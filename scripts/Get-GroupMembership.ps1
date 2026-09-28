Import-Module ActiveDirectory

$groups = @(
    "GG-IT",
    "GG-HR",
    "GG-FINANCE",
    "DL_IT_Modify",
    "DL_HR_Modify",
    "DL_FINANCE_Modify",
    "DL_Public_Modify"
)

$report = foreach ($group in $groups) {

    $members = Get-ADGroupMember -Identity $group

    foreach ($member in $members) {

        [PSCustomObject]@{
            Group       = $group
            MemberName  = $member.Name
            MemberType  = $member.objectClass
        }
    }
}

$report | Format-Table -AutoSize

$report | Export-Csv `
    -Path "C:\ATLAS-Scripts\Group-Membership-Report.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host "Report created: C:\ATLAS-Scripts\Group-Membership-Report.csv"