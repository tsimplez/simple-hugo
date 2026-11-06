[CmdletBinding()]
param(
    [string]$Ref
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$themeRelative = 'themes/hugo-theme-stack'
$metadataRelative = 'themes/hugo-theme-stack.upstream.json'
$themePath = [IO.Path]::GetFullPath((Join-Path $repoRoot $themeRelative))
$metadataPath = Join-Path $repoRoot $metadataRelative

function Invoke-Git {
    param([string[]]$GitArguments)
    $ErrorActionPreference = 'Continue'
    $output = @(& git @GitArguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArguments -join ' ') failed:`n$($output -join "`n")"
    }
    $output | ForEach-Object { $_.ToString() }
}

$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
if (-not $Ref) { $Ref = $metadata.branch }
$changes = @(Invoke-Git @('-C', $repoRoot, 'status', '--porcelain=v1', '--untracked-files=all', '--', $themeRelative, $metadataRelative))
if ($changes.Count -gt 0) {
    throw 'Theme sources or upstream metadata have uncommitted changes. Commit or stash them before updating.'
}
if (-not (Test-Path -LiteralPath $themePath -PathType Container)) {
    throw "Theme directory is missing: $themePath"
}
if (Test-Path -LiteralPath (Join-Path $themePath '.git')) {
    throw 'The theme must be ordinary files in the main repository, not a nested Git repository.'
}

$workPath = Join-Path ([IO.Path]::GetTempPath()) ('stack-theme-update-' + [Guid]::NewGuid().ToString('N'))
$clonePath = Join-Path $workPath 'upstream'
$sourcePath = Join-Path $workPath 'source'
$backupPath = Join-Path $workPath 'previous-theme'
$metadataBackup = Join-Path $workPath 'previous-upstream.json'
New-Item -ItemType Directory -Path $workPath | Out-Null

Write-Host "Fetching $($metadata.repository) ($Ref)..."
Invoke-Git @('-c', 'advice.detachedHead=false', 'clone', '--quiet', '--depth', '1', '--single-branch', '--branch', $Ref, '--', $metadata.repository, $clonePath) | Out-Null
$commit = Invoke-Git @('-C', $clonePath, 'rev-parse', 'HEAD')
$version = Invoke-Git @('-C', $clonePath, 'describe', '--tags', '--always')
if ($commit -eq $metadata.commit) {
    Write-Host "Already up to date: $version ($commit)."
    return
}

# Export tracked source files only; never copy the upstream .git directory.
$archivePath = Join-Path $workPath 'source.zip'
Invoke-Git @('-C', $clonePath, 'archive', '--format=zip', '--output', $archivePath, 'HEAD') | Out-Null
Expand-Archive -LiteralPath $archivePath -DestinationPath $sourcePath
if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'theme.toml')) -or
    -not (Test-Path -LiteralPath (Join-Path $sourcePath 'layouts') -PathType Container)) {
    throw 'The selected upstream ref does not contain a complete Hugo theme.'
}

# Keep a verified backup, including ignored files, outside the repository.
Copy-Item -LiteralPath $themePath -Destination $backupPath -Recurse -Force
Copy-Item -LiteralPath $metadataPath -Destination $metadataBackup
foreach ($file in Get-ChildItem -LiteralPath $themePath -Recurse -File -Force) {
    $relative = $file.FullName.Substring($themePath.Length + 1)
    $copy = Join-Path $backupPath $relative
    if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $copy).Hash) {
        throw "Backup verification failed: $relative"
    }
}

# Validate the exact target before replacing the directory, including obsolete files.
$expectedPath = [IO.Path]::GetFullPath((Join-Path $repoRoot 'themes/hugo-theme-stack'))
if ($themePath -ne $expectedPath -or
    (((Get-Item -LiteralPath $themePath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {
    throw 'Refusing to replace an unexpected theme path or directory link.'
}
try {
    Remove-Item -LiteralPath $themePath -Recurse -Force
    Copy-Item -LiteralPath $sourcePath -Destination $themePath -Recurse -Force
    $metadata.ref = $Ref
    $metadata.commit = $commit
    $metadata.version = $version
    [IO.File]::WriteAllText($metadataPath, ($metadata | ConvertTo-Json) + "`n", [Text.UTF8Encoding]::new($false))
} catch {
    $updateError = $_
    if (Test-Path -LiteralPath $themePath) {
        Remove-Item -LiteralPath $themePath -Recurse -Force
    }
    Copy-Item -LiteralPath $backupPath -Destination $themePath -Recurse -Force
    Copy-Item -LiteralPath $metadataBackup -Destination $metadataPath -Force
    throw $updateError
}

Write-Host "Updated to $version ($commit)."
Write-Host "Previous theme backup: $backupPath"
Write-Host 'Review and build, then commit the sources and metadata in the main repository:'
Write-Host '  hugo --minify'
Write-Host '  git add -- themes/hugo-theme-stack themes/hugo-theme-stack.upstream.json'
Write-Host '  git commit -m "chore: update Stack theme"'
