from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ICON_ROOT = ROOT / "图标"
NEW_ICONS = ICON_ROOT / "Finish"
ASSET_ROOT = ROOT / "assets" / "brand"

ICON_NAMES = {
    "nav_home.png": "首页.png",
    "nav_calendar.png": "日历.png",
    "nav_countdown.png": "倒计时.png",
    "nav_ai.png": "AI对话.png",
    "nav_settings.png": "设置.png",
    "assistant_avatar_1.png": "AI助手默认头像1.png",
    "assistant_avatar_2.png": "AI助手默认头像2.png",
    "app_icon.png": "APP图标.png",
}

ANDROID_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def resize(source: Path, destination: Path, size: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as image:
        image = image.convert("RGB")
        image.resize((size, size), Image.Resampling.LANCZOS).save(
            destination,
            format="PNG",
            optimize=True,
        )


def main() -> None:
    for variant, source_dir in (("new", NEW_ICONS), ("classic", ICON_ROOT)):
        for asset_name, source_name in ICON_NAMES.items():
            size = 1024 if asset_name == "app_icon.png" else 512
            resize(source_dir / source_name, ASSET_ROOT / variant / asset_name, size)

    app_icon = ASSET_ROOT / "new" / "app_icon.png"
    android_res = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in ANDROID_SIZES.items():
        resize(app_icon, android_res / folder / "ic_launcher.png", size)

    with Image.open(app_icon) as image:
        image = image.convert("RGB")
        image.save(
            ROOT / "windows" / "runner" / "resources" / "app_icon.ico",
            format="ICO",
            sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
        )


if __name__ == "__main__":
    main()
