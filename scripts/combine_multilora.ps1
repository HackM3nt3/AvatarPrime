# AvatarPrime — Combinar 2 LoRAs (identity + body) en produccion
# Genera imagenes con cara + cuerpo del avatar en cualquier escena
#
# USO:
#   $env:REPLICATE_API_TOKEN = "tu_token"
#   ./combine_multilora.ps1
#
# Edita las variables CONFIG y los PROMPTS abajo.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Continue"

# ====== CONFIG (editar) ======
$IDENTITY_WEIGHTS = "<WEIGHTS_URL>"  # cara mychar01 (gnsvj, 1200 steps)
$BODY_WEIGHTS     = "<WEIGHTS_URL>"  # cuerpo mychar01body (nhct, 1400 steps)
$IDENTITY_TRIGGER = "mychar01 woman"
$BODY_TRIGGER     = "mychar01body body"
$IDENTITY_SCALE   = 0.82
$BODY_SCALE       = 0.70
$OUTPUT_DIR       = "./output"
# =============================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null

$apiBase = "https://api.replicate.com/v1"
$multiLora = "ad0314563856e714367fdc7244b19b160d25926d305fec270c9e00f64665d352"  # lucataco/flux-dev-multi-lora
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

$NEG = "NOT plastic skin, NOT airbrushed skin, NOT smoothed skin, NOT beauty filter, NOT skin smoothing, NOT head cropped, NOT distorted anatomy, NOT extra limbs, NOT studio glamour lighting, NOT golden hour glamour, NOT posed for camera, NOT centered composition"

# ====== PROMPTS (editar las escenas) ======
# Escenas de captura IMPERFECTA: luz dura/mezclada, encuadre torcido, fondo con
# desorden, pose a media-accion. La perfeccion de la escena delata el AI.
$scenes = @(
    @{ name="scene_01"; desc="candid snapshot at a cafe, harsh overhead noon sun, slightly tilted framing, cluttered background with other people, mid-sip not posing, plain cotton dress" }
    @{ name="scene_02"; desc="amateur phone photo on the beach at midday, flat harsh light, sand on ground, wind blowing hair across face, squinting, awkward mid-step pose, plain bikini" }
    @{ name="scene_03"; desc="leaning on a brick wall, overcast flat grey light, messy urban background with bins and cables, unflattering angle from slightly below, relaxed not posing, crop top and cargo pants" }
)
# ==========================================

Write-Host "=== AvatarPrime multi-LoRA generation ==="
$predictions = New-Object System.Collections.ArrayList
foreach ($s in $scenes) {
    $prompt = "$IDENTITY_TRIGGER $BODY_TRIGGER, $($s.desc), face visible, real skin texture, visible skin pores, natural skin tone variation, skin specular highlights, fine body hair, hard directional light, candid not posed, real phone camera photo. $NEG"
    $bodyObj = @{
        version = $multiLora
        input = @{
            prompt = $prompt
            hf_loras = @($IDENTITY_WEIGHTS, $BODY_WEIGHTS)
            lora_scales = @($IDENTITY_SCALE, $BODY_SCALE)
            aspect_ratio = "3:4"
            num_inference_steps = 35
            guidance_scale = 2.8
            num_outputs = 1
            output_format = "jpg"
            output_quality = 95
            disable_safety_checker = $true
        }
    }
    $body = $bodyObj | ConvertTo-Json -Depth 5 -Compress
    try {
        $resp = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $body
        Write-Host "[OK] $($s.name) id=$($resp.id)"
        [void]$predictions.Add([ordered]@{ name=$s.name; id=$resp.id; status=$resp.status; output=$null })
    } catch { Write-Host "[FAIL] $($s.name): $_" }
}

# Polling
$iter = 0
while ($true) {
    $iter++; $pending = 0
    for ($i=0; $i -lt $predictions.Count; $i++) {
        $p = $predictions[$i]
        if ($p.status -in @("succeeded","failed","canceled")) { continue }
        try {
            $r = Invoke-RestMethod -Uri "$apiBase/predictions/$($p.id)" -Headers $headers
            $predictions[$i].status = $r.status
            if ($r.status -eq "succeeded") { $predictions[$i].output = $r.output; Write-Host "[DONE] $($p.name)" }
            elseif ($r.status -in @("failed","canceled")) { Write-Host "[FAIL] $($p.name): $($r.error)" }
            else { $pending++ }
        } catch { $pending++ }
    }
    if ($pending -eq 0) { break }
    if ($iter -gt 80) { break }
    Start-Sleep -Seconds 4
}

# Download
foreach ($p in $predictions) {
    if ($p.status -ne "succeeded") { continue }
    $url = if ($p.output -is [array]) { $p.output[0] } else { $p.output }
    if ($url) { Invoke-WebRequest -Uri $url -OutFile (Join-Path $OUTPUT_DIR "$($p.name).jpg") -UseBasicParsing; Write-Host "[SAVED] $($p.name)" }
}
Write-Host "Done. Output: $OUTPUT_DIR"
