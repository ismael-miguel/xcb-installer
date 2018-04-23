@echo off

REM config
setlocal EnableDelayedExpansion
set CALLPATH=%~dp0
set REGKEY="HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\NCWest\BnS"

REM needs administrator rights
REM we run net session to check the error returned
net session > NUL 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
    call :kill "You need to execute this as administrator"
)

REM this key is required
REM we check if it exists before trying to run the code
REG QUERY !REGKEY! > NUL 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
    call :kill "Registry key not found"
)

REM fetches the data in the registry
for /f "tokens=2*" %%a in ('REG QUERY !REGKEY! /v BaseDir') do set "AppPath=%%~b\"

REM ready to replace everything
echo This will install the XignCode Bypasser.
echo --------------------------------------------------------------------------------
echo Detected the game installation on !AppPath!
echo Executing from !CALLPATH!
IF NOT EXIST "!AppPath!*" (
    call :kill "!AppPath! doesn't exist or is empty"
)
echo If you wish to continue, press any key. Otherwise, close this window.
pause >nul

REM call the patching function
call :patch 32
call :patch 64

echo --------------------------------------------------------------------------------
echo The XignCode Bypasser was successfully installed
echo More in http://bnsbuddy.com/ and https://www.reddit.com/r/BladeAndSoulMods/
echo Press any key to exit

pause >nul
exit

:kill
REM creates the exit messages
REM https://ss64.com/nt/if.html
IF NOT [%1] EQU [] (
    set a=%1
    echo !a:"=!
    set a=
)
echo Press any key to close.
pause >nul
exit 1


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
    call :kill "Folder !bits! doesn't exist or is empty"
)

REM it exists, confirm the remaining
IF NOT EXIST "!folder!XignCode\*" (
    call :kill "Folder !bits!\XignCode doesn't exist or is empty"
)
IF NOT EXIST "!folder!!dll!.dll" (
    call :kill "File !bits!\!dll!.dll doesn't exist"
)

echo Folder !bits! found, patching...

REM begin copying the directory
xcopy "!folder!XignCode" "!target!\XignCode\" /i /s /q /y >nul
IF NOT %ERRORLEVEL% EQU 0 (
    call :kill "Error (%ERRORLEVEL%) while copying the folder !bits!\XignCode"
)

REM copy the dll file
copy "!folder!!dll!.dll" "!target!\XignCode\!dll!.dll" /b /y >nul
IF NOT %ERRORLEVEL% EQU 0 (
    call :kill "Error (%ERRORLEVEL%) while copying the file !bits!\!dll!.dll"
)
