$ComputerName = "CLIENT01"

$cred = Get-Credential -Message "Enter credentials for reading CLIENT01 Security log"

try {

    $events = Get-WinEvent `
        -ComputerName $ComputerName `
        -Credential $cred `
        -FilterHashtable @{
            LogName = "Security"
            Id      = 4625
        } `
        -ErrorAction Stop

    if (-not $events) {
        Write-Warning "No failed logon events were found on $ComputerName."
        return
    }

    $report = foreach ($event in $events) {

        [xml]$xml = $event.ToXml()
        $data = @{}

        foreach ($item in $xml.Event.EventData.Data) {
            $data[$item.Name] = $item.'#text'
        }

        [PSCustomObject]@{
            TimeCreated     = $event.TimeCreated
            Computer        = $event.MachineName
            AccountName     = $data["TargetUserName"]
            Domain          = $data["TargetDomainName"]
            LogonType       = $data["LogonType"]
            FailureReason   = $data["FailureReason"]
            Status          = $data["Status"]
            SubStatus       = $data["SubStatus"]
            Workstation     = $data["WorkstationName"]
            SourceIPAddress = $data["IpAddress"]
        }
    }

    $report = $report | Sort-Object TimeCreated -Descending

    $report | Format-Table -AutoSize

    $report | Export-Csv `
        -Path "C:\ATLAS-Scripts\Failed-Logon-Report.csv" `
        -NoTypeInformation `
        -Encoding UTF8

    Write-Host "Report created: C:\ATLAS-Scripts\Failed-Logon-Report.csv"
}
catch {
    Write-Error "Could not read Security events from $ComputerName. $($_.Exception.Message)"
}