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
        throw "目录不存在: $WorkingDir"
    }
    if ($DryRun) {
        Write-Host "[DRY-RUN][$Name] cd `"$WorkingDir`"; $Command"
        return
    }
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("Set-Location -LiteralPath '$WorkingDir'; $Command"))
    Start-Process -FilePath "pwsh" -ArgumentList @("-NoExit", "-EncodedCommand", $encoded) | Out-Null
    Write-Host "[OK] 已启动: $Name"
}

if (-not $NoDocker) {
    $dockerComposeFile = Join-Path $mpayDir "docker-compose.yml"
    if (-not (Test-Path $dockerComposeFile)) {
        throw "未找到 Docker Compose 文件: $dockerComposeFile"
    }
    if ($DryRun) {
        Write-Host "[DRY-RUN][Docker] docker compose -f `"$dockerComposeFile`" up -d"
    } else {
        # 检查Docker是否正在运行
        $dockerRunning = $false
        try {
            $null = docker info 2>$null
            $dockerRunning = $?
        } catch {
            $dockerRunning = $false
        }
        
        # 如果Docker没有运行，尝试启动Docker Desktop
        if (-not $dockerRunning) {
            Write-Host "[INFO] Docker未运行，正在启动Docker Desktop..."
            $dockerDesktopPath = "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe"
            if (-not (Test-Path $dockerDesktopPath)) {
                $dockerDesktopPath = "${env:ProgramFiles(x86)}\Docker\Docker\Docker Desktop.exe"
            }
            if (-not (Test-Path $dockerDesktopPath)) {
                $dockerDesktopPath = "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
            }
            
            if (Test-Path $dockerDesktopPath) {
                Start-Process -FilePath $dockerDesktopPath -WindowStyle Hidden
                Write-Host "[INFO] 已启动Docker Desktop，等待其初始化..."
                
                # 等待Docker启动（最多60秒）
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
                        Write-Host "[INFO] 等待Docker启动... ($waited/$maxWait 秒)"
                    }
                }
                
                if (-not $dockerRunning) {
                    throw "Docker Desktop启动超时，请手动启动Docker Desktop后重试"
                }
                Write-Host "[OK] Docker Desktop已启动并就绪"
            } else {
                throw "未找到Docker Desktop，请确保已安装Docker Desktop"
            }
        }
        
        docker compose -f $dockerComposeFile up -d
        Write-Host "[OK] Docker(mpays) 已启动"
    }
}

if (-not $NoBackend) {
    Start-JobWindow -Name "Backend" -WorkingDir $backendDir -Command "if (-not (Test-Path node_modules)) { npm install }; npm run start:dev"
}

if (-not $NoFrp) {
    $frpcExe = Join-Path $frpDir "frpc.exe"
    $frpcIni = Join-Path $frpDir "frpc.ini"
    if (-not (Test-Path $frpcExe)) {
        throw "未找到 FRP 客户端: $frpcExe"
    }
    if (-not (Test-Path $frpcIni)) {
        throw "未找到 FRP 配置: $frpcIni"
    }
    Start-JobWindow -Name "FRP" -WorkingDir $frpDir -Command ".\frpc.exe -c .\frpc.ini"
}

if (-not $NoUniapp) {
    Start-JobWindow -Name "UniApp" -WorkingDir $uniappDir -Command "if (-not (Test-Path node_modules)) { npm install }; npm run dev:mp-weixin"
}

Write-Host "启动完成。默认已启动: Docker(mpay) + Backend + FRP + UniApp"
