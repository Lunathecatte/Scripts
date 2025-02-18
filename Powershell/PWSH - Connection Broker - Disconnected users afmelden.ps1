# Script voor automatisch afmelden van disconnected users
# Versie 1.3 - Onderzoekt alle servers in alle RDS collecties
$allServers = @() # voor later gebruik.

# Verkrijg alle RDS-collecties
$collecties = Get-RDSessionCollection

if ($collecties -eq $null -or $collecties.Count -eq 0) {
    Write-Host "Geen RDS-collecties gevonden." -ForegroundColor red
    exit
}

Write-Host "Gevonden collecties:"
$collecties | Format-Table CollectionName, CollectionID

### Alle gevonden collecties langs gaan om een lijst op te maken met alle servers

foreach ($collectie in $collecties) {
    $collectionName = $collectie.CollectionName
    Write-Host "`nVerwerken collectie: $collectionName" -ForegroundColor Cyan

    try {
        # Verkrijg servers in de collectie
        $servers = Get-RDSessionHost -CollectionName $collectionName

        if ($servers -eq $null -or $servers.Count -eq 0) {
            Write-Host "Geen servers gevonden in collectie: $collectionName" -ForegroundColor red
        } else {
            #$servers | Format-Table ServerName, SessionCount
        }
    } catch {
        Write-Host "Fout bij ophalen van servers voor collectie: $collectionName" -ForegroundColor red
        Write-Host "Foutmelding: $_" -ForegroundColor red
    }

        foreach ($server in $servers) {
        $serverInfo = New-Object PSObject -Property @{
            CollectionName = $collectionName
            ServerName = $server.SessionHost
        }
        $allServers += $serverInfo
        
    }

}

#### USERS AFLMELDEN VAN LIJST AAN GEVONDEN SERVERS
## lijst van servers laten zien
$allServers | Format-Table -AutoSize

# Inloggen op alle servers
foreach($allServer in $allServers) {
    $serverName = $allServer.ServerName
    Write-Host "Uitvoeren quser op server $serverName.." -ForegroundColor Yellow
    try {
        $sessies = Invoke-Command -ComputerName $serverName -ScriptBlock { quser } | Select-String "Disc"

        foreach ($sessie in $sessies) {
            $sessieId = ($sessie -split '\s+')[2] #\s+ betekent dat hij splitst na 2 spaties en dus het ID krijgt
            $username = ($sessie -split '\s+' )[1]
            $afgemeldSinds = ($sessie -split '\s+' )[4]

            if ($afgemeldSinds -gt 30) {
                # Meld de sessie af
                Write-Host "$username wordt afgemeld..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $serverName -ScriptBlock { param ($id) logoff $id } -ArgumentList $sessieId
                Write-Host "$username is afgemeld..." -ForegroundColor Green
            } else {
                Write-Host "$username is pas $afgemeldSinds minuten disconnected, user wordt pas afgemeld wanneer langer dan 30 minuten disconnected is.." -ForegroundColor Orange
            }
        }
    } catch {
        Write-Host "Fout bij uitvoeren van quser op server: $serverName" -ForegroundColor Red
    }
}