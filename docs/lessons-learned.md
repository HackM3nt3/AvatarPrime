# AvatarPrime — Lessons learned

Real mistakes made during the framework's development, and how to avoid them.
Each one cost time or money — documented so you don't repeat them.

---

## Lesson 1 — The "plastic look" comes from the DATASET, not the model

**What happened:** the first identity LoRA (v1) produced plastic "AI portrait" skin. Attempts to fix it with prompts and lora_scale failed.

**Root cause:** the dataset had editorial/polished photos. The LoRA learned that style as part of the identity.

**Fix:** regenerate the dataset with natural CANDID photos (FLUX Kontext) and captions that describe real texture. v2 scored 9.3/10.

**Rule:** LoRA quality = dataset quality. Garbage in = garbage out.

---

## Lesson 2 — Captions must describe ONLY what's visible

**What happened:** captions were written "from memory" using a mapping, without looking at each image. Result: crossed captions (a red dress labeled "black lingerie", a bikini as "maxi dress").

**Root cause:** trusting memory/mapping instead of looking at each photo.

**Fix:** open EACH image and write the caption based on what's visible.

**Rule:** a crossed caption teaches false associations and contaminates the LoRA. Never invent; never assume. Look at the image.

---

## Lesson 3 — Split identity and body into two LoRAs

**What happened:** the first dataset mixed 15 face photos + 22 faceless ones under the same trigger. That contaminates: the LoRA learns the trigger also means "cropped face / headless".

**Fix:** two separate LoRAs (identity with its trigger, body with another), combined at inference with multi-LoRA.

**Rule:** don't mix photos with and without a face under the same trigger.

---

## Lesson 4 — The img2img shortcut does NOT work for "exact body + new face"

**What happened:** an attempt to put the avatar's face onto real body photos with img2img. The body stayed but the face didn't appear.

**Root cause:** img2img respects the original image. If the photo hides the face (cup, hair, crop), img2img keeps it hidden. And raising strength to force the face changes the body (no longer "exact").

**Fix:** body LoRA + multi-lora generates body + face from scratch.

**Rule:** img2img gives "exact body" XOR "new face", not both. For both → two combined LoRAs.

---

## Lesson 5 — More lora_rank does NOT create nonexistent texture

**What happened:** raising lora_rank to 24 was proposed "to learn more texture/pores".

**Root cause:** if the source images are low resolution/detail, there's no microtexture to learn. A high rank only learns the BIAS better.

**Fix:** rank 16 + good-resolution images with real visible texture.

**Rule:** rank amplifies what exists in the dataset; it doesn't invent detail.

---

## Lesson 6 — Cheap tests before large production

**What happened:** several times, money was saved by running one test before a batch. Examples: an img2img test ($0.08) confirmed the shortcut didn't work before processing 22 photos; a one-photo test before generating full sets.

**Rule:** always run one validation test ($0.04–0.14) before spending on large production ($2–4 training, large batches).

---

## Lesson 7 — Verify before asserting (models/versions)

**What happened:** certain model resolutions/behaviors were assumed incorrectly. Checking the real schema corrected it.

**Rule:** verify the real schema of each model/endpoint (its inputs, limits) before building scripts. Don't assume.

---

## Lesson 8 — Calibrate lora_scales, don't assume

**What happened:** when combining two LoRAs, the right balance wasn't obvious.

**Fix:** try three scale combinations and pick the sweet spot. For this case: identity 0.82 / body 0.70.

**Rule:** start with a moderate body scale (0.50–0.70), not high, so it doesn't impose its bias (bikini / white background) over the prompt.

---

## Lesson 9 — Dataset resolution matters for microdetail

**What happened:** FLUX Kontext generates at ~1MP (880x1184), lower than FLUX Ultra (4MP). To learn pores, dataset resolution matters.

**Trade-off:** Kontext gives better identity but lower resolution. You can upscale (clarity-upscaler) but it adds a processed touch.

**Rule:** a conscious decision between identity (Kontext) and resolution (upscale). For many cases, Kontext without upscaling already shows enough pores.

---

## Lesson 10 — Real body data = consent + care

**What happened:** the avatar's body was based on a real person's photos.

**Rules:**
- Explicit (written) consent before use
- Adult person
- No identifiable face in the photos
- Exclude nude photos that violate platform policies
- Never use for impersonation

---

## Summary: the correct order

```text
1. Character bible
2. CANDID identity dataset (not polished) + captions of what's visible
3. Train identity, validate with cheap tests
4. Body dataset (consented, faceless, balanced) + precise captions
5. Train body separately
6. Combine with multi-lora, calibrate scales
7. Production
```

Each step with a test/review before spending on the next.
