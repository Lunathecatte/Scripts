Import-Module AzureAD

$gebruikersnaam= Read-Host -Prompt 'Gebruikersnaam van de gerbuiker'
 
$gebruiker= Get-AzureADUser -SearchString $gebruikersnaam
$objectId = $gebruiker.ObjectId
 
# Revoke all refresh tokens for the user
Revoke-AzureADUserAllRefreshToken -ObjectId $objectId