param(
    [switch]$NoBackend,
    [switch]$NoFrp,
    [switch]$NoDocker,
    [switch]$NoUniapp,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $root "PrintEase-backend"
$uniappDir = Join-Path $root "PrintEase-uniapp"
$frpDir = Join-Path $root "mpay\frp"
$mpayDir = Join-Path $root "mpay"

function Start-JobWindow {
    param(
        [string]$Name,
        [string]$WorkingDir,
        [string]$Command
    )
    if (-not (Test-Path $WorkingDir)) {
        throw "Directory does not exist: $WorkingDir"
    }
    if ($DryRun) {
        Write-Host "[DRY-RUN][$Name] cd \"$WorkingDir\"; $Command"
        return
    }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("Set-Location -LiteralPath '$WorkingDir'; $Command"))
    Start-Process -FilePath "pwsh" -ArgumentList @("-NoExit", "-EncodedCommand", $encoded) | Out-Null
    Write-Host "[OK] Started: $Name"
}

if (-not $NoDocker) {
    $dockerComposeFile = Join-Path $mpayDir "docker-compose.yml"
    if (-not (Test-Path $dockerComposeFile)) {
        throw "Docker Compose file not found: $dockerComposeFile"
    }
    if ($DryRun) {
        Write-Host "[DRY-RUN][Docker] docker compose -f \"$dockerComposeFile\" up -d"
    } else {
        # Check if Docker is running
        $dockerRunning = $false
        try {
            $null = docker info 2>$null
            $dockerRunning = $?
        } catch {
            $dockerRunning = $false
        }
        
        # If Docker is not running, try to start Docker Desktop
        if (-not $dockerRunning) {
            Write-Host "[INFO] Docker is not running, starting Docker Desktop..."
            $dockerDesktopPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
            if (-not (Test-Path $dockerDesktopPath)) {
                $dockerDesktopPath = "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
            }
            if (-not (Test-Path $dockerDesktopPath)) {
                $dockerDesktopPath = "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
            }
            
            if (Test-Path $dockerDesktopPath) {
                Start-Process -FilePath $dockerDesktopPath -WindowStyle Hidden
                Write-Host "[INFO] Docker Desktop started, waiting for initialization..."
                
                # Wait for Docker to start (maximum 60 seconds)
                $maxWait = 60
                $waited = 0
                while (-not $dockerRunning -and $waited -lt $maxWait) {
                    Start-Sleep -Seconds 2
                    $waited += 2
                    try {
                        $null = docker info 2>$null
                        $dockerRunning = $?
                    } catch {
                        $dockerRunning = $false
                    }
                    if ($waited % 10 -eq 0) {
                        Write-Host "[INFO] Waiting for Docker to start... ($waited/$maxWait seconds)"
                    }
                }
                
                if (-not $dockerRunning) {
                    throw "Docker Desktop startup timeout, please start Docker Desktop manually and try again"
                }
                Write-Host "[OK] Docker Desktop started and ready"
            } else {
                throw "Docker Desktop not found, please ensure Docker Desktop is installed"
            }
        }
        
        docker compose -f $dockerComposeFile up -d
        Write-Host "[OK] Docker(mpays) started"
    }
}

if (-not $NoBackend) {
    Start-JobWindow -Name "Backend" -WorkingDir $backendDir -Command "if (-not (Test-Path node_modules)) { npm install }; npm run start:dev"
}

if (-not $NoFrp) {
    $frpcExe = Join-Path $frpDir "frpc.exe"
    $frpcIni = Join-Path $frpDir "frpc.ini"
    if (-not (Test-Path $frpcExe)) {
        throw "FRP client not found: $frpcExe"
    }
    if (-not (Test-Path $frpcIni)) {
        throw "FRP configuration not found: $frpcIni"
    }
    Start-JobWindow -Name "FRP" -WorkingDir $frpDir -Command ".\frpc.exe -c .\frpc.ini"
}

if (-not $NoUniapp) {
    Start-JobWindow -Name "UniApp" -WorkingDir $uniappDir -Command "if (-not (Test-Path node_modules)) { npm install }; npm run dev:mp-weixin"
}

Write-Host "Startup completed. Default services started: Docker(mpay) + Backend + FRP + UniApp"
