# AvatarPrime — Body prompt templates

For the body LoRA and for combined production.
Replace `<body_trigger>` (e.g. "mychar01body body") and `<face_trigger>`.

## Caption structure for the body dataset

```text
<body_trigger>, [framing/angle], [specific clothing], [pose], [setting],
[visible proportions], [skin tone], [texture], [how the face is hidden]
```

Example:
```text
mychar01body body, frontal view, navy blue string bikini, plain background,
defined waist, toned abdomen, natural hip curve, golden bronze tan, athletic
build, real skin texture, face cropped above frame
```

## Body and texture vocabulary (describe ONLY what's visible — Lesson 2)

⚠️ The body is REAL (a consenting model). Do NOT invent flaws she doesn't have
(belly roll, cellulite, stretch marks if they aren't in her photos) — that
contaminates the LoRA and fights the real identity. The tell is NOT the body: it's
that generation SMOOTHS real skin. The rule is to PRESERVE the texture the dataset
already has.

```text
# real proportions of the model (describe what's visible, without exaggerating)
defined waist · natural hip curve · toned abdomen · athletic legs

# REAL TEXTURE to preserve (this is what generation loses -> the real tell)
real skin texture · visible skin pores · natural skin tone variation
skin specular highlights from hard light · fine body hair · subtle tan lines
soft skin folds where the body bends · veins visible on hands · realistic skin sheen
sand on skin (if it applies to the photo) · natural moles where visible
```

Rule (Lesson 2): look at the real photo and name ITS concrete texture. Don't invent
imperfections; don't omit the real texture either. Smooth, textureless skin = tell #1.

## How to describe a hidden face (important)
```text
face not visible · face cropped above frame · face hidden by hair · face hidden
by phone · face turned away · head in frame face not clear
```

## Combined production (two LoRAs)

Include BOTH triggers:
```text
<face_trigger> <body_trigger>, [full scene with an imperfect capture], face visible,
real skin texture, visible skin pores, natural skin tone variation, skin specular
highlights, fine body hair, hard directional light, candid not posed, real phone
camera photo, NOT plastic skin, NOT airbrushed skin, NOT smoothed skin, NOT beauty
filter, NOT studio glamour lighting, NOT posed for camera, NOT head cropped, NOT
distorted anatomy
```

After generating, ALWAYS run `scripts/sensor_realism.py --strength 0.6` to add sensor
noise, grain, chromatic aberration, and real JPEG compression. The prompt fixes the
body/scene (tells #1, #3, #4, #5); the script fixes sensor texture (tell #2 and the
"too clean" digital look).

Scene examples:

⚠️ TELLS #3–#5: light that's too flattering, composition that's too good, a staged
scene. Real photos have ugly light, crooked framing, and messy backgrounds.

```text
# BEFORE (staged — looks AI even if the skin is perfect)
... sitting at an outdoor cafe wearing a yellow summer dress, holding coffee, warm light
... walking on a beach at sunset wearing a bikini, full body, golden hour

# AFTER (imperfect capture — looks real)
... candid snapshot at a cafe, harsh overhead noon sun, slightly tilted framing,
    cluttered background with other people, mid-sip not posing, plain cotton dress
... amateur phone photo on the beach at midday, flat harsh light, sand and trash
    on ground, wind blowing hair across face, squinting, awkward mid-step pose
... leaning on a brick wall, overcast flat grey light, messy urban background with
    bins and cables, casual unflattering angle from slightly below, relaxed not posing
... bathroom mirror selfie, direct ceiling light casting hard shadows under eyes,
    phone visible, cluttered shelf behind, plain tank top, no makeup
... kitchen at home, mixed warm bulb + cold window light, slightly out of focus,
    motion blur on hand, ordinary loungewear, caught off guard expression
```

Principle: crooked framing, hard/mixed light, a background with real clutter, a
mid-action pose (not posing), ordinary clothing. Scene perfection gives it away.

## Body dataset balance (recommended)
```text
- Wardrobe variety (NOT only swimwear): bikini, casual, athletic, dress
- Some with the head IN frame (face hidden) → avoids "headless body"
- Angle variety: front, back, profile
- Varied backgrounds if possible (not only a white studio)
```
