from pathlib import Path
from PIL import Image
import sys


def pack(source: Path, output: Path) -> None:
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    atlas = Image.new("RGBA", (640, 160), (0, 0, 0, 0))
    for row in range(2):
        for column in range(10):
            left, right = round(column * width / 10), round((column + 1) * width / 10)
            top, bottom = round(row * height / 2), round((row + 1) * height / 2)
            frame = image.crop((left, top, right, bottom))
            bounds = frame.getchannel("A").getbbox()
            if bounds is None:
                continue
            subject = frame.crop(bounds)
            subject.thumbnail((58, 76), Image.Resampling.LANCZOS)
            x = column * 64 + (64 - subject.width) // 2
            y = row * 80 + 78 - subject.height
            atlas.alpha_composite(subject, (x, y))
    atlas.save(output)


if __name__ == "__main__":
    pack(Path(sys.argv[1]), Path(sys.argv[2]))
