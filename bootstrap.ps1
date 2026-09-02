#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Symlink the nvim and Zed configs in this repo into their Windows locations.

.DESCRIPTION
    For each config: if the target path is already the correct symlink, it is left
    alone. If a real file or directory is there, it is RENAMED to a .bak (never
    deleted) and replaced with a symlink into this repo.

    Safe to re-run. Existing backups are never overwritten - a second run that
    finds one already present adds a timestamp instead.

.PARAMETER DryRun
    Print what would happen without touching the filesystem.

.PARAMETER SkipProcessCheck
    Proceed even if Zed or nvim are running. The check is deliberately coarse -
    any nvim process blocks any rename, because there is no cheap way to tell
    which directory a process holds a handle on. Use this when you know the
    running editor is unrelated to the paths being changed. Backups still
    happen; if a rename really is blocked it fails with a clear error.

.EXAMPLE
    .\bootstrap.ps1 -DryRun
    .\bootstrap.ps1
#>
[CmdletBinding()]
param([switch]$DryRun, [switch]$SkipProcessCheck)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

# link path  ->  repo-relative target, and whether it is a directory
$links = @(
    @{ Link = "$env:LOCALAPPDATA\nvim";          Target = "$repo\nvim";               Dir = $true  }
    @{ Link = "$env:APPDATA\Zed\settings.json";  Target = "$repo\zed\settings.json";  Dir = $false }
    @{ Link = "$env:APPDATA\Zed\keymap.json";    Target = "$repo\zed\keymap.json";    Dir = $false }
    @{ Link = "$env:APPDATA\Zed\tasks.json";     Target = "$repo\zed\tasks.json";     Dir = $false }
    @{ Link = "$env:APPDATA\Zed\AGENTS.md";      Target = "$repo\zed\AGENTS.md";      Dir = $false }
)

function Write-Step($msg) { Write-Host "  $msg" }
function Write-Ok($msg)   { Write-Host "  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------- preflight
Write-Host "`n== Preflight ==" -ForegroundColor Cyan

$missing = $links | Where-Object { -not (Test-Path -LiteralPath $_.Target) }
if ($missing) {
    Write-Error ("Missing in repo:`n" + (($missing | ForEach-Object { "    " + $_.Target }) -join "`n") +
                 "`n  Is this script running from inside the dotfiles repo?")
}
Write-Ok "all $($links.Count) sources present in repo"

# Symlinks on Windows need Developer Mode or an elevated shell. Test for real
# rather than inferring - the registry check alone misses some configurations.
$probeDir = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-lnprobe-$PID"
New-Item -ItemType Directory -Force -Path $probeDir | Out-Null
try {
    $probeTarget = Join-Path $probeDir 't'; New-Item -ItemType File -Path $probeTarget | Out-Null
    New-Item -ItemType SymbolicLink -Path (Join-Path $probeDir 'l') -Target $probeTarget -ErrorAction Stop | Out-Null
    Write-Ok "symlink creation permitted"
} catch {
    Remove-Item $probeDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Error @"
Cannot create symlinks. Enable ONE of:
    - Developer Mode:  Settings > System > For developers > Developer Mode
    - or run this script from an elevated (Administrator) PowerShell
"@
} finally {
    Remove-Item $probeDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($DryRun) { Write-Warn "DRY RUN - nothing will be modified" }

# ---------------------------------------------------------------- plan
# Work out what needs doing before touching anything. A re-run where every link
# is already correct must be a no-op, and must not care whether an editor is
# open - that only matters when a real path has to be renamed out of the way.
Write-Host "`n== Plan ==" -ForegroundColor Cyan

foreach ($l in $links) {
    $item = Get-Item -LiteralPath $l.Link -Force -ErrorAction SilentlyContinue
    $l.Name = $l.Link.Replace("$env:USERPROFILE\", '~\')

    if ($item -and $item.LinkType -eq 'SymbolicLink') {
        if (@($item.Target)[0] -eq $l.Target) { $l.Action = 'ok' }
        else { $l.Action = 'relink'; $l.Was = @($item.Target)[0] }
    }
    elseif ($item) {
        $l.Action = 'backup'
        $bak = "$($l.Link).pre-dotfiles.bak"
        if (Test-Path -LiteralPath $bak) {
            $bak = "$($l.Link).pre-dotfiles-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
        }
        $l.Bak = $bak
    }
    else { $l.Action = 'create' }

    switch ($l.Action) {
        'ok'     { Write-Ok   "ok        $($l.Name) (already linked)" }
        'relink' { Write-Warn "relink    $($l.Name) (was -> $($l.Was))" }
        'backup' { Write-Warn "backup    $($l.Name) -> $(Split-Path $l.Bak -Leaf), then link" }
        'create' { Write-Step "link      $($l.Name) (nothing there yet)" }
    }
}

$todo = @($links | Where-Object { $_.Action -ne 'ok' })
if ($todo.Count -eq 0) {
    Write-Host "`nNothing to do - all $($links.Count) links already correct.`n" -ForegroundColor Green
    return
}

# A running editor only matters when an existing path has to be moved out of the
# way: an open handle blocks renaming a directory, or deleting a stale symlink a
# process is sitting inside. Creating a link where nothing exists cannot block,
# so a first run on a fresh machine does not care what is open.
$blocking = @($todo | Where-Object { $_.Action -in 'backup','relink' })
if ($blocking.Count -gt 0 -and -not $SkipProcessCheck) {
    $running = Get-Process -Name 'Zed','nvim' -ErrorAction SilentlyContinue
    if ($running) {
        $names = ($running | ForEach-Object { "    $($_.Name) (pid $($_.Id))" }) -join "`n"
        if ($DryRun) {
            Write-Warn "would need these closed first:`n$names"
        } else {
            Write-Error ("Close these first, they hold handles that block renaming:`n$names`n" +
                         "  (needed for: " + (($blocking | ForEach-Object { $_.Name }) -join ', ') + ")")
        }
    }
}

# ---------------------------------------------------------------- apply
Write-Host "`n== Applying $($todo.Count) change(s) ==" -ForegroundColor Cyan

foreach ($l in $todo) {
    if ($l.Action -eq 'relink') {
        # Delete the LINK only. These .NET calls never recurse into the target,
        # unlike Remove-Item -Recurse on a directory symlink.
        if (-not $DryRun) {
            if ($l.Dir) { [System.IO.Directory]::Delete($l.Link, $false) }
            else        { [System.IO.File]::Delete($l.Link) }
        }
    }
    elseif ($l.Action -eq 'backup') {
        # Rename, never delete.
        if (-not $DryRun) { Rename-Item -LiteralPath $l.Link -NewName (Split-Path $l.Bak -Leaf) }
    }

    $parent = Split-Path $l.Link -Parent
    if (-not (Test-Path -LiteralPath $parent)) {
        Write-Step "mkdir     $($parent.Replace("$env:USERPROFILE\", '~\'))"
        if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    }

    Write-Ok "link      $($l.Name) -> $($l.Target.Replace($repo, '<repo>'))"
    if (-not $DryRun) {
        New-Item -ItemType SymbolicLink -Path $l.Link -Target $l.Target | Out-Null
    }
}

# ---------------------------------------------------------------- verify
if ($DryRun) {
    Write-Host "`nDry run complete. Re-run without -DryRun to apply.`n"
    return
}

Write-Host "`n== Verify ==" -ForegroundColor Cyan
$bad = 0
foreach ($l in $links) {
    $item = Get-Item -LiteralPath $l.Link -Force -ErrorAction SilentlyContinue
    $name = $l.Link.Replace("$env:USERPROFILE\", '~\')
    if (-not $item -or $item.LinkType -ne 'SymbolicLink' -or @($item.Target)[0] -ne $l.Target) {
        Write-Host "  FAIL      $name" -ForegroundColor Red; $bad++
    }
    elseif ($l.Dir -and -not (Test-Path -LiteralPath (Join-Path $l.Link 'init.lua'))) {
        Write-Host "  FAIL      $name (link resolves but init.lua unreadable)" -ForegroundColor Red; $bad++
    }
    elseif (-not $l.Dir -and (Get-FileHash $l.Link).Hash -ne (Get-FileHash $l.Target).Hash) {
        Write-Host "  FAIL      $name (content differs through link)" -ForegroundColor Red; $bad++
    }
    else { Write-Ok "ok        $name" }
}

if ($bad) { Write-Error "$bad link(s) failed verification" }
Write-Host "`nAll $($links.Count) links verified. Backups kept as *.pre-dotfiles.bak`n" -ForegroundColor Green
