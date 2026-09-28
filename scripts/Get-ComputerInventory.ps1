Import-Module ActiveDirectory

$computers = Get-ADComputer -Filter * -Properties OperatingSystem, OperatingSystemVersion, IPv4Address, LastLogonDate

$report = foreach ($computer in $computers) {

    [PSCustomObject]@{
        ComputerName           = $computer.Name
        OperatingSystem        = $computer.OperatingSystem
        OperatingSystemVersion = $computer.OperatingSystemVersion
        IPv4Address            = $computer.IPv4Address
        LastLogonDate          = $computer.LastLogonDate
        Enabled                = $computer.Enabled
    }
}

$report | Format-Table -AutoSize

$report | Export-Csv `
    -Path "C:\ATLAS-Scripts\Computer-Inventory.csv" `
    -NoTypeInformation `
    -Encoding UTF8

Write-Host "Report created: C:\ATLAS-Scripts\Computer-Inventory.csv"