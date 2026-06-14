# AvatarPrime — produce.ps1
# PIPELINE DE PRODUCCION completo (3 etapas) en un solo comando:
#   1. Generar (multi-LoRA cara+cuerpo, con imperfeccion real en el prompt)
#   2. Repintado de piel REAL con epiCRealism (preserva identidad)
#   3. Firma de camara de celular (sensor_realism.py)
#
# USO:
#   $env:REPLICATE_API_TOKEN = "tu_token"
#   ./produce.ps1
#
# Salidas en ./production/<scene>_FINAL.jpg  (+ _raw y _skin intermedios)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Continue"

# ================= CONFIG =================
# LoRA cara RE-ENTRENADO 2026-05-29 (consistente). Version: your-username/identity-lora
$IDENTITY_WEIGHTS = "<IDENTITY_WEIGHTS_URL>"
$BODY_WEIGHTS     = "<BODY_WEIGHTS_URL>"
$IDENTITY_TRIGGER = "mychar01 woman"
$BODY_TRIGGER     = "mychar01body body"
# Si las URLs .tar expiran: re-sacar de los modelos your-username/identity-lora
# y your-username/body-lora (output.weights de la training).

# Calibracion de piel (creativity/resemblance) vive por-preset abajo en $PRESETS.
# REGLA DE ORO (validada con el usuario): creativity 0.15-0.22 = piel real PERO bonita
# y SIGUE siendo la modelo original. 0.30+ REPINTA de mas -> la pone fea y cambia de persona.
# Identidad alta en el LoRA (0.78-0.82) para que sea la modelo original; el pase de piel solo
# agrega textura, NO debe redibujar la cara. Sensor SUAVE 0.30 (0.55 mete look procesado).
$SENSOR_STRENGTH  = 0.30

$PY = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
# Rutas ancladas al propio script (portatil: corre desde cualquier carpeta)
$ROOT   = Split-Path -Parent $PSScriptRoot
$OUTDIR = Join-Path $ROOT "production"
$SENSOR = Join-Path $PSScriptRoot "sensor_realism.py"
# =========================================

# Imperfeccion real (basada en piel humana normal: poros, brillo zona T, enrojecimiento, vello)
# Piel real PERO bonita (no fea, no envejecida) y SIN cambiar de persona.
$SKIN_POS = "real human skin with fine visible pores, natural healthy skin texture, soft realistic skin detail, beautiful attractive young woman, no makeup <lora:more_details:0.25>"
$SKIN_NEG = "airbrushed, plastic skin, smooth poreless skin, beauty filter, aged skin, old, deep wrinkles, rough skin, acne, pimples, blemishes, red blotchy skin, ruddy, ugly, haggard, different person, different face"
$GEN_SKIN = "real skin texture, visible facial pores, oily t-zone shine, subtle skin redness, light freckles, fine peach fuzz, uneven skin tone, no makeup bare skin, natural eyebrows with stray hairs"
$GEN_NEG  = "NOT plastic skin, NOT airbrushed, NOT smoothed skin, NOT beauty filter, NOT poreless, NOT flawless, NOT makeup, NOT glamour lighting, NOT posed for camera, NOT head cropped, NOT distorted anatomy, NOT oversized head, NOT big head"

# Presets de encuadre. Cada uno trae sus escalas de LoRA Y su calibracion de piel.
# CLAVE identidad en cuerpo entero: NO bajar identidad < 0.75 (rompe el parecido).
# La proporcion se arregla con el encuadre "full body head to toe", no aplastando identidad.
# Y el pase de piel en cuerpo entero debe ser MUY suave (cr 0.20) para NO repintar la cara pequena.
#   id/body = escalas LoRA | ar = aspect | cr/rs = creativity/resemblance del pase de piel
$PRESETS = @{
    face = @{ id=0.82; body=0.20; ar="3:4";  cr=0.15; rs=0.82 }
    half = @{ id=0.78; body=0.55; ar="3:4";  cr=0.15; rs=0.80 }
    full = @{ id=0.75; body=0.80; ar="9:16"; cr=0.12; rs=0.85 }
}

# ================= ESCENAS (editar) =================
# framing: face | half | full   |   desc: escena de CAPTURA IMPERFECTA
$SCENES = @(
    @{ name="selfie";  framing="face"; desc="candid close-up selfie, direct harsh phone flash, plain background, relaxed half smile" }
    @{ name="cafe";    framing="half"; desc="candid snapshot at a cafe, harsh overhead noon sun, slightly tilted framing, cluttered background with other people, mid-sip not posing, plain cotton dress" }
    @{ name="calle";   framing="full"; desc="leaning on a brick wall, overcast flat grey light, messy urban background with bins, unflattering low angle, relaxed not posing, crop top and cargo pants, full body head to feet" }
)
# ===================================================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
if (-not (Test-Path $PY)) { Write-Host "ERROR: Python no encontrado en $PY"; exit 1 }
New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null

$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
$MULTILORA = "ad0314563856e714367fdc7244b19b160d25926d305fec270c9e00f64665d352"
$CLARITY   = "dfad41707589d68ecdccd1dfa600d55a208f9310748e44bfe35b4a6291453d5e"
$EPIC      = "epicrealism_naturalSinRC1VAE.safetensors [84d76a0328]"

function Wait-Pred($id) {
    for ($i=0; $i -lt 150; $i++) {
        Start-Sleep -Seconds 4
        $r = Invoke-RestMethod -Uri "$apiBase/predictions/$id" -Headers $headers
        if ($r.status -eq "succeeded") { return $r.output }
        if ($r.status -in @("failed","canceled")) { Write-Host "  [FAIL] $($r.error)"; return $null }
    }
    Write-Host "  [TIMEOUT]"; return $null
}
function Get-Url($o) { if ($o -is [array]) { return $o[0] } else { return $o } }

foreach ($s in $SCENES) {
    Write-Host "===== $($s.name) [$($s.framing)] ====="
    $pr = $PRESETS[$s.framing]

    # --- 1. GENERAR ---
    $prompt = "$IDENTITY_TRIGGER $BODY_TRIGGER, $($s.desc), face visible, $GEN_SKIN, candid not posed, real phone camera photo. $GEN_NEG"
    $b = @{ version=$MULTILORA; input=@{ prompt=$prompt; hf_loras=@($IDENTITY_WEIGHTS,$BODY_WEIGHTS); lora_scales=@($pr.id,$pr.body); aspect_ratio=$pr.ar; num_inference_steps=35; guidance_scale=2.8; num_outputs=1; output_format="jpg"; output_quality=95; disable_safety_checker=$true } } | ConvertTo-Json -Depth 6 -Compress
    $resp = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $b
    Write-Host "  gen $($resp.id)"; $out = Wait-Pred $resp.id
    if (-not $out) { continue }
    $raw = Join-Path $OUTDIR "$($s.name)_raw.jpg"
    Invoke-WebRequest -Uri (Get-Url $out) -OutFile $raw -UseBasicParsing

    # --- 2. PIEL REAL (epiCRealism) ---
    $up = (& curl.exe -X POST "$apiBase/files" -H "Authorization: Bearer $token" -F "content=@$raw;type=image/jpeg" --silent --show-error --max-time 300) | ConvertFrom-Json
    $cb = @{ version=$CLARITY; input=@{ image=$up.urls.get; prompt=$SKIN_POS; negative_prompt=$SKIN_NEG; sd_model=$EPIC; creativity=$pr.cr; resemblance=$pr.rs; scale_factor=2; dynamic=5; num_inference_steps=25; handfix="image_and_hands"; output_format="png" } } | ConvertTo-Json -Depth 6 -Compress
    $cr = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $cb
    Write-Host "  skin $($cr.id)"; $cout = Wait-Pred $cr.id
    if (-not $cout) { continue }
    $skin = Join-Path $OUTDIR "$($s.name)_skin.png"
    Invoke-WebRequest -Uri (Get-Url $cout) -OutFile $skin -UseBasicParsing

    # --- 3. SENSOR (local) ---
    $final = Join-Path $OUTDIR "$($s.name)_FINAL.jpg"
    & $PY $SENSOR $skin $final --strength $SENSOR_STRENGTH --downscale 1440 --jpeg 88
    Write-Host "  [OK] $final"
}
Write-Host "=== PRODUCCION COMPLETA -> $OUTDIR ==="
