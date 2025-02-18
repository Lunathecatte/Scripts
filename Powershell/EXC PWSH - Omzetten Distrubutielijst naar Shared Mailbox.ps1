Connect-ExchangeOnline

# Vraag om de input
$DistributionList = Read-Host "Voer het e-mailadres van de distributielijst in (bijv. distributielijst@je_domein.com)"
$SharedMailbox = Read-Host "Voer het gewenste e-mailadres in voor de gedeelde mailbox (bijv. gedeeldemailbox@je_domein.com)"
$DisplayName = Read-Host "Voer de naam in voor de gedeelde mailbox"

# 1. Haal de leden van de distributielijst op
$Members = Get-DistributionGroupMember -Identity $DistributionList

# 2. Converteer de distributielijst naar een gedeelde mailbox
New-Mailbox -Shared -Name $DisplayName -PrimarySmtpAddress $SharedMailbox

# 3. Voeg de oorspronkelijke leden toe als gedelegeerden aan de nieuwe gedeelde mailbox
foreach ($Member in $Members) {
    Add-MailboxPermission -Identity $SharedMailbox -User $Member.PrimarySmtpAddress -AccessRights FullAccess -InheritanceType All
}

# 4. (Optioneel) Verwijder de originele distributielijst
Remove-DistributionGroup -Identity $DistributionList

Write-Host "De distributielijst is succesvol omgezet naar een gedeelde mailbox."
