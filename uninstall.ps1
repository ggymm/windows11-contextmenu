# Uninstall Context Menu Sparse Package

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
Write-Host "  Context Menu Uninstallation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find and remove package
Write-Host "Searching for installed package..." -ForegroundColor Yellow

$package = Get-AppxPackage -Name "ContextMenu.App" -ErrorAction SilentlyContinue

if ($package) {
    Write-Host "  Found: $($package.PackageFullName)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Removing package..." -ForegroundColor Yellow

    try {
        Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop
        Write-Host "  [OK] Package removed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAILED] Package removal failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Pause
        exit 1
    }
}
else {
    Write-Host "  [INFO] Package not found - nothing to uninstall" -ForegroundColor Yellow
}

Write-Host ""

# Optionally remove installed files
$installPath = "C:\Program Files\ContextMenu"

if (Test-Path $installPath) {
    Write-Host "Removing installed files from $installPath..." -ForegroundColor Yellow

    try {
        Remove-Item -Path $installPath -Recurse -Force -ErrorAction Stop
        Write-Host "  [OK] Files removed" -ForegroundColor Green
    }
    catch {
        Write-Host "  [WARNING] Could not remove files: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Note about certificate
Write-Host "Note: Development certificate was NOT removed." -ForegroundColor Yellow
Write-Host "      To remove it manually:" -ForegroundColor Yellow
Write-Host "      1. Run 'certmgr.msc'" -ForegroundColor White
Write-Host "      2. Navigate to: Trusted Root Certification Authorities > Certificates" -ForegroundColor White
Write-Host "      3. Find and delete 'ContextMenuDev'" -ForegroundColor White
Write-Host "      4. Repeat for: Trusted People > Certificates" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Uninstallation completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Pause
