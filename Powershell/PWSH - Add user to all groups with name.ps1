# Vraag de gebruiker om het trefwoord in te voeren
$keyword = Read-Host "Voer het trefwoord in voor de groepen"

# Zoek alle groepen met het opgegeven trefwoord in hun naam
$groups = Get-ADGroup -Filter {Name -like "*$keyword*"}

# Vraag de gebruikersnaam in om toe te voegen aan de groepen
$username = Read-Host "Voer de gebruikersnaam in om toe te voegen"

# Controleer of de gebruiker bestaat in AD
if (Get-ADUser -Filter {SamAccountName -eq $username}) {
    # Loop door de gevonden groepen en voeg de gebruiker toe
    foreach ($group in $groups) {
        # Controleer of de gebruiker al lid is van de groep
        if (-not (Get-ADGroupMember -Identity $group | Where-Object {$_.SamAccountName -eq $username})) {
            # Voeg de gebruiker toe aan de groep
            Add-ADGroupMember -Identity $group -Members $username
            Write-Host "Gebruiker $username toegevoegd aan groep $($group.Name)"
        } else {
            Write-Host "Gebruiker $username is al lid van groep $($group.Name)"
        }
    }
} else {
    Write-Host "Gebruiker met de naam $username bestaat niet in Active Directory."
}
