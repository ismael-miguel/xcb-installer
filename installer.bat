@echo off

REM set the title - https://stackoverflow.com/a/39329524
title XignCode Bypasser installer
color 07

REM config
setlocal EnableDelayedExpansion
set CALLPATH=%~dp0
set FILESPATH=!CALLPATH!
set WIN_BITS=64
set REGKEY="HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\NCWest\BnS"

REM needs administrator rights - https://stackoverflow.com/a/21295806
REM we run fsutil to check the error code. 0 = admin
fsutil dirty query %SystemDrive% >nul 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
	call :kill 1 "You need to execute as administrator"
)

REM detect the bitness and fixes values - https://superuser.com/a/268384
echo %PROCESSOR_ARCHITECTURE% | find /i "x86" >nul
IF %ERRORLEVEL% EQU 0 (
	set WIN_BITS=32
	set REGKEY="HKEY_LOCAL_MACHINE\SOFTWARE\NCWest\BnS"
)

REM checks if the game is running - https://stackoverflow.com/a/1329790
tasklist /FI "WINDOWTITLE eq Blade & Soul" 2>nul | find /I /N "Client.exe" >nul
IF %ERRORLEVEL% EQU 0 (
	call :kill 1 "Close the game before installing the Xigncode Bypasser"
)

set WIDTH=80
for /f "tokens=1*" %%a in ('mode con') do (
	IF "%%a" EQU "Columns:" (
		set "WIDTH=%%b"
	)
)

REM this key is required - https://stackoverflow.com/a/445323
REM we check if it exists before trying to run the code
REG QUERY !REGKEY! >nul 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
	REM call :kill 1 "Registry key !REGKEY! not found"
	call :colorecho "Registry key !REGKEY! not found" red black
	call :pause "Press any key to select the game installation directory"
	call :getfolder "Select game installation folder"
	
	IF [!getfolder!] EQU [] (
		call :kill 1 "Folder selection canceled"
	)
	set "AppPath=!getfolder!\"
) ELSE (
	REM fetches the data in the registry
	for /f "tokens=2*" %%a in ('REG QUERY !REGKEY! /v BaseDir') do set "AppPath=%%~b\"

	IF NOT EXIST "!AppPath!*" (
		call :colorecho "!AppPath! does not exist or is empty" red black
		call :pause "Press any key to select the game installation directory"
		call :getfolder "Select game installation folder"
		
		IF [!getfolder!] EQU [] (
			call :kill 1 "Folder selection canceled"
		)
		set "AppPath=!getfolder!\"
	)
)

:startpatch
REM ready to replace everything

cls
call :colorecho "This will install the XignCode Bypasser" black gray
call :line
echo Game installation: !AppPath!
echo Files in: !FILESPATH!
echo Detected !WIN_BITS! bit Windows installation
call :line

:choice
echo What to do next?
choice /c:qigeb /n /m "[Q]uit | [I]nstall | [G]ame folder | [B]ypasser folder | [E]xtract ZIP"

IF ERRORLEVEL 5 (
	REM [B]ypasser folder
	
	call :getfolder "Select XignCode Bypasser folder"
	
	IF [!getfolder!] EQU [] (
		call :colorecho "Folder selection canceled" darkyellow black
		goto choice
	) ELSE (
		IF NOT EXIST "!getfolder!\*" (
			call :colorecho "Folder is empty" red black
			goto choice
		) ELSE (
			set "FILESPATH=!getfolder!\"
			goto startpatch
		)
	)
	
) ELSE (
	IF ERRORLEVEL 4 (
		REM [E]xtract ZIP
		call :zipfile "!CALLPATH!"
		IF ERRORLEVEL 255 (
			call :colorecho "No suitable extraction program found" darkred black
			goto choice
		)
		IF ERRORLEVEL 2 (
			goto choice
		)
		IF ERRORLEVEL 1 (
			call :colorecho "File selection canceled" darkyellow black
			goto choice
		)
		IF ERRORLEVEL 0 (
			set FILESPATH=!zipfile!
			goto startpatch
		)
	) ELSE (
		IF ERRORLEVEL 3 (
			REM [G]ame folder
			call :getfolder "Select game installation folder"
			
			IF [!getfolder!] EQU [] (
				call :colorecho "Folder selection canceled" darkyellow black
				goto choice
			) ELSE (
				IF NOT EXIST "!getfolder!\*" (
					call :colorecho "Folder is empty" red black
					goto choice
				) ELSE (
					set "AppPath=!getfolder!\"
					goto startpatch
				)
			)
		) ELSE (
			IF ERRORLEVEL 2 (
				REM [I]nstall
				call :line
				
				REM call the patching function
				for %%b in (32,64) do (
					IF %%b LEQ !WIN_BITS! (
						call :patch %%b
						IF ERRORLEVEL 1 (
							call :colorecho "Installation for %%b bits was skipped" darkyellow black
						)
					)
				)
				
				call :line
				call :colorecho "The XignCode Bypasser was successfully installed!" darkgreen black
			) ELSE (
				REM [Q]uit
				call :line
				call :colorecho "You decided to quit the installer" darkyellow black
			)
		)
	)
)

call :kill 0 "More in http://bnsbuddy.com/ and https://www.reddit.com/r/BladeAndSoulMods/"

REM =====================
REM FUNCTION DECLARATION!
REM =====================

:line
REM draws a line width the width of the console
call :repeat _ !WIDTH!
echo %repeat%
goto :eof

:repeat
REM https://rosettacode.org/wiki/Repeat_a_string#Batch_File
REM repeats a char n times
REM %1 = char, %2 = times
REM exit: 1 = times missing
setlocal EnableDelayedExpansion

IF [%2] EQU [] (
	REM closest thing to a return
	REM explained below
	endlocal & set "repeat="
	exit /b 1
)
set char=%1
for /l %%i in (1,1,%2) do set res=!res!%char%

REM since %res% is expanded on compilation time
REM 	it will have the correct value before endlocal
REM 	has any effect, working as a "return"
endlocal & set "repeat=%res%"
goto :eof


:getfolder
REM fetches a folder path
REM %1 = title
setlocal EnableDelayedExpansion

set txt='Please choose a folder.'
IF NOT [%1] EQU [] (
	set txt=%1
	set txt=!txt:"=!
)

REM executes the folder dialog - https://stackoverflow.com/a/15885133
set "cmd="(new-object -COM 'Shell.Application').BrowseForFolder(0,'%txt%',0,0).self.path""
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Noninteractive -NoLogo %cmd%`) do set "folder=%%I"

endlocal & set "getfolder=%folder%"
goto :eof

:colorecho
REM prints a message with specific colors
REM %1 = message, %2 = text color, %3 = background color, %4 = extra arguments (like -NoNewline)
REM https://www.petri.com/change-powershell-console-font-and-background-colors
setlocal EnableDelayedExpansion

powershell -NoProfile -Noninteractive -NoLogo Write-Host %1 -ForegroundColor %2 -BackgroundColor %3 %4

goto :eof


:pause
REM handles the pausing
REM %1 = message
setlocal EnableDelayedExpansion

set a=%1
echo !a:"=!

pause >nul

goto :eof

:kill
REM creates the exit messages
REM %1 = exit code, %2 = message
setlocal EnableDelayedExpansion

IF NOT [%2] EQU [] (
	IF %1 EQU 0 (
		set a=%2
		echo !a:"=!
	) ELSE (
		call :colorecho %2 red black
	)
)

call :pause "Press any key to exit."
exit %1

goto :eof

:patch
REM function to handle the patching
REM %1 = bitness
REM exit: 1 = skipped
setlocal EnableDelayedExpansion

set bits=%1
set folder=!FILESPATH!!bits!\
set dll=bsengine_Shipping
set target=!AppPath!\bin

IF NOT !bits! EQU 32 (
	REM 64bit paths need treatment -.-
	set dll=!dll!!bits!
	set target=!target!!bits!
)

REM make sure the folder with the contents exist
IF NOT EXIST "!folder!*" (
	call :kill 1 "Folder !bits! does not exist or is empty"
)

REM it exists, confirm the remaining
IF NOT EXIST "!folder!XignCode\*" (
	call :kill 1 "Folder !bits!\XignCode does not exist or is empty"
)
IF NOT EXIST "!folder!!dll!.dll" (
	call :kill 1 "File !bits!\!dll!.dll does not exist"
)

echo Folder !bits! found, preparing to copy files ...

REM verifying if the bypasser was already installed may save work
REM step 1 - verify if the dll exists
IF EXIST "!target!\XignCode\!dll!.dll" (
	REM step 2 - compare if they are the same. if they are ...
	fc /b "!folder!!dll!.dll" "!target!\XignCode\!dll!.dll" >nul
	IF %ERRORLEVEL% EQU 0 (
		REM step 3 - check if the x3.xem file is the same (original one is different)
		fc /b "!folder!XignCode\x3.xem" "!target!\XignCode\x3.xem" >nul
		IF %ERRORLEVEL% EQU 0 (
			REM step 4 - faily certain it's already installed, ask user input
			call :colorecho "The bypasser was already installed for !bits! bits." darkyellow black
			choice /c:yn /n /m "Install anyway? [Y] Yes | [N] No"
			IF ERRORLEVEL 2 (
				exit /b 1
			)
		)
	)
)

REM hacky way to echo without a new line
echo | set /P ="Copying files "
call :colorecho . darkgreen black -NoNewline

REM begin copying the directory
xcopy "!folder!XignCode" "!target!\XignCode\" /i /s /q /y >nul 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
	call :colorecho . darkred black
	call :kill 1 "Error (%ERRORLEVEL%) while copying the folder !bits!\XignCode"
)

call :colorecho . darkgreen black -NoNewline

REM copy the dll file
copy "!folder!!dll!.dll" "!target!\XignCode\!dll!.dll" /b /y >nul 2>&1
IF NOT %ERRORLEVEL% EQU 0 (
	call :colorecho . darkred black
	call :kill 1 "Error (%ERRORLEVEL%) while copying the file !bits!\!dll!.dll"
)

call :colorecho . darkgreen black

goto :eof

:zipfile
REM opens a file dialog that allows to choose the zip file
REM 	also "returns" the path where the folder is when done
REM %1 = optional target for extraction
REM exit: 0 = extracted, 1 = skipped, 2 = failed
setlocal EnableDelayedExpansion

REM https://stackoverflow.com/a/50115044
REM fix for dialog not showing: https://stackoverflow.com/q/216710
set cmd=powershell -NoProfile -Noninteractive -NoLogo -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms')|Out-Null; $F = New-Object System.Windows.Forms.OpenFileDialog; $F.ShowHelp = $true; $F.filter = 'ZIP Archive (*.zip)| *.zip'; $F.ShowDialog()|Out-Null; $F.FileName}"

for /f "delims=" %%i in ('!cmd!') do (
	set filedrive=%%~di
	set filepath=%%~pi
	set filename=%%~ni
	set fileext=%%~xi
)

IF "!filedrive!!filepath!!filename!!fileext!" EQU "" (
	endlocal & exit /b 1
)

set "folder=!filedrive!!filepath!"
set "file=!filename!!fileext!"

set target=%~dp1
IF "!target!" EQU "" (
	SET target=%TEMP%\
)

set code=255

REM UNTESTED!!! CAN'T TEST THIS!
REM https://stackoverflow.com/q/1825585
set psv=powershell -NoProfile -Noninteractive -NoLogo -command "$psversiontable.PSVersion.Major"
for /f "tokens=1" %%i in ('!psv!') do (
	IF %%i GEQ 5 (
		echo Using Powershell version %%i to extact
		REM https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/expand-archive?view=powershell-6
		powershell -NoProfile -Noninteractive -NoLogo Expand-Archive "!folder!!file!" "!target!!filename!" >nul
		IF NOT %ERRORLEVEL% EQU 0 (
			call :colorecho "Failed to extract: error %ERRORLEVEL%" red black
			set code=2
		) ELSE (
			endlocal & set "zipfile=%target%%filename%\"
			exit /b 0
		)
	)
)

REM https://stackoverflow.com/q/14122732
IF EXIST "%ProgramFiles%\7-Zip\7z.exe" (
	echo Using 7-Zip to extact
	"%ProgramFiles%\7-Zip\7z.exe" x "!folder!!file!" -bd -y -o"!target!!filename!\" >nul
	IF NOT %ERRORLEVEL% EQU 0 (
		call :colorecho "Failed to extract: error %ERRORLEVEL%" red black
		set code=2
	) ELSE (
		endlocal & set "zipfile=%target%%filename%\"
		exit /b 0
	)
)

REM https://stackoverflow.com/a/19337595
IF EXIST "%ProgramFiles%\WinRAR\winrar.exe" (
	echo Using WinRAR to extact
	"%ProgramFiles%\WinRAR\winrar.exe" x -ibck "!folder!!file!" *.* "!target!!filename!\" >nul
	IF NOT %ERRORLEVEL% EQU 0 (
		call :colorecho "Failed to extract: error %ERRORLEVEL%" red black
		set code=2
	) ELSE (
		endlocal & set "zipfile=%target%%filename%\"
		exit /b 0
	)
)

exit /b !code!
