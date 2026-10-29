---
title: ""
summary: "Two small functions that make generated Markdown files behave: safe slugs and UTF-8 without a BOM."
tags: [powershell, jekyll, github-pages]
project: av-travel
---

## TL;DR

Two small functions that make generated Markdown files behave: safe slugs and UTF-8 without a BOM.

---

The travel site gets a new page for every day of a trip, so I wrote `New-TravelDay.ps1` to create them.
Two details mattered more than I expected.

## Slugs from titles with accents

Day titles include places like *Plaça Reial* and *Rüdesheim*. A plain `-replace '[^a-z0-9]+'` turns
those into `pla-a-reial`. Normalising to FormD first splits each accented letter into the letter plus
a combining mark, which you can then drop:

```powershell
function ConvertTo-Slug {
    param([string]$Value)
    $normalised = $Value.Normalize([Text.NormalizationForm]::FormD)
    $plain = -join ($normalised.ToCharArray() | Where-Object {
        [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne
            [Globalization.UnicodeCategory]::NonSpacingMark
    })
    ($plain.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
}

ConvertTo-Slug 'Plaça Reial'   # placa-reial
```

## UTF-8 without a BOM

In Windows PowerShell 5.1, `Set-Content -Encoding UTF8` writes a byte order mark. Jekyll expects the
file to start with `---`, and a BOM in front of it can stop the front matter being read. Writing
through .NET avoids it in both 5.1 and 7:

```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

I also convert line endings to LF before writing, so Git doesn't warn about CRLF on every new file.
