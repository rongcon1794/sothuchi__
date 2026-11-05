import os
from PIL import Image, ImageDraw

def generate_icons():
    raw_path = "assets/icon/app_icon_raw.png"
    if not os.path.exists(raw_path):
        raise FileNotFoundError(f"Source raw icon not found at {raw_path}")

    raw_im = Image.open(raw_path)
    
    # Crop the exact squircle badge (896x896) excluding outer gray mockup margins
    crop_badge = raw_im.crop((66, 10, 962, 906)) # 896 x 896
    
    # 1. Generate master clean 1024x1024 squircle cutout (transparent background outside squircle)
    scale = 4
    w, h = 896, 896
    mask = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(mask)
    radius = int(w * scale * 0.295) # 29.5% corner curvature perfectly matches the 3D badge
    inset = 2 * scale
    draw.rounded_rectangle([inset, inset, w * scale - inset, h * scale - inset], radius=radius, fill=255)
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)

    badge_cutout = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    badge_cutout.paste(crop_badge.convert("RGBA"), (0, 0), mask=mask)
    
    badge_1024 = badge_cutout.resize((1024, 1024), Image.Resampling.LANCZOS)
    badge_1024.save("assets/icon/app_icon_1024.png", "PNG", optimize=True)
    badge_512 = badge_cutout.resize((512, 512), Image.Resampling.LANCZOS)
    badge_512.save("assets/icon/app_icon.png", "PNG", optimize=True)
    print("Saved master assets: assets/icon/app_icon_1024.png & app_icon.png")

    # 2. Master Full-Bleed Opaque RGB Icon for iOS (Apple HIG requires 24-bit RGB with no alpha channel)
    # Background color matches the Forest Jade base: #004D40 -> (0, 77, 64)
    ios_bg = Image.new("RGB", (1024, 1024), (0, 77, 64))
    ios_master = ios_bg.copy()
    ios_master.paste(badge_1024, (0, 0), mask=badge_1024)

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
    # The badge sits on full canvas with background #004D40
    android_fg_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher_foreground.png": (108, 108),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher_foreground.png": (162, 162),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher_foreground.png": (216, 216),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_foreground.png": (324, 324),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png": (432, 432),
    }

    for path, size in android_fg_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res_fg = badge_1024.resize(size, Image.Resampling.LANCZOS)
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
    # Circular mask for round launchers
    round_mask = Image.new("L", (1024 * scale, 1024 * scale), 0)
    round_draw = ImageDraw.Draw(round_mask)
    round_inset = 2 * scale
    round_draw.ellipse([round_inset, round_inset, 1024 * scale - round_inset, 1024 * scale - round_inset], fill=255)
    round_mask = round_mask.resize((1024, 1024), Image.Resampling.LANCZOS)

    # Master round icon: composite badge onto circular mask with background
    round_composite = ios_master.copy().convert("RGBA")
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
    colors_xml_path = "android/app/src/main/res/values/colors.xml"
    os.makedirs(os.path.dirname(colors_xml_path), exist_ok=True)
    with open(colors_xml_path, "w", encoding="utf-8") as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#004D40</color>
</resources>
''')
    print("Created android/app/src/main/res/values/colors.xml")

    anydpi_dir = "android/app/src/main/res/mipmap-anydpi-v26"
    os.makedirs(anydpi_dir, exist_ok=True)
    
    adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
    with open(os.path.join(anydpi_dir, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    with open(os.path.join(anydpi_dir, "ic_launcher_round.xml"), "w", encoding="utf-8") as f:
        f.write(adaptive_xml)
    print("Created android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml and ic_launcher_round.xml")

    # Clean up any temporary test files
    for tmp in ["tools/test_badge_mask.png", "tools/test_cutout.png", "tools/test_full_bleed.png", 
                "tools/test_badge_1024.png", "tools/test_ios_icon_1024.png", "tools/test_fg_safe.png",
                "tools/test_pixel_circle_preview.png", "tools/test_pixel_circle_full.png", "tools/test_samsung_squircle_full.png"]:
        if os.path.exists(tmp):
            os.remove(tmp)

    print("\nAll iOS and Android app launcher icons generated successfully!")

if __name__ == "__main__":
    generate_icons()

