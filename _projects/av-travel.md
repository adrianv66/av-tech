---
title: Ady and Mich Travel
language: PowerShell
status: Active
started: 2026-10-26
repo: 
summary: "Our travel journal at travel.amvhome.net: Jekyll on GitHub Pages, with PowerShell scripts that create each day's page."
---

A trip journal with a page per day, a map of each day's stops and a bookshelf of trips on the front page.
It's plain Jekyll hosted free on GitHub Pages, with a custom subdomain on GoDaddy DNS.

The `tools` folder has two PowerShell scripts:

- `New-TravelDay.ps1` works out which trip a date belongs to and the day number, prompts for the stops
  (pasting coordinates straight from Google Maps), writes the page and can commit and push it.
- `New-BlogPost.ps1` does the same for blog posts.

See it live at [travel.amvhome.net](https://travel.amvhome.net).
