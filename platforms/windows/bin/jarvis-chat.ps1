# JARVIS Windows chat adapter
# Chat logic is shared in core/python/chat.py.

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Words
)

$ErrorActionPreference = "Stop"

# Preserve the previous Windows user-level API key behaviour.
if (-not $env:JARVIS_API_KEY) {
    $UserKey = [Environment]::GetEnvironmentVariable("JARVIS_API_KEY", "User")

    if ($UserKey) {
        $env:JARVIS_API_KEY = $UserKey
    }
}

if (-not $env:JARVIS_API_KEY) {
    Write-Error "JARVIS_API_KEY is not set. Configure it as a Windows user environment variable."
    exit 1
}

$env:PYTHONIOENCODING = "utf-8"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "../../..")).Path
Set-Location -LiteralPath $Root

$VenvPython = Join-Path $Root ".venv/Scripts/python.exe"

if (Test-Path -LiteralPath $VenvPython -PathType Leaf) {
    $Python = $VenvPython
}
else {
    $PythonCommand = Get-Command python -CommandType Application -ErrorAction SilentlyContinue

    if (-not $PythonCommand) {
        $PythonCommand = Get-Command python3 -CommandType Application -ErrorAction SilentlyContinue
    }

    if (-not $PythonCommand) {
        Write-Error "Python 3 was not found. Install Python 3 or create a project .venv."
        exit 1
    }

    $Python = $PythonCommand.Source
}

if (-not $Words -or $Words.Count -eq 0) {
    Write-Host 'Usage: jarvis "your question"'
    Write-Host '       jarvis --local "your private question"'
    exit 1
}

& $Python -m core.python.chat @Words
exit $LASTEXITCODE
