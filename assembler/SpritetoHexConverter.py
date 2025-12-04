import os
from glob import glob
from PIL import Image

# Folder containing your sprites
IMG_DIR = r"C:/Users/IT Admin/Documents/3710_SpritetoHexConverter/Sprites/Little Man Walking/"

# Pattern to match your input files, e.g. LittleMan_0.png, LittleMan_1.png, ...
for img_path in sorted(glob(os.path.join(IMG_DIR, "LittleMan_*.png"))):
    # Get base name without extension, e.g. "LittleMan_0"
    base = os.path.splitext(os.path.basename(img_path))[0]

    # Build hex filename, e.g. "LittleMan_0_Hex.hex"
    hex_path = os.path.join(IMG_DIR, f"{base}_Hex.hex")

    img = Image.open(img_path).convert("RGB")

    with open(hex_path, "w") as f:
        for y in range(img.height):
            for x in range(img.width):
                r, g, b = img.getpixel((x, y))
                # Convert to RGB565
                rgb565 = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)
                f.write(f"{rgb565:04X}\n")

    print(f"Wrote {hex_path}")
