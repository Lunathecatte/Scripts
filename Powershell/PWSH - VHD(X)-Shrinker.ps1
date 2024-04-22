<#
.Description
#############################################################
###             Written By Randy Drielinger               ###
###     Automatically shrink VHD(X) files to minimum size   ###
###                       v0.0.1                          ###
#############################################################


This script will search a directory and shrink all VHD(X) files to their minimum size.

Variables:
Path - Specify the path where the script should be looking
Recursive - Switch that enabled recursive search for VHDX files
LogDays - Override the default log keeping (7 days default)
#> 

param(		
		[Parameter(Mandatory=$true)][String]$Path,
        [Parameter(Mandatory=$false)][Switch]$Recursive,
        [Parameter(Mandatory=$false)][int]$LogDays = 7
)
CLS

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
$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$LogPath = "$($ScriptPath)\logs"
$TotalGBFreed = 0
#############################################################

### LOG DIRECTORY
#############################################################
IF (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType "directory" | Out-Null
} else {
    Get-ChildItem $LogPath -Filter "*.log" | ?{($_.LastWriteTime -lt (Get-Date).AddDays(- $LogDays))} | ?{Remove-Item $_.fullname -Force}
}
#############################################################





# FUNCTIONS
#############################################################
#############################################################
function Defrag ($DriveLetter) {
    Write-Host "Degfragging drive $($DriveLetter):" -ForegroundColor Cyan
    Optimize-Volume -DriveLetter $DriveLetter -Defrag   
}

function Shrink ($DriveLetter) {
    $FreeSpace = [math]::floor((Get-PSDrive -Name $DriveLetter).Free / 1GB)
    $ShrinkSize = $FreeSpace - 1
    $Location = (Get-Partition -DriveLetter $DriveLetter | Get-Disk).Location
    Dismount-DiskImage -ImagePath $Location >> $null

    if ($ShrinkSize -gt 1) {
        Write-Host "Shrinking $($Location): to allowed minimum."  -ForegroundColor Cyan
        $script = "select vdisk file=`"$($Location)`"`ncompact vdisk `nexit"
        $script | Out-File -Encoding ASCII -FilePath "$($env:TEMP)\Diskpart-Compact.txt"
        diskpart.exe /s "$($env:TEMP)\Diskpart-Compact.txt" >> $null
    }
    else 
    {
        Write-Host "Skipping `"$($Location)`": Not enough free space.." -ForegroundColor Cyan
    }
}

function MountOrFind ($Location) {
    Write-Host "Mount/Find: `"$($Location)`"" -ForegroundColor Cyan    

    $DiskObj = Get-Disk | where {$_.Location -eq $Location}       
    if ($DiskObj -eq $null) {
        $FreeDriveLetter = ls function:[d-z]: -n | ?{ !(test-path $_) } | random 
        Write-Host "Object is currently not mounted" -ForegroundColor Cyan
        Write-Host "Mounting object to drive $($FreeDriveLetter)" -ForegroundColor Cyan 
        Mount-DiskImage -ImagePath $Location -NoDriveLetter -PassThru -Confirm:$false | Out-Null
        $volInfo = Get-Partition (get-disk | ?{$_.Location -eq $Location}).Number | Get-Volume        
        mountvol $FreeDriveLetter $volInfo.UniqueId | Out-Null
        $DiskObj = Get-Disk | where {$_.Location -eq $Location}       
    }               

    $DriveLetter = "$(($DiskObj | Get-Partition).DriveLetter)".Trim()    
    $pattern = '[^a-zA-Z]'
    $DriveLetter = $DriveLetter -replace $pattern, ""
    
    if ($DriveLetter.Length -eq 0) {Throw "Drive letter was not detected, something must have gone wrong during the mounting process"}
    Write-host "`"$($Location)`" has been located on drive $($DriveLetter):" -ForegroundColor Cyan    
    Return $DriveLetter
}

function ExitScript() {
    Write-Host "#####################################################################" -ForegroundColor Yellow
    Stop-Transcript
    EXIT /B
}
#############################################################
#############################################################

### START TRANSCRIPT
#############################################################
Start-Transcript -Path "$($LogPath)\$((Get-Date).ToString('MMddyyyy_HHmmss')).log"
Write-Host ""
Write-Host ""
#############################################################

### LOGOFF ALL USERS
#############################################################
Write-Host "LOOK FOR FILES" -ForegroundColor Yellow
Write-Host "#####################################################################" -ForegroundColor Yellow
quser | Select-Object -Skip 1 | ForEach-Object {    
    $id = ($_ -split ' +')[-5]
    Write-host "Logging of: $(($_ -split ' +')[1]) (ID: $($id))"
    logoff $id
    Sleep -Seconds 10
}
Sleep -Seconds 60
Write-Host "#####################################################################" -ForegroundColor Yellow
Write-Host "" 
#############################################################


### LOOK FOR FILES
#############################################################
Write-Host "LOOK FOR FILES" -ForegroundColor Yellow
Write-Host "#####################################################################" -ForegroundColor Yellow
if (!$Recursive) { $Objects = Get-ChildItem $Path -File -Filter *.vhd* } else { $Objects = Get-ChildItem $Path -Recurse -File -Filter *.vhd* }
$NumberOfItems = ($Objects | Measure-Object).Count
if ($NumberOfItems -gt 0) {
    Write-Host "$($NumberOfItems) found for processing" -ForegroundColor Cyan
} else {
    Write-Host "No files were found, exiting.." -ForegroundColor Cyan
    ExitScript
}
Write-Host "#####################################################################" -ForegroundColor Yellow
Write-Host "" 
#############################################################

### PROCESSING FILES
#############################################################
Write-Host "PROCESSING FILES" -ForegroundColor Yellow
Write-Host "#####################################################################" -ForegroundColor Yellow
Write-Host ""
ForEach ($Object in $Objects) {
    Write-Host "Processing $($Object.Name)" -ForegroundColor Magenta
    Write-Host "--------------------------------------------" -ForegroundColor Magenta
    $CurrObj = Get-Item -Path $Object.FullName

    if ($CurrObj.Name -like "*template*") { 
        Write-Host "Skipping template file.." -ForegroundColor Cyan
        Write-Host "--------------------------------------------" -ForegroundColor Magenta
        Write-Host ""
        continue     
    }
    
    $ObjSizeinGB = [math]::Round($CurrObj.Length / 1GB, 2)
    Write-Host "Current object size is $($ObjSizeinGB)GB" -ForegroundColor Cyan


    Try{  
        $DriveLetter = MountOrFind($CurrObj.FullName)             
    }Catch{
        Write-Host "Failed to mount: $($CurrObj.FullName)" -ForegroundColor Red        
        Try{ Dismount-DiskImage -ImagePath $CurrObj.FullName -ErrorAction SilentlyContinue | Out-Null } Catch {}
        Write-Host "--------------------------------------------" -ForegroundColor Magenta
        Write-Host ""
        continue
    }
        
    Try{           
        Defrag($DriveLetter)
    }Catch{
        Write-Host "Failed to defrag: $($DriveLetter)" -ForegroundColor Red        
        Try{ Dismount-DiskImage -ImagePath $CurrObj.FullName -ErrorAction SilentlyContinue | Out-Null } Catch {}
        Write-Host "--------------------------------------------" -ForegroundColor Magenta
        Write-Host ""
        continue
    }

    Try{  
        Shrink($DriveLetter)
    }Catch{
        Write-Host "Failed to Shrink: $($DriveLetter)" -ForegroundColor Red        
        Try{ Dismount-DiskImage -ImagePath $CurrObj.FullName -ErrorAction SilentlyContinue | Out-Null } Catch {}
        Write-Host "--------------------------------------------" -ForegroundColor Magenta
        Write-Host ""
        continue
    }
    
    $NewObjSizeinGB = [math]::Round((Get-Item $CurrObj.FullName).Length / 1GB, 2)
    if ($ObjSizeinGB -eq $NewObjSizeinGB) {
        Write-Host "No changes in object size.." -ForegroundColor Cyan
    } else {
        Write-Host "Old Size: $($ObjSizeinGB) GB" -ForegroundColor Cyan
        Write-Host "New Size: $($NewObjSizeinGB) GB" -ForegroundColor Cyan
		Write-Host "Difference: $([math]::Round(($ObjSizeinGB - $NewObjSizeinGB), 2)) GB" -ForegroundColor Cyan
        Write-Host "  "  
        $TotalGBFreed += ($ObjSizeinGB - $NewObjSizeinGB)         
    }

    Try{ 
        Write-Host "Unmounting object `"$($CurrObj.FullName)`"" -ForegroundColor Cyan
        Dismount-DiskImage -ImagePath $CurrObj.FullName | Out-Null 
    } Catch {}
    Write-Host "--------------------------------------------" -ForegroundColor Magenta
    Write-Host ""
}
Write-Host "#####################################################################" -ForegroundColor Yellow
Write-Host ""
Write-Host ""
Write-Host ""
#############################################################


### DISPLAY RESULT
#############################################################
Write-Host "RESULTS" -ForegroundColor Yellow
Write-Host "#####################################################################" -ForegroundColor Yellow
Write-Host "Completed.." -ForegroundColor Green
Write-Host "Total GB's reclaimed: $([math]::Round($TotalGBFreed, 2))" -ForegroundColor Green
Write-Host "#####################################################################" -ForegroundColor Yellow
#############################################################