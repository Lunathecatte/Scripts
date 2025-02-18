### RECHTEN TOEVOEGEN ###

$USER1 = "temp"         ## SOURCE
$USER2 = "temp"         ## DESTINATION

Get-ADUser -Identity $USER1 -Properties memberof |
Select-Object -ExpandProperty memberof |
Add-ADGroupMember -Members $USER2 -PassThru |
Select-Object -Property SamAccountName


#user 1 is van wie de rechte gekopieerd moeten worden. user 2 is de nieuwe gebruiker
