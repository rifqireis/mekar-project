param(
  [string]$Command = 'sync'
)

$ErrorActionPreference = 'Stop'

$DefaultBaseUrl = 'https://pub-a7a75b256f2a45ea9e266a6ed801466d.r2.dev'
$BaseUrl        = if ($env:MEKAR_ASSET_BASE_URL) { $env:MEKAR_ASSET_BASE_URL.TrimEnd('/') } else { $DefaultBaseUrl }
$ArchiveName    = 'assets.tar.gz'
$ChecksumName   = 'assets.sha256'
$LockFile       = 'assets.lock'
$Root           = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$RemoteEtag = $null
$RemoteSize = $null
$RemoteSha  = $null

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
function Get-Md5($path)    { (Get-FileHash -Algorithm MD5 -Path $path).Hash.ToLower() }

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
  $line = Select-String -Path $LockFile -Pattern '^rev=' | Select-Object -First 1
  if ($line) { return ($line.Line -split '=', 2)[1] }
  return $null
}

function Write-Lock($rev, $count) {
  @(
    "rev=$rev"
    "files=$count"
    "installed=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))"
    "url=$BaseUrl"
  ) | Set-Content -Path $LockFile -Encoding ASCII
}

function Invoke-CurlHeaders($url) {
  for ($i = 1; $i -le 3; $i++) {
    $out = & curl.exe -fsSLI --connect-timeout 15 $url 2>$null
    if ($LASTEXITCODE -eq 0) { return $out }
    if ($i -lt 3) { Start-Sleep -Seconds 2 }
  }
  return $null
}

function Invoke-CurlFile($url, $out) {
  for ($i = 1; $i -le 3; $i++) {
    & curl.exe -fL --progress-bar --connect-timeout 15 -o $out $url
    if ($LASTEXITCODE -eq 0) { return $true }
    if ($i -lt 3) { Step "retrying ($i/3)..."; Start-Sleep -Seconds 2 }
  }
  return $false
}

function Probe-Remote {
  $script:RemoteEtag = $null
  $script:RemoteSize = $null
  $script:RemoteSha  = $null
  if (-not $BaseUrl) { return }
  $headers = Invoke-CurlHeaders "$BaseUrl/$ArchiveName"
  if ($headers) {
    $etag = $headers | Select-String -Pattern '^etag:' | Select-Object -Last 1
    if ($etag) { $script:RemoteEtag = ($etag.Line -split '"')[1] }
    $len = $headers | Select-String -Pattern '^content-length:' | Select-Object -Last 1
    if ($len) { $script:RemoteSize = [int64](($len.Line -replace '[^0-9]', '')) }
  }
  try {
    $out = & curl.exe -fsSL --connect-timeout 15 "$BaseUrl/$ChecksumName" 2>$null
    if ($LASTEXITCODE -eq 0 -and $out) { $script:RemoteSha = ("$out".Trim() -split '\s+')[0] }
  } catch { }
}

function Get-RemoteRev {
  if ($RemoteSha) { return $RemoteSha }
  return $RemoteEtag
}

function Short($s) { if ($s -and $s.Length -ge 7) { $s.Substring(0, 7) } else { $s } }

function Get-StateLabel($rev, $localRev, $fileCount) {
  if (-not $rev) { return 'unknown (remote unreachable)' }
  if ($fileCount -eq 0 -or -not $localRev) { return 'missing (run sync)' }
  if ($rev -eq $localRev) { return 'up to date' }
  return 'outdated (run sync)'
}

function Show-Status {
  Probe-Remote
  $rev = Get-RemoteRev
  $localRev = Read-Lock
  $files = @(Get-AssetFiles)

  Title 'status'; Write-Host ''
  Row 'url' $BaseUrl
  Row 'remote' $(if ($rev) { "rev $(Short $rev)" } else { 'unreachable' })
  Row 'local' $(if ($localRev) { "rev $(Short $localRev)  ($($files.Count) files)" } else { "not synced  ($($files.Count) files)" })
  Row 'state' (Get-StateLabel $rev $localRev $files.Count)
  Write-Host ''
}

function Invoke-Sync([bool]$force) {
  Probe-Remote
  $rev = Get-RemoteRev
  $localRev = Read-Lock
  $files = @(Get-AssetFiles)

  Title 'sync'; Write-Host ''
  Row 'remote' $(if ($rev) { "rev $(Short $rev)" } else { 'unreachable' })
  Row 'local' $(if ($localRev) { "rev $(Short $localRev)  ($($files.Count) files)" } else { "not synced  ($($files.Count) files)" })

  if (-not $force -and $rev -and $rev -eq $localRev -and $files.Count -gt 0) {
    Row 'state' 'up to date'; Write-Host ''
    return
  }

  Row 'state' 'updating'; Write-Host ''

  $timer = [System.Diagnostics.Stopwatch]::StartNew()
  $tmp = Join-Path $env:TEMP "mekar-assets-$([guid]::NewGuid().ToString('N')).tar.gz"
  try {
    if ($RemoteSize) { Step "downloading $ArchiveName  ($(Get-HumanSize $RemoteSize))" } else { Step "downloading $ArchiveName" }
    if (-not (Invoke-CurlFile "$BaseUrl/$ArchiveName" $tmp)) { Die 'download failed — check the bucket URL and connection.' }

    Step 'verifying'
    $expect = $null
    $algo = $null
    if ($RemoteSha) { $expect = $RemoteSha; $algo = 'sha256' }
    elseif ($RemoteEtag -match '^[0-9a-fA-F]{32}$') { $expect = $RemoteEtag.ToLower(); $algo = 'md5' }

    if ($expect) {
      if ($algo -eq 'sha256') { $actual = Get-Sha256 $tmp } else { $actual = Get-Md5 $tmp }
      if ($actual -ne $expect) { Die "checksum mismatch (expected $(Short $expect), got $(Short $actual))." }
      Ok "$algo ok  ($(Short $actual))"
    } else {
      Ok 'no reference checksum — skipped'
    }

    Step 'extracting'
    & tar.exe -xzf $tmp -C $Root
    if ($LASTEXITCODE -ne 0) { Die 'extract failed.' }

    $files = @(Get-AssetFiles)
    Write-Lock $rev $files.Count

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
  Write-Host 'mekar-assets - sync game assets from Cloudflare R2'
  Write-Host ''
  Write-Host 'Usage'
  Write-Host '  .\async.ps1            sync assets (default)'
  Write-Host '  .\async.ps1 status     show local vs remote state'
  Write-Host '  .\async.ps1 update     force re-download'
  Write-Host '  .\async.ps1 help       show this help'
  Write-Host ''
  Write-Host 'Config'
  Write-Host '  Base URL is built in. Override with:'
  Write-Host '    setx MEKAR_ASSET_BASE_URL "https://..."'
  Write-Host ''
}

if ($BaseUrl -match 'example\.com|xxxx') {
  Die "MEKAR_ASSET_BASE_URL looks like a placeholder: '$BaseUrl'. Unset it or set the real bucket URL."
}

switch ($Command.ToLower()) {
  { $_ -in 'sync', 'install' } { Invoke-Sync $false }
  { $_ -in 'update', 'pull' }  { Invoke-Sync $true }
  { $_ -in 'status', 'st' }    { Show-Status }
  { $_ -in 'help', '-h', '--help' } { Show-Usage }
  default { Die "unknown command: $Command (try: .\async.ps1 help)" }
}