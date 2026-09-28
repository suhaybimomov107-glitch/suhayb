# -*- coding: utf-8 -*-
import base64
from pathlib import Path

root = Path(__file__).resolve().parent
img_dir = root / "images"
css = (root / "css" / "style.css").read_text(encoding="utf-8")
js = (root / "js" / "app.js").read_text(encoding="utf-8")
html = (root / "template.html").read_text(encoding="utf-8").replace("__SITE_URL__", "")


def data_uri(path: Path) -> str:
    data = path.read_bytes()
    if data.startswith(b"\xff\xd8"):
        mime = "image/jpeg"
    elif data.startswith(b"\x89PNG"):
        mime = "image/png"
    elif data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        mime = "image/webp"
    else:
        mime = "image/jpeg" if path.suffix.lower() in {".jpg", ".jpeg"} else "image/png"
    return "data:%s;base64,%s" % (mime, base64.b64encode(data).decode("ascii"))


uris = {p.name: data_uri(p) for p in img_dir.iterdir() if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}}

css = css.replace('url("../images/shuhrah.png")', 'url("%s")' % uris["shuhrah.png"])
for name, uri in uris.items():
    js = js.replace("images/%s" % name, uri)
    html = html.replace("images/%s" % name, uri)

html = html.replace('  <link rel="stylesheet" href="css/style.css" />', "  <style>\n%s\n  </style>" % css)
html = html.replace('  <script src="js/app.js"></script>', "  <script>\n%s\n  </script>" % js)

out = root / "index.html"
out.write_text(html, encoding="utf-8")
print("Wrote", out.name, out.stat().st_size, "bytes")
