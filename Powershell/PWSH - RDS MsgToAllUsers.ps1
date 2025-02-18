# Vraag om het bericht dat naar alle actieve gebruikers moet worden gestuurd
$message = Read-Host "Voer het bericht in dat je wilt versturen naar alle ingelogde gebruikers"

# Haal de lijst van alle actieve sessies op de RDS server op
$activeSessions = query user | Where-Object { $_ -match ' Active ' }

# Loop door elke actieve sessie en stuur het bericht
foreach ($session in $activeSessions) {
    # Split de output van query user om de juiste kolommen te identificeren
    $fields = $session -split "\s+"

    # Controleer of de sessie-ID numeriek is, meestal in de derde of vierde kolom
    if ($fields[2] -match '^\d+$') {
        $sessionID = $fields[2]
    } elseif ($fields[3] -match '^\d+$') {
        $sessionID = $fields[3]
    } else {
        Write-Host "Ongeldige sessie-ID gevonden: $session"
        continue
    }

    # Zorg ervoor dat het bericht correct is geformatteerd met aanhalingstekens
    $formattedMessage = "$message"
    
    # Log de sessie-ID en bericht voor debugging
    Write-Host "Verzend bericht naar sessie-ID: $sessionID met bericht: $formattedMessage"

    # Stuur het bericht naar de actieve sessie met de msg command, sessie-ID en bericht moeten tussen quotes
    try {
        Start-Process "msg" -ArgumentList "$sessionID", "$formattedMessage"
    } catch {
        Write-Host "Fout bij het verzenden van bericht naar sessie $sessionID"
    }
}

