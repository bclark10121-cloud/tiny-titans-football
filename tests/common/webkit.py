#!/usr/bin/env python3
"""Shared browser test helpers (G7.3, G7.6). Pulled into a game at tests/common/webkit.py. Never edit it in a game (G10.3).

    import sys, os; sys.path.insert(0, os.path.join(os.path.dirname(__file__), "common"))
    from webkit import Run, serve
    async with Run("lofi", shots="/tmp/shots") as r:          # state name the game passes to test_bridge.gd
        await r.open("http://127.0.0.1:8793/index.html?test")
        s = await r.wait_phase([0], 90)                     # phases are the game's own numbers
        await r.key("Enter"); await r.cmd("end_match"); await r.shot("01_title")
    print(r.report())                                       # prints checks, notes and errors []

The game publishes window.<name> with at least a "phase" field (test_bridge.gd). A failed check or a page error
lands in r.errs, so a test passes only when it prints errors [].
"""
import asyncio, contextlib, os, subprocess, sys, time
from playwright.async_api import async_playwright

CHROME = os.environ.get("CHROME", "/usr/bin/google-chrome")
ARGS = ["--no-sandbox", "--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--autoplay-policy=no-user-gesture-required"]

@contextlib.contextmanager
def serve(folder, port=8793):
    """Serves a folder on 127.0.0.1 for the length of the block."""
    srv = subprocess.Popen([sys.executable, "-m", "http.server", str(port), "--bind", "127.0.0.1"], cwd=folder, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1)
    try: yield "http://127.0.0.1:%d/" % port
    finally: srv.kill()

class Run:
    def __init__(self, state_name, shots, width=1280, height=720):
        self.name = state_name; self.shots = shots; self.size = (width, height)
        self.errs, self.notes, self.checks = [], [], []
        os.makedirs(shots, exist_ok=True)
    async def __aenter__(self):
        self._p = await async_playwright().start()
        self.browser = await self._p.chromium.launch(executable_path=CHROME, args=ARGS)
        self.ctx = await self.browser.new_context(viewport={"width": self.size[0], "height": self.size[1]}, has_touch=True)
        self.page = await self.ctx.new_page()
        self.page.on("pageerror", lambda e: self.errs.append("page: " + str(e)))
        self.page.on("console", lambda m: self.errs.append("console: " + m.text) if m.type == "error" else None)
        return self
    async def __aexit__(self, *a):
        await self.browser.close(); await self._p.stop()
    async def open(self, url): await self.page.goto(url)
    async def state(self): return await self.page.evaluate("window.%s || null" % self.name)
    async def wait_phase(self, phases, secs=60):
        t = time.time()
        while time.time() - t < secs:
            s = await self.state()
            if s and s.get("phase") in phases: return s
            await self.page.wait_for_timeout(120)
        s = await self.state(); self.errs.append("timeout waiting for phase %s, got %s" % (phases, s)); return s or {}
    async def wait_for(self, fn, secs, what):
        t = time.time()
        while time.time() - t < secs:
            s = await self.state()
            if s and fn(s): return s
            await self.page.wait_for_timeout(120)
        self.notes.append("did not see: " + what); return await self.state() or {}
    async def wait_saved(self, texts, secs=150, db="/userfs"):
        """Waits until one file in the browser's IndexedDB copy of user:// contains every text in texts (a string or a
        list). Godot syncs saves over many frames, and headless Chrome draws only 1 or 2 frames a second, so a test
        must wait before a reload. Returns the seconds it took, or -1 and an error."""
        texts = [texts] if isinstance(texts, str) else list(texts)
        js = """async ([db, texts]) => { const d = await new Promise((res, rej) => { const r = indexedDB.open(db); r.onsuccess = () => res(r.result); r.onerror = rej; });
          let hit = false; for (const st of d.objectStoreNames) { const os = d.transaction(st, 'readonly').objectStore(st);
            const all = await new Promise(res => { const r = os.getAll(); r.onsuccess = () => res(r.result); });
            for (const v of all) if (v && v.contents) { const t = new TextDecoder().decode(v.contents); if (texts.every(x => t.includes(x))) hit = true; } }
          d.close(); return hit; }"""
        t = time.time()
        while time.time() - t < secs:
            if await self.page.evaluate(js, [db, texts]): return time.time() - t
            await self.page.wait_for_timeout(500)
        self.errs.append("save with %r never reached the browser's storage in %ds" % (texts, secs)); return -1
    async def key(self, k, wait=350): await self.page.keyboard.press(k); await self.page.wait_for_timeout(wait)
    async def cmd(self, c, wait=500): await self.page.evaluate("window.%s_cmd = %r" % (self.name, c)); await self.page.wait_for_timeout(wait)
    async def shot(self, n): await self.page.screenshot(path=os.path.join(self.shots, n + ".png"))
    async def touch_drag(self, x0, y0, x1, y1, hold_ms=900):
        cdp = await self.ctx.new_cdp_session(self.page)
        await cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": x0, "y": y0, "id": 1}]}); await self.page.wait_for_timeout(300)
        await cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": [{"x": x1, "y": y1, "id": 1}]}); await self.page.wait_for_timeout(hold_ms)
        return cdp
    async def touch_end(self, cdp): await cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
    def check(self, ok, what):
        self.checks.append(("ok  " if ok else "FAIL") + "  " + what)
        if not ok: self.errs.append("check failed: " + what)
    def report(self):
        return "\n".join(self.checks + ["notes %s" % self.notes, "errors %s" % self.errs])
