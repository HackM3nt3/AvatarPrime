# AvatarPrime — Metodología completa

Guía paso a paso para construir un avatar virtual de IA con identidad consistente.

---

## Fase 0 — Estrategia del personaje

Antes de generar nada, define el personaje en un **character bible** (ver `templates/character_bible_template.md`):

```text
- Nombre + trigger word único (ej: "mychar01")
- Nacionalidad, edad visual (siempre adulta)
- Rasgos faciales fijos (ojos, nariz, labios, lunar distintivo)
- Tono de piel, cabello
- Build corporal
- Estilo, nicho, ciudad base
- Disclosure de IA
```

**Regla:** el trigger debe ser único y no existir en el training del modelo base
(ej: `mychar01`, no `mychar`).

---

## Fase 1 — Generación de cara (dataset identity)

### 1.1 Elegir el modelo

```text
FLUX 1.1 Pro Ultra (raw=true) → para exploración inicial de la cara
FLUX Kontext Max              → para generar variaciones manteniendo identidad
```

El modo `raw` de FLUX Ultra produce look candid (no editorial pulido).
Kontext mantiene la identidad usando una foto de referencia.

### 1.2 Generar 12-18 fotos de cara

Variedad obligatoria:
```text
- close-up (textura facial)
- half body
- perfil estricto
- 3/4 y over-the-shoulder
- expresiones: neutra, sonrisa, risa
- distintas luces: ventana dura, suave, exterior
- distintos settings (NO todo el mismo lugar)
```

### 1.3 CRÍTICO — evitar el "look plástico"

```text
✅ Usar dataset CANDID natural (no editorial polished)
✅ Prompts con vocabulario de textura real
✅ Mencionar cámara/film específico (iPhone, Kodak Portra, Cinestill)
✅ Negaciones: NOT plastic skin, NOT airbrushed, NOT beauty filter

❌ Evitar: studio lighting, golden hour editorial, glamour, flawless skin
```

---

## Fase 2 — Captions del dataset identity

### Regla de oro: describir SOLO lo que se ve

```text
✅ Si la foto SÍ muestra poros → "visible pores on nose and cheeks"
❌ Si la foto NO muestra poros → NO escribir "visible pores"

Captions imprecisos confunden el entrenamiento.
```

### Estructura

```text
"<trigger> woman, [tipo de plano], [expresión], [ropa], [setting], [luz],
[textura real visible]"

Ejemplo:
"mychar01 woman, close-up phone portrait, visible pores on nose and cheeks,
fine skin texture, soft natural makeup, hair down, soft window light from left,
relaxed closed-mouth smile"
```

### Evitar muletillas

No repetir la misma frase en todas las captions. Describir lo específico de cada foto.

---

## Fase 3 — Entrenar LoRA identity

```yaml
trainer:              ostris/flux-dev-lora-trainer
trigger_word:         <nombre>          # ej: mychar01
steps:                1200
learning_rate:        0.0003
lora_rank:            16                # NO subir solo para "más textura"
resolution:           1024
caption_dropout_rate: 0.10
autocaption:          false             # usar captions propias
optimizer:            adamw8bit
```

**Importante:** más `lora_rank` NO crea textura que no exista en las imágenes fuente.
Si las imágenes son de baja resolución/detalle, el rank alto solo aprende el sesgo.

---

## Fase 4 — Validar LoRA identity

Generar 10 tests con prompts que fuercen variedad:
```text
- close-up textura (probar lora_scale 0.7, 0.8, 0.9 para calibrar)
- ropa de color NO presente en dataset (test de sesgo)
- "sin joyería" explícito (test de sesgo)
- setting nuevo (test de sesgo)
- full body
```

Inference recomendada:
```yaml
lora_scale:           0.85
guidance_scale:       2.8
num_inference_steps:  40
```

**Criterio:** la cara debe ser consistente + textura real + respetar el prompt
(no forzar ropa/setting del dataset).

---

## Fase 5 — Dataset cuerpo (body LoRA)

### 5.1 Origen de las fotos

```text
- Fotos del cuerpo con CONSENTIMIENTO explícito (si es persona real)
- Sin cara visible (croppeada/cubierta) para no contaminar identidad
- O fotos generadas con AI
```

### 5.2 Balance del dataset

```text
- 20-27 fotos
- Variedad de wardrobe (NO solo swimwear — agregar casual, athletic)
- Algunas con cabeza EN frame (cara oculta) → evita que aprenda "cuerpo sin cabeza"
- Variedad de ángulos (frontal, trasera, perfil)
```

### 5.3 Captions del body

```text
"<nombre>body body, [encuadre], [ropa], [pose], [proporciones visibles],
[tono de piel], [textura], [cómo se oculta la cara]"

Ejemplo:
"mychar01body body, frontal view, navy blue string bikini, plain background,
defined waist, toned abdomen, golden bronze tan, athletic build, face cropped above frame"
```

Class word recomendado: `<nombre>body body` (categoría = body).

---

## Fase 6 — Entrenar LoRA body

```yaml
trainer:              ostris/flux-dev-lora-trainer
trigger_word:         <nombre>body
steps:                1400
learning_rate:        0.0003
lora_rank:            16
resolution:           1024
caption_dropout_rate: 0.05            # bajo: pegar cuerpo al trigger
```

Destination SEPARADO del identity LoRA.

---

## Fase 7 — Combinar los 2 LoRAs

```yaml
endpoint:     lucataco/flux-dev-multi-lora
hf_loras:     [identity_weights_url, body_weights_url]
lora_scales:  [0.82, 0.70]            # identity / body — sweet spot
prompt:       "<nombre> woman <nombre>body body, [escena], [ropa], [pose],
              face visible, realistic skin texture,
              NOT plastic skin, NOT head cropped, NOT distorted anatomy"
guidance_scale:      2.8
num_inference_steps: 35
```

### Calibración de scales

```text
Cara pierde parecido?  → subir identity (0.85)
Cuerpo poco fiel?      → subir body (0.75)
Algo se degrada?       → bajar el que domina

Rango recomendado:
  identity 0.80-0.85
  body     0.50-0.75
```

---

## Fase 8 — Producción

```text
1. Reusar el script combine_multilora.ps1
2. Cambiar prompts (escena, ropa, pose) manteniendo ambos triggers
3. Mantener scales calibrados
4. Costo: ~$0.04 por foto
5. Generar lote para feed, stories, etc.
```

---

## Resumen de parámetros clave

| Parámetro | Identity | Body | Inference combinado |
|---|:---:|:---:|:---:|
| steps | 1200 | 1400 | — |
| learning_rate | 0.0003 | 0.0003 | — |
| lora_rank | 16 | 16 | — |
| caption_dropout | 0.10 | 0.05 | — |
| lora_scale | — | — | 0.82 / 0.70 |
| guidance_scale | — | — | 2.8 |
| steps inference | — | — | 35 |

---

## Errores a evitar

Ver `lessons-learned.md` para los errores documentados del caso de estudio.
