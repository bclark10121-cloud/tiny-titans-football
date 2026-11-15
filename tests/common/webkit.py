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

Pretend Xbox controller (G5.8). Call use_pad() before open(). Buttons use the Xbox names in PAD_BUTTONS:
    await r.use_pad(); await r.open(url)
    await r.pad("A"); await r.pad("DOWN"); await r.pad("VIEW")      # press and release
    await r.pad_stick(1.0, 0.0, 2000)                                 # hold the left stick right for 2 seconds
Headless Chrome draws only 1 or 2 frames a second, so presses are held long enough for the game to see them.
"""
import asyncio, contextlib, os, subprocess, sys, time
from playwright.async_api import async_playwright

CHROME = os.environ.get("CHROME", "/usr/bin/google-chrome")
# Xbox button names to the browser's standard gamepad layout (G5.8). View is Back and Menu is Start in Godot.
PAD_BUTTONS = {"A": 0, "B": 1, "X": 2, "Y": 3, "LB": 4, "RB": 5, "LT": 6, "RT": 7, "VIEW": 8, "MENU": 9,
               "LS": 10, "RS": 11, "UP": 12, "DOWN": 13, "LEFT": 14, "RIGHT": 15, "XBOX": 16}
# Stands in one connected Xbox controller in the browser's standard layout, before the game loads.
PAD_JS = """(() => {
  const pad = {id: "Xbox Wireless Controller (STANDARD GAMEPAD Vendor: 045e Product: 0b13)", index: 0, connected: true,
    mapping: "standard", timestamp: 0, axes: [0, 0, 0, 0],
    buttons: Array.from({length: 17}, () => ({value: 0, pressed: false, touched: false}))};
  Object.defineProperty(navigator, "getGamepads", {value: () => [pad, null, null, null], configurable: true});
  window.__pad_button = (b, v) => { pad.buttons[b].value = v; pad.buttons[b].pressed = v > 0.5; pad.timestamp = performance.now(); };
  window.__pad_axes = (x, y) => { pad.axes = [x, y, 0, 0]; pad.timestamp = performance.now(); };
})();"""
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
    async def use_pad(self):
        """Connects a pretend Xbox controller. Call it before open()."""
        await self.ctx.add_init_script(PAD_JS)
    async def pad(self, button, hold_ms=1200, wait=600):
        """Presses and releases one Xbox button by name (PAD_BUTTONS)."""
        b = PAD_BUTTONS[button.upper()]
        await self.page.evaluate("b => window.__pad_button(b, 1)", b); await self.page.wait_for_timeout(hold_ms)
        await self.page.evaluate("b => window.__pad_button(b, 0)", b); await self.page.wait_for_timeout(wait)
    async def pad_stick(self, x, y, hold_ms=1500, wait=400):
        """Holds the left stick at x, y (-1 to 1, y down is +1), then lets it go."""
        await self.page.evaluate("([x, y]) => window.__pad_axes(x, y)", [x, y]); await self.page.wait_for_timeout(hold_ms)
        await self.page.evaluate("() => window.__pad_axes(0, 0)"); await self.page.wait_for_timeout(wait)
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
