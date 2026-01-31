# Local build script that works around sphinx_book_theme repository context issues

Write-Host "Building book locally (Thebe will be disabled for local builds)" -ForegroundColor Cyan

# Temporarily disable Thebe in config
$configPath = "book\_config.yml"
$config = Get-Content $configPath -Raw
$originalConfig = $config

# Replace thebe: true with thebe: false
$config = $config -replace "thebe: true", "thebe: false"
Set-Content $configPath $config

try {
    # Build the book
    & "d:/Cources/Introduction to Cryptography/interactiveBook/.conda/Scripts/teachbooks.exe" build book
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nBuild successful! Starting local server..." -ForegroundColor Green
        & "d:/Cources/Introduction to Cryptography/interactiveBook/.conda/Scripts/teachbooks.exe" serve
    }
} finally {
    # Restore original config
    Set-Content $configPath $originalConfig
    Write-Host "Configuration restored" -ForegroundColor Yellow
}
