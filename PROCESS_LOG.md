# PROCESS LOG — Avatar realism & identity (reference model)

A record of the WHOLE process, including the broken parts, so you know **what NOT to do**.
Date: 2026-05-29. Chronological order = order of learning.

> **The 3 golden rules that came out of all this:**
> 1. **Skin:** epiCRealism `creativity 0.15` + anti-ugly negatives. `0.30+` = over-repaints → ugly and changes the person.
> 2. **Consistent identity:** the old LoRA (trained on FLUX faces) gives "a type", not ONE person → you must RE-TRAIN with a consistent dataset.
> 3. **Sensor:** soft `0.30`. `0.55` introduces a processed look.

---

## 00 — starting point, old LoRA
The original identity + body LoRA images. **The initial problem:** they look 95% real but a trained eye catches them (skin too perfect) and, worse, **the face changes between photos** (not the same person).
- **Lesson:** a LoRA trained on FLUX-GENERATED faces never gives consistent identity. Garbage in, garbage out (its own Lesson 1).

## 01 — sensor v1
First sensor-degradation script (grain, noise, aberration, JPEG).
- **Result:** helps (95→98%) but TIMID. The skin is still smooth underneath.
- **Lesson:** degradation adds defects on top; it does NOT create texture that doesn't exist. Not enough alone.

## 02 — sensor v2
Improved sensor (phone ISP: local contrast + tone curve + texture break + halation).
- **Result:** better camera look. But at `--strength 0.55` it adds a processed/HDR look.
- **Lesson:** sensor v2 works, but at low strength (0.30). Strong = visibly processed.

## 03 — corrected-prompt generation
Regenerate with a CANDID prompt (imperfect scene) instead of a "staged postcard" + clarity-upscaler (juggernaut).
- **Result:** the corrected prompt was lever #1 (free). `fresh_*_raw` jumped on that alone.
- **DEFECT:** `playa_*` and clarity with **juggernaut** beautify the skin (wrong model).
- **Lesson:** the candid scene matters a lot. For skin, NOT juggernaut (it beautifies); use epiCRealism.

## 04 — epiCRealism skin calibration  ← KEY LESSONS
Sweep of epiCRealism `creativity` over the same face (`skin_raw.jpg`).
- `skin_FINAL.jpg` / `skin_clarity.png` = **creativity 0.5 → DEFECTIVE**: changed person (older), too many freckles.
- `skin_c38r65_*` = **0.38 → DEFECTIVE**: artifacts.
- `skin_c36r70_*` = 0.36 → marginal: too much redness/blotchiness.
- `skin_c33r70_*` = 0.33 → initial balance (acceptable).
- `skin_c30r70_*` = 0.30 → good.
- **Lesson:** `creativity 0.30+` starts drifting from the model and turning ugly. The safe ceiling is low. (0.15 was later confirmed as ideal — see folder 08.)

## 05 — soft sensor
Sensor at 0.30 vs 0.45 on the good image.
- **Lesson:** 0.30 preserves the skin and only adds camera grain. Confirmed lowering the sensor.

## 06 — full-body identity  ← KEY LESSON
Full body: fix the "big head" without breaking identity.
- `calle2_*` = fix with identity **0.75** + full-body framing + 9:16 + soft skin. Proportion OK and identity OK.
- **DEFECT (folder 09):** lowering identity to 0.62 fixes the big head BUT breaks the likeness.
- **Face-swap (cdingram):** FAILS on turned/candid faces (empty output). Discarded.
- **Lesson:** do NOT lower identity below 0.75; fix proportion with framing, not by crushing identity. The skin pass on full body must be VERY soft (0.20) to avoid repainting the small face.

## 07 — PuLID consistency
PuLID-FLUX anchored to one face to force consistent identity across scenes.
- `pulid_cafe/calle` + `production_pulid/*` = SAME person in different scenes ✓ (consistency achieved).
- **DEFECT:** PuLID **drifts away from the original model** (not the exact reference model), **re-smooths the skin**, and the **eye color varies**.
- **Lesson:** PuLID gives consistency across images, but anchored to a derivative it drifts from the model. Good for BUILDING a consistent dataset (see 10), not as a direct final product.

## 08 — winning skin recipe  ← THE RECIPE
`orig_c15_FINAL.jpg` = ORIGINAL model + epiCRealism **0.15** + anti-ugly negatives + sensor 0.30.
- **Result:** same original model, still ATTRACTIVE, real skin (fine pores, texture). NOT plastic, NOT ugly, NOT a different person.
- `orig_c22` = a touch more texture (0.22). `orig_sensoronly` = sensor only (zero repaint).
- **Lesson:** the right band is **0.15–0.22 with anti-ugly negatives**. This is the production skin recipe.

## 09 — production v1
First automatic production set (`produce.ps1`).
- `selfie_FINAL` good. **DEFECT:** `calle_FINAL` = full body with broken identity (0.62) → doesn't look like the same person.
- **Lesson:** v1's full-body broke identity; fixed in recipe 06/08.

## 10 — retraining dataset
A CONSISTENT dataset generated with PuLID (id_weight 1.4) anchored to the original face, + skin 0.15, to RE-TRAIN the identity LoRA.
- `id_01`..`id_16` = consistent but **frontal** (little pose variety — defect of high id_weight).
- `id_17`..`id_22` (in progress) = forced poses (profile, 3/4, laugh) at low id_weight for variety.
- `_contact_sheet.jpg` = curation view.
- **Lesson:** high id_weight = consistency but kills pose variety. For a dataset, mix consistent shots + forced-pose shots (low id_weight).

---

## 11 — new LoRA validation, WINNER  ← FINAL RESULT ✅
6 diverse scenes (selfie, cafe, park, street, room, laugh) with the **RE-TRAINED LoRA** + skin 0.15 + sensor 0.30.
- **Result:** the SAME model in all 6, consistent, attractive, real skin, correct proportion. Root problem solved.
- `_VALIDACION.jpg` = contact sheet of the 6.
- **Lesson:** retraining with a CONSISTENT dataset (anchored to one face) turns "a type of person" into ONE person. That + the 0.15 skin recipe + 0.30 sensor = production.

## 12 — final curated dataset (15)
The 15 images used for retraining (9 frontal with variation + 6 with pose/gesture). Anchored to the original `identity-closeup.jpg`.

---

## Summary: the correct production pipeline
```
1. Consistent identity  → RE-TRAIN the LoRA with a consistent dataset (folder 10)
2. Generate scene       → identity LoRA (0.78-0.82) + body LoRA + candid prompt
3. Real but pretty skin → epiCRealism creativity 0.15 + anti-ugly negatives
4. Camera               → sensor_realism.py --strength 0.30
```
