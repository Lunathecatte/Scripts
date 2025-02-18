# Maak verbinding met Exchange Online
Connect-ExchangeOnline -ShowProgress $true

# User opvragen
$user1 = Read-host "Voer e-mail in van gebruiker die je onderzocht wil"

# Zoeken naar mailboxen
Write-host "- - - - - Mailboxen - - - - -" -ForegroundColor Blue
Get-Mailbox | Get-MailboxPermission -User $user1 | Format-Table -AutoSize

# Zoeken naar Mailgroepen
Write-host "- - - - - Mailgroepen - - - - -" -ForegroundColor Blue
Get-DistributionGroup | Get-DistributionGroupMember -ResultSize Unlimited | Where-Object {$_.PrimarySmtpAddress -eq $user1} | Format-Table -AutoSize
