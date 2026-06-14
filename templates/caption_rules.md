# Caption Rules — AvatarPrime

Captions are as important as the images. These rules avoid the most common mistakes
that ruin a LoRA.

---

## Rule 1 — Describe ONLY what's visible

```text
✅ If the photo DOES show pores → "visible pores"
❌ If the photo does NOT show pores → do NOT write "visible pores"

NEVER caption from memory or from a mapping. OPEN each image and describe it.
A crossed caption (a red dress labeled as lingerie) contaminates the LoRA.
```

## Rule 2 — Start with the trigger

```text
Identity: "<trigger> woman, ..."
Body:     "<trigger>body body, ..."   (class word "body")
```

## Rule 3 — Describe the VARIABLE, not the fixed identity

```text
The LoRA learns what does NOT change between photos (the identity).
Captions describe what DOES change: clothing, pose, setting, light.

Do NOT describe fixed facial traits in every caption (the LoRA already learns them).
DO describe: wardrobe, angle, expression, environment.
```

## Rule 4 — Avoid filler

```text
Don't repeat the same long phrase across all 13 captions.
Describe what's specific to each photo.

Bad:  "raw unretouched attractive natural woman" in all 13
Good: each caption describes its particular scene
```

## Rule 5 — Texture vocabulary (where it applies)

```text
visible pores on nose and cheeks · fine skin texture · subtle under-eye texture
slight uneven skin tone · natural lip texture · stray hairs · small skin marks
```

## Rule 6 — For body: describe proportions

```text
defined waist · natural hip curve · toned abdomen · athletic legs · rounded glutes
+ indicate how the face is hidden: "face cropped above frame", "face hidden by hair"
```

---

## Correct example (identity)
```text
mychar01 woman, close-up phone portrait, visible pores on nose and cheeks,
fine skin texture, soft minimal makeup, hair down with loose strands, soft
window light from left, relaxed closed-mouth smile
```

## Correct example (body)
```text
mychar01body body, frontal view, navy blue string bikini, plain background,
defined waist, toned abdomen, golden bronze tan, athletic build, face cropped above frame
```

## INCORRECT example (crossed caption — what ruins the LoRA)
```text
[photo shows a red dress]  →  caption says "black lace lingerie"   ❌❌❌
```
