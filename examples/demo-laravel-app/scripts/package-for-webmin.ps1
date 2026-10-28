param (
    [Parameter(Position = 0)]
    [ValidateSet("zip", "targz", "dir", "all")]
    [string]$Mode = "zip"
)

$ErrorActionPreference = "Stop"

$AppDir = (Resolve-Path "$PSScriptRoot\..").Path
$SrcDir = Join-Path $AppDir "src"
$DistDir = Join-Path $AppDir "dist"
$TargetDir = Join-Path $DistDir "serverlab-pulse"
$ZipFile = Join-Path $AppDir "serverlab-pulse.zip"
$TarGzFile = Join-Path $AppDir "serverlab-pulse.tar.gz"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " ServerLab Pulse: Track 1 Deployment Packaging Utility" -ForegroundColor Cyan
Write-Host " Mode: $Mode" -ForegroundColor Cyan
Write-Host " Source: $SrcDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $SrcDir)) {
    Write-Error "Source directory not found: $SrcDir"
    exit 1
}

# 1. Prepare clean staging folder (dist/serverlab-pulse)
Write-Host "`n[1/3] Preparing clean distribution staging folder..." -ForegroundColor Yellow
if (Test-Path $TargetDir) {
    Remove-Item -Recurse -Force $TargetDir
}
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

robocopy $SrcDir $TargetDir /E /XD .git tests node_modules /XF *.sqlite *.log .env | Out-Null

if (Test-Path (Join-Path $SrcDir ".env.example")) {
    Copy-Item (Join-Path $SrcDir ".env.example") (Join-Path $TargetDir ".env.example") -Force
}
Write-Host " Clean directory ready at: $TargetDir" -ForegroundColor Green

# 2. Mode: zip or all -> Build clean ZIP using Windows native bsdtar
if ($Mode -eq "zip" -or $Mode -eq "all") {
    Write-Host "`n[2/3] Generating Webmin-compatible ZIP archive: $ZipFile" -ForegroundColor Yellow
    if (Test-Path $ZipFile) { Remove-Item -Force $ZipFile }
    
    tar -a -c -f $ZipFile -C $TargetDir .
    
    $zipItem = Get-Item $ZipFile
    $zipMB = [math]::Round($zipItem.Length / 1MB, 2)
    Write-Host " ZIP archive created: $ZipFile ($zipMB MB)" -ForegroundColor Green
}

# 3. Mode: targz or all -> Build tar.gz (native to Debian/Webmin)
if ($Mode -eq "targz" -or $Mode -eq "all") {
    Write-Host "`n[3/3] Generating native Linux tar.gz archive: $TarGzFile" -ForegroundColor Yellow
    if (Test-Path $TarGzFile) { Remove-Item -Force $TarGzFile }
    
    tar -czf $TarGzFile -C $TargetDir .
    
    $tarItem = Get-Item $TarGzFile
    $tarMB = [math]::Round($tarItem.Length / 1MB, 2)
    Write-Host " tar.gz archive created: $TarGzFile ($tarMB MB)" -ForegroundColor Green
}

# Step guidance for credentials
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " Production Preparation Reminder:" -ForegroundColor Yellow
Write-Host " 1. Generate your fresh production APP_KEY manually using:" -ForegroundColor Yellow
Write-Host "    powershell -Command `"`$bytes = New-Object byte[] 32; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes(`$bytes); 'base64:' + [Convert]::ToBase64String(`$bytes)`"" -ForegroundColor Gray
Write-Host "    OR (via openssl): openssl rand -base64 32" -ForegroundColor Gray
Write-Host " 2. In Webmin File Manager, copy .env.example to .env and insert the generated key." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
