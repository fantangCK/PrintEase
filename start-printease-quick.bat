@echo off
setlocal enabledelayedexpansion

REM 定义变量
set "root=%~dp0"
set "backendDir=%root%PrintEase-backend"
set "uniappDir=%root%PrintEase-uniapp"
set "frpDir=%root%mpay\frp"
set "mpayDir=%root%mpay"

REM 处理命令行参数
set "NoBackend=false"
set "NoFrp=false"
set "NoDocker=false"
set "NoUniapp=false"
set "DryRun=false"

:parse_args
if "%1"=="-NoBackend" set "NoBackend=true" & shift & goto parse_args
if "%1"=="-NoFrp" set "NoFrp=true" & shift & goto parse_args
if "%1"=="-NoDocker" set "NoDocker=true" & shift & goto parse_args
if "%1"=="-NoUniapp" set "NoUniapp=true" & shift & goto parse_args
if "%1"=="-DryRun" set "DryRun=true" & shift & goto parse_args

REM 启动Docker
if "%NoDocker%"=="false" (
    set "dockerComposeFile=%mpayDir%\docker-compose.yml"
    if not exist "%dockerComposeFile%" (
        echo 未找到 Docker Compose 文件: %dockerComposeFile%
        pause
        exit /b 1
    )
    
    if "%DryRun%"=="true" (
        echo [DRY-RUN][Docker] docker compose -f "%dockerComposeFile%" up -d
    ) else (
        REM 检查Docker是否正在运行
        docker info >nul 2>&1
        if %errorlevel% neq 0 (
            echo [INFO] Docker未运行，正在启动Docker Desktop...
            set "dockerDesktopPath=%ProgramFiles%\Docker\Docker\Docker Desktop.exe"
            if not exist "%dockerDesktopPath%" (
                set "dockerDesktopPath=%ProgramFiles(x86)%\Docker\Docker\Docker Desktop.exe"
            )
            if not exist "%dockerDesktopPath%" (
                set "dockerDesktopPath=%LOCALAPPDATA%\Docker\Docker Desktop.exe"
            )
            
            if exist "%dockerDesktopPath%" (
                start "Docker Desktop" "%dockerDesktopPath%"
                echo [INFO] 已启动Docker Desktop，等待其初始化...
                
                REM 等待Docker启动（最多60秒）
                set "maxWait=60"
                set "waited=0"
                :wait_docker
                timeout /t 2 >nul
                set /a "waited+=2"
                docker info >nul 2>&1
                if %errorlevel% equ 0 goto docker_ready
                if !waited! geq !maxWait! (
                    echo [ERROR] Docker Desktop启动超时，请手动启动Docker Desktop后重试
                    pause
                    exit /b 1
                )
                if !waited! equ 10 echo [INFO] 等待Docker启动... (!waited!/!maxWait! 秒)
                if !waited! equ 20 echo [INFO] 等待Docker启动... (!waited!/!maxWait! 秒)
                if !waited! equ 30 echo [INFO] 等待Docker启动... (!waited!/!maxWait! 秒)
                if !waited! equ 40 echo [INFO] 等待Docker启动... (!waited!/!maxWait! 秒)
                if !waited! equ 50 echo [INFO] 等待Docker启动... (!waited!/!maxWait! 秒)
                goto wait_docker
                :docker_ready
                echo [OK] Docker Desktop已启动并就绪
            ) else (
                echo [ERROR] 未找到Docker Desktop，请确保已安装Docker Desktop
                pause
                exit /b 1
            )
        )
        
        docker compose -f "%dockerComposeFile%" up -d
        echo [OK] Docker(mpays) 已启动
    )
)

REM 启动Backend
if "%NoBackend%"=="false" (
    if "%DryRun%"=="true" (
        echo [DRY-RUN][Backend] cd "%backendDir" && if not exist node_modules npm install && npm run start:dev
    ) else (
        start "Backend" cmd /k "cd "%backendDir%" && if not exist node_modules npm install && npm run start:dev"
        echo [OK] 已启动: Backend
    )
)

REM 启动FRP
if "%NoFrp%"=="false" (
    set "frpcExe=%frpDir%\frpc.exe"
    set "frpcIni=%frpDir%\frpc.ini"
    if not exist "%frpcExe%" (
        echo [ERROR] 未找到 FRP 客户端: %frpcExe%
        pause
        exit /b 1
    )
    if not exist "%frpcIni%" (
        echo [ERROR] 未找到 FRP 配置: %frpcIni%
        pause
        exit /b 1
    )
    if "%DryRun%"=="true" (
        echo [DRY-RUN][FRP] cd "%frpDir" && frpc.exe -c frpc.ini
    ) else (
        start "FRP" cmd /k "cd "%frpDir%" && frpc.exe -c frpc.ini"
        echo [OK] 已启动: FRP
    )
)

REM 启动UniApp
if "%NoUniapp%"=="false" (
    if "%DryRun%"=="true" (
        echo [DRY-RUN][UniApp] cd "%uniappDir" && if not exist node_modules npm install && npm run dev:mp-weixin
    ) else (
        start "UniApp" cmd /k "cd "%uniappDir%" && if not exist node_modules npm install && npm run dev:mp-weixin"
        echo [OK] 已启动: UniApp
    )
)

echo 启动完成。默认已启动: Docker(mpay) + Backend + FRP + UniApp

if "%DryRun%"=="true" (
    echo [DRY-RUN] 模式，未实际启动任何服务
)

pause
