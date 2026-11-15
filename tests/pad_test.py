#!/usr/bin/env python3
# Xbox controller check (G5.8): plays Tiny Titans Football in the browser with the kit's pretend Xbox controller only.
# Title card, team screen, kickoff meter, a play card, the snap, a pass to receiver B, then Menu, B to go back and View.
# usage: pad_test.py [web build folder] [shots folder]
import asyncio, sys, os, time
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "common"))
from webkit import Run, serve
OUT = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/ttf-out/web"
SHOTS = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/ttf-out/pad_shots"
TITLE, TEAMSEL, PLAYCALL, PRESNAP, LIVE, DEAD, KICK, OVER = range(8)

async def main():
    with serve(OUT, 8793) as base:
        async with Run("ttf", SHOTS) as r:
            await r.use_pad()
            await r.open(base + "index.html?test")
            s = await r.wait_phase([TITLE], 90)
            await r.page.wait_for_timeout(1500); await r.shot("pad_01_title")
            await r.pad("A")
            s = await r.wait_phase([TEAMSEL], 20)
            r.checks.append("%s A on the title card opens the team screen" % ("ok  " if s.get("phase") == TEAMSEL else "FAIL"))
            await r.shot("pad_02_team")
            await r.pad("A")
            t0 = time.time(); picked = False; held = False; thrown = False
            while time.time() - t0 < 200 and not thrown:
                s = await r.state() or {}
                ph = s.get("phase"); poss = s.get("poss")
                if ph == PLAYCALL and poss == 0 and not picked:
                    await r.page.wait_for_timeout(800); await r.shot("pad_03_playcall")
                    await r.pad("A")
                    s = await r.wait_phase([PRESNAP], 20)
                    picked = s.get("phase") == PRESNAP
                    await r.page.wait_for_timeout(1500)
                    s = await r.state() or {}
                    held = s.get("phase") == PRESNAP
                elif ph == PRESNAP and poss == 0 and s.get("kind") == "scrim" and picked:
                    await r.pad("A")                                  # snap
                    for _ in range(80):
                        s = await r.state() or {}
                        if s.get("phase") == LIVE and s.get("ctrl") == "QB" and s.get("ball") == "held": break
                        if s.get("phase") not in (PRESNAP, LIVE): break
                        await r.page.wait_for_timeout(100)
                    if s.get("phase") == LIVE and s.get("ctrl") == "QB":
                        await r.pad("B", hold_ms=500, wait=200)       # throw to the receiver marked B
                        s = await r.state() or {}
                        thrown = s.get("ball") in ("air", "held") and s.get("phase") in (LIVE, DEAD)
                        await r.shot("pad_04_pass")
                    await r.wait_phase([DEAD, PLAYCALL, KICK, OVER], 40)
                elif ph == PLAYCALL:
                    await r.page.wait_for_timeout(600); await r.pad("A")   # pick a defense or a kick
                elif ph == PRESNAP and poss == 0:
                    await r.page.wait_for_timeout(600); await r.pad("A")   # kick meter
                else:
                    await r.page.wait_for_timeout(300)
            r.checks.append("%s A picks a play card" % ("ok  " if picked else "FAIL"))
            r.checks.append("%s the same press does not snap the ball" % ("ok  " if held else "FAIL"))
            r.checks.append("%s A snaps and B passes" % ("ok  " if thrown else "FAIL"))
            await r.wait_phase([PLAYCALL, PRESNAP], 60)
            await r.pad("MENU"); s = await r.state() or {}
            await r.shot("pad_05_menu")
            r.checks.append("%s Menu opens the Menu" % ("ok  " if s.get("menu") else "FAIL"))
            await r.pad("B"); s = await r.state() or {}
            r.checks.append("%s B closes the Menu" % ("ok  " if not s.get("menu") else "FAIL"))
            await r.pad("VIEW"); s = await r.state() or {}
            r.checks.append("%s View opens the Menu" % ("ok  " if s.get("menu") else "FAIL"))
            await r.pad("VIEW"); s = await r.state() or {}
            r.checks.append("%s View closes the Menu" % ("ok  " if not s.get("menu") else "FAIL"))
            for c in r.checks:
                if c.startswith("FAIL"): r.errs.append(c)
    print(r.report())

asyncio.run(main())
