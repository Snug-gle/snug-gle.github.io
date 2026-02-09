@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set APP_NAME=snap
set PORT=9006
set JAVAW=javaw
set JAVA=java

REM MainScript()
:MainScript
    where wmic >nul 2>&1
    if not "%errorlevel%"=="0" (
       powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\snap.ps1" %1 %2 %3
       exit /b %errorlevel%
    )

    set argCount=0
    for %%x in (%*) do Set /A argCount+=1

    if "%1" == "encrypt" (
        if NOT %argCount% GEQ 2 (
            GOTO PrintUsage
        )
    ) else if NOT %argCount% == 1 (
        GOTO PrintUsage
    )

    for /f "delims== tokens=1,2" %%G in (%~dp0/.env) do set %%G=%%H

    if "%1" == "start" (
        GOTO StartSnap
    ) else if "%1" == "stop" (
        GOTO StopSnap
    ) else if "%1" == "encrypt" (
        GOTO EncryptData
    )

REM PrintUsage()
:PrintUsage
    echo usage: snap.cmd start/stop/encrypt
    echo        start   : START LG U+ Snap Agent.
    echo        stop    : STOP LG U+ Snap Agent.
    echo        encrypt [plain text] ([key seed]) : Encrypt input text.
    GOTO :EOF

REM StartSnap()
:StartSnap
    CALL :CreateSnapPid
    CALL :GetSnapPid

    if not defined JVM_OPTION (
        for /f "usebackq delims=" %%A in (%~dp0\jvm_option) do set "JVM_OPTION=%%A"
    )

    if defined snapPid (
        echo %APP_NAME%-%PORT% is already running
    ) else (
        start "%APP_NAME%-%PORT%" /D %~dp0.. /B %JAVAW% -Dapp.name=%APP_NAME% %JVM_OPTION% -jar lib/snap-%APP_VERSION%.jar --server.port=%PORT% 2> log/%APP_NAME%-%PORT%.err 1> log/%APP_NAME%-%PORT%.out
        CALL :CreateSnapPid
        CALL :PrintSnapPid
    )
    GOTO :EOF

REM StopSnap()
:StopSnap
    CALL :CreateSnapPid
    CALL :GetSnapPid

    if defined snapPid (
        echo %APP_NAME%-%PORT% starting graceful shutdown...
        bin\util\wget.exe --quiet --spider http://localhost:%PORT%/snap/control/shutdown
        echo Done
    ) else if "%snapPid%" == "" (
        echo %APP_NAME%-%PORT% is not running
    ) else (
        echo %APP_NAME%-%PORT% is not running
    )
    GOTO :EOF

REM GetSnapPid()
:GetSnapPid
    cd %~dp0..
    set "snapPid="
    for /f "usebackq skip=1 tokens=1 delims= " %%g in (`type "log\%APP_NAME%-%PORT%.pid"`) do (
        set "snapPid=%%g"
        exit /b
    )
    cd %CD%
    exit /b

REM CreateSnapPid()
:CreateSnapPid
    cd %~dp0..
    set wmicOption="commandline like '%JAVAW%%%app.name=%APP_NAME%%%server.port=%PORT%%%' and not commandLine like 'wmic%%'"
    wmic process where %wmicOption% get processid > log/%APP_NAME%-%PORT%.pid 2> NUL
    cd %CD%
    exit /b

REM PrintSnapPid()
:PrintSnapPid
    set wmicOption="commandline like '%JAVAW%%%app.name=%APP_NAME%%%server.port=%PORT%%%' and not commandLine like 'wmic%%'"
    wmic process where %wmicOption% get processid
    exit /b

REM EncryptData()
:EncryptData
    cd %~dp0..
    %JAVA% -jar lib/snap-%APP_VERSION%.jar utility encrypt "%2" "%3"
    cd %CD%
    exit /b
