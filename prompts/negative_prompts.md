# AvatarPrime — Negative prompts (anti-plástico)

FLUX no usa negative prompt como parámetro separado en muchos endpoints.
Se incluyen las negaciones DENTRO del prompt positivo con "NOT ...".
(El endpoint PuLID y algunos sí aceptan negative_prompt separado.)

## Negaciones embebidas (dentro del prompt positivo)
```text
NOT plastic skin, NOT smooth skin, NOT airbrushed, NOT beauty filter,
NOT doll face, NOT CGI, NOT porcelain skin, NOT perfect symmetric face,
NOT head cropped, NOT distorted anatomy, NOT extra limbs
```

## Negative prompt completo (para endpoints que lo aceptan separado)
```text
plastic skin, waxy skin, porcelain skin, flawless skin, airbrushed skin,
beauty filter, skin smoothing, over retouched, perfect skin, doll face, CGI,
3d render, fake skin texture, glossy plastic face, hyper perfect model,
instagram filter, symmetrical face, perfect makeup, editorial retouching,
unrealistically smooth, blurred skin detail, face restoration, beauty enhancement
```

## Para full body (anti-anatomía rota)
```text
head cropped, face cropped, missing head, decapitated framing, mannequin body,
distorted anatomy, extra limbs, warped hands, extra fingers, studio catalog background
```

## Para full body (anti-ALISADO, NO anti-cuerpo — el cuerpo es real)
El cuerpo de la modelo es real y fit; NO negar su forma. Negar solo el ALISADO y
el glamour que borran la textura real de su piel.
```text
airbrushed skin, smoothed skin, plastic skin, beauty filter, skin smoothing,
hairless smooth body, waxy skin, glossy body, magazine retouching, perfect even
lighting, golden hour glamour, studio glamour, posed for camera, centered composition,
clean studio background
```

## CRÍTICO en el pipeline de inference

Verificar que NO esté activo ningún post-procesamiento que borre textura:
```text
❌ face_restoration (GFPGAN, CodeFormer)
❌ skin_smoothing
❌ beauty_enhance / face_enhance
❌ upscaler suavizante sin control de detalle
❌ noise reduction agresivo

Si está activo, el LoRA mejorará pero el post borrará la textura real.
```
