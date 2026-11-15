#!/usr/bin/env python3
# Browser check: the page loads with no errors, the title shows, a team is picked, a pass play and a run play
# are called and run with the keyboard, the defense screen shows, the menu opens and touch controls appear.
# The game reports its state to the page (?test), so the test waits for each state instead of guessing times.
# Server, browser, keys, screenshots and touch come from the shared kit: tests/common/webkit.py (G10).
# usage: web_test.py [web build folder] [shots folder]
import asyncio, sys, time, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "common"))
from webkit import Run, serve
OUT = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/ttf-out/web"
SHOTS = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/ttf-out/shots"
TITLE, TEAMSEL, PLAYCALL, PRESNAP, LIVE, DEAD, KICK, OVER = range(8)

async def main():
    with serve(OUT, 8792) as base:
        async with Run("ttf", SHOTS) as r:
            pg = r.page; notes = r.notes; errs = r.errs
            await r.open(base + "index.html?test")
            async def st(): return await r.state()
            async def wait_state(states, secs=40):
                # The game publishes "state", not "phase", until it moves to test_bridge.gd (next release).
                t = time.time()
                while time.time() - t < secs:
                    s = await st()
                    if s and s["state"] in states: return s
                    await pg.wait_for_timeout(150)
                errs.append("timeout waiting for %s, got %s" % (states, await st())); return await st()
            shot = r.shot
            async def key(k, wait=400): await r.key(k, wait)
            await wait_state([TITLE], 60); await pg.wait_for_timeout(1500); await shot("01_title")
            await key("Enter"); await wait_state([TEAMSEL]); await pg.wait_for_timeout(800); await shot("02_teams")
            await key("Enter"); await wait_state([PLAYCALL]); await pg.wait_for_timeout(2500); await shot("03_playcall_offense")
            await key("1"); await wait_state([PRESNAP]); await pg.wait_for_timeout(900); await shot("04_presnap_pass")
            await key("Space"); await wait_state([LIVE]); await pg.wait_for_timeout(1500); await shot("05_live_pass")
            await key("1", 500); s = await st(); notes.append("after throw ball=%s" % s["ball"]); await shot("06_ball_in_air")
            await pg.keyboard.down("w"); await wait_state([DEAD, KICK]); await pg.keyboard.up("w"); await pg.wait_for_timeout(500); await shot("07_pass_result")
            await wait_state([PLAYCALL, KICK])
            s = await st()
            if s["state"] == PLAYCALL and s["poss"] == 0:
                await key("8"); await wait_state([PRESNAP]); await key("Space"); await wait_state([LIVE])
                await pg.keyboard.down("w"); await pg.keyboard.down("d"); await pg.wait_for_timeout(1400); await shot("08_live_run")
                await pg.keyboard.up("d"); await wait_state([DEAD]); await pg.keyboard.up("w"); await pg.wait_for_timeout(400); await shot("09_run_result")
            # keep playing until the computer has had the ball and a kick has been seen
            seen_def = False; seen_kick = False
            for i in range(40):
                s = await wait_state([PLAYCALL, KICK, PRESNAP, OVER], 60)
                if s is None or s["state"] == OVER: break
                if s["state"] == KICK:
                    if not seen_kick and s["poss"] == 0:
                        await pg.wait_for_timeout(700); await shot("12_kick_meter"); seen_kick = True
                    await key("Space", 300); await wait_state([DEAD, PLAYCALL], 30); continue
                if s["state"] == PLAYCALL:
                    if s["poss"] == 1 and not seen_def:
                        await pg.wait_for_timeout(600); await shot("10_playcall_defense")
                    await key("2" if s["poss"] == 0 else "1")
                    s = await wait_state([PRESNAP, DEAD, KICK], 20)
                if s and s["state"] == PRESNAP:
                    if s["poss"] == 0: await key("Space", 200)
                    await wait_state([LIVE], 20)
                    if s["poss"] == 1 and not seen_def:
                        await pg.wait_for_timeout(1200); await shot("11_live_defense"); seen_def = True
                    if s["poss"] == 0:
                        await pg.wait_for_timeout(1700); await key("1", 100)
                    await pg.keyboard.down("w"); await wait_state([DEAD, KICK], 40); await pg.keyboard.up("w")
                if seen_def and seen_kick and i > 8: break
            notes.append("seen_def=%s seen_kick=%s final=%s" % (seen_def, seen_kick, await st()))
            await key("Escape", 700); await shot("13_menu"); await key("Escape", 400)
            cdp = await r.touch_drag(200, 500, 240, 440, 1200); await shot("14_touch"); await r.touch_end(cdp)
    print(r.report())
asyncio.run(main())
