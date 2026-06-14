# AvatarPrime — build_dataset.ps1
# Construye un DATASET DE IDENTIDAD CONSISTENTE para re-entrenar el LoRA de cara.
# Genera N fotos de UNA misma cara heroe (PuLID, identidad bloqueada) con variedad de
# angulo/luz/gesto/encuadre, y le aplica piel real-pero-bonita (epiCRealism 0.15).
# Resultado: set coherente de UNA persona -> el LoRA reentrenado da la modelo exacta siempre.
#
# USO: $env:REPLICATE_API_TOKEN="..."; ./build_dataset.ps1
# Salida: ./dataset_identity/id_XX.jpg

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Continue"

# ===== CONFIG =====
$HERO_FACE = Join-Path (Split-Path -Parent $PSScriptRoot) "docs\images\identity-closeup.jpg"  # cara canonica original
$ID_WEIGHT = 1.4   # alto = dataset muy consistente con el heroe
$FACE_LOCK = "warm brown eyes, dark brown eyes"
$SKIN_CR   = 0.15  # piel real pero bonita
$SKIN_RS   = 0.82
$PY        = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
$OUTDIR    = Join-Path (Split-Path -Parent $PSScriptRoot) "dataset_identity"
# ==================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
if (-not (Test-Path $HERO_FACE)) { Write-Host "ERROR: heroe no existe: $HERO_FACE"; exit 1 }
New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null
$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }
$PULID   = "8baa7ef2255075b46f4d91cd238c21d31181b3e6a864463f967960bb0112525b"
$CLARITY = "dfad41707589d68ecdccd1dfa600d55a208f9310748e44bfe35b4a6291453d5e"
$EPIC    = "epicrealism_naturalSinRC1VAE.safetensors [84d76a0328]"
$SKIN_POS = "real human skin with fine visible pores, natural healthy skin texture, soft realistic skin detail, beautiful attractive young woman, no makeup <lora:more_details:0.25>"
$SKIN_NEG = "airbrushed, plastic skin, smooth poreless skin, beauty filter, aged skin, old, wrinkles, rough skin, acne, blemishes, red blotchy skin, ugly, different person, different face"

function Wait-Pred($id){ for($i=0;$i -lt 150;$i++){Start-Sleep -Seconds 4; try { $r=Invoke-RestMethod -Uri "$apiBase/predictions/$id" -Headers $headers } catch { continue }; if($r.status -eq "succeeded"){return $r.output};if($r.status -in @("failed","canceled")){Write-Host "  [FAIL] $($r.error)";return $null}};return $null }
function Up($path,$ct){ (& curl.exe -X POST "$apiBase/files" -H "Authorization: Bearer $token" -F "content=@$path;type=$ct" --silent --show-error --max-time 300 | ConvertFrom-Json).urls.get }
function Get-Url($o){ if($o -is [array]){return $o[0]}else{return $o} }

# Variedad de tomas (todas la MISMA cara, distinto angulo/luz/gesto/encuadre)
$SHOTS = @(
  "front facing portrait, neutral expression, soft window light, plain background",
  "three-quarter view from the left, gentle smile, outdoor daylight",
  "three-quarter view from the right, neutral, indoor warm light",
  "slight profile looking away, soft natural daylight, contemplative",
  "close-up laughing genuinely, natural teeth, eyes squinted, candid",
  "portrait serious expression, hard flash light, plain wall",
  "half body casual tank top, bright daylight, relaxed",
  "portrait looking slightly down, soft diffused light",
  "portrait looking slightly up, outdoor overcast light",
  "candid mid-expression talking, natural light, unposed",
  "portrait with hair tied up, even studio-free light, plain background",
  "portrait hair down messy, at home, soft lamp light",
  "selfie angle slightly from above, arm extended look, daylight",
  "outdoor portrait warm late afternoon light, relaxed smile",
  "indoor portrait warm lamp light at night, calm expression",
  "frontal clean portrait, soft even light, neutral catalog style"
)

$heroUrl = Up $HERO_FACE "image/jpeg"
Write-Host "Heroe: $heroUrl  | generando $($SHOTS.Count) tomas..."
$idx = 0
foreach ($shot in $SHOTS) {
    $idx++
    $tag = "{0:D2}" -f $idx
    Write-Host "===== id_$tag ====="
    $prompt = "candid amateur phone photo of a woman, $shot, real skin texture with pores, $FACE_LOCK, no makeup"
    $b = @{ version=$PULID; input=@{ main_face_image=$heroUrl; prompt=$prompt; negative_prompt="plastic skin, airbrushed, beauty filter, smooth skin, cartoon, cgi, deformed, different eye color, blue eyes, green eyes"; width=896; height=1152; id_weight=$ID_WEIGHT; start_step=0; num_steps=20; guidance_scale=4; true_cfg=1; num_outputs=1; output_format="png"; output_quality=95 } } | ConvertTo-Json -Depth 6 -Compress
    $r = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $b
    $o = Wait-Pred $r.id
    if (-not $o) { continue }
    $raw = Join-Path $OUTDIR "id_$($tag)_raw.png"
    Invoke-WebRequest -Uri (Get-Url $o) -OutFile $raw -UseBasicParsing
    # piel real-pero-bonita
    $up = Up $raw "image/png"
    $cb = @{ version=$CLARITY; input=@{ image=$up; prompt=$SKIN_POS; negative_prompt=$SKIN_NEG; sd_model=$EPIC; creativity=$SKIN_CR; resemblance=$SKIN_RS; scale_factor=2; dynamic=4; num_inference_steps=22; handfix="disabled"; output_format="png" } } | ConvertTo-Json -Depth 6 -Compress
    $cr = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $cb
    $co = Wait-Pred $cr.id
    if (-not $co) { continue }
    Invoke-WebRequest -Uri (Get-Url $co) -OutFile (Join-Path $OUTDIR "id_$tag.jpg") -UseBasicParsing
    Write-Host "  [OK] id_$tag.jpg"
}
Write-Host "=== DATASET LISTO -> $OUTDIR ==="
