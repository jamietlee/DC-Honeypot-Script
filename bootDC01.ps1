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
    Set-Location C:\DC-Honeypot-Script\BadBlood-master
    Write-Output "$(Get-Date) running BadBlood" | Out-file C:\log.txt -append
    ./Invoke-BadBlood.ps1 -NonInteractive
    Write-Output "$(Get-Date) BadBlood run complete" | Out-file C:\log.txt -append
 }

 function run-userdeception {
   Set-Location C:\
   Write-Output "$(Get-Date) cloning deploy-deception" | Out-file C:\log.txt -append
   git clone https://github.com/samratashok/Deploy-Deception.git
   Write-Output "$(Get-Date) deploy-deception clone complete" | Out-file C:\log.txt -append
   Set-Location C:/Deploy-Deception
   Write-Output "$(Get-Date) importing deploy-deception module" | Out-file C:\log.txt -append
   Import-Module C:\Deploy-Deception\Deploy-Deception.ps1
   Write-Output "$(Get-Date) importing users csv" | Out-file C:\log.txt -append
   $users = import-csv C:\DC-Honeypot-Script\honeyusers.csv

   Write-Output "$(Get-Date) creating honeyusers" | Out-file C:\log.txt -append
   foreach ($user in $users) {
      $firstname = $user.UserFirstName
      $lastname = $user.UserLastName
      $password = $user.Password
      
      # Log a 4662 whenever user properties are read
      # Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-UserDeception -UserFlag PasswordNeverExpires -Verbose
      # Write-Output "$(Get-Date) $firstname $surname created" | Out-file C:\log.txt -append

      Triggers logging only when x500uniqueIdentifier property is read
      Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-UserDeception -RemoveAuditing $true -UserFlag PasswordNeverExpires -GUID d07da11f-8a3d-42b6-b0aa-76c962be719a -Verbose
      Write-Output "$(Get-Date) $firstname $surname created" | Out-file C:\log.txt -append

      # Logs a 4662 log only when DACL (or all attributes) of a user are read
      # Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-UserDeception -UserFlag AllowReversiblePasswordEncryption -Right ReadControl -Verbose
      # Write-Output "$(Get-Date) $firstname $surname created" | Out-file C:\log.txt -append
  }
  Write-Output "$(Get-Date) Honey user creation complete" | Out-file C:\log.txt -append
}

function run-computerdeception {
   Set-Location C:/Deploy-Deception
   Write-Output "$(Get-Date) importing deploy-deception module" | Out-file C:\log.txt -append
   Import-Module C:\Deploy-Deception\Deploy-Deception.ps1
   Write-Output "$(Get-Date) importing computers csv" | Out-file C:\log.txt -append
   $computers = import-csv C:\DC-Honeypot-Script\honeycomputers.csv

   Write-Output "$(Get-Date) creating honeycomputers" | Out-file C:\log.txt -append
   foreach ($computer in $computers) {
      $name = $computer.ComputerName
      
      Create-DecoyComputer -ComputerName $name -Verbose | Deploy-ComputerDeception -PropertyFlag TrustedForDelegation -GUID d07da11f-8a3d-42b6-b0aa-76c962be719a -Verbose
      Write-Output "$(Get-Date) $name created" | Out-file C:\log.txt -append
      # Log a 4662 whenever user properties are read
      # Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-UserDeception -UserFlag PasswordNeverExpires -Verbose
      # Write-Output "$(Get-Date) $firstname $surname created" | Out-file C:\log.txt -append

  }
  Write-Output "$(Get-Date) Honey computer creation complete" | Out-file C:\log.txt -append
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
        #clone-bb
        Remove-Item 'C:\stepfile\5.txt'
        Restart-Computer
     }
     if (Test-Path C:\stepfile\6.txt){
        run-bb
        Remove-Item 'C:\stepfile\6.txt'
     }
     if (Test-Path C:\stepfile\7.txt){
         run-userdeception
         Remove-Item 'C:\stepfile\7.txt'
     }
     if (Test-Path C:\stepfile\8.txt){
         run-computerdeception
         Remove-Item 'C:\stepfile\8.txt'
     
   }

 }else{
     New-Item -Path 'C:\stepfile' -ItemType Directory
     New-Item 'C:\stepfile\1.txt'
     New-Item 'C:\stepfile\2.txt'
     New-Item 'C:\stepfile\3.txt'
     New-Item 'C:\stepfile\4.txt'
     New-Item 'C:\stepfile\5.txt'
     New-Item 'C:\stepfile\6.txt'
     New-Item 'C:\stepfile\7.txt'
     New-Item 'C:\stepfile\8.txt'
     change-name
 }