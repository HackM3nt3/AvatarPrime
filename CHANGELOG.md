# Changelog — AvatarPrime

Todas las versiones notables del framework se documentan aquí.
Formato basado en [Keep a Changelog](https://keepachangelog.com).

---

## [2.0.0] — 2026-05-30

### Pivote mayor: FLUX → Seedream 4

La v1 (2 LoRAs de FLUX) no alcanzó calidad de producción: **piel plástica** e **identidad
inconsistente** entre fotos. La v2 reemplaza todo el motor.

### Changed (cambios de fondo)
- **Motor de generación:** FLUX 1.1 / multi-LoRA → **Seedream 4** (`bytedance/seedream-4`).
  Da piel realista de fábrica (no plástica).
- **Identidad y cuerpo:** de 2 LoRAs entrenados → **pack de referencia** (`image_input`,
  1-10 fotos). Consistencia sin entrenar. Mismo pack = misma persona + mismo cuerpo.
- **Costo:** de ~$10/avatar + entrenamiento → **~$0.03 por imagen**, sin costo de training.

### Added
- `scripts/seedream_produce.ps1` — producción con Seedream + pack de identidad.
- `pack_identidad/` — el "ADN" de la modelo (fotos de referencia fijas: cara + ancla de cuerpo).
- `REGISTRO.md` + `archivo_proceso/` — registro completo del proceso y "qué NO hacer".
- `scripts/sensor_realism.py` — grano/firma de cámara opcional (Python nativo Windows).
- `examples/` — feed gym de ejemplo (10 fotos consistentes y reales).

### Deprecated (legado, no usar para producción)
- Camino FLUX: `combine_multilora.ps1`, `produce.ps1`, `pulid_produce.ps1`,
  `build_dataset.ps1`, `validate_lora.ps1`. Se conservan como referencia histórica.

### Lessons learned nuevas (2.0)
- FLUX deja "glow" plástico que no llega a foto real; Seedream/Imagen sí (bake-off documentado).
- Un LoRA entrenado sobre caras generadas = "un tipo de mujer", no UNA persona → inconsistente.
- Consistencia real = pack de referencia FIJO, no entrenar.
- Seedream filtro E005: no usar referencias reveladoras; anclar cuerpo con foto vestida.
- Piel real PERO bonita: el cliente rechaza tanto lo plástico como lo feo/envejecido.
- Economía PRIMERO (estudio de factibilidad) antes de elegir motor.
- Todo Windows-native (sin WSL) por portabilidad.

### Validado en
- Feed gym de 10 escenas: misma modelo + mismo cuerpo fit, piel real, aguanta a full-res.

---

## [1.0.0] — 2026-05-28

### Primera versión pública

AvatarPrime 1.0 es el primer release del framework para crear modelos virtuales
de IA con identidad consistente mediante un sistema de 2 LoRAs.

### Added (incluido)

**Metodología**
- Sistema de 2 LoRAs separados (identity + body) combinados en inference
- Flujo completo: character bible → datasets → entrenamiento → combinación → producción
- Estrategia de captions con textura real para evitar "look plástico AI"
- Calibración de lora_scales (sweet spot identity 0.82 / body 0.70)

**Scripts (PowerShell)**
- `generate_faces.ps1` — generación de caras con FLUX Kontext Max
- `train_lora.ps1` — entrenamiento de LoRA en Replicate (ostris trainer)
- `test_lora.ps1` — validación de un LoRA entrenado
- `combine_multilora.ps1` — combinación de 2 LoRAs en producción
- `monitor_training.ps1` — monitoreo de entrenamiento en background

**Prompts y templates**
- Templates de prompts de cara (close-up, half body, full body, perfil)
- Templates de prompts de cuerpo
- Negative prompts anti-plástico
- Template de character bible
- Reglas de captions

**Documentación**
- Metodología completa paso a paso
- Lecciones aprendidas (errores documentados)
- Caso de estudio completo (MD + HTML visual con galerías)

### Lessons learned incluidas en esta versión

- El "look plástico AI" viene del DATASET, no del modelo
- Captions deben describir SOLO lo que se ve (no inventar características)
- Separar identity y body en 2 LoRAs evita contaminación de identidad
- FLUX Kontext preserva identidad mejor que text-to-image puro para datasets
- Más lora_rank NO crea textura que no existe en las imágenes fuente
- El atajo img2img NO sirve para "cuerpo exacto + cara nueva"
- Tests baratos antes de producción grande ahorran dinero

### Validado en

- Caso de estudio real: avatar "a demo persona" (a major city lifestyle)
- 2 LoRAs entrenados y combinados con éxito
- Score de realismo: 9.3/10
- Costo total del caso: ~$10.6 USD

### Notas de seguridad

- Los scripts leen el API token de variable de entorno (nunca hardcoded)
- `.gitignore` excluye tokens, datos privados y fotos de cuerpo real
- Datos corporales de personas reales requieren consentimiento explícito

---

## Roadmap (futuras versiones)

### [2.1.0] — planeado
- Selección automática del mejor pack de referencia (cull por face embedding)
- Lotes temáticos predefinidos (lifestyle, gym, viajes, moda)
- QA de consistencia con face embeddings (InsightFace) entre lotes

### [3.0.0] — planeado
- Pipeline de video (image-to-video con Kling/Runway) manteniendo el pack
- Soporte multi-personaje (portafolio de avatares)
