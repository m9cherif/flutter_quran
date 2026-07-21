param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName = "flutter_quran_data",
    
    [string]$SourcePng = "G:\trav_quran2\png",
    [string]$SourceXlsx = "G:\trav_quran2\annotation",
    [string]$SourceAudio = "G:\trabelsi",
    [string]$SourceTimeline = "G:\trav_quran2\timeline",
    
    [string]$WorkDir = "$env:TEMP\quran_upload"
)

# Check for gh CLI
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is required. Install from https://cli.github.com/"
    exit 1
}

# Check auth
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not authenticated with GitHub. Run 'gh auth login' first."
    exit 1
}

# Create temp dir for repo
if (Test-Path -LiteralPath $WorkDir) {
    Remove-Item -Recurse -Force -LiteralPath $WorkDir
}
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
Set-Location -LiteralPath $WorkDir

# Get GitHub username
$user = gh api user --jq '.login' 2>$null
Write-Host "Creating repo $RepoName for user $user..."

# Create GitHub repo
gh repo create "$user/$RepoName" --public --description "Quran page images, annotations, audio, and timelines for Quran Preview app" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Repo may already exist, continuing..."
}

# Init git
git init
git checkout -b main

# Copy data files
Write-Host "Copying PNG files..."
if (Test-Path -LiteralPath $SourcePng) {
    New-Item -ItemType Directory -Path "png" -Force | Out-Null
    Copy-Item "$SourcePng\*.png" "png\" -Force
}

Write-Host "Copying XLSX files..."
if (Test-Path -LiteralPath $SourceXlsx) {
    New-Item -ItemType Directory -Path "annotation" -Force | Out-Null
    Copy-Item "$SourceXlsx\*.xlsx" "annotation\" -Force
}

Write-Host "Copying Audio files..."
if (Test-Path -LiteralPath $SourceAudio) {
    New-Item -ItemType Directory -Path "audio" -Force | Out-Null
    Copy-Item "$SourceAudio\*.mp3" "audio\" -Force
}

Write-Host "Copying Timeline files..."
if (Test-Path -LiteralPath $SourceTimeline) {
    New-Item -ItemType Directory -Path "timeline" -Force | Out-Null
    Copy-Item "$SourceTimeline\*.json" "timeline\" -Force
}

# Create .gitattributes for LFS
@"
*.png filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.xlsx filter=lfs diff=lfs merge=lfs -text
"@ | Out-File -FilePath ".gitattributes" -Encoding utf8

# Add and commit
git add .
git commit -m "Initial data upload"

# Push
git remote add origin "https://github.com/$user/$RepoName.git"
git push -u origin main

Write-Host "Done! Repo: https://github.com/$user/$RepoName"
Write-Host "Update data URL in lib/mobile/mobile_data_service.dart if needed."

# Cleanup
Set-Location -LiteralPath $env:TEMP
Remove-Item -Recurse -Force -LiteralPath $WorkDir -ErrorAction SilentlyContinue
