# -*- coding: utf-8 -*-
"""抠黑转透明 + 缩放到目标尺寸，生成游戏 UI 素材（assets/ui/*.png）"""
import os
from PIL import Image

BASE = r"C:\Users\Administrator\Doubao\chats\2026-09-12\new-chat\match3"
RAW = os.path.join(BASE, "assets_raw", "ui")
OUT = os.path.join(BASE, "assets", "ui")
os.makedirs(OUT, exist_ok=True)

# (源文件, 输出名, 目标尺寸)
JOBS = [
    ("ui_header_raw.jpeg", "ui_header.png", (1152, 230)),
    ("ui_result_raw.jpeg", "ui_result.png", (500, 470)),
    ("ui_pause_raw.jpeg", "ui_pause.png", (420, 400)),
    ("ui_btn_primary_raw.jpeg", "ui_btn_primary.png", (760, 120)),
    ("ui_btn_secondary_raw.jpeg", "ui_btn_secondary.png", (760, 116)),
    ("ui_board_raw.jpeg", "ui_board.png", (660, 660)),
]


def key_out(img):
    """近黑色像素转透明，边缘做半透明过渡"""
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            mx = max(r, g, b)
            if mx < 26:
                px[x, y] = (r, g, b, 0)
            elif mx < 42:
                alpha = int(255 * (mx - 26) / 16.0)
                px[x, y] = (r, g, b, min(a, alpha))
    return rgba


for src, name, size in JOBS:
    p = os.path.join(RAW, src)
    im = Image.open(p).convert("RGB")
    # 先抠黑（原始分辨率），再缩放，保证边缘平滑
    im = key_out(im)
    im = im.resize(size, Image.LANCZOS)
    out = os.path.join(OUT, name)
    im.save(out)
    print(name, im.size, os.path.getsize(out))
print("DONE")
