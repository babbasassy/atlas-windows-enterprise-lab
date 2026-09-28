Import-Module ActiveDirectory

$CsvPath = "C:\ATLAS-Scripts\users.csv"

$Password = Read-Host "Enter initial password for new lab users" -AsSecureString

$users = Import-Csv $CsvPath

foreach ($user in $users) {

    $ou = "OU=$($user.Department),OU=users,OU=ATLAS,DC=corp,DC=atlas,DC=test"

    $existingUser = Get-ADUser `
        -Filter "SamAccountName -eq '$($user.Username)'" `
        -ErrorAction SilentlyContinue

    if ($existingUser) {
        Write-Warning "$($user.Username) already exists. Skipping."
        continue
    }

    try {

        New-ADUser `
            -Name "$($user.FirstName) $($user.LastName)" `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -SamAccountName $user.Username `
            -UserPrincipalName "$($user.Username)@corp.atlas.test" `
            -Department $user.Department `
            -Path $ou `
            -AccountPassword $Password `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Add-ADGroupMember `
            -Identity $user.Group `
            -Members $user.Username

        Write-Host "Created: $($user.Username) → $($user.Group)"
    }
    catch {
        Write-Error "Failed to create $($user.Username): $($_.Exception.Message)"
    }
}

Write-Host "Bulk user creation completed."