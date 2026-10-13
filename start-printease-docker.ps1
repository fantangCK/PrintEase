[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$EnvFile,
  [ValidateSet('database','converter','mpay','backend','proxy')][string[]]$Components = @('database','converter','backend','proxy'),
  [switch]$ValidateOnly,
  [switch]$Plan,
  [switch]$PromptDatabaseRootPassword,
  [ValidateSet('PasswordPrompt','PasswordFile','Certificate','NoRootInput')][string]$StartupAuthMode,
  [Alias('DatabaseSslMode')][ValidateSet('Required','Disabled','LocalPlaintext')][string]$SSLMode,
  [switch]$AllowLocalPlaintext,
  [switch]$StartWorker,
  [Alias('WorkerConfigFile')][string]$WorkerConfig,
  [string]$Python = 'python'
)
$ErrorActionPreference = 'Stop'
$backend = Join-Path $PSScriptRoot 'PrintEase-backend'
if (-not (Test-Path -LiteralPath $EnvFile -PathType Leaf)) { throw 'Private deployment environment file is required' }
$EnvFile = (Resolve-Path -LiteralPath $EnvFile).Path
$databaseAuth = @{}
if ($StartupAuthMode) { $databaseAuth.StartupAuthMode = $StartupAuthMode }
if ($PromptDatabaseRootPassword) { $databaseAuth.PromptRootPassword = $true }
$ordered = @('database','converter','mpay','backend','proxy') | Where-Object { $_ -in $Components }
if ($StartWorker -and 'converter' -notin $Components) { throw 'StartWorker requires the converter component' }
if ($Plan) {
  Write-Host ('Selected order: ' + ($ordered -join ' -> '))
  Write-Host 'Backend, MySQL, converter API and proxy run in Docker; WPS worker remains native Windows.'
  Write-Host 'Plan performs no deployment. Prepare an isolated checkout, private files, networks and an empty database volume; provision schema with separate administrator credentials.'
  return
}
$savedDatabaseSSLMode = $env:DATABASE_SSL_MODE
$savedDatabaseSSLCompose = $env:DATABASE_SSL_COMPOSE_FILE
try {
if ('database' -in $Components) {
  if ($SSLMode) { $databaseAuth.SSLMode = $SSLMode }
  if ($AllowLocalPlaintext) { $databaseAuth.AllowLocalPlaintext = $true }
  if ('converter' -in $Components) { $databaseAuth.RejectPlaintextConverter = $true }
  $resolvedSSLMode = & "$backend/docker/database/start.ps1" -EnvFile $EnvFile -ResolveSSLModeOnly -ValidateOnly:$ValidateOnly @databaseAuth
  $databaseAuth.SSLMode = $resolvedSSLMode
  if ($resolvedSSLMode -eq 'LocalPlaintext') {
    $databaseAuth.AllowLocalPlaintext = $true
    if ($Components | Where-Object { $_ -ne 'database' }) { throw 'Disabled SSL is supported by this entrypoint only with -Components database for local development; application production profiles require TLS.' }
  }
  $env:DATABASE_SSL_MODE = $resolvedSSLMode
  $env:DATABASE_SSL_COMPOSE_FILE = if ($resolvedSSLMode -eq 'Required') { 'compose.ssl.yml' } else { 'compose.off.yml' }
} elseif ($SSLMode -in @('Disabled','LocalPlaintext')) { throw 'Disabled SSL requires -Components database for local development.' }
foreach ($component in $ordered) {
  switch ($component) {
    'database' { & "$backend/docker/database/start.ps1" -EnvFile $EnvFile -ValidateOnly @databaseAuth }
    'converter' { & "$PSScriptRoot/convert2api/scripts/start-api.ps1" -EnvFile $EnvFile -ValidateOnly -StartWorker:$StartWorker -WorkerConfig $WorkerConfig -Python $Python }
    'mpay' {
      & docker compose --env-file $EnvFile -f "$PSScriptRoot/mpay/docker-compose.production.yml" config --quiet
      if ($LASTEXITCODE -ne 0) { throw 'mpay Compose validation failed' }
    }
    'backend' { & "$backend/docker/production/start.ps1" -EnvFile $EnvFile -Mode backend -ValidateOnly }
    'proxy' { & "$backend/docker/production/start.ps1" -EnvFile $EnvFile -Mode proxy -ValidateOnly }
  }
}
if ($ValidateOnly) { Write-Host 'Selected configuration checks passed. No services were started and no WPS acceptance was claimed.'; return }
foreach ($component in $ordered) {
  switch ($component) {
    'database' { & "$backend/docker/database/start.ps1" -EnvFile $EnvFile @databaseAuth }
    'converter' { & "$PSScriptRoot/convert2api/scripts/start-api.ps1" -EnvFile $EnvFile -StartWorker:$StartWorker -WorkerConfig $WorkerConfig -Python $Python }
    'mpay' {
      & docker compose --env-file $EnvFile -f "$PSScriptRoot/mpay/docker-compose.production.yml" up -d --build nginx php
      if ($LASTEXITCODE -ne 0) { throw 'mpay deployment failed' }
      & docker compose --env-file $EnvFile -f "$PSScriptRoot/mpay/docker-compose.production.yml" exec -T php php -r 'require "/var/www/html/vendor/autoload.php"; (new think\App())->initialize(); think\facade\Db::query("SELECT 1");'
      if ($LASTEXITCODE -ne 0) { throw 'mpay database TLS readiness failed' }
    }
    'backend' { & "$backend/docker/production/start.ps1" -EnvFile $EnvFile -Mode backend }
    'proxy' { & "$backend/docker/production/start.ps1" -EnvFile $EnvFile -Mode proxy }
  }
}
Write-Host 'Selected services started. Real WPS acceptance, payment acceptance and data migration remain separate gates.'
} finally {
  $env:DATABASE_SSL_MODE = $savedDatabaseSSLMode
  $env:DATABASE_SSL_COMPOSE_FILE = $savedDatabaseSSLCompose
}
