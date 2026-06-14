# AvatarPrime

> A framework for creating **ultra-realistic, identity-consistent AI virtual models** — same face, same body, every shot — using a reference "identity pack" and modern image models, with no LoRA training required.

![Stack](https://img.shields.io/badge/stack-Replicate%20%C2%B7%20Seedream%204%20%C2%B7%20PowerShell%20%C2%B7%20Python-4f46e5)
![Cost](https://img.shields.io/badge/cost-~%240.03%20per%20image-success)
![License](https://img.shields.io/badge/license-MIT-blue)

AvatarPrime is the distilled result of a real R&D effort to make AI-generated people that **actually look real and stay the same person** across an entire content feed. Version 2.0 abandons trained LoRAs in favor of a reference-pack approach on **Seedream 4**, which delivers natural skin and consistent identity at a fraction of the cost.

> The full v1 journey (a two-LoRA FLUX pipeline) and exactly why it failed is documented in [`REGISTRO.md`](REGISTRO.md) and [`docs/case-study.md`](docs/case-study.md) — a "what *not* to do" log that's as useful as the recipe itself.

## Why 2.0 (the key insight)

v1 built identity with **two trained FLUX LoRAs**. In real production that failed on the two things that matter most:

- **Plastic skin.** FLUX leaves a waxy "glow" a trained eye detects — it never reaches photo-real.
- **Inconsistent identity.** A LoRA trained on *generated* faces learns "a type of person," not **one** person → the face drifts between shots.

**v2.0 pivots to Seedream 4 + a reference "identity pack."** Result: real skin out of the box, the same face and body in every image, no training, at ~$0.03 per image.

## Architecture

```text
IDENTITY PACK (fixed)                 SEEDREAM 4 (bytedance/seedream-4)
  3-4 face photos          ─┐
  1 full-body (clothed)     ├──►  image_input  ──►  new photo, same person,
  body anchor              ─┘     + prompt           same body, photoreal
```

Consistency doesn't come from training — it comes from passing **the same reference pack on every generation.** Same pack = same model + same body, always.

## Tech stack

| Component | Tool | Why |
|---|---|---|
| Generation | **Seedream 4** (Replicate) | real skin (not plastic), accepts 1-10 reference photos |
| Identity + body | `image_input` reference pack | consistency with no LoRA training |
| Camera grain (optional) | `scripts/sensor_realism.py` | final realism touch, local, free |
| Orchestration | PowerShell + native Python | portable on Windows (no WSL) |

## Quick start

```powershell
# 1. Token (NEVER hardcode it)
$env:REPLICATE_API_TOKEN = "your_token_here"

# 2. Put YOUR reference photos in pack_identidad/  (3-4 face + 1 clothed full-body)
#    Use your own assets, with explicit consent, adults only. See pack_identidad/README.md

# 3. Edit the scenes you want in scripts/seedream_produce.ps1 ($SCENES)

# 4. Generate the batch
./scripts/seedream_produce.ps1
```

## Repository layout

```text
AvatarPrime/
├── README.md                 → this file
├── CHANGELOG.md              → version notes (the FLUX → Seedream pivot)
├── REGISTRO.md               → process log + "what NOT to do" (Spanish)
├── pack_identidad/           → YOUR reference pack goes here (git-ignored)
├── scripts/
│   ├── seedream_produce.ps1  → PRODUCTION (Seedream + pack) ★
│   ├── sensor_realism.py     → camera grain / sensor signature
│   └── (legacy FLUX scripts) → produce.ps1, etc. — kept as reference, not for prod
├── prompts/                  → prompt + negative-prompt templates
├── templates/                → character bible + caption rules
└── docs/                     → methodology, lessons learned, case study
```

## Production rules (learned the hard way — see REGISTRO.md)

1. It's an **AI virtual model** — disclosure is mandatory (bio, posts).
2. Any real body/face reference requires **explicit consent**; **adults only**, always.
3. Realism > magazine beauty: real skin with pores and texture, not plastic.
4. Consistency = a **fixed** reference pack on every generation.
5. Seedream has a content filter: don't use revealing references; anchor the body with a **clothed** photo + a body-type description.
6. Cheap first: validate with one image before a large batch.

## Ethics & safety

This framework is for creating **clearly-disclosed synthetic personas** (virtual influencers, brand mascots, concept models). Do not use it to impersonate real people, generate non-consensual imagery, or depict minors. Reference media of real people must be your own or used with documented consent.

## License

MIT © Leonardo Ramirez Toro
