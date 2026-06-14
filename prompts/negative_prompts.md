# AvatarPrime — Negative prompts (anti-plastic)

FLUX doesn't use a separate negative-prompt parameter on many endpoints, so the
negations go INSIDE the positive prompt with "NOT ...".
(The PuLID endpoint and some others do accept a separate negative_prompt.)

## Embedded negations (inside the positive prompt)
```text
NOT plastic skin, NOT smooth skin, NOT airbrushed, NOT beauty filter,
NOT doll face, NOT CGI, NOT porcelain skin, NOT perfect symmetric face,
NOT head cropped, NOT distorted anatomy, NOT extra limbs
```

## Full negative prompt (for endpoints that accept one separately)
```text
plastic skin, waxy skin, porcelain skin, flawless skin, airbrushed skin,
beauty filter, skin smoothing, over retouched, perfect skin, doll face, CGI,
3d render, fake skin texture, glossy plastic face, hyper perfect model,
instagram filter, symmetrical face, perfect makeup, editorial retouching,
unrealistically smooth, blurred skin detail, face restoration, beauty enhancement
```

## For full body (anti-broken-anatomy)
```text
head cropped, face cropped, missing head, decapitated framing, mannequin body,
distorted anatomy, extra limbs, warped hands, extra fingers, studio catalog background
```

## For full body (anti-SMOOTHING, NOT anti-body — the body is real)
The model's body is real and fit; do NOT negate its shape. Only negate the SMOOTHING
and glamour that erase the real skin texture.
```text
airbrushed skin, smoothed skin, plastic skin, beauty filter, skin smoothing,
hairless smooth body, waxy skin, glossy body, magazine retouching, perfect even
lighting, golden hour glamour, studio glamour, posed for camera, centered composition,
clean studio background
```

## CRITICAL in the inference pipeline

Make sure NO post-processing is active that erases texture:
```text
❌ face_restoration (GFPGAN, CodeFormer)
❌ skin_smoothing
❌ beauty_enhance / face_enhance
❌ a smoothing upscaler with no detail control
❌ aggressive noise reduction

If any is active, the LoRA improves but the post-processing erases the real texture.
```
