# Run script for msftplayground.com (Jekyll)
# Usage:
#   .\run.ps1              - Start Jekyll server (published posts only)
#   .\run.ps1 -Future      - Include future-dated posts
#   .\run.ps1 -SkipInstall - Skip bundle install check (faster startup)

param(
    [switch]$Future,
    [switch]$SkipInstall
)

# Kill any stale Jekyll Ruby processes (only those running `jekyll serve`) to free port 4000
$jekyllRubyProcesses = Get-CimInstance Win32_Process -Filter "Name='ruby.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'jekyll\s+serve' }
if ($jekyllRubyProcesses) {
    $jekyllRubyProcesses | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

# Check if bundler is available
if (-not (Get-Command bundle -ErrorAction SilentlyContinue)) {
    Write-Host "Bundler not found. Installing Jekyll and Bundler..." -ForegroundColor Yellow
    gem install jekyll bundler
}

# Install dependencies to a short path to avoid Windows MAX_PATH (260 char) limit
# Skip if -SkipInstall flag is set or if Gemfile hasn't changed since last install
$gemfilePath = ".\Gemfile"
$stampFile   = "C:/gems/msftplayground/.install_stamp"
$needsInstall = $true

if ($SkipInstall) {
    $needsInstall = $false
    Write-Host "Skipping bundle install (-SkipInstall)." -ForegroundColor DarkGray
}

if ($needsInstall) {
    Write-Host "Installing dependencies..." -ForegroundColor Cyan
    bundle config set --local path 'C:/gems/msftplayground'
    bundle install
    # Update stamp so we can skip next time
    New-Item -ItemType Directory -Force -Path (Split-Path $stampFile) | Out-Null
    Get-Date | Out-File $stampFile
}

# Build flags
$serveArgs = @("--livereload", "--incremental")
if ($Future) {
    $serveArgs += "--future"
    Write-Host "Starting Jekyll server with future posts enabled..." -ForegroundColor Green
} else {
    Write-Host "Starting Jekyll server..." -ForegroundColor Green
}

# Open browser after a short delay to allow Jekyll to start
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 8
    Start-Process "http://localhost:4000"
} | Out-Null

# Set production environment so comments and other production-only features are visible locally
$previousJekyllEnv = $env:JEKYLL_ENV
try {
    $env:JEKYLL_ENV = "production"
    bundle exec jekyll serve @serveArgs
}
finally {
    if ($null -ne $previousJekyllEnv) {
        $env:JEKYLL_ENV = $previousJekyllEnv
    }
    else {
        Remove-Item Env:JEKYLL_ENV -ErrorAction SilentlyContinue
    }
}
