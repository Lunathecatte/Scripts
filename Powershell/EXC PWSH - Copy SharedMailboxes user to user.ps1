# Maak verbinding met Exchange Online
Connect-ExchangeOnline -ShowProgress $true

# Vraag om de bron- en doelgebruikersnamen
$SourceUser = Read-Host -Prompt 'Voer de gebruikersnaam van de bron in'
$TargetUser = Read-Host -Prompt 'Voer de gebruikersnaam van het doel in'

# Vraag of distributiegroepen ook moeten worden overgenomen
$IncludeDistributionGroups = Read-Host -Prompt 'Wilt u ook distributiegroepen overnemen? (Y/n)' -Default 'y'

# Haal alle gedeelde mailboxen op waar de bron gebruiker verzend- en volledige toegangsrechten voor heeft
$Mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {(Get-RecipientPermission $_.Identity | Where-Object { $_.Trustee -like "$SourceUser*" -and $_.AccessRights -eq "SendAs" }) -or (Get-MailboxPermission $_.Identity | Where-Object { $_.User -like "$SourceUser*" -and $_.AccessRights -eq "FullAccess" })}

# Verleen de doelgebruiker dezelfde rechten op deze mailboxen
foreach ($Mailbox in $Mailboxes) {
    Write-Host "Bezig met het toevoegen van rechten aan de mailbox: $($Mailbox.Identity)" -ForegroundColor Green

    # Verleen SendAs-rechten
    if (Get-RecipientPermission $Mailbox.Identity | Where-Object { $_.Trustee -like "$SourceUser*" -and $_.AccessRights -eq "SendAs" }) {
        try {
            Add-RecipientPermission -Identity $Mailbox.Identity -Trustee $TargetUser -AccessRights SendAs
        } catch {
            Write-Host "Er is een fout opgetreden bij het verlenen van SendAs-rechten voor de mailbox: $($Mailbox.Identity)" -ForegroundColor Red
        }
    }

    # Verleen volledige toegangsrechten
    if (Get-MailboxPermission $Mailbox.Identity | Where-Object { $_.User -like "$SourceUser*" -and $_.AccessRights -eq "FullAccess" }) {
        try {
            Add-MailboxPermission -Identity $Mailbox.Identity -User $TargetUser -AccessRights FullAccess -InheritanceType All
        } catch {
            Write-Host "Er is een fout opgetreden bij het verlenen van volledige toegangsrechten voor de mailbox: $($Mailbox.Identity)" -ForegroundColor Red
        }
    }
}

# Als distributiegroepen ook moeten worden overgenomen
if ($IncludeDistributionGroups -eq 'Y' -or $IncludeDistributionGroups -eq 'y') {
    # Haal alle distributiegroepen op waar de bron gebruiker lid van is
    $DistributionGroups = Get-DistributionGroup | Where-Object { (Get-DistributionGroupMember $_.Identity | Where-Object { $_.PrimarySmtpAddress -eq $SourceUser }) }

    # Voeg de doelgebruiker toe aan deze distributiegroepen
    foreach ($Group in $DistributionGroups) {
        try {
            Add-DistributionGroupMember -Identity $Group.Identity -Member $TargetUser
        } catch {
            Write-Host "Er is een fout opgetreden bij het toevoegen van de gebruiker aan de distributiegroep: $($Group.Identity)" -ForegroundColor Red
        }
    }
}
