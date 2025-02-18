# Vraag om de bron- en doelgebruikersnamen
$Mailbox = Read-Host -Prompt 'Voer de gewenste mailbox in om CopyforSentAs op in te stellen'

set-mailbox $Mailbox -MessageCopyForSentAsEnabled $True
set-mailbox $Mailbox -MessageCopyForSendOnBehalfEnabled $True