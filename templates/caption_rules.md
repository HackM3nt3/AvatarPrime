# Reglas de Captions — AvatarPrime

Las captions son tan importantes como las imágenes. Estas reglas evitan los
errores más comunes que arruinan un LoRA.

---

## Regla 1 — Describir SOLO lo que se ve

```text
✅ Si la foto SÍ muestra poros → "visible pores"
❌ Si la foto NO muestra poros → NO escribir "visible pores"

NUNCA escribir de memoria o de un mapping. ABRIR cada imagen y describir.
Un caption cruzado (vestido rojo etiquetado como lencería) contamina el LoRA.
```

## Regla 2 — Empezar con el trigger

```text
Identity: "<trigger> woman, ..."
Body:     "<trigger>body body, ..."   (class word "body")
```

## Regla 3 — Describir lo VARIABLE, no la identidad fija

```text
El LoRA aprende lo que NO cambia entre fotos (la identidad).
Las captions describen lo que SÍ cambia: ropa, pose, setting, luz.

NO describir rasgos faciales fijos en cada caption (el LoRA ya los aprende).
SÍ describir: vestuario, ángulo, expresión, ambiente.
```

## Regla 4 — Evitar muletillas

```text
NO repetir la misma frase larga en las 13 captions.
Describir lo específico de cada foto.

Malo:  "raw unretouched attractive natural woman" en las 13
Bueno: cada caption describe su escena particular
```

## Regla 5 — Vocabulario de textura (donde aplique)

```text
visible pores on nose and cheeks · fine skin texture · subtle under-eye texture
slight uneven skin tone · natural lip texture · stray hairs · small skin marks
```

## Regla 6 — Para body: describir proporciones

```text
defined waist · natural hip curve · toned abdomen · athletic legs · rounded glutes
+ indicar cómo se oculta la cara: "face cropped above frame", "face hidden by hair"
```

---

## Ejemplo correcto (identity)
```text
mychar01 woman, close-up phone portrait, visible pores on nose and cheeks,
fine skin texture, soft minimal makeup, hair down with loose strands, soft
window light from left, relaxed closed-mouth smile
```

## Ejemplo correcto (body)
```text
mychar01body body, frontal view, navy blue string bikini, plain background,
defined waist, toned abdomen, golden bronze tan, athletic build, face cropped above frame
```

## Ejemplo INCORRECTO (caption cruzado — lo que arruina el LoRA)
```text
[foto muestra vestido rojo]  →  caption dice "black lace lingerie"   ❌❌❌
```
