"""Build a seamless 1024px terrain tile with less visible repetition."""
from pathlib import Path
from PIL import Image
import cv2
import numpy as np
import sys


for value in sys.argv[1:]:
    path = Path(value)
    base = np.asarray(Image.open(path).convert("RGB").resize((256, 256), Image.Resampling.LANCZOS))
    tiled = np.tile(base, (4, 4, 1))
    size = tiled.shape[0]
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float32)
    # Periodic coordinate warping preserves seamless outer edges while ensuring
    # repeated motifs no longer line up every four world cells.
    dx = 13.0 * np.sin(2.0 * np.pi * yy / size) + 7.0 * np.sin(6.0 * np.pi * yy / size)
    dy = 11.0 * np.sin(2.0 * np.pi * xx / size) + 5.0 * np.cos(4.0 * np.pi * xx / size)
    warped = cv2.remap(tiled, (xx + dx) % size, (yy + dy) % size, cv2.INTER_CUBIC, borderMode=cv2.BORDER_WRAP)
    tone = 1.0 + .035 * np.sin(2.0 * np.pi * xx / size) * np.sin(2.0 * np.pi * yy / size)
    warped = np.clip(warped.astype(np.float32) * tone[..., None], 0, 255).astype(np.uint8)
    Image.fromarray(warped, "RGB").save(path, optimize=True)
