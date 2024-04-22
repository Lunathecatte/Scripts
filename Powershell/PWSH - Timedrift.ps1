$hostname = Read-Host -Prompt 'Voer de hostnaam in'
Stop-Service w32time
Unregister-W32Time
Register-W32Time
Start-Service w32time
Start-Sleep -Seconds 15
w32tm /resync
Start-Sleep -Seconds 15
net time \\$hostname /set /y
