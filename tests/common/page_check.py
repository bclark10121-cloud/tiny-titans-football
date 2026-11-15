#!/usr/bin/env python3
"""Shared game page check (G1.4, G1.8, G7.4). Pulled into a game at tests/common/page_check.py.
    python3 tests/common/page_check.py <game page url> [shots folder]
Checks every link answers, the screenshots load and the version line under the buttons reads exactly
'Version <version>. Release notes · Backlog · Source on GitHub' (G1.8), with links that match the APK and release notes. Prints each check and ends with errors [] when all pass.
"""
import asyncio, os, re, sys
from playwright.async_api import async_playwright
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from webkit import CHROME, ARGS

async def check_page(url, shots=None):
    checks, errs = [], []
    def check(ok, what):
        checks.append(("ok  " if ok else "FAIL") + "  " + what)
        if not ok: errs.append("check failed: " + what)
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=CHROME, args=ARGS)
        pg = await b.new_page(viewport={"width": 1280, "height": 900})
        pg.on("pageerror", lambda e: errs.append("page: " + str(e)))
        await pg.goto(url); await pg.wait_for_timeout(1500)
        if shots:
            os.makedirs(shots, exist_ok=True); await pg.screenshot(path=os.path.join(shots, "00_game_page.png"), full_page=True)
        for u in await pg.evaluate("Array.from(document.querySelectorAll('a[href]')).map(a => a.href)"):
            r = await pg.request.fetch(u, method="HEAD") if u.endswith(".apk") else await pg.request.get(u)
            if r.status == 429:   # GitHub asks us to slow down: wait and try once more
                await pg.wait_for_timeout(5000); r = await pg.request.get(u)
            check(r.status == 200, "link %s answers %d" % (u.replace(url, ""), r.status))
        imgs = await pg.evaluate("Array.from(document.images).map(i => [i.getAttribute('src'), i.naturalWidth])")
        check(len(imgs) >= 3 and all(w > 0 for _, w in imgs), "three or more screenshots load %s" % imgs)
        info = await pg.evaluate("""() => {
            const apk = document.querySelector('a[href$=".apk"]'); const cta = apk ? apk.parentElement : null;
            const line = cta ? cta.nextElementSibling : null;
            const links = line ? Array.from(line.querySelectorAll('a')).map(a => [a.innerText.trim(), a.getAttribute('href')]) : [];
            return {line: line ? line.innerText.trim() : '', links, apk: apk ? apk.getAttribute('href') : ''}; }""")
        m = re.fullmatch(r"Version (\d+(?:\.\d+)+)\. Release notes · Backlog · Source on GitHub", info["line"])
        ver = m.group(1) if m else ""
        check(bool(m), "the line under the buttons reads 'Version <version>. Release notes · Backlog · Source on GitHub' with nothing else (G1.8): '%s'" % info["line"])
        names = [n for n, _ in info["links"]]; hrefs = dict(info["links"])
        check(names == ["Release notes", "Backlog", "Source on GitHub"], "the line links Release notes, Backlog and Source on GitHub in that order %s" % names)
        check(bool(ver) and hrefs.get("Release notes", "").endswith("release-notes/v%s.md" % ver), "Release notes links to release-notes/v%s.md (%s)" % (ver, hrefs.get("Release notes")))
        check(hrefs.get("Backlog", "").endswith("/BACKLOG.md") and "github.com" in hrefs.get("Source on GitHub", ""), "Backlog and Source on GitHub link to the repo")
        check(bool(ver) and ("v%s.apk" % ver) in info["apk"], "version %s matches the APK link %s" % (ver, info["apk"]))
        await b.close()
    return checks, errs

if __name__ == "__main__":
    c, e = asyncio.run(check_page(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None))
    print("\n".join(c)); print("errors", e)
