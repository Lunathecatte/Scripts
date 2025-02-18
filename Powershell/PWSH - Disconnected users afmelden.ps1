# Script voor automatisch afmelden van disconnected users
# Versie 1.0 - Eerste opzet

# Haal een lijst op van alle sessies
$sessies = quser | Select-String "Disc" 

foreach ($sessie in $sessies) {
    $sessieId = ($sessie -split '\s+')[2] #\s+ betekent dat hij splitst na 2 spaties en dus het ID krijgt
    $username = ($sessie -split '\s+' )[1]
    $AfgemeldSinds = ($sessie -split '\s+' )[4]
    
    if ( $AfgemeldSinds -gt 30){
        # Meld de sessie af
        write-host $username wordt afgemeld... -foreground yellow
        logoff $sessieId
        write-host $username is afgemeld... -foreground green
    }
    Else{
        write-host "$username is pas $AfgemeldSinds minuten disconnected, user wordt pas afgemeld wanneer langer dan 10 minuten disconnected is.." -ForegroundColor Red
    }
}
