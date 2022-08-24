# Changes the host name of the EC2 instance
function change-name {
    Write-Output "$(Get-Date) change-name called" | Out-file C:\log.txt -append
    Rename-Computer -NewName DC01
    Remove-Item 'C:\stepfile\1.txt'
    Restart-Computer
 }
 
 # Install active directory domain services
 function install-ad {
    Write-Output "$(Get-Date) install-ad called" | Out-file C:\log.txt -append
     "Installing AD-Domain-Services"
     Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
     "Install complete"
     Remove-Item 'C:\stepfile\2.txt'
     Write-Output "$(Get-Date) install-ad complete" | Out-file C:\log.txt -append
 }
 
 # Create the domain - rename 'testdomain' here.
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

 # Clone BadBlood repo to the C: drive
 function clone-bb {
    Set-Location C:\
    Write-Output "$(Get-Date) clone starting" | Out-file C:\log.txt -append
    git clone https://github.com/davidprowe/BadBlood.git
    Write-Output "$(Get-Date) clone complete" | Out-file C:\log.txt -append
 }

 # Run bad blood to populate active directory
 function run-bb {
    Set-Location C:\DC-Honeypot-Script\BadBlood-master
    Write-Output "$(Get-Date) running BadBlood" | Out-file C:\log.txt -append
    ./Invoke-BadBlood.ps1 -NonInteractive
    Write-Output "$(Get-Date) BadBlood run complete" | Out-file C:\log.txt -append
 }

# Run Deploy-Deception and deploy honey users from honeyusers.csv into the active directory
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
      $department = $user.Department
      $description = $user.Description
      $name = $firstname + $lastname
      # Log a 4662 whenever user properties are read
      # Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-UserDeception -UserFlag PasswordNeverExpires -Verbose
      # Write-Output "$(Get-Date) $firstname $surname created" | Out-file C:\log.txt -append

      # Triggers logging only when x500uniqueIdentifier property is read
      # if($department = 'IT Helpdesk'){
      #    Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-PrivilegedUserDeception -Technique DomainAdminsMembership -Protection DenyLogon -Right ReadControl -Verbose
      #    Write-Output "$(Get-Date) $firstname $surname privileged user created" | Out-file C:\log.txt -append
      # }else{
      #    Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-UserDeception -RemoveAuditing $true -UserFlag PasswordNeverExpires -GUID d07da11f-8a3d-42b6-b0aa-76c962be719a -Verbose
      #    Write-Output "$(Get-Date) $firstname $surname created" | Out-file C:\log.txt -append

      # }
      
      Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-UserDeception -RemoveAuditing $true -UserFlag PasswordNeverExpires -GUID d07da11f-8a3d-42b6-b0aa-76c962be719a -Verbose
      Write-Output "$(Get-Date) $firstname $surname created" | Out-file C:\log.txt -append

      Get-ADUser -Identity $name | Set-AdUser -GivenName $firstname -Surname $lastname -Description $description
      Write-Output "$(Get-Date) set attributes for $name" | Out-file C:\log.txt -append

      Move-ADObject -Identity "CN=$name,CN=Users,DC=testdomain,DC=local" -TargetPath "OU=$department,DC=testdomain,DC=local"
      Write-Output "$(Get-Date) moved $name to $department" | Out-file C:\log.txt -append

      # Add-ADGroupMember -Identity RDP -Members $name
      # Write-Output "$(Get-Date) added $name to RDP decoy group" | Out-file C:\log.txt -append

      # Logs a 4662 log only when DACL (or all attributes) of a user are read
      # Create-DecoyUser -UserFirstName $firstname -UserLastName $lastname -Password $password | Deploy-UserDeception -UserFlag AllowReversiblePasswordEncryption -Right ReadControl -Verbose
      # Write-Output "$(Get-Date) $firstname $surname created" | Out-file C:\log.txt -append
  }

  Deploy-PrivilegedUserDeception -DecoySamAccountName TomHarris -Technique DomainAdminsMemebership -Protection DenyLogon -Verbose
  Write-Output "$(Get-Date) Tom Harris upgraded to privileged user" | Out-file C:\log.txt -append
  Write-Output "$(Get-Date) Honey user creation complete" | Out-file C:\log.txt -append
}

function run-computerandgroupdeception {
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
}

# Create a series of files used to establish at what stage the script is at
# Script checks if file exists:
# If yes - complete function and then delete file and move on to the next
# If no - loop through to establish where in the process the script is
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
      #run-computerandgroupdeception
      Set-ExecutionPolicy Unrestricted -Force
      Set-Location C:\DC-Honeypot-Scipt
      Write-Output "$(Get-Date) calling compandgroupobjects.ps1" | Out-file C:\log.txt -append
      & .\compandgroupobjects.ps1
      Write-Output "$(Get-Date) completed compandgroupobjects.ps1" | Out-file C:\log.txt -append
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