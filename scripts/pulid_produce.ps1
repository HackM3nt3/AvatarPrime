# AvatarPrime — pulid_produce.ps1
# PRODUCCION con IDENTIDAD BLOQUEADA. Ancla CADA imagen a una unica cara heroe
# (la "cara de la marca") con PuLID-FLUX, garantizando la MISMA persona en toda escena.
# Pipeline: PuLID (cara heroe) -> epiCRealism (piel real) -> sensor (camara).
#
# USO:
#   $env:REPLICATE_API_TOKEN = "tu_token"
#   ./pulid_produce.ps1
#
# Salidas en ./production_pulid/<scene>_FINAL.jpg

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Continue"

# ================= CONFIG =================
# CARA HEROE = "la cara de la marca". UN solo retrato frontal claro. TODO se ancla a esta.
$HERO_FACE = Join-Path (Split-Path -Parent $PSScriptRoot) "realism_test\skin_c30r70_clarity.png"

# PuLID: id_weight alto = mas fiel al heroe (1.3-1.5). start_step 0 = maxima fidelidad.
$ID_WEIGHT   = 1.35
$START_STEP  = 0
# Rasgos fijos del heroe que PuLID no bloquea solo (color de ojos, etc). Se anexan a CADA prompt.
$FACE_LOCK   = "warm brown eyes, dark brown eyes"
$NUM_STEPS   = 20
$GUIDANCE    = 4
$TRUE_CFG    = 1

# Piel (epiCRealism) y sensor — calibracion validada
$SKIN_CR     = 0.30
$SKIN_RS     = 0.72
$SENSOR      = 0.35

$PY     = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$ROOT   = Split-Path -Parent $PSScriptRoot
$OUTDIR = Join-Path $ROOT "production_pulid"
$SENSORPY = Join-Path $PSScriptRoot "sensor_realism.py"
# =========================================

# ================= ESCENAS (editar) =================
# w/h opcionales (default 832x1216 retrato). Prompts de CAPTURA IMPERFECTA.
$SCENES = @(
    @{ name="01_selfie_bano"; p="candid bathroom mirror selfie of a woman, holding phone, direct ceiling light, plain tank top, cluttered shelf behind, no makeup, real skin texture with pores, amateur iphone photo" }
    @{ name="02_cafe";        p="candid half body phone photo of a woman at an outdoor cafe, casual summer top, harsh midday sun, other people in background, mid moment not posing, real skin texture, amateur photo" }
    @{ name="03_calle";       p="candid phone photo of a woman on a city sidewalk, crop top, overcast flat grey light, brick wall and bins behind, unposed, real skin texture with pores, amateur photo" }
    @{ name="04_cuarto";      p="candid phone photo of a woman sitting on a bed at home, casual hoodie, soft window light mixed with warm lamp, messy room, relaxed, real skin texture, amateur iphone photo" }
)
# ===================================================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
if (-not (Test-Path $HERO_FACE)) { Write-Host "ERROR: cara heroe no existe: $HERO_FACE"; exit 1 }
if (-not (Test-Path $PY)) { Write-Host "ERROR: Python no encontrado: $PY"; exit 1 }
New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null

$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
$PULID   = "8baa7ef2255075b46f4d91cd238c21d31181b3e6a864463f967960bb0112525b"
$CLARITY = "dfad41707589d68ecdccd1dfa600d55a208f9310748e44bfe35b4a6291453d5e"
$EPIC    = "epicrealism_naturalSinRC1VAE.safetensors [84d76a0328]"
$SKIN_POS = "raw amateur phone photo, real human skin with visible pores, natural skin texture, slight oily t-zone shine, light freckles, subtle skin redness, no makeup, normal realistic skin <lora:more_details:0.3>"
$SKIN_NEG = "airbrushed, smooth skin, flawless, beauty filter, poreless, perfect skin, makeup, doll skin, plastic"

function Wait-Pred($id) {
    for ($i=0; $i -lt 150; $i++) {
        Start-Sleep -Seconds 4
        try { $r = Invoke-RestMethod -Uri "$apiBase/predictions/$id" -Headers $headers } catch { continue }
        if ($r.status -eq "succeeded") { return $r.output }
        if ($r.status -in @("failed","canceled")) { Write-Host "  [FAIL] $($r.error)"; return $null }
    }
    Write-Host "  [TIMEOUT]"; return $null
}
function Up($path, $ct) { (& curl.exe -X POST "$apiBase/files" -H "Authorization: Bearer $token" -F "content=@$path;type=$ct" --silent --show-error --max-time 300 | ConvertFrom-Json).urls.get }
function Get-Url($o) { if ($o -is [array]) { return $o[0] } else { return $o } }

# Subir cara heroe UNA vez
$heroUrl = Up $HERO_FACE "image/png"
Write-Host "Cara heroe: $heroUrl"

foreach ($s in $SCENES) {
    Write-Host "===== $($s.name) ====="
    $w = if ($s.w) { $s.w } else { 832 }
    $h = if ($s.h) { $s.h } else { 1216 }

    # --- 1. PuLID: cara heroe bloqueada ---
    $fullPrompt = "$($s.p), $FACE_LOCK"
    $b = @{ version=$PULID; input=@{ main_face_image=$heroUrl; prompt=$fullPrompt; negative_prompt="plastic skin, airbrushed, beauty filter, smooth skin, cartoon, cgi, deformed, different eye color, blue eyes, green eyes"; width=$w; height=$h; id_weight=$ID_WEIGHT; start_step=$START_STEP; num_steps=$NUM_STEPS; guidance_scale=$GUIDANCE; true_cfg=$TRUE_CFG; num_outputs=1; output_format="png"; output_quality=95 } } | ConvertTo-Json -Depth 6 -Compress
    $r = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $b
    Write-Host "  pulid $($r.id)"; $o = Wait-Pred $r.id
    if (-not $o) { continue }
    $raw = Join-Path $OUTDIR "$($s.name)_raw.png"
    Invoke-WebRequest -Uri (Get-Url $o) -OutFile $raw -UseBasicParsing

    # --- 2. epiCRealism: piel real ---
    $up = Up $raw "image/png"
    $cb = @{ version=$CLARITY; input=@{ image=$up; prompt=$SKIN_POS; negative_prompt=$SKIN_NEG; sd_model=$EPIC; creativity=$SKIN_CR; resemblance=$SKIN_RS; scale_factor=2; dynamic=5; num_inference_steps=25; handfix="disabled"; output_format="png" } } | ConvertTo-Json -Depth 6 -Compress
    $cr = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $cb
    Write-Host "  skin $($cr.id)"; $co = Wait-Pred $cr.id
    if (-not $co) { continue }
    $skin = Join-Path $OUTDIR "$($s.name)_skin.png"
    Invoke-WebRequest -Uri (Get-Url $co) -OutFile $skin -UseBasicParsing

    # --- 3. sensor ---
    $final = Join-Path $OUTDIR "$($s.name)_FINAL.jpg"
    & $PY $SENSORPY $skin $final --strength $SENSOR --downscale 1280 --jpeg 90
    Write-Host "  [OK] $final"
}
Write-Host "=== LISTO -> $OUTDIR ==="
