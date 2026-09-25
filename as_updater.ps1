param(
  [string]$Command = 'sync'
)

$ErrorActionPreference = 'Stop'

$BaseUrl      = if ($env:MEKAR_ASSET_BASE_URL) { $env:MEKAR_ASSET_BASE_URL.TrimEnd('/') } else { '' }
$ArchiveName  = 'assets.tar.gz'
$ChecksumName = 'assets.sha256'
$LockFile     = 'assets.lock'
$Root         = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

function Title($text) {
  Write-Host 'mekar-assets ' -NoNewline
  Write-Host "· $text" -ForegroundColor DarkGray
}
function Row($key, $value) { Write-Host ("  {0,-7} {1}" -f $key, $value) }
function Step($text) {
  Write-Host '  ' -NoNewline
  Write-Host '› ' -NoNewline -ForegroundColor DarkGray
  Write-Host $text
}
function Ok($text) {
  Write-Host '  ' -NoNewline
  Write-Host '✓ ' -NoNewline -ForegroundColor Green
  Write-Host $text
}
function Die($text) {
  Write-Host '  ' -NoNewline
  Write-Host '✗ ' -NoNewline -ForegroundColor Red
  Write-Host $text
  exit 1
}

function Get-Sha256($path) { (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLower() }

function Get-AssetFiles {
  if (-not (Test-Path 'assets')) { return @() }
  Get-ChildItem -Path 'assets' -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -notin @('.import', '.uid') -and $_.FullName -notmatch '__MACOSX' }
}

function Get-HumanSize($bytes) {
  if ($bytes -ge 1073741824) { return ('{0:N1} GB' -f ($bytes / 1073741824)) }
  if ($bytes -ge 1048576)    { return ('{0:N1} MB' -f ($bytes / 1048576)) }
  if ($bytes -ge 1024)       { return ('{0:N0} KB' -f ($bytes / 1024)) }
  return "$bytes B"
}

function Get-DirSizeHuman {
  $files = Get-AssetFiles
  if (-not $files) { return '0 B' }
  return Get-HumanSize (($files | Measure-Object -Property Length -Sum).Sum)
}

function Read-Lock {
  if (-not (Test-Path $LockFile)) { return $null }
  $line = Select-String -Path $LockFile -Pattern '^sha256=' | Select-Object -First 1
  if ($line) { return ($line.Line -split '=', 2)[1] }
  return $null
}

function Write-Lock($sha, $count) {
  @(
    "sha256=$sha"
    "files=$count"
    "installed=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    "url=$BaseUrl"
  ) | Set-Content -Path $LockFile -Encoding ASCII
}

function Get-RemoteRev {
  if (-not $BaseUrl) { return $null }
  try {
    $out = & curl.exe -fsSL --retry 2 --max-time 15 "$BaseUrl/$ChecksumName" 2>$null
    if ($LASTEXITCODE -eq 0 -and $out) { return ("$out".Trim() -split '\s+')[0] }
  } catch { }
  return $null
}

function Get-RemoteSize {
  if (-not $BaseUrl) { return $null }
  try {
    $headers = & curl.exe -fsSLI --retry 2 --max-time 15 "$BaseUrl/$ArchiveName" 2>$null
    $match = $headers | Select-String -Pattern '^content-length:' | Select-Object -Last 1
    if ($match) { return [int64](($match.Line -replace '[^0-9]', '')) }
  } catch { }
  return $null
}

function Short($sha) { if ($sha.Length -ge 7) { $sha.Substring(0, 7) } else { $sha } }

function Get-StateLabel($remote, $localSha, $fileCount) {
  if (-not $remote) { return 'unknown (remote checksum unavailable)' }
  if ($fileCount -eq 0 -or -not $localSha) { return 'missing (run sync)' }
  if ($remote -eq $localSha) { return 'up to date' }
  return 'outdated (run sync)'
}

function Show-Status {
  $remote = Get-RemoteRev
  $localSha = Read-Lock
  $files = @(Get-AssetFiles)

  Title 'status'; Write-Host ''
  Row 'url' $(if ($BaseUrl) { $BaseUrl } else { '<not set>' })
  Row 'remote' $(if ($remote) { "rev $(Short $remote)" } else { 'unavailable' })
  Row 'local' $(if ($localSha) { "rev $(Short $localSha)  ($($files.Count) files)" } else { "not synced  ($($files.Count) files)" })
  Row 'state' (Get-StateLabel $remote $localSha $files.Count)
  Write-Host ''
}

function Invoke-Sync([bool]$force) {
  if (-not $BaseUrl) { Die "MEKAR_ASSET_BASE_URL is not set. See: .\as_updater.ps1 help" }

  $remote = Get-RemoteRev
  $localSha = Read-Lock
  $files = @(Get-AssetFiles)

  Title 'sync'; Write-Host ''
  Row 'remote' $(if ($remote) { "rev $(Short $remote)" } else { 'unavailable' })
  Row 'local' $(if ($localSha) { "rev $(Short $localSha)  ($($files.Count) files)" } else { "not synced  ($($files.Count) files)" })

  if (-not $force -and $remote -and $remote -eq $localSha -and $files.Count -gt 0) {
    Row 'state' 'up to date'; Write-Host ''
    return
  }

  Row 'state' 'updating'; Write-Host ''

  $timer = [System.Diagnostics.Stopwatch]::StartNew()
  $tmp = Join-Path $env:TEMP "mekar-assets-$([guid]::NewGuid().ToString('N')).tar.gz"
  try {
    $rsize = Get-RemoteSize
    if ($rsize) { Step "downloading $ArchiveName  ($(Get-HumanSize $rsize))" } else { Step "downloading $ArchiveName" }
    & curl.exe -fL --progress-bar --retry 3 --retry-delay 2 -o $tmp "$BaseUrl/$ArchiveName"
    if ($LASTEXITCODE -ne 0) { Die 'download failed — check MEKAR_ASSET_BASE_URL and that the bucket is public.' }

    Step 'verifying checksum'
    $sha = Get-Sha256 $tmp
    if ($remote -and $sha -ne $remote) { Die "checksum mismatch (expected $(Short $remote), got $(Short $sha))." }
    Ok "checksum ok  ($(Short $sha))"

    Step 'extracting assets'
    & tar.exe -xzf $tmp -C $Root
    if ($LASTEXITCODE -ne 0) { Die 'extract failed.' }

    $files = @(Get-AssetFiles)
    Write-Lock $sha $files.Count

    $timer.Stop()
    $secs = [math]::Round($timer.Elapsed.TotalSeconds, 1)
    Ok "done — $($files.Count) files, $(Get-DirSizeHuman), ${secs}s"
    Write-Host ''
  } finally {
    if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
  }
}

function Show-Usage {
  Write-Host ''
  Write-Host 'mekar-assets ' -NoNewline
  Write-Host '- sync game assets from Cloudflare R2'
  Write-Host ''
  Write-Host 'Usage'
  Write-Host '  .\as_updater.ps1           sync assets (default)'
  Write-Host '  .\as_updater.ps1 status    show local vs remote state'
  Write-Host '  .\as_updater.ps1 update    force re-download'
  Write-Host '  .\as_updater.ps1 help      show this help'
  Write-Host ''
  Write-Host 'Config'
  Write-Host '  Set the bucket base URL once:'
  Write-Host '    setx MEKAR_ASSET_BASE_URL "https://assets.example.com"'
  Write-Host ''
  Write-Host 'Files'
  Write-Host '  assets.lock    local state (last synced revision) — not committed'
  Write-Host ''
}

switch ($Command.ToLower()) {
  { $_ -in 'sync', 'install' } { Invoke-Sync $false }
  { $_ -in 'update', 'pull' }  { Invoke-Sync $true }
  { $_ -in 'status', 'st' }    { Show-Status }
  { $_ -in 'help', '-h', '--help' } { Show-Usage }
  default { Die "unknown command: $Command (try: .\as_updater.ps1 help)" }
}