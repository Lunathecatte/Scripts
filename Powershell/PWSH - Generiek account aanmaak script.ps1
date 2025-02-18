# # # Generiek AD Indienst Script
# Door LunatheCatte
# Versiebeheer:
# V0.1 - Eerste opzet  
Clear-Host

# Importeer de Active Directory-module
Import-Module ActiveDirectory

# Vraag de gebruikersinformatie op
$voornaam = Read-Host -Prompt "Voer de voornaam van de gebruiker in"
$tussenvoegsel = Read-Host -Prompt "Voer het tussenvoegsel van de gebruiker in"
if ($tussenvoegsel) {
    # Voeg een spatie toe na tussenvoegsel
    $tussenvoegsel += " "
}
$achternaam = Read-Host -Prompt "Voer de achternaam van de gebruiker in"
$achternaam = "$tussenvoegsel$achternaam" # Voeg tussenvoegsel toe aan de achternaam
$userLogonName = Read-Host -Prompt "Voer de gebruikersnaam van de gebruiker in"
$userLogonName = $userLogonName.Split("@")[0] # Dit zal het "@domein" gedeelte verwijderen als het er is
$wachtwoord = Read-Host -Prompt "Voer het wachtwoord van de gebruiker in" -AsSecureString
$expiryDateString = Read-Host -Prompt "Voer de einddatum van het dienstverband in"
$expiryDate = [DateTime]::ParseExact($expiryDateString, "dd-MM-yyyy", [Globalization.CultureInfo]::InvariantCulture)
$expiryDate = $expiryDate.AddDays(1)
$employeeNumber = Read-Host -Prompt "Voer het personeelsnummer van de gebruiker in"
$functie = Read-Host -Prompt "Voer de functietitel van de gebruiker in"
$afdeling = Read-Host -Prompt "Voer de afdeling van de gebruiker in"
$Tijd = Get-Date -Format "dd-MM-yyyy"
# Vraag welk basisprofiel moet worden gekopieerd (Dit geld alleen als een voorbeeld user is)
$RechtenUser = Read-Host -Prompt "Van wie kunnen we de rechten kopieren? (Dit moet de Pre-2000 username zijn)"

# # # # Algemene gegevens (aanpassen per klant) # # # #

$OUvariabel = "OU=Active Users,OU=Users,OU=Resources,DC=DOMEIN,DC=local"
$domein = "@DOMEIN.nl"
$UserPrincipalName = "$userLogonName$domein"
$email = "$voornaam.$achternaam$domein"
$frommailadres = "Admin <Admin@DOMEIN.nl>"
$SmtpServer = "SMTP.mail.protection.outlook.com"

<# Licentiegroep (voor als er geen basisprofielen zijn)
Write-Host "Geef het nummer in van de type licentie die de gebruiker moet krijgen:" -ForegroundColor Green
Write-Host "1 - A1"
Write-Host "2 - A3"
Write-Host "3 - Business Premium"
$BasisProfiel = Read-Host -Prompt "Typ het nummer"
Switch ($BasisProfiel ) {
    "1" { $BasisProfiel = "A1" }
    "2" { $BasisProfiel = "A3" }
    "3" { $BasisProfiel = "BP" }
    Default { Write-Host "Ongeldige keuze. Probeer het opnieuw." -ForegroundColor red }
}
#>

# Vraag de gebruiker om extra rechten groep
Write-Host "Heeft de gebruiker recht op een van deze groepen? Zo ja, welke? (Als er meerdere zijn, geef dan de nummers op gescheiden door een comma. Zie voorbeeld: 1,3)"
Write-Host "0 - Geen extra rechten"
Write-Host "1 - APP 1"
Write-Host "2 - APP 2"
Write-Host "3 - APP 3"
Write-Host "4 - APP 3"

$KeuzeExtraRechten = Read-Host -Prompt "geef de groep(en) op" 
$ExtraRechten = @()
foreach ($ExtraRechtenNummer in $KeuzeExtraRechten.Split(',')) {
    Switch ($ExtraRechtenNummer.Trim()) {
        "0" { $ExtraRechten += "GEEN" }
        "1" { $ExtraRechten += "App1" }
        "2" { $ExtraRechten += "App2" }
        "3" { $ExtraRechten += "App3" }
        Default { Write-Host "Ongeldige keuze: $ExtraRechtenNummer. Probeer het opnieuw." -ForegroundColor red }
    }
}
Write-Host "De gebruiker heeft rechten op de volgende groepen: $ExtraRechtenNummer"

# # # # Onderstaande gaat over het aanmaken van de user # # # #

Write-Host "Starten met aanmaken van $email" -ForegroundColor DarkMagenta
try {
    # Maak de nieuwe gebruiker aan in de juiste OU
    New-ADUser -SamAccountName $userLogonName -UserPrincipalName $UserPrincipalName -Name "$voornaam $achternaam" -GivenName $voornaam -Surname $achternaam -Enabled $true -DisplayName "$voornaam $achternaam" -AccountExpirationDate $expiryDate -Description "Gebruiker aangemaakt op $Tijd" -EmployeeNumber $employeeNumber -Title $functie -Department $afdeling <#-ScriptPath "logon.bat"#> -AccountPassword $wachtwoord -Email $email -PasswordNeverExpires $true -Path $OUvariabel -PassThru  | Enable-ADAccount

    Write-Host "Gebruiker aangemaakt in de juiste OU" -ForegroundColor Green

    # Rechten overnemen van voorbeeld
    Get-ADUser -Identity $RechtenUser -Properties memberof |
    Select-Object -ExpandProperty memberof |
    Add-ADGroupMember -Members $userLogonName -PassThru |
    Select-Object -Property SamAccountName

    Write-Host "Rechten overgenomen van $RechtenUser" -ForegroundColor Green

    # Voeg de gebruiker toe aan de gespecificeerde groepen
    $ExtraRechten | ForEach-Object {
        if ($ExtraRechten = "GEEN") {
            write-host "Geen extra rechten toegevoegd"
        }
        else {
            $group = Get-ADGroup -Identity $_.Trim() -ErrorAction SilentlyContinue
            $user = Get-ADUser -Identity $userLogonName -ErrorAction SilentlyContinue
            if ($group -and $user) {
                Add-ADGroupMember -Identity $group -Members $user
            }
            else {
                if (-not $group) { Write-Host "Groep '$_' niet gevonden." -ForegroundColor red }
                if (-not $user) { Write-Host "Gebruiker '$userLogonName' niet gevonden." -ForegroundColor red }
            }
        }
    
    }
    Write-Host "$ExtraRechten toegevoegd" -ForegroundColor Green

    # Stel het wachtwoord in om nooit te verlopen
    Set-ADUser -Identity $userLogonName -passwordNeverExpires $true
    Write-Host "Wachtwoord ingesteld om nooit te verlopen" -ForegroundColor Yellow

    # Vul de extra velden in
    Set-ADUser -Identity $userLogonName -EmailAddress $email -Title $functie -Department $afdeling -AccountExpirationDate $expiryDate -Replace @{employeeNumber = $employeeNumber }
    Write-Host "Extra velden ingevuld" -ForegroundColor Green
    Write-Host "Account is succesvol aangemaakt." -ForegroundColor blue
}
catch {
    Write-Host "Er is een fout opgetreden: $($_.Exception.Message)" -ForegroundColor red
}

# Vraag of de AAD sync moet worden uitgevoerd
$runSync = Read-Host "Wil je een AAD sync uitvoeren? (Y/n)"
if ($runSync -eq "" -or $runSync -eq "y" -or $runSync -eq "y") {
    # Maak verbinding met AADCONNECT voor SYNC naar O365
    try {
        $session = New-PSSession -ComputerName "AAD Connect Server"
        Invoke-Command -Session $session -ScriptBlock { Import-Module ADSync }
        Invoke-Command -Session $session -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Delta }
    }
    catch {
        Write-Host "Er is een fout opgetreden: $($_.Exception.Message)" -ForegroundColor red
    }
    finally {
        Remove-PSSession -Session $session
    }
}
else {
    Write-Host "AAD sync is niet uitgevoerd." -ForegroundColor red
}

#Mail sturen naar aanvrager om door te sturen naar klant
$OutputEmail = Read-Host -Prompt "Voer je email in voor het versturen van de gegevens (bijvoorbeeld testuser@domein.nl)"
$message = "


Beste,

Onderstaand de output van het script.

Name: $voornaam $achternaam
Email: $email
SamAccountName: $userLogonName
Afdeling: $afdeling
Functie: $functie
Personeelsnummer: $employeeNumber

Met vriendelijke groet,
IT Automatisering

"
Send-MailMessage -From $frommailadres -To $OutputEmail -Subject 'Account automatisering' -Body $message -SmtpServer $SmtpServer