#!/usr/bin/env python3
# Search the Patch.gg asset library and fetch files. No login needed.
#   python3 tools/common/patch_assets.py search music "calm lofi"       lists CC0 hits with size and length
#   python3 tools/common/patch_assets.py search sprite "shell"
#   python3 tools/common/patch_assets.py get "<asset id>" out_file        downloads the first audio or PNG file of an asset
# After fetching: re-encode music with ffmpeg (-c:a libvorbis -q:a 2.5), check pictures by eye and add each asset to CREDITS.md.
import json, sys, urllib.parse, urllib.request
API = "https://patch.gg/api/v1/assets/"
def get(u):
    with urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": "curl/8"}), timeout=60) as r:
        return r.read()
def urls(o, out):
    if isinstance(o, dict):
        for v in o.values():
            if isinstance(v, str) and v.startswith("http") and v.lower().split("?")[0].endswith((".ogg", ".mp3", ".wav", ".png")) and "thumbnail" not in v and "/levels/" not in v:
                out.append(v)
            else:
                urls(v, out)
    elif isinstance(o, list):
        for v in o:
            urls(v, out)
    return out
if len(sys.argv) >= 4 and sys.argv[1] == "search":
    d = json.loads(get(API + "search?q=%s&type=%s&limit=30" % (urllib.parse.quote(sys.argv[3]), sys.argv[2])))
    for h in d.get("hits", []):
        f = h.get("fit") or {}
        print("%s | %s | %s | %s MB | %ss" % (h["id"], h.get("title"), h.get("license"), f.get("mb"), int(f.get("duration_s") or 0)))
elif len(sys.argv) >= 4 and sys.argv[1] == "get":
    a = json.loads(get(API + urllib.parse.quote(sys.argv[2], safe="")))
    u = urls(a, [])
    open(sys.argv[3], "wb").write(get(u[0]))
    print("saved", sys.argv[3]); print("credit:", a.get("credit"))
else:
    print(__doc__ or "see the comments at the top of this file")
