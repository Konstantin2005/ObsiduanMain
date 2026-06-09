$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
    throw "Set OPENAI_API_KEY first."
}

$model = "gpt-5"
$messages = @()

Write-Host "OpenAI terminal chat"
Write-Host "Type /exit to quit, /reset to clear history." -ForegroundColor DarkGray

while ($true) {
    $userInput = Read-Host "you"

    if ($null -eq $userInput) {
        continue
    }

    $trimmed = $userInput.Trim()
    if ($trimmed -eq "") {
        continue
    }

    switch ($trimmed.ToLowerInvariant()) {
        "/exit" { break }
        "/quit" { break }
        "/reset" {
            $messages = @()
            Write-Host "history cleared" -ForegroundColor DarkGray
            continue
        }
    }

    $messages += @{
        role = "user"
        content = $trimmed
    }

    $body = @{
        model = $model
        input = $messages
    } | ConvertTo-Json -Depth 20

    $headers = @{
        Authorization = "Bearer $env:OPENAI_API_KEY"
        "Content-Type" = "application/json"
    }

    try {
        $response = Invoke-RestMethod `
            -Uri "https://api.openai.com/v1/responses" `
            -Method Post `
            -Headers $headers `
            -Body $body

        $assistantText = $response.output_text
        if ([string]::IsNullOrWhiteSpace($assistantText)) {
            $assistantText = "(empty response)"
        }

        Write-Host "assistant: $assistantText" -ForegroundColor Cyan

        $messages += @{
            role = "assistant"
            content = $assistantText
        }
    }
    catch {
        Write-Host "request failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
