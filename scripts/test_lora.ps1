# AvatarPrime — Validar un LoRA entrenado con prompts de test
# USO:
#   $env:REPLICATE_API_TOKEN = "tu_token"
#   ./test_lora.ps1
# Genera tests para verificar identidad, textura y ausencia de sesgos.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Continue"

# ====== CONFIG (editar) ======
$LORA_VERSION = "tuusuario/mi-lora:VERSION_ID"   # version del LoRA destination
$TRIGGER      = "miavatar woman"
$OUTPUT_DIR   = "./lora_tests"
# =============================

$token = $env:REPLICATE_API_TOKEN
if (-not $token) { Write-Host "ERROR: set REPLICATE_API_TOKEN"; exit 1 }
New-Item -ItemType Directory -Force -Path $OUTPUT_DIR | Out-Null
$apiBase = "https://api.replicate.com/v1"
$headers = @{ "Authorization" = "Bearer $token"; "Content-Type" = "application/json" }

$NEG = "NOT plastic skin, NOT smooth skin, NOT airbrushed, NOT beauty filter, NOT doll face, NOT CGI"

# Tests para validar identidad + textura + sesgos
$tests = @(
    @{ name="01_closeup_s09"; scale=0.9; p="close-up portrait, visible pores, fine skin texture, soft window light, relaxed expression" }
    @{ name="02_closeup_s08"; scale=0.8; p="close-up portrait, visible pores, fine skin texture, soft window light, relaxed expression" }
    @{ name="03_color_test"; scale=0.85; p="wearing a red blouse, urban background, natural skin texture, soft daylight" }
    @{ name="04_nojewel_test"; scale=0.85; p="no jewelry, plain white t-shirt, plain gray background, soft studio daylight" }
    @{ name="05_setting_test"; scale=0.85; p="on a city street, harsh daylight, casual outfit, hair moved by wind" }
)

Write-Host "=== Testing LoRA ==="
$preds = New-Object System.Collections.ArrayList
foreach ($t in $tests) {
    $prompt = "raw unretouched photo of $TRIGGER, $($t.p), realistic human skin texture, real phone camera photo. $NEG"
    $bodyObj = @{ version=$LORA_VERSION; input=@{ prompt=$prompt; aspect_ratio="3:4"; num_outputs=1; num_inference_steps=40; guidance_scale=2.8; output_format="jpg"; output_quality=95; lora_scale=$t.scale; model="dev" } } | ConvertTo-Json -Depth 5 -Compress
    try { $r = Invoke-RestMethod -Uri "$apiBase/predictions" -Method POST -Headers $headers -Body $bodyObj
        Write-Host "[OK] $($t.name) scale=$($t.scale)"; [void]$preds.Add([ordered]@{ name=$t.name; id=$r.id; status=$r.status; output=$null }) } catch { Write-Host "[FAIL] $($t.name)" }
}
$iter=0
while ($true) { $iter++; $pending=0
    for ($i=0; $i -lt $preds.Count; $i++) { $p=$preds[$i]; if ($p.status -in @("succeeded","failed","canceled")) { continue }
        try { $r=Invoke-RestMethod -Uri "$apiBase/predictions/$($p.id)" -Headers $headers; $preds[$i].status=$r.status
            if ($r.status -eq "succeeded") { $preds[$i].output=$r.output; Write-Host "[DONE] $($p.name)" } elseif ($r.status -in @("failed","canceled")) {} else { $pending++ } } catch { $pending++ } }
    if ($pending -eq 0) { break }; if ($iter -gt 60) { break }; Start-Sleep -Seconds 3
}
foreach ($p in $preds) { if ($p.status -ne "succeeded") { continue }
    $url = if ($p.output -is [array]) { $p.output[0] } else { $p.output }
    if ($url) { Invoke-WebRequest -Uri $url -OutFile (Join-Path $OUTPUT_DIR "$($p.name).jpg") -UseBasicParsing } }
Write-Host "Done. Output: $OUTPUT_DIR"
