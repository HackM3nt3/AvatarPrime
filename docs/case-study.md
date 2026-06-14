# Case study: a consistent, photorealistic AI persona

> Anonymized write-up of a real build. All references to specific individuals and
> client assets have been removed; this documents the **method and the engineering
> decisions**, which is what transfers to the next project.

**Goal:** a disclosed AI virtual model for a lifestyle content feed — one believable
person, the same face and body across many scenes, skin that reads as real (not "AI plastic").

**Outcome:** a repeatable pipeline that produces a consistent feed at **~$0.03–$0.04 per image**,
with a realism score of **9.3/10** on internal review. Total R&D cost to reach it: **~$10 USD**.

---

## v1 — the two-LoRA FLUX approach (and why it was abandoned)

The first system trained **two separate LoRAs** — one for identity (face), one for body —
and combined them at inference (`lucataco/flux-dev-multi-lora`, scales ~0.82 / 0.70).

It worked mechanically but failed on quality:

- **Plastic skin.** The first identity LoRA was trained on *polished* images, so it learned the
  "AI plastic" look and every test was rejected. **Lesson: the plastic look comes from the
  dataset, not the model.**
- **Identity drift.** A LoRA trained on generated faces learns "a type," not one person, so the
  face changed between shots.
- **Fixes that worked:** regenerate the dataset with a *candid/natural* technique (FLUX Kontext),
  caption only what is actually visible (no invented "visible pores"), keep `lora_rank` modest
  (more rank does not create texture that isn't in the source), and hold identity scale high
  (0.78–0.82) so the face stays the original.

Realism score after the v2 retrain: **9.3/10**. But the approach was expensive, slow, and fragile.

## v2 — the pivot to Seedream + a reference pack

The breakthrough was dropping training entirely:

- **Engine:** FLUX/multi-LoRA → **Seedream 4** (`bytedance/seedream-4`), which produces realistic
  skin out of the box.
- **Identity & body:** two trained LoRAs → a **fixed reference pack** (`image_input`, 3–4 face
  photos + one clothed full-body anchor) passed on *every* generation. Same pack = same person.
- **Cost:** ~$10/avatar + training → **~$0.03 per image, no training cost**.

## The skin-realism recipe (the hard-won part)

For the FLUX path, the production-grade recipe was a narrow band:

```text
1. Candid scene prompt (imperfect framing, real settings) — the #1 free lever
2. epiCRealism skin pass at creativity 0.15–0.22  (0.30+ repaints too much → ugly / different person)
3. Camera sensor pass at strength 0.30            (0.55 introduces a processed/HDR look)
4. Keep identity high on full-body shots (>0.75); fix proportions with framing, not by lowering identity
```

## Lessons that transfer

- Economics first: a feasibility pass on cost/model *before* committing to an engine.
- Document failures as first-class artifacts (the "what not to do" log saved real money).
- Validate cheap (one image) before paying for a batch.
- Windows-native (no WSL) for portability.
- Consent and disclosure are non-negotiable; adults only.

See [`methodology.md`](methodology.md) for the step-by-step and [`lessons-learned.md`](lessons-learned.md)
for the full list of documented mistakes.
