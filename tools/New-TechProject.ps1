#Requires -Version 5.1
<#
.SYNOPSIS
    Adds a project to the AV-Tech site (tech.amvhome.net).

.DESCRIPTION
    Builds _projects\<slug>.md with front matter filled in and opens it for
    writing. The project appears as a book on the front page shelf, coloured
    by its language (see language_colors in _config.yml).

    Works in Windows PowerShell 5.1 and PowerShell 7.

.PARAMETER Title
    The project's name, e.g. "Invoke-ServerHealth".

.PARAMETER Language
    Main language, e.g. PowerShell, Python, Bash. Defaults to PowerShell.

.PARAMETER Repo
    Link to the code, e.g. https://github.com/adrianv66/server-health. Optional.

.PARAMETER Summary
    One line describing the project. Optional.

.PARAMETER Status
    Active, Paused or Archived. Defaults to Active.

.PARAMETER Started
    When the project began. Defaults to today; controls the order on the shelf.

.PARAMETER NoEdit
    Don't open the new file in an editor afterwards.

.EXAMPLE
    .\tools\New-TechProject.ps1 "Invoke-ServerHealth" -Repo https://github.com/adrianv66/server-health -Summary "Morning health checks for Windows servers."
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Title,

    [string]$Language = 'PowerShell',

    [string]$Repo,

    [string]$Summary,

    [ValidateSet('Active', 'Paused', 'Archived')]
    [string]$Status = 'Active',

    [datetime]$Started = (Get-Date).Date,

    [switch]$NoEdit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $repoRoot '_config.yml'))) {
    throw "Can't find _config.yml in '$repoRoot'. Is the script in the repo's tools folder?"
}
$projectsDir = Join-Path $repoRoot '_projects'
if (-not (Test-Path $projectsDir)) { New-Item -ItemType Directory -Path $projectsDir | Out-Null }

function ConvertTo-YamlString {
    param([string]$Value)
    '"' + ($Value -replace '\\', '\\' -replace '"', '\"') + '"'
}

function ConvertTo-Slug {
    param([string]$Value)
    $normalised = $Value.Normalize([Text.NormalizationForm]::FormD)
    $plain = -join ($normalised.ToCharArray() | Where-Object {
        [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark
    })
    $slug = ($plain.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if (-not $slug) { $slug = 'project' }
    $slug
}

$slug = ConvertTo-Slug $Title
$filePath = Join-Path $projectsDir "$slug.md"
if (Test-Path $filePath) { throw "A project already exists at '$filePath'." }

if ($Repo -and $Repo -notmatch '^https?://') {
    throw "Repo should be a full link starting with https://, e.g. https://github.com/adrianv66/$slug"
}

$lines = @(
    '---'
    "title: $(ConvertTo-YamlString $Title)"
    "language: $(ConvertTo-YamlString $Language)"
    "status: $Status"
    ('started: {0:yyyy-MM-dd}' -f $Started)
)
if ($Repo) { $lines += "repo: $Repo" }
if ($Summary) { $lines += "summary: $(ConvertTo-YamlString $Summary)" }
$lines += @(
    '---'
    ''
    'What it does, why you built it, and how to use it.'
    ''
)

[IO.File]::WriteAllText($filePath, ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host "Created _projects\$slug.md" -ForegroundColor Green
Write-Host "  Link posts to it with: .\tools\New-TechPost.ps1 ""Title"" -Project $slug" -ForegroundColor DarkGray

if (-not $NoEdit) {
    if (Get-Command code -ErrorAction SilentlyContinue) { & code $filePath }
    else { Start-Process notepad.exe -ArgumentList "`"$filePath`"" }
}
