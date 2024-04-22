<#
.Description
#############################################################
###             Written By Randy Drielinger               ###
###      Install windows update for WSUS deployments      ###
###                       v1.0.0                          ###
#############################################################
#> 


### SET CULTURE
#############################################################
$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
[System.Threading.Thread]::CurrentThread.CurrentCulture = $culture
#############################################################

### SET BASIC VARIABLES
#############################################################
$ErrorActionPreference = "Stop"
$WarningPreference = "Continue"
#############################################################


### INSTALL MODULES
#############################################################
Try {    
    $InstalledVersion = (Get-Module -Name PowerShellGet).Version.ToString()
    $PSGalleryVersion = (Find-Module -Name PowerShellGet).Version.ToString()
    If ($InstalledVersion -ne $PSGalleryVersion) {
	    Install-Module -Name PowerShellGet -Force
        shutdown /r /f /t 0
    }
    Import-Module PowerShellGet
}
Catch {
    Install-Module -Name PowerShellGet -Force
}

Try {    
    $InstalledVersion = (Get-InstalledModule -Name PSWindowsUpdate).Version.ToString()
    $PSGalleryVersion = (Find-Module -Name PSWindowsUpdate).Version.ToString()
    If ($InstalledVersion -ne $PSGalleryVersion) {
	    Install-Module -Name PSWindowsUpdate -Force
        shutdown /r /f /t 0
    }
    Import-Module -Name PSWindowsUpdate
}
Catch {
    Install-Module -Name PSWindowsUpdate -Force
}
#############################################################

### INSTALL THE UPDATES
#############################################################
Get-WindowsUpdate -IgnoreReboot -AcceptAll -Install -Confirm:$false
#############################################################