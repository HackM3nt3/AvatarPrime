# AvatarPrime — Face prompt templates

Replace `<trigger>` with your avatar's trigger (e.g. "mychar01 woman").
Use with FLUX Kontext Max (with a reference photo) or FLUX 1.1 Pro Ultra (raw).

## Rules

```text
✅ Texture vocabulary: visible pores, fine skin texture, slight asymmetry
✅ Specific camera: iPhone 15 Pro, Kodak Portra 400, Cinestill 800T
✅ Candid: amateur photo, real phone camera, documentary realism
✅ Negations: NOT plastic skin, NOT airbrushed, NOT beauty filter

❌ Avoid: studio lighting, glamour, flawless skin, editorial, polished golden hour
```

## Close-up (facial texture)
```text
raw unretouched close-up phone photo of <trigger>, realistic human skin texture,
visible pores on nose and cheeks, fine skin texture on forehead, slight uneven
skin tone, subtle under-eye texture, natural lip texture, flyaway hair, soft
imperfect window light, relaxed closed-mouth smile, real phone camera photo,
NOT plastic skin, NOT airbrushed
```

## Half body (casual selfie)
```text
raw unretouched casual phone selfie of <trigger>, sitting at home, plain casual
top, real skin texture with visible pores, hair down natural with stray strands,
relaxed natural smile, soft window light, real iPhone front camera photo, no filter
```

## Strict profile
```text
raw unretouched strict side profile portrait of <trigger> at ninety degrees,
looking out a window, soft natural daylight on one side creating chiaroscuro,
visible skin texture on cheek, contemplative neutral expression, hair down,
real candid moment, no retouch
```

## Genuine laugh
```text
raw unretouched candid close-up of <trigger> laughing genuinely, mouth open
showing natural teeth not bleached, eyes squinted, visible pores, stray hair
strands from movement, soft natural light, spontaneous joyful moment, NOT posed
```

## Outdoor natural
```text
raw unretouched outdoor candid photo of <trigger> sitting in a park, harsh
direct midday sunlight, casual cotton top, visible pores, slight squint from sun,
hair moved by breeze, natural skin glow, soft natural smile, documentary realism
```

## Full body with face
```text
raw unretouched full body photo of <trigger> standing, casual jeans and t-shirt,
soft natural daylight, relaxed posture not posed, realistic skin texture, natural
body proportions, real phone camera photo, NOT head cropped
```

## Notes
- For Kontext: the reference photo defines identity; the prompt defines scene/style.
- For variety: change seeds + pose/light/wardrobe description, not just a single word.
- Calibrate lora_scale 0.7–0.9 at inference to balance identity vs. texture.
