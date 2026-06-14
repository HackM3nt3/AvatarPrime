# AvatarPrime — Full methodology

A step-by-step guide to building an identity-consistent AI virtual avatar.

---

## Phase 0 — Character strategy

Before generating anything, define the character in a **character bible** (see `templates/character_bible_template.md`):

```text
- Name + unique trigger word (e.g. "mychar01")
- Nationality, visual age (always adult)
- Fixed facial traits (eyes, nose, lips, distinctive mole)
- Skin tone, hair
- Body build
- Style, niche, home city
- AI disclosure
```

**Rule:** the trigger must be unique and not exist in the base model's training (e.g. `mychar01`, not a common word like `maria`).

---

## Phase 1 — Face generation (identity dataset)

### 1.1 Choose the model

```text
FLUX 1.1 Pro Ultra (raw=true) → initial face exploration
FLUX Kontext Max              → generate variations while keeping identity
```

FLUX Ultra's `raw` mode produces a candid look (not polished editorial). Kontext preserves identity using a reference photo.

### 1.2 Generate 12–18 face photos

Required variety:
```text
- close-up (facial texture)
- half body
- strict profile
- 3/4 and over-the-shoulder
- expressions: neutral, smile, laugh
- different light: hard window, soft, outdoor
- different settings (NOT all the same place)
```

### 1.3 CRITICAL — avoid the "plastic look"

```text
✅ Use a natural CANDID dataset (not polished editorial)
✅ Prompts with real-texture vocabulary
✅ Mention a specific camera/film (iPhone, Kodak Portra, Cinestill)
✅ Negations: NOT plastic skin, NOT airbrushed, NOT beauty filter

❌ Avoid: studio lighting, editorial golden hour, glamour, flawless skin
```

---

## Phase 2 — Identity dataset captions

### Golden rule: describe ONLY what's visible

```text
✅ If the photo DOES show pores → "visible pores on nose and cheeks"
❌ If the photo does NOT show pores → do NOT write "visible pores"

Inaccurate captions confuse training.
```

### Structure

```text
"<trigger> woman, [shot type], [expression], [clothing], [setting], [light],
[real visible texture]"

Example:
"mychar01 woman, close-up phone portrait, visible pores on nose and cheeks,
fine skin texture, soft natural makeup, hair down, soft window light from left,
relaxed closed-mouth smile"
```

### Avoid filler

Don't repeat the same phrase across all captions. Describe what's specific to each photo.

---

## Phase 3 — Train the identity LoRA

```yaml
trainer:              ostris/flux-dev-lora-trainer
trigger_word:         <name>            # e.g. mychar01
steps:                1200
learning_rate:        0.0003
lora_rank:            16                # do NOT raise just for "more texture"
resolution:           1024
caption_dropout_rate: 0.10
autocaption:          false             # use your own captions
optimizer:            adamw8bit
```

**Important:** more `lora_rank` does NOT create texture that isn't in the source images. If the images are low-resolution/detail, a high rank only learns the bias better.

---

## Phase 4 — Validate the identity LoRA

Generate 10 tests with prompts that force variety:
```text
- close-up texture (try lora_scale 0.7, 0.8, 0.9 to calibrate)
- a clothing color NOT present in the dataset (bias test)
- explicit "no jewelry" (bias test)
- a new setting (bias test)
- full body
```

Recommended inference:
```yaml
lora_scale:           0.85
guidance_scale:       2.8
num_inference_steps:  40
```

**Criteria:** the face must be consistent + real texture + obey the prompt (not force the dataset's clothing/setting).

---

## Phase 5 — Body dataset (body LoRA)

### 5.1 Photo source

```text
- Body photos with EXPLICIT consent (if a real person)
- No visible face (cropped/covered) to avoid contaminating identity
- Or AI-generated photos
```

### 5.2 Dataset balance

```text
- 20–27 photos
- Wardrobe variety (NOT only swimwear — add casual, athletic)
- Some with the head IN frame (face hidden) → avoids learning "headless body"
- Angle variety (front, back, profile)
```

### 5.3 Body captions

```text
"<name>body body, [framing], [clothing], [pose], [visible proportions],
[skin tone], [texture], [how the face is hidden]"

Example:
"mychar01body body, frontal view, navy blue string bikini, plain background,
defined waist, toned abdomen, golden bronze tan, athletic build, face cropped above frame"
```

Recommended class word: `<name>body body` (category = body).

---

## Phase 6 — Train the body LoRA

```yaml
trainer:              ostris/flux-dev-lora-trainer
trigger_word:         <name>body
steps:                1400
learning_rate:        0.0003
lora_rank:            16
caption_dropout_rate: 0.05            # low: bind the body to the trigger
```

Destination SEPARATE from the identity LoRA.

---

## Phase 7 — Combine the two LoRAs

```yaml
endpoint:     lucataco/flux-dev-multi-lora
hf_loras:     [identity_weights_url, body_weights_url]
lora_scales:  [0.82, 0.70]            # identity / body — sweet spot
prompt:       "<name> woman <name>body body, [scene], [clothing], [pose],
              face visible, realistic skin texture,
              NOT plastic skin, NOT head cropped, NOT distorted anatomy"
guidance_scale:      2.8
num_inference_steps: 35
```

### Scale calibration

```text
Face loses likeness?  → raise identity (0.85)
Body not faithful?    → raise body (0.75)
Something degrades?   → lower whichever dominates

Recommended range:
  identity 0.80–0.85
  body     0.50–0.75
```

---

## Phase 8 — Production

```text
1. Reuse the combine_multilora.ps1 script
2. Change prompts (scene, clothing, pose) keeping both triggers
3. Keep calibrated scales
4. Cost: ~$0.04 per photo
5. Generate batches for feed, stories, etc.
```

---

## Key parameter summary

| Parameter | Identity | Body | Combined inference |
|---|:---:|:---:|:---:|
| steps | 1200 | 1400 | — |
| learning_rate | 0.0003 | 0.0003 | — |
| lora_rank | 16 | 16 | — |
| caption_dropout | 0.10 | 0.05 | — |
| lora_scale | — | — | 0.82 / 0.70 |
| guidance_scale | — | — | 2.8 |
| inference steps | — | — | 35 |

---

## Mistakes to avoid

See `lessons-learned.md` for the documented mistakes from the case study.
