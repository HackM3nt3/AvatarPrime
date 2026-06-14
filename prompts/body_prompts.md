# AvatarPrime — Templates de prompts de cuerpo

Para el LoRA body y para producción combinada.
Reemplaza `<body_trigger>` (ej: "mychar01body body") y `<face_trigger>`.

## Estructura de caption para dataset body

```text
<body_trigger>, [encuadre/angulo], [ropa especifica], [pose], [setting],
[proporciones visibles], [tono piel], [textura], [como se oculta la cara]
```

Ejemplo:
```text
mychar01body body, frontal view, navy blue string bikini, plain background,
defined waist, toned abdomen, natural hip curve, golden bronze tan, athletic
build, real skin texture, face cropped above frame
```

## Vocabulario de cuerpo y textura (usar SOLO lo que se ve — Lección 2)

⚠️ El cuerpo es REAL (modelo consentida). NO inventar defectos que ella no tiene
(belly roll, cellulite, stretch marks si no están en sus fotos) — eso contamina el
LoRA y pelea contra la identidad real. El tell NO es el cuerpo: es que la generación
ALISA la piel real. La regla es PRESERVAR la textura que el dataset ya tiene.

```text
# proporciones reales de la modelo (describir las que se ven, sin exagerar)
defined waist · natural hip curve · toned abdomen · athletic legs

# TEXTURA REAL a preservar (esto es lo que la generación pierde -> el tell real)
real skin texture · visible skin pores · natural skin tone variation
skin specular highlights from hard light · fine body hair · subtle tan lines
soft skin folds where the body bends · veins visible on hands · realistic skin sheen
sand on skin (si aplica a la foto) · natural moles where visible
```

Regla (Lección 2): mirar la foto real y nombrar SU textura concreta. No inventar
imperfecciones; tampoco omitir la textura real. La piel lisa sin textura = tell #1.

## Cómo describir cara oculta (importante)
```text
face not visible · face cropped above frame · face hidden by hair · face hidden
by phone · face turned away · head in frame face not clear
```

## Producción combinada (2 LoRAs)

Incluir AMBOS triggers:
```text
<face_trigger> <body_trigger>, [escena completa con captura imperfecta], face visible,
real skin texture, visible skin pores, natural skin tone variation, skin specular
highlights, fine body hair, hard directional light, candid not posed, real phone
camera photo, NOT plastic skin, NOT airbrushed skin, NOT smoothed skin, NOT beauty
filter, NOT studio glamour lighting, NOT posed for camera, NOT head cropped, NOT
distorted anatomy
```

Tras generar, SIEMPRE pasar por `scripts/sensor_realism.py --strength 0.6` para
agregar ruido de sensor, grano, aberración cromática y compresión JPEG real.
El prompt arregla el cuerpo/escena (tells #1,#3,#4,#5); el script arregla la
textura de sensor (tell #2 y el "demasiado limpio" digital).

Ejemplos de escenas:

⚠️ TELLS #3-#5: luz demasiado favorecedora, composición demasiado buena, escena
montada. Las fotos reales tienen luz fea, encuadre torcido y fondo desordenado.

```text
# ANTES (montado — se ve AI aunque la piel sea perfecta)
... sitting at an outdoor cafe wearing a yellow summer dress, holding coffee, warm light
... walking on a beach at sunset wearing a bikini, full body, golden hour

# DESPUÉS (captura imperfecta — se ve real)
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

Principio: encuadre torcido, luz dura/mezclada, fondo con desorden real, pose
a media-acción (no posando), ropa ordinaria. La perfección de la escena delata.

## Balance del dataset body (recomendado)
```text
- Variedad de wardrobe (NO solo swimwear): bikini, casual, athletic, dress
- Algunas con cabeza EN frame (cara oculta) → evita "cuerpo sin cabeza"
- Variedad de angulos: frontal, trasera, perfil
- Fondos variados si es posible (no solo estudio blanco)
```
