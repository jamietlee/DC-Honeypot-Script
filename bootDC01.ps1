function change-name {
    Write-Output "$(Get-Date) change-name called" | Out-file C:\log.txt -append
    Rename-Computer -NewName DC01
    Remove-Item 'C:\stepfile\1.txt'
    Restart-Computer
 }
 
 function install-ad {
    Write-Output "$(Get-Date) install-ad called" | Out-file C:\log.txt -append
     "Installing AD-Domain-Services"
     Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
     "Install complete"
     Remove-Item 'C:\stepfile\2.txt'
     Write-Output "$(Get-Date) install-ad complete" | Out-file C:\log.txt -append
 }
 
 function create-domain {
    Write-Output "$(Get-Date) create-domain called" | Out-file C:\log.txt -append
     "Converting secure password"
     $Secure = ConvertTo-SecureString "SMAdminPassw0rd" -AsPlainText -Force
     "Creating domain"
     Install-ADDSForest -DomainName "testdomain.local" -DomainNetBiosName "testdomain" -SafeModeAdministratorPassword $Secure -InstallDns:$true -NoRebootOnCompletion:$true -Force
     "Domain Creation Complete"
     Remove-Item 'C:\stepfile\3.txt'
     Write-Output "$(Get-Date) create-domain complete" | Out-file C:\log.txt -append
 }

 function clone-bb {
    Set-Location C:\
    Write-Output "$(Get-Date) clone starting" | Out-file C:\log.txt -append
    git clone https://github.com/davidprowe/BadBlood.git
    Write-Output "$(Get-Date) clone complete" | Out-file C:\log.txt -append
 }

 function run-bb {
    Set-Location C:\BadBlood
    Write-Output "$(Get-Date) running BadBlood" | Out-file C:\log.txt -append
    ./Invoke-BadBlood.ps1 -NonInteractive
    Write-Output "$(Get-Date) BadBlood run complete" | Out-file C:\log.txt -append
 }

 if (Test-Path C:\stepfile){
     if (Test-Path C:\stepfile\1.txt){
         change-name
     }
     if (Test-Path C:\stepfile\2.txt){
         install-ad
     }
     if (Test-Path C:\stepfile\3.txt){
        create-domain
     }
     if (Test-Path C:\stepfile\4.txt){
        Remove-Item 'C:\stepfile\4.txt'
     }
     if (Test-Path C:\stepfile\5.txt){
        clone-bb
        Remove-Item 'C:\stepfile\5.txt'
        Restart-Computer
     }
     if (Test-Path C:\stepfile\6.txt){
        run-bb
        Remove-Item 'C:\stepfile\6.txt'
     }
 }else{
     New-Item -Path 'C:\stepfile' -ItemType Directory
     New-Item 'C:\stepfile\1.txt'
     New-Item 'C:\stepfile\2.txt'
     New-Item 'C:\stepfile\3.txt'
     New-Item 'C:\stepfile\4.txt'
     New-Item 'C:\stepfile\5.txt'
     New-Item 'C:\stepfile\6.txt'
     change-name
 }