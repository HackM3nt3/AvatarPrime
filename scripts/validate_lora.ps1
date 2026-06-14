# AvatarPrime — validate_lora.ps1
# Valida el LoRA de identidad RE-ENTRENADO: genera escenas diversas y verifica que
# sea la MISMA modelo, consistente, bonita y con piel real.
# Pipeline: multi-LoRA (identidad nueva + cuerpo) -> epiCRealism 0.15 -> sensor 0.30.
#
# USO: $env:REPLICATE_API_TOKEN="..."; ./validate_lora.ps1
# Lee los pesos del training ID; salida en ./validation_nuevo_lora/

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Continue"

# ===== CONFIG =====
$TRAINING_ID = "7btdy4hf99rmt0cyf2grz61m4g"   # training del LoRA nuevo
$BODY_WEIGHTS = "<WEIGHTS_URL>"
$ID_TRIGGER = "mychar01 woman"
$BODY_TRIGGER = "mychar01body body"
$PY = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$ROOT = Split-Path -Parent $PSScriptRoot
$OUTDIR = Join-Path $ROOT "validation_nuevo_lora"
$SENSORPY = Join-Path $PSScriptRoot "sensor_realism.py"
# ==================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

# pesos del LoRA nuevo
$tr = Invoke-RestMethod -Uri "$apiBase/trainings/$TRAINING_ID" -Headers $headers
if ($tr.status -ne "succeeded") { Write-Host "Training status: $($tr.status) - aun no listo"; exit 1 }
$ID_WEIGHTS = $tr.output.weights
Write-Host "LoRA nuevo: $ID_WEIGHTS"
New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null

$MULTILORA = "ad0314563856e714367fdc7244b19b160d25926d305fec270c9e00f64665d352"
$CLARITY   = "dfad41707589d68ecdccd1dfa600d55a208f9310748e44bfe35b4a6291453d5e"
$EPIC      = "epicrealism_naturalSinRC1VAE.safetensors [84d76a0328]"
$SKIN_POS = "real human skin with fine visible pores, natural healthy skin texture, soft realistic skin detail, beautiful attractive young woman, no makeup <lora:more_details:0.25>"
$SKIN_NEG = "airbrushed, plastic skin, smooth poreless skin, beauty filter, aged skin, old, wrinkles, rough skin, acne, blemishes, blotchy, ugly, different person, different face"
$GEN_SKIN = "real skin texture, visible pores, no makeup, candid"
$GEN_NEG  = "NOT plastic skin, NOT airbrushed, NOT smoothed, NOT beauty filter, NOT glamour lighting, NOT posed, NOT oversized head, NOT distorted anatomy"

# presets: id/body/aspect/creativity/resemblance
$PRESETS = @{
    face = @{ id=0.85; body=0.20; ar="3:4";  cr=0.15; rs=0.82 }
    half = @{ id=0.80; body=0.55; ar="3:4";  cr=0.15; rs=0.80 }
    full = @{ id=0.78; body=0.80; ar="9:16"; cr=0.12; rs=0.85 }
}
$SCENES = @(
    @{ name="v1_selfie";  fr="face"; d="candid close-up selfie, soft window light, relaxed half smile, plain room" }
    @{ name="v2_cafe";    fr="half"; d="half body at an outdoor cafe, casual tank top, harsh noon sun, people in background, mid moment" }
    @{ name="v3_parque";  fr="half"; d="half body in a park, casual t-shirt, overcast flat light, walking, unposed" }
    @{ name="v4_calle";   fr="full"; d="full body head to toe on a city sidewalk, crop top and jeans, overcast, leaning on a wall" }
    @{ name="v5_cuarto";  fr="half"; d="sitting on a couch at home, hoodie, warm lamp light, relaxed candid" }
    @{ name="v6_risa";    fr="face"; d="close-up laughing genuinely, mouth open natural teeth, outdoor daylight, candid" }
)

function Wait-Pred($id){ for($i=0;$i -lt 150;$i++){Start-Sleep -Seconds 4; try { $r=Invoke-RestMethod -Uri "$apiBase/predictions/$id" -Headers $headers } catch { continue }; if($r.status -eq "succeeded"){return $r.output};if($r.status -in @("failed","canceled")){Write-Host "  [FAIL] $($r.error)";return $null}};return $null }
function Up($p,$ct){ (& curl.exe -X POST "$apiBase/files" -H "Authorization: Bearer $token" -F "content=@$p;type=$ct" --silent --show-error --max-time 300 | ConvertFrom-Json).urls.get }
function UrlOf($o){ if($o -is [array]){return $o[0]}else{return $o} }

foreach ($s in $SCENES) {
    Write-Host "===== $($s.name) ====="
    $pr = $PRESETS[$s.fr]
    $prompt = "$ID_TRIGGER $BODY_TRIGGER, $($s.d), face visible, $GEN_SKIN, real phone camera photo. $GEN_NEG"
    $b = @{ version=$MULTILORA; input=@{ prompt=$prompt; hf_loras=@($ID_WEIGHTS,$BODY_WEIGHTS); lora_scales=@($pr.id,$pr.body); aspect_ratio=$pr.ar; num_inference_steps=35; guidance_scale=2.8; num_outputs=1; output_format="jpg"; output_quality=95; disable_safety_checker=$true } } | ConvertTo-Json -Depth 6 -Compress
    $r = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $b
    Write-Host "  gen $($r.id)"; $o = Wait-Pred $r.id
    if (-not $o) { continue }
    $raw = Join-Path $OUTDIR "$($s.name)_raw.jpg"
    Invoke-WebRequest -Uri (UrlOf $o) -OutFile $raw -UseBasicParsing
    $up = Up $raw "image/jpeg"
    $cb = @{ version=$CLARITY; input=@{ image=$up; prompt=$SKIN_POS; negative_prompt=$SKIN_NEG; sd_model=$EPIC; creativity=$pr.cr; resemblance=$pr.rs; scale_factor=2; dynamic=4; num_inference_steps=22; handfix="image_and_hands"; output_format="png" } } | ConvertTo-Json -Depth 6 -Compress
    $cr = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $cb
    Write-Host "  skin $($cr.id)"; $co = Wait-Pred $cr.id
    if (-not $co) { continue }
    $skin = Join-Path $OUTDIR "$($s.name)_skin.png"
    Invoke-WebRequest -Uri (UrlOf $co) -OutFile $skin -UseBasicParsing
    $final = Join-Path $OUTDIR "$($s.name)_FINAL.jpg"
    & $PY $SENSORPY $skin $final --strength 0.30 --downscale 1440 --jpeg 90
    Write-Host "  [OK] $final"
}

Write-Host "=== VALIDACION LISTA -> $OUTDIR ==="
