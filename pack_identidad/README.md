# pack_identidad — your identity reference pack

Put the reference photos that define your virtual model here. They are passed on
**every** generation, which is what keeps the face and body consistent.

Recommended pack:

```
face1_closeup.jpg   → clear, well-lit close-up of the face
face2_best.jpg      → a second face angle / expression
face3_laugh.jpg     → a third face variation
body_anchor.jpg     → one FULL-BODY photo, CLOTHED (anchors body type)
```

## Rules (read before adding anything)

- **Use your own assets only**, or media you have **explicit, documented consent** to use.
- **Adults only.** Never use images of minors.
- Anchor the body with a **clothed** photo + a text description of the body type
  (revealing references trip Seedream's content filter).
- These files are **git-ignored on purpose** — real people's photos must never be
  committed to a public repository.

This folder ships empty (only this README). The framework reads whatever `.jpg`/`.png`
files you drop in here.
