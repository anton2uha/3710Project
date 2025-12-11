import os
from glob import glob
from PIL import Image

# Folder containing your sprites
IMG_DIR = r"C:/Users/Test/Documents/3710_SpritetoHexConverter/Sprites/"

for img_path in sorted(glob(os.path.join(IMG_DIR, "b*.png"))):
    base = os.path.splitext(os.path.basename(img_path))[0]
    hex_path = os.path.join(IMG_DIR, f"{base}.hex")
    img = Image.open(img_path).convert("RGB")

    with open(hex_path, "w") as f:
        for y in range(img.height):
            for x in range(img.width):
                r, g, b = img.getpixel((x, y))
                # Convert to RGB565
                rgb565 = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
                f.write(f"{rgb565:04X}\n")

    print(f"Wrote {hex_path}")
