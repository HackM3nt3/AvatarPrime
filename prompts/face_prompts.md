# AvatarPrime — Templates de prompts de cara

Reemplaza `<trigger>` por el trigger de tu avatar (ej: "mychar01 woman").
Usar con FLUX Kontext Max (con foto de referencia) o FLUX 1.1 Pro Ultra (raw).

## Reglas

```text
✅ Vocabulario de textura: visible pores, fine skin texture, slight asymmetry
✅ Cámara específica: iPhone 15 Pro, Kodak Portra 400, Cinestill 800T
✅ Candid: amateur photo, real phone camera, documentary realism
✅ Negaciones: NOT plastic skin, NOT airbrushed, NOT beauty filter

❌ Evitar: studio lighting, glamour, flawless skin, editorial, golden hour pulido
```

## Close-up (textura facial)
```text
raw unretouched close-up phone photo of <trigger>, realistic human skin texture,
visible pores on nose and cheeks, fine skin texture on forehead, slight uneven
skin tone, subtle under-eye texture, natural lip texture, flyaway hair, soft
imperfect window light, relaxed closed-mouth smile, real phone camera photo,
NOT plastic skin, NOT airbrushed
```

## Half body (selfie casual)
```text
raw unretouched casual phone selfie of <trigger>, sitting at home, plain casual
top, real skin texture with visible pores, hair down natural with stray strands,
relaxed natural smile, soft window light, real iPhone front camera photo, no filter
```

## Perfil estricto
```text
raw unretouched strict side profile portrait of <trigger> at ninety degrees,
looking out window, soft natural daylight on one side creating chiaroscuro,
visible skin texture on cheek, contemplative neutral expression, hair down,
real candid moment, no retouch
```

## Risa genuina
```text
raw unretouched candid close-up of <trigger> laughing genuinely, mouth open
showing natural teeth not bleached, eyes squinted, visible pores, stray hair
strands from movement, soft natural light, spontaneous joyful moment, NOT posed
```

## Exterior natural
```text
raw unretouched outdoor candid photo of <trigger> sitting in a park, harsh
direct midday sunlight, casual cotton top, visible pores, slight squint from sun,
hair moved by breeze, natural skin glow, soft natural smile, documentary realism
```

## Full body con cara
```text
raw unretouched full body photo of <trigger> standing, casual jeans and t-shirt,
soft natural daylight, relaxed posture not posed, realistic skin texture, natural
body proportions, real phone camera photo, NOT head cropped
```

## Notas
- Para Kontext: la foto de referencia define la identidad. El prompt define escena/estilo.
- Para variedad: cambiar seeds + descripción de pose/luz/ropa, NO solo 1 palabra.
- Calibrar lora_scale 0.7-0.9 en inference para balance identidad/textura.
