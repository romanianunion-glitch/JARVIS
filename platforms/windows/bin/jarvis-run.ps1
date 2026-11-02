# jarvis-run.ps1 - you paste a PROPOSED COMMAND, blocked patterns are refused, runs only after y/N approval

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

Write-Host "Paste the PROPOSED COMMAND from the web app, then press Enter:"
$command = (Read-Host "command").Trim()
if (-not $command) {
    Write-Host "Nothing entered. Nothing was run."
    exit 1
}

# Never run jarvis itself
if ($command -match '(?i)^\s*jarvis') {
    Write-Host "BLOCKED: that is a jarvis command, not a PowerShell proposal. Nothing was run."
    exit 2
}

# Destructive or system-level patterns. Matching commands are never run from here.
$blocked = @(
    '\brm\b', '\bdel\b', '\berase\b', '\brd\b', '\brmdir\b', '\bRemove-Item\b',
    '\bformat\b', '\bdiskpart\b', '\bClear-Disk\b', '\bFormat-Volume\b', '\bRemove-Partition\b',
    '\bbcdedit\b', '\bbootrec\b', '\bbcdboot\b', '\bcipher\b', '\bvssadmin\b',
    '\breg\b', '\bregedit\b', '\bNew-ItemProperty\b', '\bSet-ItemProperty\b', '\bRemove-ItemProperty\b',
    '\bshutdown\b', '\bStop-Computer\b', '\bRestart-Computer\b',
    '\bSet-ExecutionPolicy\b', '\bInvoke-Expression\b', '\biex\b', '\|\s*iex', '\|\s*Invoke-Expression',
    '\bStop-Process\b', '\btaskkill\b', '\bnet\s+user\b', '\bnet\s+localgroup\b',
    '\bsc\s+(delete|config)\b',
    '\bdocker\s+(rm|rmi|system\s+prune|volume\s+rm)\b',
    '\bwsl\s+--(unregister|import)\b',
    '\btailscale\s+(down|logout|funnel)\b',
    '\bgit\s+(reset\s+--hard|clean)\b',
    'C:\\Windows'
)

$hits = @($blocked | Where-Object { $command -match "(?i)$_" })
if ($hits.Count -gt 0) {
    Write-Host ""
    Write-Host "BLOCKED. JARVIS will not run this command:"
    Write-Host $command
    Write-Host "Matched pattern(s): $($hits -join ', ')"
    Write-Host "If you still need it, review it yourself and run it by hand."
    exit 2
}

Write-Host ""
Write-Host "JARVIS proposes:"
Write-Host $command
Write-Host ""
$answer = Read-Host "Run this command? (y/N)"
if ($answer -notmatch '^(y|yes)$') {
    Write-Host "Cancelled. Nothing was run."
    exit 0
}

Write-Host "Running..."
[scriptblock]::Create($command).Invoke()