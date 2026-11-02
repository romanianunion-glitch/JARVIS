param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Words
)

$serviceActions = @("start", "stop", "restart", "status", "logs", "help")

if ($Words.Count -eq 1 -and $Words[0].ToLowerInvariant() -in $serviceActions) {
    $global:LASTEXITCODE = 0

    & (Join-Path $PSScriptRoot "../Jarvis.ps1") -Action $Words[0].ToLowerInvariant()

    exit [int]$global:LASTEXITCODE
}

if ($Words.Count -eq 0) {
    Write-Host 'Usage: jarvis "your question"'
    Write-Host '       jarvis --local "your private question"'
    Write-Host '       jarvis {start|stop|restart|status|logs|help}'
    exit 1
}

if ($Words[0].StartsWith("-") -and $Words[0] -ne "--local") {
    Write-Error "Unknown option: $($Words[0])"
    exit 2
}

if ($Words[0] -eq "--local" -and $Words.Count -lt 2) {
    Write-Error "Missing question after --local."
    exit 1
}

& (Join-Path $PSScriptRoot "jarvis-chat.ps1") @Words
exit $LASTEXITCODE