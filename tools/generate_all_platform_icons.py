import os
import shutil
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

def generate_icons():
    # Source image: Option 1 Flat 2D Ledger Icon
    raw_source = r"C:\Users\nguye\.gemini\antigravity\brain\b40330e3-cc31-488a-ba25-db7746ec90d4\so_thu_chi_flat_icon_ledger_1793949404920.jpg"
    
    if not os.path.exists(raw_source):
        raise FileNotFoundError(f"Source icon not found at {raw_source}")

    raw_im = Image.open(raw_source)
    arr = np.array(raw_im)

    # 1. Detect and crop badge boundaries
    # Outer canvas is white (R > 240, G > 240, B > 240)
    is_badge = ~((arr[:, :, 0] > 240) & (arr[:, :, 1] > 240) & (arr[:, :, 2] > 240))
    rows = np.any(is_badge, axis=1)
    cols = np.any(is_badge, axis=0)
    ymin, ymax = np.where(rows)[0][[0, -1]]
    xmin, xmax = np.where(cols)[0][[0, -1]]

    badge_crop = raw_im.crop((xmin, ymin, xmax + 1, ymax + 1)).resize((1024, 1024), Image.Resampling.LANCZOS)

    # 2. Synthesize seamless vertical background gradient for full-bleed 1024x1024
    # Matches top emerald (#1A826C) to bottom forest emerald (#063A33)
    grad = np.zeros((1024, 1024, 3), dtype=np.uint8)
    for y in range(1024):
        factor = y / 1023.0
        r = int(26 * (1 - factor) + 6 * factor)
        g = int(130 * (1 - factor) + 58 * factor)
        b = int(108 * (1 - factor) + 51 * factor)
        grad[y, :] = [r, g, b]

    grad_im = Image.fromarray(grad, 'RGB')

    # Detect white corners in badge_crop to blend seamlessly
    badge_arr = np.array(badge_crop)
    is_corner_white = (badge_arr[:, :, 0] > 235) & (badge_arr[:, :, 1] > 235) & (badge_arr[:, :, 2] > 235)
    mask_arr = np.where(is_corner_white, 0, 255).astype(np.uint8)
    mask_im = Image.fromarray(mask_arr, 'L').filter(ImageFilter.GaussianBlur(1.5))

    # Full-bleed 1024x1024 RGB master (no alpha, no white corners)
    master_full_bleed = grad_im.copy()
    master_full_bleed.paste(badge_crop, (0, 0), mask=mask_im)

    os.makedirs("assets/icon", exist_ok=True)
    master_full_bleed.save("assets/icon/app_icon_raw.png", "PNG", optimize=True)
    print("Saved assets/icon/app_icon_raw.png (1024x1024 Full Bleed RGB)")

    # 3. Generate Apple 23.5% Continuous Squircle Cutout (with smooth transparent corners)
    scale = 4
    w, h = 1024, 1024
    sq_mask = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(sq_mask)
    radius = int(w * scale * 0.235)
    inset = 2 * scale
    draw.rounded_rectangle([inset, inset, w * scale - inset, h * scale - inset], radius=radius, fill=255)
    sq_mask = sq_mask.resize((w, h), Image.Resampling.LANCZOS)

    squircle_1024 = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    squircle_1024.paste(master_full_bleed, (0, 0), mask=sq_mask)
    squircle_1024.save("assets/icon/app_icon_1024.png", "PNG", optimize=True)

    squircle_512 = squircle_1024.resize((512, 512), Image.Resampling.LANCZOS)
    squircle_512.save("assets/icon/app_icon.png", "PNG", optimize=True)
    print("Saved master assets: assets/icon/app_icon_1024.png & app_icon.png")

    # 4. Generate all iOS icons (Apple HIG requires 24-bit RGB without alpha)
    ios_master = master_full_bleed.convert("RGB")
    ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(ios_dir, exist_ok=True)
    
    ios_sizes = {
        "Icon-App-20x20@1x.png": (20, 20),
        "Icon-App-20x20@2x.png": (40, 40),
        "Icon-App-20x20@3x.png": (60, 60),
        "Icon-App-29x29@1x.png": (29, 29),
        "Icon-App-29x29@2x.png": (58, 58),
        "Icon-App-29x29@3x.png": (87, 87),
        "Icon-App-40x40@1x.png": (40, 40),
        "Icon-App-40x40@2x.png": (80, 80),
        "Icon-App-40x40@3x.png": (120, 120),
        "Icon-App-60x60@2x.png": (120, 120),
        "Icon-App-60x60@3x.png": (180, 180),
        "Icon-App-76x76@1x.png": (76, 76),
        "Icon-App-76x76@2x.png": (152, 152),
        "Icon-App-83.5x83.5@2x.png": (167, 167),
        "Icon-App-1024x1024@1x.png": (1024, 1024),
    }

    for filename, size in ios_sizes.items():
        out_path = os.path.join(ios_dir, filename)
        resized = ios_master.resize(size, Image.Resampling.LANCZOS)
        resized.save(out_path, "PNG", optimize=True)
        print(f"Generated iOS icon: {filename} ({size[0]}x{size[1]})")

    # 5. Generate Android Adaptive Icons (API 26+)
    # Foreground canvas is 108dp. Safe zone is inner 72dp (ratio ~ 0.72)
    # The flat 2D emblem sits centered in safe zone.
    safe_ratio = 0.72
    fg_canvas = 1024
    emblem_size = int(fg_canvas * safe_ratio)
    scaled_emblem = squircle_1024.resize((emblem_size, emblem_size), Image.Resampling.LANCZOS)

    android_fg_master = Image.new("RGBA", (fg_canvas, fg_canvas), (0, 0, 0, 0))
    offset = (fg_canvas - emblem_size) // 2
    android_fg_master.paste(scaled_emblem, (offset, offset), mask=scaled_emblem)

    android_fg_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png": (108, 108),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png": (162, 162),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png": (216, 216),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png": (324, 324),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png": (432, 432),
    }

    for path, size in android_fg_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res_fg = android_fg_master.resize(size, Image.Resampling.LANCZOS)
        res_fg.save(path, "PNG", optimize=True)
        print(f"Generated Android adaptive foreground: {path} ({size[0]}x{size[1]})")

    # 6. Generate Android Legacy Icons (ic_launcher.png)
    android_legacy_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
    }

    for path, size in android_legacy_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res_legacy = squircle_1024.resize(size, Image.Resampling.LANCZOS)
        res_legacy.save(path, "PNG", optimize=True)
        print(f"Generated Android legacy icon: {path} ({size[0]}x{size[1]})")

    # 7. Generate Android Round Icons (ic_launcher_round.png)
    round_mask = Image.new("L", (1024 * scale, 1024 * scale), 0)
    round_draw = ImageDraw.Draw(round_mask)
    round_inset = 2 * scale
    round_draw.ellipse([round_inset, round_inset, 1024 * scale - round_inset, 1024 * scale - round_inset], fill=255)
    round_mask = round_mask.resize((1024, 1024), Image.Resampling.LANCZOS)

    round_composite = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    round_composite.paste(master_full_bleed, (0, 0), mask=round_mask)

    android_round_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png": (192, 192),
    }

    for path, size in android_round_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res_round = round_composite.resize(size, Image.Resampling.LANCZOS)
        res_round.save(path, "PNG", optimize=True)
        print(f"Generated Android round icon: {path} ({size[0]}x{size[1]})")

    # 8. Create Android Adaptive Icon Background Color Resource
    # Emerald green base matching the master background
    colors_xml_path = "android/app/src/main/res/values/colors.xml"
    os.makedirs(os.path.dirname(colors_xml_path), exist_ok=True)
    with open(colors_xml_path, "w", encoding="utf-8") as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0B5D4D</color>
</resources>
''')
    print("Updated android/app/src/main/res/values/colors.xml with #0B5D4D")

    print("\nAll 2D Flat iOS, Android, and in-app icons generated successfully!")

if __name__ == "__main__":
    generate_icons()
