# REGISTRO DE PROCESO — Realismo e Identidad de Avatar (modelo de referencia)

Archivo de TODO el proceso, incluyendo lo defectuoso, para saber **qué NO se debe hacer**.
Fecha: 2026-05-29. Orden cronológico = orden de aprendizaje.

> **Las 3 reglas de oro que salieron de todo esto:**
> 1. **Piel:** epiCRealism `creativity 0.15` + negativos anti-fea. `0.30+` = repinta de más → fea y cambia de persona.
> 2. **Identidad consistente:** el LoRA viejo (entrenado con caras de FLUX) da "un tipo", no UNA persona → hay que RE-ENTRENAR con dataset consistente.
> 3. **Sensor:** suave `0.30`. `0.55` mete look procesado.

---

## 00_punto_partida_LoRA_viejo
Las imágenes originales del LoRA de identidad + cuerpo. **El problema inicial:** se ven 95% reales pero un ojo entrenado las detecta (piel demasiado perfecta) y, peor, **la cara cambia entre fotos** (no es la misma mujer).
- **Lección:** un LoRA entrenado sobre caras GENERADAS por FLUX nunca da identidad consistente. Garbage in, garbage out (su propia Lección 1).

## 01_sensor_v1
Primer script de degradación de sensor (grano, ruido, aberración, JPEG).
- **Resultado:** ayuda (95→98%) pero TÍMIDO. La piel sigue lisa por debajo.
- **Lección:** la degradación agrega defectos encima, NO crea textura que no existe. No basta sola.

## 02_sensor_v2
Sensor mejorado (ISP de celular: contraste local + curva de tono + rotura de textura + halación).
- **Resultado:** mejor look de cámara. Pero a `--strength 0.55` mete look procesado/HDR.
- **Lección:** el sensor v2 sirve, pero a fuerza baja (0.30). Fuerte = se nota procesado.

## 03_generacion_prompt_corregido
Generar de nuevo con prompt CANDID (escena imperfecta) en vez de "postal montada" + clarity-upscaler (juggernaut).
- **Resultado:** el prompt corregido fue el lever #1 (gratis). `fresh_*_raw` ya saltó solo con eso.
- **DEFECTO:** `playa_*` y clarity con **juggernaut** beautifica la piel (modelo equivocado).
- **Lección:** la escena candid importa muchísimo. Para piel, juggernaut NO (embellece); usar epiCRealism.

## 04_calibracion_piel_epicrealism  ← LECCIONES CLAVE
Barrido de `creativity` de epiCRealism sobre la misma cara (`skin_raw.jpg`).
- `skin_FINAL.jpg` / `skin_clarity.png` = **creativity 0.5 → DEFECTUOSA**: cambió de persona (más vieja), demasiadas pecas.
- `skin_c38r65_*` = **0.38 → DEFECTUOSA**: artefactos ("errores").
- `skin_c36r70_*` = 0.36 → marginal: demasiado enrojecimiento/manchado.
- `skin_c33r70_*` = 0.33 → equilibrio inicial (aceptable).
- `skin_c30r70_*` = 0.30 → bueno.
- **Lección:** `creativity 0.30+` empieza a alejarse de la modelo y a afear. El techo seguro es bajo. (Después se confirmó 0.15 como ideal — ver carpeta 08.)

## 05_sensor_suave
Sensor a 0.30 vs 0.45 sobre la imagen buena.
- **Lección:** 0.30 conserva la piel y solo agrega grano de cámara. Confirmó bajar el sensor.

## 06_cuerpo_entero_identidad  ← LECCIÓN CLAVE
Cuerpo entero: arreglar "cabezona" sin romper identidad.
- `calle2_*` = fix con identidad **0.75** + encuadre full body + 9:16 + piel suave. Proporción OK e identidad OK.
- **DEFECTO (en carpeta 09):** bajar identidad a 0.62 arregla la cabezona PERO rompe el parecido.
- **Face-swap (cdingram):** FALLA en caras giradas/candid (salida vacía). Descartado.
- **Lección:** NO bajar identidad <0.75; la proporción se arregla con encuadre, no aplastando identidad. El pase de piel en cuerpo entero debe ser MUY suave (0.20) para no repintar la cara pequeña.

## 07_pulid_consistencia
PuLID-FLUX anclado a una cara para forzar identidad consistente entre escenas.
- `pulid_cafe/calle` + `production_pulid/*` = MISMA mujer en escenas distintas ✓ (consistencia lograda).
- **DEFECTO:** PuLID **driftea fuera de la modelo original** (no es la modelo de referencia exacta), **re-alisa la piel**, y el **color de ojos varía**.
- **Lección:** PuLID da consistencia entre imágenes, pero anclado a un derivado se va de la modelo. Sirve para CONSTRUIR un dataset consistente (ver 10), no como producto final directo.

## 08_receta_final_piel_GANADORA  ← LA RECETA
`orig_c15_FINAL.jpg` = modelo ORIGINAL + epiCRealism **0.15** + negativos anti-fea + sensor 0.30.
- **Resultado:** misma modelo original, sigue BONITA, piel real (poros finos, textura). NI plástica NI fea NI otra persona.
- `orig_c22` = un toque más de textura (0.22). `orig_sensoronly` = solo sensor (cero repintado).
- **Lección:** la banda correcta es **0.15–0.22 con negativos anti-fea**. Esta es la receta de piel de producción.

## 09_produccion_v1
Primer set de producción automático (`produce.ps1`).
- `selfie_FINAL` bueno. **DEFECTO:** `calle_FINAL` = cuerpo entero con identidad rota (0.62) → no parece la misma.
- **Lección:** el full-body de v1 rompía identidad; corregido en la receta 06/08.

## 10_dataset_reentrenamiento
Dataset CONSISTENTE generado con PuLID (id_weight 1.4) anclado a la cara original, + piel 0.15, para RE-ENTRENAR el LoRA de identidad.
- `id_01`..`id_16` = consistentes pero **frontales** (poca variedad de pose — defecto de id_weight alto).
- `id_17`..`id_22` (en curso) = pose forzada (perfil, 3/4, risa) a id_weight bajo para dar variedad.
- `_contact_sheet.jpg` = vista de curación.
- **Lección:** id_weight alto = consistencia pero mata la variedad de pose. Para dataset, mezclar tomas consistentes + tomas con pose forzada (id_weight bajo).

---

## 11_validacion_LoRA_nuevo_GANADOR  ← RESULTADO FINAL ✅
6 escenas diversas (selfie, café, parque, calle, cuarto, risa) con el **LoRA RE-ENTRENADO** + piel 0.15 + sensor 0.30.
- **Resultado:** la MISMA modelo en las 6, consistente, bonita, piel real, proporción correcta. Problema de raíz resuelto.
- `_VALIDACION.jpg` = contact sheet de las 6.
- **Lección:** re-entrenar con dataset CONSISTENTE (anclado a una cara) convierte "un tipo de mujer" en UNA persona. Eso + receta de piel 0.15 + sensor 0.30 = producción.

## 12_dataset_final_curado_15
Las 15 imágenes con las que se re-entrenó (9 frontales con variación + 6 con pose/gesto). Anclado a `identity-closeup.jpg` original.

---

## Resumen: el pipeline de producción correcto
```
1. Identidad consistente  → RE-ENTRENAR LoRA con dataset consistente (carpeta 10)
2. Generar escena         → LoRA identidad (0.78-0.82) + LoRA cuerpo + prompt candid
3. Piel real pero bonita  → epiCRealism creativity 0.15 + negativos anti-fea
4. Cámara                 → sensor_realism.py --strength 0.30
```
