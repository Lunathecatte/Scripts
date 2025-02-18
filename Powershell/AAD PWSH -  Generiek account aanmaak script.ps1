# # # Generiek O365 account aanmaak Script
# Door LunatheCatte
# Versiebeheer:
# V0.1 - Eerste opzet  
# V0.2 - Toevoegen module voor Domeinkeuze module
# V0.3 - Toevoegen module voor Mailboxbeheer module
# V0.4 - Toevoegen module voor Groepsbeheer module
# V0.5 - Toevoegen standaardgroepenlijst op basis van een array  
# V0.6 - Toevoegen module voor het verzenden van e-mails aan het einde
# V0.7 - Leesbaarheid verhoogd dmv comments
# V0.7.1 - Bugfix mbt lege velden in accountgegevens module
# V0.8 - Eerste opzet mbt licentiegroepen

clear-host
Write-host "# # # # Account aanmaak script  - Versie 0.7.1 # # # #" -ForegroundColor Green
Write-host "Zorg dat er een licentie beschikbaar is bij de klant VOORDAT je dit script draait" -ForegroundColor Yellow
Write-host "Draai dit script ALTIJD in de 'oude' powershell, NIET de v7" -ForegroundColor RED
Start-sleep 3
write-host "Inloggen bij Azure-AD van klant.." -ForegroundColor Yellow
# Verbinding maken met AAD
if (-not (Get-Module -ListAvailable -Name AzureAD)) {
    Install-Module -Name AzureAD -Force -AllowClobber
}
Import-Module -Name AzureAD
Connect-AzureAD | Out-Null
clear-host 

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# Accountgegevens Module
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
write-host "- - - GEGEVENSOPVRAAG MODULE - - -" -ForegroundColor Green
$FirstName = Read-Host "Voornaam"
$MiddleName = Read-Host "Tussenvoegsel (laat leeg indien niet van toepassing)"
$LastName = Read-Host "Achternaam"
$Email = Read-Host "Voer de gebruikersnaam van de gebruiker in"
$Email = $Email.Split("@")[0] # Dit zal het "@EMAIL" gedeelte verwijderen als het er is
$MobileNumber = Read-Host "Mobiel nummer (bijv. 0612345678)"
$Department = Read-Host "Afdeling"
$JobTitle = Read-host "Functie"
$wachtwoord = Read-Host "Voer het wachtwoord van de gebruiker in" -AsSecureString
clear-host

# Controleer of de waarden leeg zijn en zet ze anders op $null
if ([string]::IsNullOrWhiteSpace($FirstName)) {
    $FirstName = $null
}

if ([string]::IsNullOrWhiteSpace($MiddleName)) {
    $MiddleName = $null
}

if ([string]::IsNullOrWhiteSpace($LastName)) {
    Write-Host "Achternaam is verplicht!" -ForegroundColor Red
    exit
}

if ([string]::IsNullOrWhiteSpace($Email)) {
    Write-Host "email is verplicht!" -ForegroundColor Red
    exit
}

if ([string]::IsNullOrWhiteSpace($MobileNumber)) {
    $MobileNumber = $null
}

if ([string]::IsNullOrWhiteSpace($Department)) {
    $Department = $null
}

if ([string]::IsNullOrWhiteSpace($JobTitle)) {
    $JobTitle = $null
}

# Controleer of het wachtwoord niet is ingesteld
if ($wachtwoord -eq $null) {
    Write-Host "Het wachtwoord is verplicht!" -ForegroundColor Red
    exit
}

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# DOMEINKEUZE MODULE
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
write-host "- - - DOMEINKEUZE MODULE - - -" -ForegroundColor Green
# Haal de domeinen op uit Azure AD
$Domeinen = Get-AzureADDomain

# Toon de domeinen als genummerde lijst
Write-Host "Voer het nummer in dat overeenkomt met het domein dat gebruikt moet worden:" -ForegroundColor Green

# Genereer een genummerde lijst van domeinen
$Domeinen | ForEach-Object -Begin { $DomeinCounter = 1 } {
    Write-Host "$DomeinCounter. $($_.Name)"
    $DomeinCounter++
}

# Vraag de gebruiker om een nummer in te voeren
$Domeinkeuze = Read-Host -Prompt "Kies het nummer van het gewenste domein"

# Verkrijg het gekozen domein
$GekozenDomein = $Domeinen[$Domeinkeuze - 1]
Write-Host "Je hebt gekozen voor het domein: $($GekozenDomein.Name)" -ForegroundColor Cyan
$GekozenDomein = $GekozenDomein.Name
Start-sleep 2

# Genereer het e-mailadres
$Email = "$Email@$GekozenDomein"
# Controleer of het e-mailadres al bestaat
$Bestaandegebruiker = Get-AzureADUser -SearchString "$Email" 

if ($Bestaandegebruiker -ne $null) {
    Write-Host "$Email bestaat al.." -ForegroundColor Red
    start-sleep 3
    exit
    }
$mailNickname = $email.Split("@")[0]
Clear-host

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# GEBRUIKER AANMAAK MODULE
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
try{
    New-AzureADUser -DisplayName "$FirstName $MiddleName $LastName" `
    -GivenName $FirstName `
    -Surname "$MiddleName $LastName" `
    -UserPrincipalName $Email `
    -AccountEnabled $true `
    -PasswordProfile @{Password = $wachtwoord; ForceChangePasswordNextLogin = $true} `
    -mailNickname $mailNickname `
    -Department $Department `
    -Mobile $MobileNumber `
    -JobTitle $JobTitle `
    -ErrorAction SilentlyContinue `
    | Out-Null

    Write-Host "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#" -ForegroundColor Yellow
    Write-Host "Account is succesvol aangemaakt." -ForegroundColor Green
    Write-Host "#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#" -ForegroundColor Yellow
}
catch{
    Write-host "Gebruiker niet aangemaakt, Error:" -ForegroundColor red
    Write-host "$($_.Exception.Message)" -ForegroundColor Yellow
    exit
}

start-sleep 3
clear-host

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# Groepsbeheer module
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
write-host "- - - Groepsbeheer module - - -" -ForegroundColor Green
# Array met licentiegroepen
$licenseGroups = @(
    "Licentiegroep1",
    "Licentiegroep2"
)

# Toon de opties
Write-Host "Kies een of meerdere licentiegroepen door het corresponderende nummer in te voeren, gescheiden door een komm:`n"
for ($i = 0; $i -lt $licenseGroups.Count; $i++) {
    Write-Host "$($i + 1). $($licenseGroups[$i])"
}

# Vraag om invoer
$userInput = Read-Host "Voer je keuze(s) in (bijv. 1,3,5)"

# Zorg ervoor dat de invoer wordt behandeld als een lijst, zelfs als het slechts één getal is
$selectedIndices = $userInput -split ',' | ForEach-Object {
    $_ = $_.Trim()
    if ([int]::TryParse($_, [ref]$null)) {
        [int]$_ - 1
    }
} | Where-Object { $_ -ge 0 -and $_ -lt $licenseGroups.Count }

# Toon de geselecteerde licentiegroepen
Write-Host "`nGeselecteerde licentiegroepen:"
$selectedGroups = $selectedIndices | ForEach-Object { $licenseGroups[$_] }
$selectedGroups | ForEach-Object { Write-Host "- $_" }

# Voeg de gebruiker toe aan de geselecteerde groepen
Write-Host "`nBezig met toevoegen van de gebruiker aan de geselecteerde groepen..."
foreach ($group in $selectedGroups) {
    try {
        # Haal de Group ObjectId op
        $groupObjectId = (Get-AzureADGroup -Filter "DisplayName eq '$group'" -ErrorAction Stop).ObjectId

        # Haal de User ObjectId op
        $user = Get-AzureADUser -Filter "UserPrincipalName eq '$Email'" -ErrorAction Stop
        $userObjectId = $user.ObjectId

        # Voeg de gebruiker toe aan de groep
        Add-AzureADGroupMember -ObjectId $groupObjectId -RefObjectId $userObjectId | Out-Null
        Write-Host "Gebruiker succesvol toegevoegd aan groep: $group"
    } catch {
        Write-Host "Fout bij het toevoegen van gebruiker aan groep $_" -ForegroundColor Red
    }
}


# Groepen toevoegen - Worden uitgelezen uit onderstaande Array
$StandaardGroepenlijst = @(
    "DefaultUserGroep1"
)
write-host "Volgende groepen toegevoegd:" -ForegroundColor green
foreach ($Groep in $StandaardGroepenlijst) {
    write-host $Groep
    try {
    Add-AzureADGroupMember -ObjectId (Get-AzureADGroup -SearchString $Groep).ObjectId -RefObjectId (Get-AzureADUser -SearchString "$Email").ObjectId | Out-Null
} catch {
    
    }
}
$confirmCopy = Read-Host "Wil je groepen van een andere gebruiker kopieren? (ja/nee)"

# Voer het script alleen uit als de invoer "ja" is
if ($confirmCopy -eq "ja") {
    # Enter login name of the first user
    $user1 = Read-Host "Voer het e-mail adres in van de gebruiker waar je rechten van wilt overnemen"

    # Enter login name of the second user
    $user2 = $Email

    # Get ObjectId based on username of user to copy from and user to copy to
    $user1Obj = Get-AzureADUser -ObjectId $user1
    $user2Obj = Get-AzureADUser -ObjectId $user2

    # Retrieve membership groups
    $membershipGroups = Get-AzureADUserMembership -ObjectId $user1Obj.ObjectId

    Write-Host "Groepen die gekopieerd kunnen worden van $user1 naar $user2" -ForegroundColor Yellow

    foreach ($group in $membershipGroups) {
        Write-Host "[!] - Toevoegen van "$group.DisplayName"aan"$user2Obj.UserPrincipalName"... `n" -ForegroundColor Green -NoNewline
        
        try{
            Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $user2Obj.ObjectId | Out-Null
        }
        Catch{
            
        }
    }
} else {
    Write-Host "Geen rechten overgenomen." -ForegroundColor Yellow
}
Write-host "Klaar met overnemen van groepen!" -ForegroundColor Green
Start-sleep 3
Clear-Host

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# MAILBOX MODULE
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
write-host "- - - Mailboxbeheer module - - -" -ForegroundColor Green
$bevestiging = Read-Host "Wil je mailboxen overnemen van een andere gebruiker? (ja/nee)"

if ($bevestiging -eq "ja") {
    # Maak verbinding met Exchange Online
    Connect-ExchangeOnline -ShowProgress $true
    # Vraag om de bron- en doelgebruikersnamen
    Clear-Host
    write-host "- - - Mailboxbeheer module - - -" -ForegroundColor Green
    write-host "Module is erg traag, dit komt door Exchange Online van Microsoft" -ForegroundColor yellow
    $BronGebruiker = Read-Host -Prompt 'Voer de gebruikersnaam van de bron in'
    $DoelGebruiker = $Email

    # Vraag of distributiegroepen ook moeten worden overgenomen
    $InclusiefDistributiegroepen = Read-Host -Prompt 'Wil je ook distributiegroepen overnemen? (ja/nee)'

    # Haal alle gedeelde mailboxen op waar de bron gebruiker verzend- en volledige toegangsrechten voor heeft
    $Mailboxen = Get-Mailbox -ResultSize Unlimited | Where-Object {
        (Get-RecipientPermission $_.Identity | Where-Object { $_.Trustee -like "$BronGebruiker*" -and $_.AccessRights -eq "SendAs" }) -or 
        (Get-MailboxPermission $_.Identity | Where-Object { $_.User -like "$BronGebruiker*" -and $_.AccessRights -eq "FullAccess" })
    } 

    # Verleen de doelgebruiker dezelfde rechten op deze mailboxen
    foreach ($Mailbox in $Mailboxen) {
        Write-Host "[!] - Toevoegen van rechten aan: $($Mailbox.Identity)" -ForegroundColor Green

        # Verleen SendAs-rechten
        if (Get-RecipientPermission $Mailbox.Identity | Where-Object { $_.Trustee -like "$BronGebruiker*" -and $_.AccessRights -eq "SendAs" }) {
            try {
                Add-RecipientPermission -Identity $Mailbox.Identity -Trustee $DoelGebruiker -AccessRights SendAs -Confirm:$false | Out-Null
            } catch {
                Write-Host "Er is een fout opgetreden bij het verlenen van SendAs-rechten voor de mailbox: $($Mailbox.Identity)" -ForegroundColor Red
            }
        }

        # Verleen volledige toegangsrechten
        if (Get-MailboxPermission $Mailbox.Identity | Where-Object { $_.User -like "$BronGebruiker*" -and $_.AccessRights -eq "FullAccess" }) {
            try {
                Add-MailboxPermission -Identity $Mailbox.Identity -User $DoelGebruiker -AccessRights FullAccess -InheritanceType All -Confirm:$false | Out-Null
            } catch {
                Write-Host "Er is een fout opgetreden bij het verlenen van volledige toegangsrechten voor de mailbox: $($Mailbox.Identity)" -ForegroundColor Red
            }
        }
    }

    # Als distributiegroepen ook moeten worden overgenomen
    if ($InclusiefDistributiegroepen -eq 'ja') {
        # Haal alle distributiegroepen op waar de bron gebruiker lid van is
        $Distributiegroepen = Get-DistributionGroup | Where-Object {
            (Get-DistributionGroupMember $_.Identity | Where-Object { $_.PrimarySmtpAddress -eq $BronGebruiker })
        }

        # Voeg de doelgebruiker toe aan deze distributiegroepen
        foreach ($Groep in $Distributiegroepen) {
            try {
                Add-DistributionGroupMember -Identity $Groep.Identity -Member $DoelGebruiker -Confirm:$false | Out-Null
            } catch {
                Write-Host "Er is een fout opgetreden bij het toevoegen van de gebruiker aan de distributiegroep: $($Groep.Identity)" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "Er zijn geen mailboxen overgenomen." -ForegroundColor Yellow
}

#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# Mail Module
#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#
# Werkt alleen als je SMTP configureerd
$OutputEmail = Read-Host -Prompt "Voer je email in voor het versturen van de gegevens (bijvoorbeeld jan.jansen@jansen.nl)"
$message = "Beste,

Onderstaand de output van het script.

Name: $FirstName $MiddleName $LastName
Email: $email
Afdeling: $Department
Functie: $JobTitle
Mobielnummer: $MobileNumber

Met vriendelijke groet,
Account Automatisering"

Send-MailMessage -From 'Account Admin <AccountAutomatisering@DOMAIN.nl>' -To $OutputEmail -Subject 'Account Aangemaakt' -Body $message -SmtpServer 'ENTERSMTPSERVER'
Clear-Host