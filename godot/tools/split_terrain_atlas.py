"""Split the authored 2x2 terrain atlas into scenario texture resources."""
from pathlib import Path
from PIL import Image
import sys

source = Image.open(sys.argv[1]).convert("RGB")
target = Path(sys.argv[2])
target.mkdir(parents=True, exist_ok=True)
labels = sys.argv[3:7] if len(sys.argv) >= 7 else ["mars_ground", "mars_path", "mars_ice", "mars_basalt"]
names = tuple((label, index % 2, index // 2) for index, label in enumerate(labels))
width, height = source.width // 2, source.height // 2
for name, column, row in names:
    source.crop((column * width, row * height, (column + 1) * width, (row + 1) * height)).save(target / f"{name}.png")
