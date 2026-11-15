#!/usr/bin/env python3
# Shared sound maker (common). Makes stadium sounds with a small synth: whistle, crowd loop, cheer, kick and click.
# Needs numpy and ffmpeg. usage: python3 tools/common/make_sfx.py [output folder, default ./audio]
# Output: whistle.ogg, crowd.ogg, cheer.ogg, kick.ogg, click.ogg (mono, 32 kHz). E6.3 asks for .wav: see common/CHANGELOG.md.
import numpy as np, os, wave, subprocess
SR = 32000
import sys
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.getcwd(), "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)
def lowpass(x, k):
    c = np.cumsum(np.insert(x, 0, 0.0)); return (c[k:] - c[:-k]) / k
def noise_band(n, lo, hi):
    f = np.fft.rfft(rng.standard_normal(n)); fr = np.fft.rfftfreq(n, 1 / SR)
    f[(fr < lo) | (fr > hi)] = 0; x = np.fft.irfft(f, n); return x / np.max(np.abs(x))
def write(name, buf):
    p = os.path.join(OUT, name + ".wav")
    with wave.open(p, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((np.clip(buf, -1, 1) * 30000).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", p, "-c:a", "libvorbis", "-q:a", "3", os.path.join(OUT, name + ".ogg")], check=True); os.remove(p)
def whistle(dur):
    t = np.arange(int(SR * dur)) / SR
    trill = 1 + 0.25 * np.sign(np.sin(2 * np.pi * 38 * t))
    s = np.sin(2 * np.pi * 2850 * t + 3 * np.sin(2 * np.pi * 38 * t)) * trill + 0.3 * np.sin(2 * np.pi * 5700 * t)
    env = np.minimum(1, t * 80) * np.minimum(1, (dur - t) * 30)
    return s * env * 0.35
def crowd(dur, swell=False):
    n = int(SR * dur); t = np.arange(n) / SR
    x = noise_band(n, 250, 2600) * 0.7 + noise_band(n, 80, 400) * 0.5
    slow = 0.75 + 0.25 * lowpass(np.abs(rng.standard_normal(n + 7999)), 8000) * 2
    x = x * slow[:n]
    if swell:
        x = x * (np.minimum(1, t * 6) * np.exp(-np.maximum(0, t - 1.2) * 1.3)) * 1.6
        x = x + noise_band(n, 900, 3800) * np.minimum(1, t * 8) * np.exp(-t * 1.5) * 0.5
    else:
        f = int(SR * 0.5); r = np.linspace(0, 1, f)   # cross-fade the ends so the loop is seamless
        x[:f] = x[:f] * r + x[-f:] * (1 - r); x = x[:-f]
    return x * 0.35
def kick():
    t = np.arange(int(SR * 0.25)) / SR
    return (np.sin(2 * np.pi * (140 * np.exp(-t * 18) + 50) * t) * np.exp(-t * 16) + noise_band(len(t), 800, 4000) * np.exp(-t * 60) * 0.4) * 0.9
def click():
    t = np.arange(int(SR * 0.06)) / SR
    return np.sin(2 * np.pi * 900 * t) * np.exp(-t * 70) * 0.5
write("whistle", whistle(0.55)); write("crowd", crowd(8.0)); write("cheer", crowd(3.5, True)); write("kick", kick()); write("click", click())
print("sounds written to", OUT)
