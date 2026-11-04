import os
from PIL import Image, ImageDraw

def create_masked_app_icon():
    raw_path = "assets/icon/app_icon_raw.png"
    im = Image.open(raw_path).convert("RGBA")
    w, h = im.size

    # Create anti-aliased squircle rounded rectangle mask
    # We draw at 4x resolution for perfect anti-aliasing
    scale = 4
    mask = Image.new("L", (w * scale, h * scale), 0)
    draw = ImageDraw.Draw(mask)
    
    # 22% corner radius for continuous squircle look
    radius = int(w * scale * 0.22)
    # Give a tiny 4px inset from border so edges don't clip
    inset = 8 * scale
    draw.rounded_rectangle(
        [inset, inset, w * scale - inset, h * scale - inset],
        radius=radius,
        fill=255
    )
    
    mask = mask.resize((w, h), Image.Resampling.LANCZOS)
    
    # Apply mask
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask=mask)
    
    # Save master 1024x1024 icon
    master_path = "assets/icon/app_icon_1024.png"
    out.save(master_path, "PNG", optimize=True)
    print(f"Saved master icon: {master_path}")

    # Generate all Android mipmap densities
    android_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
        "assets/icon/app_icon.png": (512, 512),
    }

    for path, size in android_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res = out.resize(size, Image.Resampling.LANCZOS)
        res.save(path, "PNG", optimize=True)
        print(f"Generated {path} ({size[0]}x{size[1]})")

    # Also generate circular icons for launchers that request round icons
    circle_mask = Image.new("L", (w * scale, h * scale), 0)
    circle_draw = ImageDraw.Draw(circle_mask)
    circle_draw.ellipse([inset, inset, w * scale - inset, h * scale - inset], fill=255)
    circle_mask = circle_mask.resize((w, h), Image.Resampling.LANCZOS)

    round_out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    round_out.paste(im, (0, 0), mask=circle_mask)

    round_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png": (192, 192),
    }

    for path, size in round_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        res = round_out.resize(size, Image.Resampling.LANCZOS)
        res.save(path, "PNG", optimize=True)
        print(f"Generated round icon: {path} ({size[0]}x{size[1]})")

    print("Successfully generated all app icon assets!")

if __name__ == "__main__":
    create_masked_app_icon()

