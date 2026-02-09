# PowerShell script for snap agent
$APP_NAME = "snap"
$PORT = "9006"
$JAVAW = "javaw"
$JAVA = "java"

# Function to print usage information
function PrintUsage {
    Write-Host "usage: snap.ps1 start/stop/encrypt"
    Write-Host "       start   : START LG U+ Snap Agent."
    Write-Host "       stop    : STOP LG U+ Snap Agent."
    Write-Host "       encrypt [plain text] ([key seed]) : Encrypt input text."
}

# Function to start the Snap application
function StartSnap {
    # Check if the application is already running
    CreateSnapPid
    GetSnapPid

    if ($script:snapPid) {
        Write-Host "$APP_NAME-$PORT is already running"
    } else {
        try {
            # Get JVM options from file
            $JVM_OPTION = Get-Content -Path "$PSScriptRoot\jvm_option" -Raw -ErrorAction SilentlyContinue
            $WORKING_DIR = (Split-Path -Parent $PSScriptRoot)

            Start-Process -FilePath "cmd.exe" `
                -ArgumentList "/c", "start /D $WORKING_DIR /B $JAVAW -Dapp.name=$APP_NAME $JVM_OPTION -jar lib/snap-$APP_VERSION.jar --server.port=$PORT 2> log/$APP_NAME-$PORT.err 1> log/$APP_NAME-$PORT.out" `
                -WorkingDirectory $WORKING_DIR `
                -WindowStyle Hidden

            CreateSnapPid
            PrintSnapPid
        }
        catch {
            Write-Host "Error starting - ${JAVAW} ${APP_NAME}-${PORT}: $_"
        }
    }
}

# Function to stop the Snap application
function StopSnap {
    # Check if the application is running
    CreateSnapPid
    GetSnapPid

    if ($script:snapPid) {
        Write-Host "$APP_NAME-$PORT starting graceful shutdown..."

        try {
            # Send a graceful shutdown request and wait for the response
            # No timeout is set as the application will respond only after it has terminated
            Invoke-WebRequest -Uri "http://localhost:$PORT/snap/control/shutdown" -Method GET -ErrorAction Stop | Out-Null

            # The application has responded, which means it has terminated
            Write-Host "Done"

            # Update PID file to reflect the current state
            CreateSnapPid
        }
        catch {
            Write-Host "Failed to send shutdown request or receive response: $_"
        }
    }
    else {
        Write-Host "$APP_NAME-$PORT is not running"
    }
}

# Function to get the Snap PID
function GetSnapPid {
    $CURRENT_DIR = "$PWD"
    try {
        Set-Location (Split-Path -Parent $PSScriptRoot)

        $script:snapPid = $null
        if (Test-Path "log\$APP_NAME-$PORT.pid") {
            $pidContent = Get-Content "log\$APP_NAME-$PORT.pid" -ErrorAction SilentlyContinue
            if ($pidContent -and $pidContent.Count -gt 1) {
                $script:snapPid = $pidContent[1].Trim()
            }
        }
    }
    finally {
        Set-Location $CURRENT_DIR
    }
}

# Function to create the Snap PID file
function CreateSnapPid {
    $CURRENT_DIR = "$PWD"
    try {
        Set-Location (Split-Path -Parent $PSScriptRoot)

        # Get process information with command line details
        $processes = Get-WmiObject Win32_Process | Where-Object {
            $_.CommandLine -like "*$JAVAW*app.name=$APP_NAME*server.port=$PORT*"
        } | Select-Object -ExpandProperty ProcessId

        # Write to PID file
        "ProcessId" | Out-File -FilePath "log\$APP_NAME-$PORT.pid" -Force
        if ($processes) {
            $processes | Out-File -FilePath "log\$APP_NAME-$PORT.pid" -Append
        }
    }
    finally {
        Set-Location $CURRENT_DIR
    }
}

# Function to print the Snap PID
function PrintSnapPid {
    $processes = Get-WmiObject Win32_Process | Where-Object {
        $_.CommandLine -like "*$JAVAW*app.name=$APP_NAME*server.port=$PORT*"
    } | Select-Object -ExpandProperty ProcessId

    if ($processes) {
        Write-Host "ProcessId: $processes"
    }
}

# Function to encrypt data
function EncryptData($plainText, $keySeed) {
    $CURRENT_DIR = "$PWD"
    try {
        Set-Location (Split-Path -Parent $PSScriptRoot)
        if ([string]::IsNullOrEmpty($keySeed)) {
            & $JAVA -jar "lib\snap-$APP_VERSION.jar" utility encrypt "$plainText"
        } else {
            & $JAVA -jar "lib\snap-$APP_VERSION.jar" utility encrypt "$plainText" "$keySeed"
        }
    }
    catch {
        Write-Host "Error: $_"
    }
    finally {
        Set-Location $CURRENT_DIR
    }
}

# Load environment variables from .env file
if (Test-Path "$PSScriptRoot\.env") {
    Get-Content "$PSScriptRoot\.env" | ForEach-Object {
        $name, $value = $_ -split '=', 2
        if ($name -and $value) { Set-Variable -Name $name -Value $value }
    }
}

# Process command line arguments
if ($args.Count -ge 2 -and $args[0] -eq "encrypt") {
    $keySeed = if ($args.Count -eq 3) { $args[2] } else { "" }
    EncryptData $args[1] $keySeed
}
elseif ($args.Count -eq 1) {
    switch ($args[0]) {
        "start" { StartSnap }
        "stop" { StopSnap }
        default { PrintUsage }
    }
} 
else {
    PrintUsage
}
