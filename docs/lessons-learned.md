# AvatarPrime — Lecciones aprendidas

Errores reales cometidos durante el desarrollo del framework y cómo evitarlos.
Cada uno costó tiempo o dinero — documentados para que no los repitas.

---

## Lección 1 — El "look plástico" viene del DATASET, no del modelo

**Qué pasó:** el primer LoRA de identidad (v1) producía piel plástica de
"AI portrait". Se intentó arreglar con prompts y lora_scale sin éxito.

**Causa raíz:** el dataset tenía fotos con look editorial/polished. El LoRA
aprendió ese estilo como parte de la identidad.

**Solución:** regenerar el dataset con fotos CANDID naturales (FLUX Kontext)
y captions que describen textura real. El v2 salió 9.3/10.

**Regla:** la calidad del LoRA = calidad del dataset. Garbage in = garbage out.

---

## Lección 2 — Captions deben describir SOLO lo que se ve

**Qué pasó:** se escribieron captions "de memoria" usando un mapping, sin mirar
cada imagen. Resultado: captions cruzados (vestido rojo etiquetado como
"lencería negra", bikini como "maxi dress").

**Causa raíz:** confiar en la memoria/mapping en vez de mirar cada foto.

**Solución:** abrir CADA imagen y escribir el caption basado en lo que se ve.

**Regla:** un caption cruzado enseña asociaciones falsas y contamina el LoRA.
Nunca inventar; nunca asumir. Mirar la imagen.

---

## Lección 3 — Separar identity y body en 2 LoRAs

**Qué pasó:** el primer dataset mezclaba 15 fotos de cara + 22 sin cara bajo
el mismo trigger. Eso contamina: el LoRA aprende que el trigger significa
también "cara croppeada / sin cabeza".

**Solución:** 2 LoRAs separados (identity con su trigger, body con otro),
combinados en inference con multi-LoRA.

**Regla:** no mezcles fotos con cara y sin cara bajo el mismo trigger.

---

## Lección 4 — El atajo img2img NO sirve para "cuerpo exacto + cara nueva"

**Qué pasó:** se intentó poner la cara del avatar sobre fotos del cuerpo real
con img2img. El cuerpo se mantenía pero la cara no aparecía.

**Causa raíz:** img2img respeta la imagen original. Si la foto oculta la cara
(vaso, pelo, crop), el img2img la mantiene oculta. Y subir el strength para
forzar la cara cambia el cuerpo (ya no es "exacto").

**Solución:** body LoRA + multi-lora genera cuerpo + cara desde cero.

**Regla:** img2img da "cuerpo exacto" XOR "cara nueva", no ambos.
Para ambos → 2 LoRAs combinados.

---

## Lección 5 — Más lora_rank NO crea textura inexistente

**Qué pasó:** se propuso subir lora_rank a 24 "para aprender más textura/poros".

**Causa raíz:** si las imágenes fuente son de baja resolución/detalle, no hay
microtextura que aprender. El rank alto solo aprende mejor el SESGO.

**Solución:** rank 16 + imágenes de buena resolución con textura real visible.

**Regla:** el rank amplifica lo que existe en el dataset, no inventa detalle.

---

## Lección 6 — Tests baratos antes de producción grande

**Qué pasó:** varias veces se evitó gastar mal haciendo 1 test antes de un lote.
Ejemplos: test img2img ($0.08) confirmó que el atajo no servía antes de
procesar 22 fotos; test de 1 foto antes de generar sets completos.

**Regla:** siempre 1 test de validación ($0.04-0.14) antes de gastar en
producción grande ($2-4 training, lotes grandes).

---

## Lección 7 — Verificar antes de afirmar (modelos/versiones)

**Qué pasó:** se asumió incorrectamente que ciertas resoluciones/comportamientos
de los modelos eran de cierta forma. La verificación del schema real corrigió.

**Regla:** verificar el schema real de cada modelo/endpoint (sus inputs, límites)
antes de construir scripts. No asumir.

---

## Lección 8 — Calibrar lora_scales, no asumir

**Qué pasó:** al combinar 2 LoRAs, el balance correcto no era obvio.

**Solución:** probar 3 combinaciones de scales y elegir el sweet spot.
Para este caso: identity 0.82 / body 0.70.

**Regla:** empezar con body scale moderado (0.50-0.70), no alto, para que
no imponga su sesgo (bikini/fondo blanco) sobre el prompt.

---

## Lección 9 — Resolución del dataset importa para microdetalle

**Qué pasó:** FLUX Kontext genera a ~1MP (880x1184), menor que FLUX Ultra (4MP).
Para aprender poros, la resolución del dataset importa.

**Trade-off:** Kontext da mejor identidad pero menor resolución. Se puede
upscalear (clarity-upscaler) pero agrega un toque procesado.

**Regla:** decisión consciente entre identidad (Kontext) y resolución (upscale).
Para muchos casos, Kontext sin upscale ya muestra poros suficientes.

---

## Lección 10 — Datos corporales reales = consentimiento + cuidado

**Qué pasó:** el cuerpo del avatar se basó en fotos reales de una persona.

**Reglas:**
- Consentimiento explícito (escrito) antes de usar
- Persona adulta
- Sin cara identificable en las fotos
- Excluir fotos con desnudez que violen políticas de plataforma
- No usar para suplantación

---

## Resumen: el orden correcto

```text
1. Character bible
2. Dataset identity CANDID (no polished) + captions de lo que se ve
3. Entrenar identity, validar con tests baratos
4. Dataset body (consentido, sin cara, balanceado) + captions precisos
5. Entrenar body separado
6. Combinar con multi-lora, calibrar scales
7. Producción
```

Cada paso con test/revisión antes de gastar en el siguiente.
