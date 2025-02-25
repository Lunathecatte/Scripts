# Script om automapping uit te schakelen voor een gedeelde mailbox in Exchange Online
# V0.1
Connect-exchangeonline
cls
# Vraag om gedeelde mailbox
$SharedMailbox = Read-Host -Prompt "Voer de naam in van de gedeelde mailbox waarvoor je automapping wilt bijwerken"

# Verbinden met Exchange Online (veronderstelt dat de ExchangeOnlineManagement-module is geïnstalleerd)
Write-Host "Verbinding maken met Exchange Online..." -ForegroundColor Yellow

try {
    # Haal alle gebruikers met FullAccess op voor de mailbox
    $FullAccessUsers = Get-MailboxPermission -Identity $SharedMailbox | Where-Object {
        $_.AccessRights -contains "FullAccess" -and $_.User -notlike "NT AUTHORITY*"
    }

    if ($FullAccessUsers.Count -eq 0) {
        Write-Host "Er zijn geen gebruikers met FullAccess gevonden voor de mailbox: $SharedMailbox" -ForegroundColor Yellow
        return
    }
    # Verwijder FullAccess-rechten
    foreach ($User in $FullAccessUsers) {
        $UserIdentity = $User.User.ToString()
        Write-Host "FullAccess-rechten verwijdert voor $UserIdentity op $SharedMailbox..." -ForegroundColor Yellow
        Remove-MailboxPermission -Identity $SharedMailbox -User $UserIdentity -AccessRights FullAccess -Confirm:$false
    }

    # Wacht 20 seconden
    Write-Host "Wachten op synchronisatie.." -ForegroundColor Cyan
    Start-Sleep -Seconds 20

    # Voeg FullAccess-rechten opnieuw toe met AutoMapping uitgeschakeld
    foreach ($User in $FullAccessUsers) {
        $UserIdentity = $User.User.ToString()
        Write-Host "FullAccess-rechten opnieuw toegevoegd voor $UserIdentity op $SharedMailbox zonder AutoMapping" -ForegroundColor Green
        Add-MailboxPermission -Identity $SharedMailbox -User $UserIdentity -AccessRights FullAccess -AutoMapping $false -Confirm:$false | Out-Null 
    }


    Write-Host "Automapping bijwerken voltooid voor mailbox: $SharedMailbox" -ForegroundColor Green
} catch {
    Write-Host "Er is een fout opgetreden: $_" -ForegroundColor Red
} finally {
    Disconnect-ExchangeOnline -Confirm:$false
}