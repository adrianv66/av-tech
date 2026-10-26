#Requires -Version 5.1
<#
.SYNOPSIS
    Creates a new post for the AV-Tech site (tech.amvhome.net).

.DESCRIPTION
    Builds _posts\YYYY-MM-DD-<slug>.md with front matter filled in and opens it
    for writing. Optionally links the post to a project in _projects, so it is
    listed on that project's page.

    Works in Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER Title
    The post title, e.g. "Reading Intune devices with Graph".

.PARAMETER Summary
    One line shown under the title in post lists. Optional.

.PARAMETER Tags
    Tags for the post, e.g. -Tags powershell, graph, intune

.PARAMETER Project
    File name (without .md) of a project in _projects, e.g. av-travel.

.PARAMETER Date
    Publish date. Defaults to today. A future date keeps the post hidden until then.

.PARAMETER Publish
    Commit and push the new post straight away (git add, commit, push).

.PARAMETER NoEdit
    Don't open the new file in an editor afterwards.

.EXAMPLE
    .\tools\New-TechPost.ps1 "Reading Intune devices with Graph" -Tags powershell, graph -Summary "Paging through managedDevices."

.EXAMPLE
    .\tools\New-TechPost.ps1 "Adding maps to Jekyll" -Project av-travel -Tags jekyll, leaflet -Publish
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Title,

    [string]$Summary,

    [string[]]$Tags,

    [string]$Project,

    [datetime]$Date = (Get-Date).Date,

    [switch]$Publish,

    [switch]$NoEdit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $repoRoot '_config.yml'))) {
    throw "Can't find _config.yml in '$repoRoot'. Is the script in the repo's tools folder?"
}
$postsDir = Join-Path $repoRoot '_posts'
if (-not (Test-Path $postsDir)) { New-Item -ItemType Directory -Path $postsDir | Out-Null }

if ($Project) {
    $projectsDir = Join-Path $repoRoot '_projects'
    if (-not (Test-Path (Join-Path $projectsDir "$Project.md"))) {
        $known = @(Get-ChildItem -Path $projectsDir -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object BaseName)
        throw "No project called '$Project'. Projects: $($known -join ', ')"
    }
}

function ConvertTo-YamlString {
    param([string]$Value)
    '"' + ($Value -replace '\\', '\\' -replace '"', '\"') + '"'
}

function ConvertTo-Slug {
    param([string]$Value, [string]$Fallback = 'post')
    $normalised = $Value.Normalize([Text.NormalizationForm]::FormD)
    $plain = -join ($normalised.ToCharArray() | Where-Object {
        [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark
    })
    $slug = ($plain.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $slug) { $slug = $Fallback }
    $slug
}

$fileName = '{0:yyyy-MM-dd}-{1}.md' -f $Date, (ConvertTo-Slug $Title)
$filePath = Join-Path $postsDir $fileName
if (Test-Path $filePath) { throw "A post already exists at '$filePath'." }

$lines = @('---', "title: $(ConvertTo-YamlString $Title)")
if ($Summary) { $lines += "summary: $(ConvertTo-YamlString $Summary)" }
if ($Tags) {
    # Accept -Tags a, b and -Tags "a, b" alike.
    $clean = @($Tags | ForEach-Object { $_ -split ',' } | Where-Object { $_.Trim() } |
        ForEach-Object { ConvertTo-Slug $_.Trim() 'misc' } | Select-Object -Unique)
    $lines += "tags: [$($clean -join ', ')]"
}
if ($Project) { $lines += "project: $Project" }
$lines += @(
    '---'
    ''
    'Write your post here.'
    ''
    '```powershell'
    '# Code blocks get highlighting and a Copy button. Change the language after the backticks as needed.'
    '```'
    ''
)

# UTF-8 without BOM, LF line endings.
[IO.File]::WriteAllText($filePath, ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host "Created _posts\$fileName" -ForegroundColor Green
if ($Date -gt (Get-Date)) {
    Write-Host "  Dated $($Date.ToString('d MMM yyyy')), so it stays hidden on the site until then." -ForegroundColor DarkGray
}

if (-not $NoEdit) {
    if (Get-Command code -ErrorAction SilentlyContinue) { & code $filePath }
    else { Start-Process notepad.exe -ArgumentList "`"$filePath`"" }
}

if ($Publish) {
    if (-not $NoEdit) { Read-Host 'Finish writing, save the file, then press Enter to publish' }
    Push-Location $repoRoot
    try {
        git add -- "_posts/$fileName"
        if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
        git commit -m "Add post: $Title"
        if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
        git push
        if ($LASTEXITCODE -ne 0) { throw 'git push failed. The commit is saved locally; run git push again later.' }
        Write-Host 'Published. The site updates in about a minute.' -ForegroundColor Green
    }
    finally { Pop-Location }
}
else {
    Write-Host 'When you''re ready: git add . ; git commit -m "Add post" ; git push' -ForegroundColor DarkGray
}
