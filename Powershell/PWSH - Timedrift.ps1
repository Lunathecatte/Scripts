# Display current time configuration
Get-WmiObject Win32_TimeZone

# Set the NTP server (replace with your preferred NTP server if necessary)
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update

# Restart the Windows Time service to apply the changes
Restart-Service w32time

# Force synchronization
w32tm /resync

$hostname = Read-Host -Prompt 'Voer de hostnaam in'
Stop-Service w32time
w32tm /unregister
w32tm /register
Start-Service w32time
Start-Sleep -Seconds 15
w32tm /resync
Start-Sleep -Seconds 15
net time \\$hostname /set /y
