#!/usr/bin/env python3
"""
AvatarPrime - sensor_realism.py  (v2)
Degrada una imagen "perfecta" (FLUX/SDXL) hasta que parezca capturada y
procesada por un celular real. La v1 solo agregaba ruido encima; la v2 ataca
la firma estructural que delata el AI:

  - ISP de celular: contraste local + curva de tono (HDR computacional)
  - rotura de textura de piel (alta frecuencia) -> mata la lisura FLUX
  - sobre-enfoque con halos (sharpening del procesador)
  - halacion / bloom calido en los brillos (lente real)
  - aberracion cromatica, vineta (lente)
  - ruido de sensor signal-dependent + grano (sensor)
  - recompresion JPEG 4:2:0 (archivo real)

USO (Windows, Python nativo):
  python sensor_realism.py entrada.jpg salida.jpg
  python sensor_realism.py entrada.jpg salida.jpg --strength 0.75
  python sensor_realism.py in.jpg out.jpg --strength 0.7 --downscale 1280 --jpeg 86

--strength 0..1 intensidad global. 0.65 punto de partida; 0.8+ para "foto de
celular en mala luz". Subir si todavia se ve limpia.
"""
import argparse
import io
import numpy as np
from PIL import Image, ImageFilter


# ---------- helpers ----------
def _blur(arr: np.ndarray, radius: float) -> np.ndarray:
    im = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(radius))).astype(np.float32)


def _rng(seed):
    return np.random.default_rng(seed)


def downscale(img: Image.Image, target_long: int) -> Image.Image:
    """Fotos reales se comparten a baja resolucion. Bajar resolucion mata el
    look 'demasiado nitido' y obliga a interpolacion como una camara real."""
    w, h = img.size
    long_side = max(w, h)
    if target_long <= 0 or long_side <= target_long:
        return img
    scale = target_long / long_side
    new = (max(1, round(w * scale)), max(1, round(h * scale)))
    return img.resize(new, Image.LANCZOS)


# ---------- ISP de celular (la firma mas importante) ----------
def tone_curve(arr: np.ndarray, s: float) -> np.ndarray:
    """El procesador de un celular LEVANTA sombras y ROLEA brillos (HDR). Eso
    da bajo contraste global + look 'computacional'. FLUX tiene rango limpio
    con negros puros y blancos limpios -> tell inmediato."""
    x = arr / 255.0
    # levantar sombras (HDR shadow lift)
    lift = 0.06 * s
    x = x * (1 - lift) + lift  # piso de negro mas alto
    # rolloff de brillos (compresion suave del highlight)
    knee = 0.78
    over = np.clip(x - knee, 0, None)
    x = np.where(x > knee, knee + over * (1 - 0.45 * s), x)
    return np.clip(x, 0, 1) * 255.0


def local_contrast(arr: np.ndarray, s: float) -> np.ndarray:
    """'Clarity' / micro-contraste del HDR de celular: unsharp de radio grande.
    Combinado con la curva de tono da el look computacional caracteristico."""
    radius = max(8.0, min(arr.shape[:2]) / 40.0)
    base = _blur(arr, radius)
    amount = 0.35 * s
    return arr + (arr - base) * amount


def texture_break(arr: np.ndarray, s: float) -> np.ndarray:
    """Mata la lisura de FLUX amplificando la alta frecuencia existente. La piel
    real tiene microtextura caotica; FLUX la promedia. Esto la realza."""
    detail = arr - _blur(arr, 2.0)
    amount = 0.45 * s
    return arr + detail * amount


def oversharpen(arr: np.ndarray, s: float) -> np.ndarray:
    """El sharpening del procesador del celular deja halos finos en los bordes.
    Su ausencia es un tell: las fotos reales de celular estan sobre-enfocadas."""
    base = _blur(arr, 1.1)
    amount = 0.55 * s
    return arr + (arr - base) * amount


# ---------- lente ----------
def halation(arr: np.ndarray, s: float) -> np.ndarray:
    """Glow calido alrededor de los brillos (luz que rebota en el sensor/lente).
    Toda foto real lo tiene; los renders no."""
    lum = arr @ np.array([0.299, 0.587, 0.114])
    mask = np.clip((lum - 200) / 55.0, 0, 1)  # solo brillos
    glow = _blur(mask[..., None] * arr, 6.0)
    tint = np.array([1.0, 0.78, 0.62])  # calido naranja-rojo
    add = glow * tint * (0.18 * s)
    # screen blend suave
    return 255.0 - (255.0 - arr) * (255.0 - add) / 255.0


def chromatic_aberration(arr: np.ndarray, s: float) -> np.ndarray:
    """Lentes reales desvian los canales RGB hacia los bordes. FLUX no."""
    h, w, _ = arr.shape
    max_shift = 2.0 * s
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    dx = (xx - cx) / cx
    dy = (yy - cy) / cy
    out = arr.copy()
    for ch, sign in ((0, 1.0), (2, -1.0)):
        sx = np.clip(xx + sign * dx * max_shift, 0, w - 1)
        sy = np.clip(yy + sign * dy * max_shift, 0, h - 1)
        x0 = np.floor(sx).astype(int); y0 = np.floor(sy).astype(int)
        x1 = np.clip(x0 + 1, 0, w - 1); y1 = np.clip(y0 + 1, 0, h - 1)
        fx = sx - x0; fy = sy - y0
        c = arr[..., ch]
        top = c[y0, x0] * (1 - fx) + c[y0, x1] * fx
        bot = c[y1, x0] * (1 - fx) + c[y1, x1] * fx
        out[..., ch] = top * (1 - fy) + bot * fy
    return out


def vignette(arr: np.ndarray, s: float) -> np.ndarray:
    h, w, _ = arr.shape
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    cy, cx = (h - 1) / 2.0, (w - 1) / 2.0
    r = np.sqrt(((xx - cx) / cx) ** 2 + ((yy - cy) / cy) ** 2)
    r = r / r.max()
    strength = 0.20 * s
    return arr * (1.0 - strength * (r ** 2.2))[..., None]


# ---------- color y sensor ----------
def color_cast(arr: np.ndarray, s: float, rng) -> np.ndarray:
    """Balance de blancos imperfecto + menos saturacion que el render clinico."""
    wb = 1.0 + (rng.uniform(-0.045, 0.045, 3) * s)
    arr = arr * wb
    gray = arr @ np.array([0.299, 0.587, 0.114])
    desat = 0.07 * s
    return arr * (1 - desat) + gray[..., None] * desat


def sensor_noise(arr: np.ndarray, s: float, rng) -> np.ndarray:
    """Ruido de sensor: luminancia fina + croma blotchy, mas en sombras."""
    h, w, _ = arr.shape
    lum = arr @ np.array([0.299, 0.587, 0.114])
    shadow_w = 1.0 - (lum / 255.0) * 0.6
    luma = rng.normal(0, 5.5 * s, (h, w)) * shadow_w
    arr = arr + luma[..., None]
    small = (max(1, h // 4), max(1, w // 4))
    chroma_small = rng.normal(0, 3.5 * s, (small[0], small[1], 3))
    chroma = np.asarray(
        Image.fromarray(np.clip(chroma_small + 128, 0, 255).astype(np.uint8))
        .resize((w, h), Image.BILINEAR)
    ).astype(np.float32) - 128
    return arr + chroma * shadow_w[..., None]


def film_grain(arr: np.ndarray, s: float, rng) -> np.ndarray:
    grain = rng.normal(0, 3.2 * s, arr.shape[:2])
    return arr + grain[..., None]


def jpeg_recompress(img: Image.Image, quality: int, passes: int = 2) -> Image.Image:
    """JPEG 4:2:0 como celular; doble pase hornea los artefactos de bloque."""
    out = img
    for i in range(max(1, passes)):
        q = quality + (2 if i == 0 else 0)  # primer pase un poco mas alto
        buf = io.BytesIO()
        out.convert("RGB").save(buf, format="JPEG", quality=q, subsampling=2)
        buf.seek(0)
        out = Image.open(buf).convert("RGB")
    return out


def process(in_path, out_path, strength, downscale_long, jpeg_q, seed):
    img = Image.open(in_path).convert("RGB")
    img = downscale(img, downscale_long)
    rng = _rng(seed)

    arr = np.asarray(img).astype(np.float32)
    # orden = pipeline de captura real
    arr = local_contrast(arr, strength)   # ISP
    arr = tone_curve(arr, strength)        # ISP
    arr = color_cast(arr, strength, rng)   # WB
    arr = texture_break(arr, strength)     # anti-lisura FLUX
    arr = oversharpen(arr, strength)       # ISP sharpening
    arr = halation(arr, strength)          # lente
    arr = chromatic_aberration(arr, strength)  # lente
    arr = vignette(arr, strength)          # lente
    arr = sensor_noise(arr, strength, rng) # sensor
    arr = film_grain(arr, strength, rng)   # sensor
    arr = np.clip(arr, 0, 255).astype(np.uint8)

    out = jpeg_recompress(Image.fromarray(arr), jpeg_q, passes=2)
    out.save(out_path, format="JPEG", quality=jpeg_q, subsampling=2)
    print(f"OK -> {out_path}  ({out.size[0]}x{out.size[1]}, strength={strength}, jpeg={jpeg_q})")


def main():
    ap = argparse.ArgumentParser(description="Degradacion de sensor v2 (realismo de celular)")
    ap.add_argument("input")
    ap.add_argument("output")
    ap.add_argument("--strength", type=float, default=0.65, help="Intensidad 0..1 (default 0.65)")
    ap.add_argument("--downscale", type=int, default=1440, help="Lado largo px; 0=no bajar (default 1440)")
    ap.add_argument("--jpeg", type=int, default=88, help="Calidad JPEG final (default 88)")
    ap.add_argument("--seed", type=int, default=None, help="Semilla de ruido")
    args = ap.parse_args()
    process(args.input, args.output, args.strength, args.downscale, args.jpeg, args.seed)


if __name__ == "__main__":
    main()
