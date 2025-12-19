# PowerShell script to package and sign the Sparse Package

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Packaging Sparse Package" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installPath = "C:\Program Files\ContextMenu"
$packageWorkDir = Join-Path $scriptDir "sparse_package"
$distDir = Join-Path $scriptDir "dist"

$stubExe = Join-Path $scriptDir "com_handler\target\release\contextmenu.exe"
$comDll = Join-Path $scriptDir "com_handler\target\release\ContextMenuHandler.dll"
$manifestTemplate = Join-Path $packageWorkDir "AppxManifest.xml"
$pfxFile = Join-Path $scriptDir "ContextMenuDev.pfx"
$certPassword = "Dev123456"

# Check if certificate exists
if (-not (Test-Path $pfxFile)) {
    Write-Host "ERROR: Certificate not found!" -ForegroundColor Red
    Write-Host "Please run create_cert.ps1 first to create a certificate" -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

# Check if executables exist
if (-not (Test-Path $stubExe)) {
    Write-Host "ERROR: contextmenu.exe not found at: $stubExe" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $comDll)) {
    Write-Host "ERROR: ContextMenuHandler.dll not found at: $comDll" -ForegroundColor Red
    exit 1
}

# Step 1: Install files to Program Files
Write-Host "Step 1: Installing files to $installPath..." -ForegroundColor Yellow

if (-not (Test-Path $installPath)) {
    New-Item -ItemType Directory -Path $installPath -Force | Out-Null
}

Copy-Item $stubExe -Destination $installPath -Force
Copy-Item $comDll -Destination $installPath -Force

Write-Host "  [OK] Files installed" -ForegroundColor Green
Write-Host ""

# Step 2: Copy files to package directory for Sparse Package
Write-Host "Step 2: Copying files to package directory..." -ForegroundColor Yellow

Copy-Item $stubExe -Destination $packageWorkDir -Force
Copy-Item $comDll -Destination $packageWorkDir -Force

Write-Host "  [OK] Files copied to package" -ForegroundColor Green
Write-Host ""

# Step 3: Find Windows SDK tools
Write-Host "Step 3: Finding Windows SDK tools..." -ForegroundColor Yellow

$sdkPaths = @(
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64",
    "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64"
)

$makeAppx = $null
$signTool = $null

foreach ($sdkPath in $sdkPaths) {
    $testMakeAppx = Join-Path $sdkPath "makeappx.exe"
    $testSignTool = Join-Path $sdkPath "signtool.exe"

    if ((Test-Path $testMakeAppx) -and (Test-Path $testSignTool)) {
        $makeAppx = $testMakeAppx
        $signTool = $testSignTool
        Write-Host "  [OK] Found SDK tools at: $sdkPath" -ForegroundColor Green
        break
    }
}

if (-not $makeAppx) {
    Write-Host "ERROR: Windows SDK tools not found!" -ForegroundColor Red
    Write-Host "Please install Windows 10/11 SDK" -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

Write-Host ""

# Step 4: Create sparse package directory
Write-Host "Step 4: Creating package..." -ForegroundColor Yellow

# Create package directly without modifying manifest
$msixPath = Join-Path $distDir "ContextMenu.msix"

if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

if (Test-Path $msixPath) {
    Remove-Item $msixPath -Force
}

& $makeAppx pack /d $packageWorkDir /p $msixPath /nv

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAILED] Package creation failed" -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] Package created: $msixPath" -ForegroundColor Green
Write-Host ""

# Step 5: Sign package
Write-Host "Step 5: Signing package..." -ForegroundColor Yellow

& $signTool sign /fd SHA256 /f $pfxFile /p $certPassword $msixPath

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FAILED] Package signing failed" -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] Package signed" -ForegroundColor Green
Write-Host ""

# Step 6: Copy install scripts to dist
Write-Host "Step 6: Copying installation files..." -ForegroundColor Yellow

Copy-Item (Join-Path $scriptDir "install.ps1") -Destination $distDir -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $scriptDir "uninstall.ps1") -Destination $distDir -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $scriptDir "install.bat") -Destination $distDir -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $scriptDir "uninstall.bat") -Destination $distDir -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $scriptDir "ContextMenuDev.cer") -Destination $distDir -Force -ErrorAction SilentlyContinue

Write-Host "  [OK] Files copied" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Package created successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Package location: $msixPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "To install:"
Write-Host "  1. Go to dist folder"
Write-Host "  2. Right-click install.ps1"
Write-Host "  3. Select 'Run with PowerShell' (as administrator)"
Write-Host ""
