# Run script for msftplayground.com (Jekyll)
# Usage:
#   .\run.ps1              - Start Jekyll server (published posts only)
#   .\run.ps1 -Future      - Include future-dated posts
#   .\run.ps1 -SkipInstall - Skip bundle install check (faster startup)

param(
    [switch]$Future,
    [switch]$SkipInstall
)

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
} elseif ((Test-Path $stampFile) -and (Test-Path $gemfilePath)) {
    $gemfileTime = (Get-Item $gemfilePath).LastWriteTime
    $stampTime   = (Get-Item $stampFile).LastWriteTime
    if ($stampTime -gt $gemfileTime) {
        $needsInstall = $false
        Write-Host "Gemfile unchanged, skipping bundle install." -ForegroundColor DarkGray
    }
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

# Open browser once Jekyll is ready by polling port 4000
Start-Job -ScriptBlock {
    $timeout = 120
    $elapsed = 0
    while ($elapsed -lt $timeout) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $tcp.Connect("localhost", 4000)
            if ($tcp.Connected) {
                $tcp.Dispose()
                Start-Process "http://localhost:4000"
                break
            }
            $tcp.Dispose()
        } catch { }
        Start-Sleep -Seconds 1
        $elapsed++
    }
} | Out-Null

bundle exec jekyll serve @serveArgs
