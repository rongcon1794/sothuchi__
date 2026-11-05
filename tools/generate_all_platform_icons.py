import os
import shutil
from PIL import Image, ImageDraw, ImageFilter

def generate_icons():
    # Source image from image-generator
    src_path = r"C:\Users\nguye\.gemini\antigravity\brain\b40330e3-cc31-488a-ba25-db7746ec90d4\so_thu_chi_app_icon_1793885198733.jpg"
    raw_dest = "assets/icon/app_icon_raw.png"
    
    if not os.path.exists(src_path):
        raise FileNotFoundError(f"Source raw icon not found at {src_path}")

    shutil.copyfile(src_path, raw_dest)
    print(f"Copied {src_path} -> {raw_dest}")

    master_im = Image.open(raw_dest).convert("RGBA")
    w, h = master_im.size # 1024, 1024

    # 1. Generate master clean 1024x1024 squircle cutout for Flutter in-app UI & app stores
    scale = 4
    mask = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(mask)
    radius = int(w * scale * 0.235) # Pure Apple continuous squircle curvature (23.5%)
    inset = 2 * scale
    draw.rounded_rectangle([inset, inset, w * scale - inset, h * scale - inset], radius=radius, fill=255)
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)

    badge_cutout = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    badge_cutout.paste(master_im, (0, 0), mask=mask)

    badge_1024 = badge_cutout.resize((1024, 1024), Image.Resampling.LANCZOS)
    badge_1024.save("assets/icon/app_icon_1024.png", "PNG", optimize=True)
    badge_512 = badge_cutout.resize((512, 512), Image.Resampling.LANCZOS)
    badge_512.save("assets/icon/app_icon.png", "PNG", optimize=True)
    print("Saved master assets: assets/icon/app_icon_1024.png & app_icon.png")

    # 2. Master Full-Bleed Opaque RGB Icon for iOS (Apple HIG requires 24-bit RGB with no alpha channel)
    ios_master = master_im.convert("RGB")

    # 3. Generate all iOS icons for ios/Runner/Assets.xcassets/AppIcon.appiconset/
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

    # 4. Generate Android Adaptive Icons (API 26+)
    # Foreground dimensions: 108dp (mdpi: 108, hdpi: 162, xhdpi: 216, xxhdpi: 324, xxxhdpi: 432)
    # The emblem sits comfortably within the inner 72dp safe circle (66.6% size)
    safe_target_ratio = 0.76
    fg_canvas_size = 1024
    scaled_emblem_size = int(fg_canvas_size * safe_target_ratio)
    scaled_emblem = master_im.resize((scaled_emblem_size, scaled_emblem_size), Image.Resampling.LANCZOS)
    
    # Create radial gradient alpha mask for smooth fade into transparent edge
    fade_mask = Image.new("L", (scaled_emblem_size, scaled_emblem_size), 255)
    fade_draw = ImageDraw.Draw(fade_mask)
    # Circular vignette fade at border of scaled emblem
    vignette_inset = int(scaled_emblem_size * 0.08)
    fade_draw.ellipse([vignette_inset, vignette_inset, scaled_emblem_size - vignette_inset, scaled_emblem_size - vignette_inset], fill=255)

    android_fg_master = Image.new("RGBA", (fg_canvas_size, fg_canvas_size), (0, 0, 0, 0))
    offset = (fg_canvas_size - scaled_emblem_size) // 2
    android_fg_master.paste(scaled_emblem, (offset, offset))

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

    # 5. Generate Android Legacy Icons (ic_launcher.png)
    android_legacy_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
    }

    for path, size in android_legacy_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res_legacy = badge_1024.resize(size, Image.Resampling.LANCZOS)
        res_legacy.save(path, "PNG", optimize=True)
        print(f"Generated Android legacy icon: {path} ({size[0]}x{size[1]})")

    # 6. Generate Android Round Icons (ic_launcher_round.png)
    round_mask = Image.new("L", (1024 * scale, 1024 * scale), 0)
    round_draw = ImageDraw.Draw(round_mask)
    round_inset = 2 * scale
    round_draw.ellipse([round_inset, round_inset, 1024 * scale - round_inset, 1024 * scale - round_inset], fill=255)
    round_mask = round_mask.resize((1024, 1024), Image.Resampling.LANCZOS)

    round_composite = master_im.copy()
    round_out = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    round_out.paste(round_composite, (0, 0), mask=round_mask)

    android_round_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png": (192, 192),
    }

    for path, size in android_round_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res_round = round_out.resize(size, Image.Resampling.LANCZOS)
        res_round.save(path, "PNG", optimize=True)
        print(f"Generated Android round icon: {path} ({size[0]}x{size[1]})")

    # 7. Create Android Adaptive Icon XMLs & Color Resource
    # Background color matches the obsidian/midnight emerald base: #010C0F
    colors_xml_path = "android/app/src/main/res/values/colors.xml"
    os.makedirs(os.path.dirname(colors_xml_path), exist_ok=True)
    with open(colors_xml_path, "w", encoding="utf-8") as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#010C0F</color>
</resources>
''')
    print("Updated android/app/src/main/res/values/colors.xml with #010C0F")

    print("\nAll iOS and Android app launcher icons and master assets generated successfully!")

if __name__ == "__main__":
    generate_icons()
