# Changelog — AvatarPrime

All notable versions of the framework are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com).

---

## [2.0.0] — 2026-05-30

### Major pivot: FLUX → Seedream 4

v1 (two FLUX LoRAs) never reached production quality: **plastic skin** and **inconsistent identity** across photos. v2 replaces the whole engine.

### Changed
- **Generation engine:** FLUX 1.1 / multi-LoRA → **Seedream 4** (`bytedance/seedream-4`). Real skin out of the box (not plastic).
- **Identity & body:** from two trained LoRAs → a **reference pack** (`image_input`, 1–10 photos). Consistency with no training. Same pack = same person + same body.
- **Cost:** from ~$10/avatar + training → **~$0.03 per image**, no training cost.

### Added
- `scripts/seedream_produce.ps1` — production with Seedream + identity pack.
- `pack_identidad/` — the model's "DNA" (fixed reference photos: face + body anchor).
- `PROCESS_LOG.md` — full process log and "what NOT to do".
- `scripts/sensor_realism.py` — optional camera grain/signature (native Windows Python).

### Deprecated (legacy — not for production)
- The FLUX path: `combine_multilora.ps1`, `produce.ps1`, `pulid_produce.ps1`, `build_dataset.ps1`, `validate_lora.ps1`. Kept as historical reference.

### Lessons learned (2.0)
- FLUX leaves a plastic "glow" that never reaches photo-real; Seedream/Imagen do (documented bake-off).
- A LoRA trained on generated faces learns "a type of person," not ONE person → inconsistent.
- Real consistency = a FIXED reference pack, not training.
- Seedream content filter (E005): don't use revealing references; anchor the body with a clothed photo.
- Real but attractive skin: clients reject both plastic and ugly/aged results.
- Economics FIRST (feasibility study) before choosing an engine.
- Windows-native (no WSL) for portability.

### Validated on
- A 10-scene gym feed: same model + same fit body, real skin, holds up at full resolution.

---

## [1.0.0] — 2026-05-28

### First public release

AvatarPrime 1.0 is the first release of the framework for creating identity-consistent AI virtual models via a two-LoRA system.

### Added
**Methodology**
- Two separate LoRAs (identity + body) combined at inference.
- Full flow: character bible → datasets → training → combination → production.
- Caption strategy with real texture to avoid the "AI plastic look".
- lora_scale calibration (sweet spot: identity 0.82 / body 0.70).

**Scripts (PowerShell)**
- `generate_faces.ps1` — face generation with FLUX Kontext Max.
- `train_lora.ps1` — LoRA training on Replicate (ostris trainer).
- `test_lora.ps1` — validate a trained LoRA.
- `combine_multilora.ps1` — combine two LoRAs in production.
- `monitor_training.ps1` — background training monitor.

**Prompts and templates**
- Face prompt templates (close-up, half body, full body, profile).
- Body prompt templates.
- Anti-plastic negative prompts.
- Character bible template.
- Caption rules.

**Documentation**
- Full step-by-step methodology.
- Lessons learned (documented mistakes).
- Full case study.

### Lessons learned in this version
- The "AI plastic look" comes from the DATASET, not the model.
- Captions must describe ONLY what's visible (don't invent traits).
- Splitting identity and body into two LoRAs avoids identity contamination.
- FLUX Kontext preserves identity better than pure text-to-image for datasets.
- More lora_rank does NOT create texture that isn't in the source images.
- The img2img shortcut does NOT work for "exact body + new face".
- Cheap tests before large production save money.

### Validated on
- Real case study: a demo lifestyle persona.
- Two LoRAs trained and combined successfully.
- Realism score: 9.3/10.
- Total case cost: ~$10.6 USD.

### Security notes
- Scripts read the API token from an environment variable (never hardcoded).
- `.gitignore` excludes tokens, private data, and real body photos.
- Real people's body data requires explicit consent.

---

## Roadmap (future versions)

### [2.1.0] — planned
- Automatic best-reference-pack selection (cull by face embedding).
- Predefined themed batches (lifestyle, gym, travel, fashion).
- Consistency QA with face embeddings (InsightFace) across batches.

### [3.0.0] — planned
- Video pipeline (image-to-video with Kling/Runway) keeping the pack.
- Multi-character support (avatar portfolio).
