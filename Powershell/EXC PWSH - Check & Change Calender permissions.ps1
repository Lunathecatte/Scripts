Cls
# Maak verbinding met Exchange Online
Connect-ExchangeOnline -ShowProgress $true
cls
Write-host " - - - Uitlezen van Mailbox calender permissies - - -" -ForegroundColor Green
# Vraag om de bron- en doelgebruikersnamen
$CalenderUser = Read-Host -Prompt 'Voer het e-mail adres in van de gebruiker die je onderzocht wil hebben'

#Uitlezen mailbox

Try {
    Get-MailboxFolderPermission -Identity "${CalenderUser}:\Calendar" -ErrorAction SilentlyContinue
}
Catch {
}

Try {
    Get-MailboxFolderPermission -Identity "${CalenderUser}:\Agenda" -ErrorAction SilentlyContinue
}
Catch {
}
Try {
    Get-MailboxFolderPermission -Identity "${CalenderUser}:\Calender" -ErrorAction SilentlyContinue
}
Catch {
}

Write-host "Wil je aanpassingen maken?"
$Aanpassingen = read-host "ja/nee"
if ($Aanpassingen -like "ja"){
$UserPermissions = Read-Host -Prompt ("Wie wil je aanpassen / toegang geven tot" + $CalenderUser + "?")
$Permissions = Read-Host -Prompt ("Welke permissions wil je dat een " + $UserPermissions + " krijgt op " + $CalenderUser + "?")
    Try {
        Set-MailboxFolderPermission -Identity "${CalenderUser}:\Calendar" -ErrorAction SilentlyContinue -AccessRights $Permissions -User $UserPermissions
    }
    Catch {
    }

    Try {
        Set-MailboxFolderPermission -Identity "${CalenderUser}:\Agenda" -ErrorAction SilentlyContinue -AccessRights $Permissions -User $UserPermissions
    }
    Catch {
    }
    Try {
        Set-MailboxFolderPermission -Identity "${CalenderUser}:\Calender" -ErrorAction SilentlyContinue -AccessRights $Permissions -User $UserPermissions
    }
    Catch {
    }
}
Elseif ($Aanpassingen -like "Ja"){
$UserPermissions = Read-Host -Prompt ("Wie wil je aanpassen / toegang geven tot" + $CalenderUser + "?")
$Permissions = Read-Host -Prompt ("Welke permissions wil je dat een " + $UserPermissions + " krijgt op " + $CalenderUser + "?")
    Try {
        Set-MailboxFolderPermission -Identity "${CalenderUser}:\Calendar" -ErrorAction SilentlyContinue -AccessRights $Permissions -User $UserPermissions
    }
    Catch {
    }

    Try {
        Set-MailboxFolderPermission -Identity "${CalenderUser}:\Agenda" -ErrorAction SilentlyContinue -AccessRights $Permissions -User $UserPermissions
    }
    Catch {
    }
    Try {
        Set-MailboxFolderPermission -Identity "${CalenderUser}:\Calender" -ErrorAction SilentlyContinue -AccessRights $Permissions -User $UserPermissions
    }
    Catch {
    }
}
Else{
exit
}