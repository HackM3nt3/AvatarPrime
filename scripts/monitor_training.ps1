# AvatarPrime — Monitorear un training hasta que termine
# USO:
#   $env:REPLICATE_API_TOKEN = "tu_token"
#   ./monitor_training.ps1 -TrainingId "abc123..."
# Pollea cada 60s y termina al completar. Ideal para correr en background.

param([Parameter(Mandatory=$true)][string]$TrainingId)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization" = "Bearer $token" }
$start = Get-Date
$iter = 0

Write-Host "Monitoring training $TrainingId ..."
while ($iter -lt 90) {
    $iter++
    try {
        $s = Invoke-RestMethod -Uri "$apiBase/trainings/$TrainingId" -Headers $headers
        $el = ((Get-Date) - $start).TotalMinutes.ToString("F1")
        Write-Host "[$iter @ ${el}min] $($s.status)"
        if ($s.status -eq "succeeded") {
            Write-Host "=== SUCCEEDED ($el min) ==="
            Write-Host "Version: $($s.output.version)"
            Write-Host "Weights: $($s.output.weights)"
            break
        } elseif ($s.status -in @("failed","canceled")) {
            Write-Host "=== $($s.status.ToUpper()) ==="
            Write-Host "Error: $($s.error)"
            break
        }
    } catch { Write-Host "[$iter] err: $_" }
    Start-Sleep -Seconds 60
}
