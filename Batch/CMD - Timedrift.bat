set /p hostname="Voer de hostnaam in: "
net stop w32time
w32tm /unregister
w32tm /register
net start w32time
sleep 15
w32tm /resync
sleep 15
net time \\%hostname% /set /y
