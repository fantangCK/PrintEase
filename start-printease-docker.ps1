[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$EnvFile,
  [ValidateSet('database','converter','mpay','backend','proxy')][string[]]$Components = @('converter','proxy'),
  [switch]$ValidateOnly,
  [switch]$Plan,
  [switch]$StartWorker,
  [string]$WorkerConfig,
  [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
$backend = Join-Path $PSScriptRoot 'PrintEase-backend'
if (-not (Test-Path -LiteralPath $EnvFile -PathType Leaf)) { throw 'Private deployment environment file is required' }
$EnvFile = (Resolve-Path -LiteralPath $EnvFile).Path
$ordered = @('database','converter','mpay','backend','proxy') | Where-Object { $_ -in $Components }
if ($StartWorker -and 'converter' -notin $Components) { throw 'StartWorker requires the converter component' }
if ($Plan) {
  Write-Host ('Selected order: ' + ($ordered -join ' -> '))
  Write-Host 'Database is new-empty-volume only. Backend and WPS worker run natively on Windows; other selected services run in Docker.'
  Write-Host 'WPS real acceptance remains a separate gate; Plan performs no deployment.'
  return
}
# Resolve every selected configuration before starting any service.
foreach ($component in $ordered) {
  switch ($component) {
    'database' { & "$backend/database/start.ps1" -EnvFile $EnvFile -ValidateOnly }
    'converter' { & "$backend/converter/start.ps1" -EnvFile $EnvFile -ValidateOnly -StartWorker:$StartWorker -WorkerConfig $WorkerConfig -Python $Python }
    'mpay' {
      & docker compose --env-file $EnvFile -f "$PSScriptRoot/mpay/docker-compose.production.yml" config --quiet
      if ($LASTEXITCODE -ne 0) { throw 'mpay Compose validation failed' }
    }
    'backend' {
      if (-not $IsWindows) { throw 'Native backend deployment requires Windows PowerShell 7' }
      if (-not (Test-Path "$backend/dist/main.js" -PathType Leaf)) { throw 'Build and locally validate backend before deployment: npm run build' }
      if (-not (Test-Path "$backend/.env" -PathType Leaf)) { throw 'Native backend private .env is missing; configure its validated database TLS settings first' }
      Get-Command node -ErrorAction Stop | Out-Null
    }
    'proxy' { & "$backend/docker/production/start.ps1" -EnvFile $EnvFile -ValidateOnly }
  }
}
if ($ValidateOnly) { Write-Host 'Selected configuration checks passed. No services were started and no WPS acceptance was claimed.'; return }
foreach ($component in $ordered) {
  switch ($component) {
    'database' { & "$backend/database/start.ps1" -EnvFile $EnvFile }
    'converter' { & "$backend/converter/start.ps1" -EnvFile $EnvFile -StartWorker:$StartWorker -WorkerConfig $WorkerConfig -Python $Python }
    'mpay' {
      & docker compose --env-file $EnvFile -f "$PSScriptRoot/mpay/docker-compose.production.yml" up -d --build nginx php
      if ($LASTEXITCODE -ne 0) { throw 'mpay deployment failed' }
      & docker compose --env-file $EnvFile -f "$PSScriptRoot/mpay/docker-compose.production.yml" exec -T php php -r 'require "/var/www/html/vendor/autoload.php"; (new think\App())->initialize(); think\facade\Db::query("SELECT 1");'
      if ($LASTEXITCODE -ne 0) { throw 'mpay database TLS readiness failed' }
    }
    'backend' {
      $process = Start-Process node -ArgumentList 'dist/main.js' -WorkingDirectory $backend -PassThru
      $ready = $false
      for ($i=0; $i -lt 30; $i++) {
        $process.Refresh()
        if ($process.HasExited) { throw 'Native backend exited during startup' }
        try { $null = Invoke-WebRequest 'http://127.0.0.1:3000/api/health/ready' -TimeoutSec 2; $ready=$true; break } catch { Start-Sleep -Seconds 1 }
      }
      if (-not $ready) { throw 'Native backend readiness timed out; inspect its configuration and port' }
    }
    'proxy' { & "$backend/docker/production/start.ps1" -EnvFile $EnvFile }
  }
}
Write-Host 'Selected services started. Real WPS acceptance and business migrations must be verified separately.'
