# AvatarPrime — Entrenar un LoRA (identity o body) en Replicate
# USO:
#   $env:REPLICATE_API_TOKEN = "tu_token"
#   ./train_lora.ps1
# Edita CONFIG. Sirve para identity Y body (cambiar trigger/dataset/params).

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"

# ====== CONFIG (editar) ======
$ZIP_PATH    = "./dataset.zip"          # ZIP con imagenes .jpg + captions .txt
$DESTINATION = "tuusuario/mi-lora"      # modelo destino en Replicate (crear antes o se crea)
$TRIGGER     = "miavatar"               # identity: "<nombre>" | body: "<nombre>body"
$STEPS       = 1200                     # identity: 1200 | body: 1400
$LR          = 0.0003
$RANK        = 16
$DROPOUT     = 0.10                     # identity: 0.10 | body: 0.05
# =============================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

# Crear destination model si no existe
$owner = $DESTINATION.Split('/')[0]
$name = $DESTINATION.Split('/')[1]
try { Invoke-RestMethod -Uri "$apiBase/models/$DESTINATION" -Headers $headers -ErrorAction Stop | Out-Null; Write-Host "Model exists" }
catch {
    $cb = @{ owner=$owner; name=$name; description="AvatarPrime LoRA"; visibility="private"; hardware="gpu-t4" } | ConvertTo-Json -Compress
    Invoke-RestMethod -Uri "$apiBase/models" -Method POST -Headers $headers -Body $cb | Out-Null
    Write-Host "Model created: $DESTINATION"
}

# Subir ZIP (curl maneja multipart correctamente)
Write-Host "Uploading ZIP..."
$up = (& curl.exe -X POST "$apiBase/files" -H "Authorization: Bearer $token" -F "content=@$ZIP_PATH;type=application/zip" --silent --show-error --max-time 600) | ConvertFrom-Json
$fileUrl = $up.urls.get
if (-not $fileUrl) { Write-Host "ERROR upload"; exit 1 }

# Trainer version (ostris/flux-dev-lora-trainer)
$trainer = Invoke-RestMethod -Uri "$apiBase/models/ostris/flux-dev-lora-trainer" -Headers $headers
$tv = $trainer.latest_version.id

# Crear training
$ti = @{
    destination = $DESTINATION
    input = @{
        input_images = $fileUrl
        trigger_word = $TRIGGER
        autocaption = $false
        steps = $STEPS
        learning_rate = $LR
        batch_size = 1
        resolution = "1024"
        lora_rank = $RANK
        caption_dropout_rate = $DROPOUT
        optimizer = "adamw8bit"
    }
} | ConvertTo-Json -Compress -Depth 5
$training = Invoke-RestMethod -Uri "$apiBase/models/ostris/flux-dev-lora-trainer/versions/$tv/trainings" -Method POST -Headers $headers -Body $ti

Write-Host ""
Write-Host "=== TRAINING LAUNCHED ==="
Write-Host "ID: $($training.id)"
Write-Host "Monitor: https://replicate.com/p/$($training.id)"
Write-Host "Tiempo: 20-40 min | Costo: USD 2-4"
Write-Host "(usa monitor_training.ps1 con este ID para esperar)"
