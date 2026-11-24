$repoUrl = "https://github.com/CHS-PROD-ORG/IT_Infra_Engineer_DevTools.git"
$repoName = (($repoUrl.TrimEnd('/') -split '/')[-1] -replace '\.git$', '')
$gitUserName = Read-Host "What name should Git use globally?"
$gitUserEmail = Read-Host "What email should Git use globally?"

if ($env:GIT_CONFIG_GLOBAL) {
    $gitConfigPath = [System.IO.Path]::GetFullPath($env:GIT_CONFIG_GLOBAL)
}
else {
    $gitConfigPath = Join-Path $HOME ".gitconfig"
    if (-not (Test-Path -LiteralPath $gitConfigPath) -and $env:XDG_CONFIG_HOME) {
        $xdgGitConfigPath = Join-Path $env:XDG_CONFIG_HOME "git\config"
        if (Test-Path -LiteralPath $xdgGitConfigPath) {
            $gitConfigPath = $xdgGitConfigPath
        }
    }
}

$existingGitUserName = git config --global --get user.name 2>$null
$gitUserNameExitCode = $LASTEXITCODE
if ($gitUserNameExitCode -gt 1) { throw "Failed to read the global Git user name." }
$existingGitUserEmail = git config --global --get user.email 2>$null
$gitUserEmailExitCode = $LASTEXITCODE
if ($gitUserEmailExitCode -gt 1) { throw "Failed to read the global Git user email." }

if ($existingGitUserName -cne $gitUserName -or $existingGitUserEmail -cne $gitUserEmail) {
    if (Test-Path -LiteralPath $gitConfigPath) {
        $backupPath = Join-Path (Split-Path -Parent $gitConfigPath) "original_GIT_config"
        if ([System.IO.Path]::GetFullPath($gitConfigPath) -eq [System.IO.Path]::GetFullPath($backupPath)) {
            throw "The global Git configuration path conflicts with the backup file path."
        }
        Copy-Item -LiteralPath $gitConfigPath -Destination $backupPath -Force -ErrorAction Stop
        Write-Host "Backed up the existing global Git configuration to $backupPath"
    }
}

git config --global user.name $gitUserName
if ($LASTEXITCODE -ne 0) { throw "Failed to set the global Git user name." }
git config --global user.email $gitUserEmail
if ($LASTEXITCODE -ne 0) { throw "Failed to set the global Git user email." }

$repoPath = Read-Host "Where should the repository folder be created? (parent directory)"
$repoCheckPath = Join-Path $repoPath $repoName

if (Test-Path -LiteralPath $repoCheckPath) {
    $originUrl = git -C $repoCheckPath remote get-url origin 2>$null
    if ($LASTEXITCODE -ne 0) { throw "The destination exists but is not a Git clone." }
    if ($originUrl -ne $repoUrl) { throw "The destination contains a different repository." }
    Write-Host "Repository already cloned at $repoCheckPath"
}
else {
    git clone $repoUrl $repoCheckPath
    if ($LASTEXITCODE -ne 0) { throw "Git clone failed." }
}

code $repoCheckPath