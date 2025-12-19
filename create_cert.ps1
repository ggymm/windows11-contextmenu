# Create self-signed certificate for development testing
# The Subject MUST match the Publisher in AppxManifest.xml

$certSubject = "CN=ContextMenuDev"
$certPassword = "Dev123456"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Creating Self-Signed Certificate" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if certificate already exists
$existingCert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.Subject -eq $certSubject}

if ($existingCert) {
    Write-Host "Certificate already exists:" -ForegroundColor Yellow
    Write-Host "  Thumbprint: $($existingCert.Thumbprint)"
    Write-Host "  Subject: $($existingCert.Subject)"
    Write-Host ""
    $response = Read-Host "Do you want to create a new certificate? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Using existing certificate." -ForegroundColor Green
        $cert = $existingCert
    } else {
        Write-Host "Creating new certificate..." -ForegroundColor Yellow
        # Remove old certificate
        Remove-Item -Path "Cert:\CurrentUser\My\$($existingCert.Thumbprint)" -Force
        $cert = $null
    }
}

if (-not $cert) {
    Write-Host "Creating new certificate..." -ForegroundColor Yellow

    # Create self-signed certificate
    $cert = New-SelfSignedCertificate `
        -Type Custom `
        -Subject $certSubject `
        -KeyUsage DigitalSignature `
        -FriendlyName "Context Menu Development Certificate" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}") `
        -NotAfter (Get-Date).AddYears(5)

    Write-Host "  [OK] Certificate created" -ForegroundColor Green
}

Write-Host ""
Write-Host "Certificate details:"
Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Cyan
Write-Host "  Subject: $($cert.Subject)" -ForegroundColor Cyan
Write-Host "  Valid until: $($cert.NotAfter)" -ForegroundColor Cyan
Write-Host ""

# Export certificate (public key only) for installation
$certPath = Join-Path $PSScriptRoot "ContextMenuDev.cer"
Write-Host "Exporting certificate (public key)..."
Export-Certificate -Cert $cert -FilePath $certPath -Force | Out-Null
Write-Host "  [OK] Saved to: $certPath" -ForegroundColor Green

# Export certificate with private key for signing
$pfxPath = Join-Path $PSScriptRoot "ContextMenuDev.pfx"
Write-Host "Exporting certificate with private key..."
$securePwd = ConvertTo-SecureString -String $certPassword -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $securePwd -Force | Out-Null
Write-Host "  [OK] Saved to: $pfxPath" -ForegroundColor Green
Write-Host "  Password: $certPassword" -ForegroundColor Yellow

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Certificate created successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:"
Write-Host "  - ContextMenuDev.cer (public certificate)"
Write-Host "  - ContextMenuDev.pfx (private key for signing)"
Write-Host ""
Write-Host "Note: These certificates are for DEVELOPMENT ONLY." -ForegroundColor Yellow
Write-Host "      For production, use a certificate from a trusted CA." -ForegroundColor Yellow
Write-Host ""

Pause
