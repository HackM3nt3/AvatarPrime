# AvatarPrime — Generar caras del avatar con FLUX Kontext Max
# Mantiene identidad usando una foto de referencia + prompts variados
# USO:
#   $env:REPLICATE_API_TOKEN = "tu_token"
#   ./generate_faces.ps1

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Continue"

# ====== CONFIG (editar) ======
$REF_IMAGE  = "./reference_face.jpg"   # foto de referencia del avatar (1 buena foto)
$TRIGGER    = "miavatar woman"
$OUTPUT_DIR = "./faces_output"
# =============================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

# Subir referencia
$up = (& curl.exe -X POST "$apiBase/files" -H "Authorization: Bearer $token" -F "content=@$REF_IMAGE;type=image/jpeg" --silent --show-error --max-time 300) | ConvertFrom-Json
$refUrl = $up.urls.get
if (-not $refUrl) { Write-Host "ERROR upload ref"; exit 1 }

$NEG = "NOT plastic skin, NOT smooth airbrushed, NOT beauty filter, NOT doll face, NOT CGI"

# Prompts variados (editar segun necesidad — ver prompts/face_prompts.md)
$variations = @(
    @{ name="01_closeup";  p="close-up phone portrait, visible pores, fine skin texture, soft natural makeup, hair down, soft window light, relaxed smile" }
    @{ name="02_halfbody"; p="casual phone selfie at home, plain top, natural skin texture, soft window light, relaxed expression" }
    @{ name="03_profile";  p="strict side profile, looking out window, natural daylight one side, visible skin texture on cheek, contemplative" }
    @{ name="04_laugh";    p="candid close-up laughing, mouth open natural teeth, eyes squinted, visible pores, stray hairs, spontaneous" }
    @{ name="05_outdoor";  p="outdoor candid, harsh midday sun, casual top, natural skin glow, hair moved by breeze, slight squint" }
)

Write-Host "=== Generating faces (Kontext) ==="
$preds = New-Object System.Collections.ArrayList
foreach ($v in $variations) {
    $prompt = "raw unretouched $($v.p) of $TRIGGER, attractive natural woman, real phone camera photo, no beauty filter. $NEG"
    $bodyObj = @{ input = @{ prompt=$prompt; input_image=$refUrl; aspect_ratio="3:4"; output_format="jpg"; safety_tolerance=5 } } | ConvertTo-Json -Depth 5 -Compress
    try {
        $r = Invoke-RestMethod -Uri "$apiBase/models/black-forest-labs/flux-kontext-max/predictions" -Method POST -Headers $headers -Body $bodyObj
        Write-Host "[OK] $($v.name) id=$($r.id)"
        [void]$preds.Add([ordered]@{ name=$v.name; id=$r.id; status=$r.status; output=$null })
    } catch { Write-Host "[FAIL] $($v.name): $_" }
}

$iter=0
while ($true) {
    $iter++; $pending=0
    for ($i=0; $i -lt $preds.Count; $i++) {
        $p=$preds[$i]
        if ($p.status -in @("succeeded","failed","canceled")) { continue }
        try { $r = Invoke-RestMethod -Uri "$apiBase/predictions/$($p.id)" -Headers $headers; $preds[$i].status=$r.status
            if ($r.status -eq "succeeded") { $preds[$i].output=$r.output; Write-Host "[DONE] $($p.name)" }
            elseif ($r.status -in @("failed","canceled")) { Write-Host "[FAIL] $($p.name)" } else { $pending++ } } catch { $pending++ }
    }
    if ($pending -eq 0) { break }; if ($iter -gt 60) { break }; Start-Sleep -Seconds 3
}
foreach ($p in $preds) {
    if ($p.status -ne "succeeded") { continue }
    $url = if ($p.output -is [array]) { $p.output[0] } else { $p.output }
    if ($url) { Invoke-WebRequest -Uri $url -OutFile (Join-Path $OUTPUT_DIR "$($p.name).jpg") -UseBasicParsing }
}
Write-Host "Done. Output: $OUTPUT_DIR"
