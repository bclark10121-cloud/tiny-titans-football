#!/usr/bin/env python3
# Browser check for Tiny Titans Football. The game reports its state to the page (?test), so the test
# reacts to each state instead of guessing times. It plays part of a game: kickoff or return, play call tabs,
# hot route, audible, a lob and a bullet pass, a run, an option pitch, auto pass, defense, kicks and the menu. Then it checks touch
# controls and a pretend notch (?test&notch). It prints errors [] and the largest draw call, triangle and
# video memory numbers seen while the ball was live.
# Server, browser, screenshots and touch come from the shared kit: tests/common/webkit.py (G10).
# Test switches work only with the whole-word ?test flag (G7.8).
# usage: web_test.py [web build folder] [shots folder]
import asyncio, sys, time, os, json
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "common"))
from webkit import Run, serve
OUT = sys.argv[1] if len(sys.argv) > 1 else "/home/claude/ttf-out/web"
SHOTS = sys.argv[2] if len(sys.argv) > 2 else "/home/claude/ttf-out/shots"
os.makedirs(SHOTS, exist_ok=True)
seen = set(); perf = {"dc": 0, "tris": 0, "vram": 0, "fps_min": 999}
TITLE, TEAMSEL, PLAYCALL, PRESNAP, LIVE, DEAD, KICK, OVER = range(8)

async def main():
    with serve(OUT, 8792) as base:
        async with Run("ttf", SHOTS) as r:
            pg = r.page; ctx = r.ctx; errs = r.errs; notes = r.notes
            await r.open(base + "index.html?test")
            async def st():
                s = await r.state()
                if s and "phase" in s: s["state"] = s["phase"]  # the kit bridge publishes the game state as phase
                return s
            async def wait_state(states, secs=40):
                t = time.time()
                while time.time() - t < secs:
                    s = await st()
                    if s and s["state"] == LIVE:
                        perf["dc"] = max(perf["dc"], s["dc"]); perf["tris"] = max(perf["tris"], s["tris"]); perf["vram"] = max(perf["vram"], s["vram"])
                    if s and s["state"] in states: return s
                    await pg.wait_for_timeout(120)
                errs.append("timeout waiting for %s, got %s" % (states, await st())); return await st()
            async def shot(n):
                if n in seen: return
                seen.add(n); await r.shot(n)
            async def key(k, wait=350): await pg.keyboard.press(k); await pg.wait_for_timeout(wait)
            await wait_state([TITLE], 60); await pg.wait_for_timeout(1200); await shot("01_title")
            await key("Enter"); await wait_state([TEAMSEL]); await pg.wait_for_timeout(600); await shot("02_teams")
            await key("Enter")
            off_calls = 0; t0 = time.time(); plays = 0; mode = "pass"; auto_on = False
            async def toggle_auto(tag):
                # Menu, then the Auto pass button in the top row, then close the menu
                await key("Escape", 600); await pg.mouse.click(882, 38); await pg.wait_for_timeout(500)
                await shot(tag); await key("Escape", 500)
            while time.time() - t0 < 230 and plays < 26:
                s = await st()
                if not s: await pg.wait_for_timeout(200); continue
                k = s["state"]
                if k == OVER: notes.append("game over reached"); break
                if k == PRESNAP and s["kind"] in ("kickoff", "punt"):
                    if s["poss"] == 0:
                        await pg.wait_for_timeout(500); await shot("03_%s_meter" % s["kind"]); await key("Space", 200)
                    else:
                        await shot("03_%s_receive" % s["kind"])
                    s = await wait_state([LIVE, DEAD, PLAYCALL], 20)
                    await pg.wait_for_timeout(1500); await shot("04_%s_in_air" % s.get("kind", "kick"))
                    await pg.keyboard.down("w")
                    s = await wait_state([DEAD, PLAYCALL, KICK, OVER], 40); await pg.keyboard.up("w")
                    if s and s.get("ret"): pass
                    plays += 1; continue
                if k == PLAYCALL:
                    if s["poss"] == 0:
                        if s["tabs"] == "Try":
                            await shot("12_pat_choice"); await key("2" if "two" not in notes else "1", 400); notes.append("two"); continue
                        await pg.wait_for_timeout(500); await shot("05_playcall_offense")
                        await key("e", 400); await shot("06_playcall_deep_tab"); await key("q", 300)
                        if "Kick" in s["tabs"] and s["down"] == 4:
                            await key("e"); await key("e"); await key("e"); await key("e"); await shot("13_kick_tab"); await key("1", 400); continue
                        if auto_on:
                            await toggle_auto("18b_auto_off_menu"); auto_on = False
                        choice = off_calls % 4
                        mode = ["pass", "run", "option", "auto"][choice]
                        if choice == 1: await key("e"); await key("e")   # run tab
                        if choice == 2:
                            await key("e"); await key("e"); await key("e"); await shot("21_option_tab")   # option tab
                        if choice == 3:
                            await toggle_auto("18_auto_on_menu"); auto_on = True
                        await key("1", 500); off_calls += 1
                    else:
                        await pg.wait_for_timeout(500); await shot("10_playcall_defense"); await key("3" if off_calls % 2 else "1", 400)
                    continue
                if k == PRESNAP:
                    if s["poss"] == 0:
                        if "07_hot_route" not in seen:
                            await key("1", 500); await shot("07_hot_route")
                            await key("r", 500); await shot("08_audible"); await key("r", 300)
                        await key("Space", 200)
                        s = await wait_state([LIVE, DEAD], 10)
                        if mode == "option" and s and s["state"] == LIVE:
                            await pg.wait_for_timeout(700); await key("e", 100); await pg.wait_for_timeout(500)
                            s = await st(); await shot("20_option_pitch"); notes.append("option: ctrl after pitch %s" % (s or {}).get("ctrl"))
                            await pg.keyboard.down("w"); await wait_state([DEAD, KICK, PLAYCALL, OVER], 40); await pg.keyboard.up("w")
                            plays += 1; continue
                        if mode == "auto" and s and s["state"] == LIVE:
                            await pg.wait_for_timeout(900); s = await st(); await shot("19_auto_pass")
                            ctrls = [s["ctrl"]]
                            for _ in range(80):
                                s = await st()
                                if not s or s["state"] != LIVE: break
                                if s["ctrl"] != ctrls[-1]: ctrls.append(s["ctrl"])
                                await pg.wait_for_timeout(150)
                            notes.append("auto pass: control went %s, ended %s" % (" > ".join(c or "none" for c in ctrls), (s or {}).get("state")))
                            await wait_state([DEAD, KICK, PLAYCALL, OVER], 40)
                            plays += 1; continue
                        await pg.wait_for_timeout(1600)
                        s = await st()
                        if s and s["state"] == LIVE and s["ctrl"] == "QB":
                            if "09_lob" not in seen:
                                await pg.keyboard.down("1"); await pg.wait_for_timeout(450); await pg.keyboard.up("1")
                                await pg.wait_for_timeout(500); await shot("09_lob")
                            else:
                                await key("2", 100)
                        else:
                            await pg.keyboard.down("w"); await pg.wait_for_timeout(700); await shot("09_run"); await pg.keyboard.up("w")
                        await pg.keyboard.down("w")
                        await wait_state([DEAD, KICK, PLAYCALL, OVER], 40); await pg.keyboard.up("w")
                    else:
                        await wait_state([LIVE, DEAD], 10); await pg.wait_for_timeout(1200); await shot("11_live_defense")
                        await key("Tab", 200)
                        await pg.keyboard.down("w"); await wait_state([DEAD, KICK, PLAYCALL, OVER], 40); await pg.keyboard.up("w")
                    plays += 1; continue
                if k == LIVE:
                    perf["dc"] = max(perf["dc"], s["dc"]); perf["tris"] = max(perf["tris"], s["tris"]); perf["vram"] = max(perf["vram"], s["vram"])
                    await pg.wait_for_timeout(200); continue
                if k == KICK:
                    if s["poss"] == 0:
                        await pg.wait_for_timeout(600); await shot("14_fg_meter"); await key("Space", 200)
                    await wait_state([DEAD, PLAYCALL, PRESNAP], 20); continue
                if k == DEAD:
                    perf["fps_min"] = min(perf["fps_min"], s["fps"]) if s["fps"] > 0 else perf["fps_min"]
                await pg.wait_for_timeout(200)
            s = await st(); notes.append("after loop: %s plays=%d" % (json.dumps(s), plays))
            await key("Escape", 700); await shot("15_menu"); await key("Escape", 400)
            cdp = await ctx.new_cdp_session(pg)
            await cdp.send("Input.dispatchTouchEvent", {"type": "touchStart", "touchPoints": [{"x": 200, "y": 500, "id": 1}]})
            await pg.wait_for_timeout(300)
            await cdp.send("Input.dispatchTouchEvent", {"type": "touchMove", "touchPoints": [{"x": 240, "y": 440, "id": 1}]})
            await pg.wait_for_timeout(1200); await shot("16_touch")
            await cdp.send("Input.dispatchTouchEvent", {"type": "touchEnd", "touchPoints": []})
            # pretend notch: HUD must move clear of an 80 px inset on the left
            pg2 = await ctx.new_page()
            pg2.on("pageerror", lambda e: errs.append("page2: " + str(e)))
            await pg2.goto(base + "index.html?test&notch")
            for _ in range(300):
                s2 = await pg2.evaluate("window.ttf || null")
                if s2 and s2["phase"] == TITLE: break
                await pg2.wait_for_timeout(150)
            await pg2.keyboard.press("Enter"); await pg2.wait_for_timeout(800); await pg2.keyboard.press("Enter")
            for _ in range(200):
                s2 = await pg2.evaluate("window.ttf || null")
                if s2 and s2["phase"] in (PRESNAP, PLAYCALL): break
                await pg2.wait_for_timeout(150)
            await pg2.wait_for_timeout(1500); await pg2.screenshot(path=SHOTS + "/17_notch80.png")
    print("shots", sorted(seen)); print("perf", perf); print(r.report())
asyncio.run(main())
