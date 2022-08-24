Write-Output "$(Get-Date) starting compandgroupobjects.ps1" | Out-file C:\log.txt -append
Set-Location C:/Deploy-Deception
Write-Output "$(Get-Date) importing deploy-deception module" | Out-file C:\log.txt -append
Import-Module C:\Deploy-Deception\Deploy-Deception.ps1
$users = import-csv C:\DC-Honeypot-Script\honeyusers.csv

Create-DecoyComputer -ComputerName DC02 -Verbose | Deploy-ComputerDeception -PropertyFlag TrustedForDelegation -GUID d07da11f-8a3d-42b6-b0aa-76c962be719a -Verbose
Write-Output "$(Get-Date) created DC02 decoy" | Out-file C:\log.txt -append

Move-ADObject -Identity "CN=DC02,CN=Computers,DC=testdomain,DC=local" -TargetPath "OU=Domain Controllers,DC=testdomain,DC=local"
Write-Output "$(Get-Date) Moved DC02 decoy" | Out-file C:\log.txt -append

Set-ADComputer -Identity "DC02" -OperatingSystem "Windows Server 2019 Datacenter" -OperatingSystemVersion "10.0 (17763)"
Write-Output "$(Get-Date) Updated DC02 attributes" | Out-file C:\log.txt -append

Create-DecoyComputer -ComputerName IT_Helpdesk_NUC -Verbose | Deploy-ComputerDeception -PropertyFlag TrustedForDelegation -GUID d07da11f-8a3d-42b6-b0aa-76c962be719a -Verbose
Write-Output "$(Get-Date) created NUC decoy" | Out-file C:\log.txt -append

Move-ADObject -Identity "CN=IT_Helpdesk_NUC,CN=Computers,DC=testdomain,DC=local" -TargetPath "OU=IT Helpdesk,DC=testdomain,DC=local"
Write-Output "$(Get-Date) Moved NUC decoy" | Out-file C:\log.txt -append

Set-ADComputer -Identity "IT_Helpdesk_NUC" -OperatingSystem "Windows Server 2019 Datacenter" -OperatingSystemVersion "10.0 (17763)"
Write-Output "$(Get-Date) Updated NUC attributes" | Out-file C:\log.txt -append

Create-DecoyGroup -GroupName 'RDPAccess' -Verbose | Deploy-GroupDeception -GUID bc0ac240-79a9-11d0-9020-00c04fc2d4cf -Verbose
Write-Output "$(Get-Date) RDP decoy group created" | Out-file C:\log.txt -append

foreach ($user in $users) {
    $firstname = $user.UserFirstName
    $lastname = $user.UserLastName
    $name = $firstname + $lastname

    Add-ADGroupMember -Identity RDPAccess -Members $name
    Write-Output "$(Get-Date) added $name to RDP decoy group" | Out-file C:\log.txt -append
}
Write-Output "$(Get-Date) completing compandgroupobjects.ps1" | Out-file C:\log.txt -append