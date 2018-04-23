@echo off

REM config
setlocal EnableDelayedExpansion
set CALLPATH=%~dp0
set REGKEY="HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\NCWest\BnS"

REM needs administrator rights
REM we run net session to check the error returned
net session > NUL 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
    call :kill 1 "You need to execute as administrator"
)

REM this key is required
REM we check if it exists before trying to run the code
REG QUERY !REGKEY! > NUL 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
    call :kill 1 "Registry key not found"
)

REM checks if the game is running | https://stackoverflow.com/a/1329790
tasklist /FI "WINDOWTITLE eq Blade & Soul" 2>NUL | find /I /N "Client.exe">NUL
IF %ERRORLEVEL% EQU 0 (
    call :kill 1 "Close the game before installing the Xigncode Bypasser"
)

REM fetches the data in the registry
for /f "tokens=2*" %%a in ('REG QUERY !REGKEY! /v BaseDir') do set "AppPath=%%~b\"

REM ready to replace everything
echo This will install the XignCode Bypasser
echo --------------------------------------------------------------------------------
echo Game installation: !AppPath!
echo Executing from: !CALLPATH!
IF NOT EXIST "!AppPath!*" (
	call :kill 1 "!AppPath! doesn't exist or is empty"
)
call :pause "If you wish to continue, press any key. Otherwise, close this window."

REM call the patching function
for %%b in (32,64) do call :patch %%b

echo --------------------------------------------------------------------------------
echo The XignCode Bypasser was successfully installed
call :kill 0 "More in http://bnsbuddy.com/ and https://www.reddit.com/r/BladeAndSoulMods/"

REM FUNCTION DECLARATION!

:pause
REM handles the pausing
set a=%1
echo !a:"=!
pause >nul
goto :eof

:kill
REM creates the exit messages
IF NOT [%2] EQU [] (
	set a=%2
	echo !a:"=!
)
call :pause "Press any key to close."
exit %1
goto :eof

:patch
REM function to handle the patching
set bits=%1
set folder=!CALLPATH!!bits!\
set dll=bsengine_Shipping
set target=!AppPath!\bin

IF NOT !bits! EQU 32 (
	REM 64bit (or, if it ever exists for consumers, 128bit) paths need treatment -.-
	set dll=!dll!!bits!
	set target=!target!!bits!
)

REM make sure the folder with the contents exist
IF NOT EXIST "!folder!*" (
	call :kill 1 "Folder !bits! doesn't exist or is empty"
)

REM it exists, confirm the remaining
IF NOT EXIST "!folder!XignCode\*" (
	call :kill 1 "Folder !bits!\XignCode doesn't exist or is empty"
)
IF NOT EXIST "!folder!!dll!.dll" (
	call :kill 1 "File !bits!\!dll!.dll doesn't exist"
)

echo Folder !bits! found, copying files ...

REM begin copying the directory
xcopy "!folder!XignCode" "!target!\XignCode\" /i /s /q /y >nul 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
    call :kill 1 "Error (%ERRORLEVEL%) while copying the folder !bits!\XignCode"
)

REM copy the dll file
copy "!folder!!dll!.dll" "!target!\XignCode\!dll!.dll" /b /y >nul 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
    call :kill 1 "Error (%ERRORLEVEL%) while copying the file !bits!\!dll!.dll"
)
goto :eof
