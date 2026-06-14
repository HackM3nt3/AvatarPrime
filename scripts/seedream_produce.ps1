# AvatarPrime — seedream_produce.ps1
# PRODUCCION con Seedream 4. Identidad + cuerpo CONSISTENTES via "pack de identidad" fijo
# (fotos de referencia que se pasan en CADA generacion). Realismo nativo, sin entrenar LoRA.
#
# USO: $env:REPLICATE_API_TOKEN="..."; ./seedream_produce.ps1
# Salida: ./production_seedream/<scene>.jpg
#
# Para cambiar la modelo: reemplaza las fotos en ./pack_identidad/
# Para cambiar el feed: edita el array $SCENES abajo.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Continue"

# ===== CONFIG =====
$ROOT   = Split-Path -Parent $PSScriptRoot
$PACK   = Join-Path $ROOT "pack_identidad"          # fotos de referencia (cara + ancla de cuerpo)
$OUTDIR = Join-Path $ROOT "production_seedream"
$SEEDREAM = "cf7d431991436f19d1c8dad83fe463c729c816d7a21056c5105e75c84a0aa7e9"
$SIZE   = "2K"
# Descripcion de cuerpo FIJA (refuerza consistencia ademas del ancla). Editar al cuerpo real.
$BODY   = "fit toned athletic body, defined waist, natural curves, slim build, tanned skin"
# ==================

# ===== ESCENAS (editar para tu feed) =====
#  n = nombre archivo | ar = aspect (3:4 medio, 9:16 cuerpo entero, 1:1 feed) | p = escena
$SCENES = @(
    @{ n="01_mirror";    ar="9:16"; p="full body gym mirror selfie, grey sports bra and black leggings, holding phone, gym equipment and mirrors behind, bright gym lighting, full figure head to feet" }
    @{ n="02_pesas";     ar="9:16"; p="full body candid photo holding dumbbells next to a weight rack, sports bra and shorts, focused expression, gym interior, natural light" }
    @{ n="03_postworkout"; ar="3:4"; p="candid post-workout selfie, slightly sweaty glowing skin, towel around neck, tank top, flushed cheeks, gym background, real skin" }
    @{ n="04_sentadilla"; ar="9:16"; p="full body candid photo mid-workout at a squat rack, athletic wear, dynamic pose, gym interior, full figure" }
    @{ n="05_yoga";      ar="9:16"; p="full body candid photo stretching on a yoga mat, fitted athletic set, bright studio with plants, calm expression, full figure" }
    @{ n="06_agua";      ar="3:4";  p="candid close-up smiling holding a water bottle after training, sports bra, slightly sweaty, gym background, warm natural light" }
    @{ n="07_athleisure"; ar="9:16"; p="full body candid street photo in athleisure, leggings and cropped hoodie, holding iced coffee, walking on sidewalk, daylight, full figure" }
    @{ n="08_casa";      ar="9:16"; p="full body home workout candid photo in living room, sports bra and leggings, yoga mat on floor, soft window light, full figure" }
    @{ n="09_vestidor";  ar="3:4";  p="candid locker room mirror selfie, athletic set, holding phone, lockers behind, flat indoor light, ordinary snapshot" }
    @{ n="10_outdoor";   ar="9:16"; p="full body candid photo jogging on an outdoor running track, athletic wear and running shoes, morning daylight, full figure" }
)
# =========================================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
if (-not (Test-Path $PACK)) { Write-Host "ERROR: no existe el pack: $PACK"; exit 1 }
New-Item -ItemType Directory -Force -Path $OUTDIR | Out-Null
$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization"="Bearer $token"; "Content-Type"="application/json" }

function Wait-Pred($id){ for($i=0;$i -lt 90;$i++){Start-Sleep -Seconds 4; try{$r=Invoke-RestMethod -Uri "$apiBase/predictions/$id" -Headers $headers}catch{continue}; if($r.status -eq "succeeded"){return $r}; if($r.status -in @("failed","canceled")){return $r}}; return $null }
function UrlOf($o){ if($o -is [array]){return $o[0]}else{return $o} }
function Up($p){ $ct = if($p -match '\.png$'){"image/png"}else{"image/jpeg"}; (& curl.exe -X POST "$apiBase/files" -H "Authorization: Bearer $token" -F "content=@$p;type=$ct" --silent --show-error --max-time 300 | ConvertFrom-Json).urls.get }

# Subir el pack de identidad una vez
$refs = @()
foreach ($f in (Get-ChildItem $PACK -File | Where-Object { $_.Extension -in ".jpg",".png" })) {
    $u = Up $f.FullName
    if ($u) { $refs += $u }
}
Write-Host "Pack de identidad: $($refs.Count) referencias"
if ($refs.Count -eq 0) { Write-Host "ERROR: pack vacio"; exit 1 }

foreach ($s in $SCENES) {
    Write-Host "===== $($s.n) ====="
    $prompt = "candid amateur phone photo of this exact same woman, $($s.p), $BODY, keep the exact same face and same body, real natural skin with texture, not glossy, not professional photography"
    $input = @{ prompt=$prompt; image_input=$refs; size=$SIZE; aspect_ratio=$s.ar; max_images=1; sequential_image_generation="disabled" }
    $b = @{ version=$SEEDREAM; input=$input } | ConvertTo-Json -Depth 6 -Compress
    $resp = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $b
    $r = Wait-Pred $resp.id
    if ($r -and $r.status -eq "succeeded") {
        Invoke-WebRequest -Uri (UrlOf $r.output) -OutFile (Join-Path $OUTDIR "$($s.n).jpg") -UseBasicParsing
        Write-Host "  [OK] $($s.n).jpg"
    } else {
        Write-Host "  [FALLO] $($s.n): $($r.error)"
    }
}
Write-Host "=== LOTE LISTO -> $OUTDIR ==="
