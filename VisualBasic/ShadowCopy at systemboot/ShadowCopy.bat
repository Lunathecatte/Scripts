@echo off
REM Create shadow copies for specified volumes
REM Adjust the volume names (C, D, E, F, G) as needed

REM Create shadow copy for C:
wmic shadowcopy call create Volume=C:\

REM Create shadow copy for D:
wmic shadowcopy call create Volume=D:\

REM Create shadow copy for E:
wmic shadowcopy call create Volume=E:\

REM Create shadow copy for F:
wmic shadowcopy call create Volume=F:\

REM Create shadow copy for G:
wmic shadowcopy call create Volume=G:\

REM Display a message (optional)
echo Shadow copies created successfully!

REM Exit the script
exit /b
