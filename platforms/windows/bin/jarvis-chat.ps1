# jarvis-chat.ps1 - send one question to JARVIS from the terminal
# jarvis "question"          -> cloud preset (jarvis-cloud)
# jarvis --local "question"  -> private preset (jarvis-private)
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Words
)

# Show UTF-8 correctly in the terminal (emoji, accents, symbols)
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$BaseUrl      = "http://127.0.0.1:3000"
$CloudModel   = "-jarvis-cloud"
$PrivateModel = "-jarvis-local"

$useLocal = $false
$parts = @()
foreach ($w in $Words) {
    if ($w -eq "--local") { $useLocal = $true } else { $parts += $w }
}
$question = ($parts -join " ").Trim()

if (-not $question) {
    Write-Host 'Usage: jarvis "your question"'
    Write-Host '       jarvis --local "your private question"'
    exit 1
}

$key = [Environment]::GetEnvironmentVariable("JARVIS_API_KEY", "User")
if (-not $key) { $key = $env:JARVIS_API_KEY }
if (-not $key) {
    Write-Host "JARVIS_API_KEY is not set. Add it as a Windows user environment variable, then open a NEW terminal."
    exit 1
}

$model = if ($useLocal) { $PrivateModel } else { $CloudModel }
$label = if ($useLocal) { "PRIVATE, local, nothing leaves this PC" } else { "CLOUD, Gemini" }
Write-Host "[$label] model: $model"

$body = @{
    model    = $model
    messages = @(@{ role = "user"; content = $question })
    stream   = $false
} | ConvertTo-Json -Depth 5
$bytes = [System.Text.Encoding]::UTF8.GetBytes($body)

try {
    # Read the raw bytes and decode them as UTF-8 ourselves
    $resp = Invoke-WebRequest -Uri "$BaseUrl/api/chat/completions" -Method Post `
        -Headers @{ Authorization = "Bearer $key" } `
        -ContentType "application/json; charset=utf-8" `
        -Body $bytes -TimeoutSec 240 -UseBasicParsing

    $raw  = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    $json = $raw | ConvertFrom-Json

    $answer = $json.choices[0].message.content
    $answer = ($answer -replace '(?s)<think>.*?</think>', '').Trim()
    Write-Host ""
    Write-Host $answer
}
catch {
    Write-Host "Request failed: $($_.Exception.Message)"
    if (-not $useLocal) { Write-Host "If this is a 429 or rate-limit error, wait a minute or use --local." }
    exit 1
}