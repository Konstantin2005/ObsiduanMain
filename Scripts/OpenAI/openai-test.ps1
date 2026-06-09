$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:OPENAI_API_KEY)) {
    throw "Set OPENAI_API_KEY first."
}

$headers = @{
    Authorization = "Bearer $env:OPENAI_API_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    model = "gpt-5"
    input = "Скажи 'привет' одним словом."
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod `
    -Uri "https://api.openai.com/v1/responses" `
    -Method Post `
    -Headers $headers `
    -Body $body

$response.output_text
