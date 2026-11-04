import os
import sys
from PIL import Image

SIZES = {
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
    "assets/icon/app_icon.png": (512, 512),
}

def generate_icons(source_path: str):
    if not os.path.exists(source_path):
        print(f"Error: Source image not found at {source_path}")
        sys.exit(1)

    img = Image.open(source_path).convert("RGBA")
    print(f"Loaded source image {source_path} ({img.size[0]}x{img.size[1]})")

    for dest_path, size in SIZES.items():
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        resized = img.resize(size, Image.Resampling.LANCZOS)
        resized.save(dest_path, "PNG", optimize=True)
        print(f"Generated {dest_path} ({size[0]}x{size[1]})")

    print("All app icons successfully generated!")

if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else "assets/icon/app_icon_1024.png"
    generate_icons(src)
