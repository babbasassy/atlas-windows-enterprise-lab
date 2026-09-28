Import-Module ActiveDirectory

$users = Get-ADUser -Filter * -Properties Department, Enabled, LastLogonDate |
    Select-Object Name,
                  SamAccountName,
                  Department,
                  Enabled,
                  LastLogonDate

$users | Format-Table -AutoSize

$users | Export-Csv `
    -Path "C:\ATLAS-Scripts\AD-User-Report.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host "Report created: C:\ATLAS-Scripts\AD-User-Report.csv"