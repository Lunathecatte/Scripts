write-host "Inloggen bij Azure-AD van klant.." -ForegroundColor Yellow
# Verbinding maken met AAD
if (-not (Get-Module -ListAvailable -Name AzureAD)) {
    Install-Module -Name AzureAD -Force -AllowClobber
}
Import-Module -Name AzureAD
Connect-AzureAD | Out-Null
clear-host 

# Voer bron gebruiker op
$user1 = Read-host "Voer bron gebruiker in: "

# Voer doel gebruiker op
$user2  = Read-host "Voer doel gebruiker in: " 

# Verkrijg  ObjectIds
$user1Obj = Get-AzureADUser -ObjectID $user1
$user2Obj = Get-AzureADUser -ObjectID $user2


$membershipGroups = Get-AzureADUserMembership -ObjectId $user1Obj.ObjectId

Write-Host "\-- Volgende groepen zijn over te nemen van" $user1 naar $user2 "--\" -ForegroundColor Green

foreach($group in $membershipGroups) {
Write-Host "[!] - Toevoegen van" $user2Obj.UserPrincipalName " aan " $group.DisplayName "... " -ForegroundColor Green -nonewline
Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $user2Obj.ObjectId
Write-Host "Klaar"
}