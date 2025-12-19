# Install Context Menu Sparse Package

# Require administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red
    Write-Host "Please right-click this script and select 'Run as administrator'" -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Context Menu Installation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$msixPath = Join-Path $scriptDir "ContextMenu.msix"
$certPath = Join-Path $scriptDir "ContextMenuDev.cer"

# Check if files exist
if (-not (Test-Path $msixPath)) {
    Write-Host "ERROR: ContextMenu.msix not found!" -ForegroundColor Red
    Write-Host "Please run build.bat first to create the package" -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

if (-not (Test-Path $certPath)) {
    Write-Host "ERROR: Certificate not found!" -ForegroundColor Red
    Write-Host "Please run build.bat first to create the package" -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

# Step 1: Install certificate
Write-Host "Step 1: Installing certificate..." -ForegroundColor Yellow

try {
    # Import to Trusted Root Certification Authorities
    Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\Root -ErrorAction Stop | Out-Null
    Write-Host "  [OK] Certificate installed to Trusted Root" -ForegroundColor Green

    # Also import to Trusted People (required for app packages)
    Import-Certificate -FilePath $certPath -CertStoreLocation Cert:\LocalMachine\TrustedPeople -ErrorAction Stop | Out-Null
    Write-Host "  [OK] Certificate installed to Trusted People" -ForegroundColor Green
}
catch {
    Write-Host "  [WARNING] Certificate import failed or already exists" -ForegroundColor Yellow
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Check if package is already installed
Write-Host "Step 2: Checking existing installation..." -ForegroundColor Yellow

$existingPackage = Get-AppxPackage -Name "ContextMenu.App" -ErrorAction SilentlyContinue

if ($existingPackage) {
    Write-Host "  Found existing package: $($existingPackage.Version)" -ForegroundColor Yellow
    Write-Host "  Removing old package..." -ForegroundColor Yellow

    try {
        Remove-AppxPackage -Package $existingPackage.PackageFullName -ErrorAction Stop
        Write-Host "  [OK] Old package removed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAILED] Could not remove old package" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Pause
        exit 1
    }
}
else {
    Write-Host "  No existing package found" -ForegroundColor Green
}

Write-Host ""

# Step 3: Install package
Write-Host "Step 3: Installing package..." -ForegroundColor Yellow

try {
    Add-AppxPackage -Path $msixPath -ErrorAction Stop
    Write-Host "  [OK] Package installed successfully" -ForegroundColor Green
}
catch {
    Write-Host "  [FAILED] Package installation failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  - Certificate Subject must match AppxManifest.xml Publisher" -ForegroundColor Yellow
    Write-Host "  - Package must be properly signed" -ForegroundColor Yellow
    Write-Host "  - Windows Developer Mode may need to be enabled" -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

Write-Host ""

# Step 4: Verify installation
Write-Host "Step 4: Verifying installation..." -ForegroundColor Yellow

$installedPackage = Get-AppxPackage -Name "ContextMenu.App" -ErrorAction SilentlyContinue

if ($installedPackage) {
    Write-Host "  [OK] Package verified" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Package Name: $($installedPackage.Name)" -ForegroundColor Cyan
    Write-Host "  Version: $($installedPackage.Version)" -ForegroundColor Cyan
    Write-Host "  Install Location: $($installedPackage.InstallLocation)" -ForegroundColor Cyan
}
else {
    Write-Host "  [WARNING] Package not found after installation" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "How to test:" -ForegroundColor Cyan
Write-Host "  1. Right-click on any file or folder" -ForegroundColor White
Write-Host "  2. Look for 'My Right-Click Menu' in the context menu" -ForegroundColor White
Write-Host "  3. On Windows 11, it should appear DIRECTLY (no 'Show more options' needed)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Note: You may need to restart Explorer or reboot for changes to take effect" -ForegroundColor Yellow
Write-Host ""

Pause
