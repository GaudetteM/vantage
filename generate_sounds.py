#!/usr/bin/env python3
"""
Synthesize game SFX using only Python stdlib (wave + math).
Outputs: assets/audio/{move,blocked,rotate,solved}.wav
"""

import wave, math, struct, os

RATE = 44100

def pcm(samples):
    """Convert float samples [-1,1] to 16-bit signed PCM bytes."""
    out = bytearray()
    for s in samples:
        v = max(-32767, min(32767, int(s * 32767)))
        out += struct.pack('<h', v)
    return bytes(out)

def write_wav(path, samples):
    with wave.open(path, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm(samples))
    print(f'  wrote {path}  ({len(samples)/RATE*1000:.0f}ms)')

def sine(freq, dur, vol=1.0):
    n = int(RATE * dur)
    return [vol * math.sin(2 * math.pi * freq * t / RATE) for t in range(n)]

def sweep(f0, f1, dur, vol=1.0):
    """Linear frequency sweep."""
    n = int(RATE * dur)
    return [vol * math.sin(2 * math.pi * (f0 + (f1 - f0) * t / n) * t / RATE)
            for t in range(n)]

def add(*tracks):
    length = max(len(t) for t in tracks)
    result = [0.0] * length
    for t in tracks:
        for i, s in enumerate(t):
            result[i] += s
    return result

def apply_env(samples, attack=0.005, decay=0.05, sustain=0.7, release=0.08):
    n = len(samples)
    a = int(RATE * attack)
    d = int(RATE * decay)
    r = int(RATE * release)
    sl = max(0, n - a - d - r)
    result = []
    for i, s in enumerate(samples):
        if i < a:
            amp = i / max(1, a)
        elif i < a + d:
            amp = 1.0 - (1.0 - sustain) * (i - a) / max(1, d)
        elif i < a + d + sl:
            amp = sustain
        else:
            pos = i - a - d - sl
            amp = sustain * max(0.0, 1.0 - pos / max(1, r))
        result.append(s * amp)
    return result

def silence(dur):
    return [0.0] * int(RATE * dur)

# ── move.wav ─────────────────────────────────────────────────────────────────
# Soft "tick" — two brief sine tones slightly detuned, fast decay.
def make_move():
    dur = 0.09
    wave1 = sine(780, dur, 0.55)
    wave2 = sine(785, dur, 0.35)   # slight beating for warmth
    combined = add(wave1, wave2)
    return apply_env(combined, attack=0.003, decay=0.02, sustain=0.3, release=0.06)

# ── blocked.wav ───────────────────────────────────────────────────────────────
# Low thud — descending sweep with a dissonant second pulse.
def make_blocked():
    s1 = apply_env(sweep(280, 130, 0.10, 0.8), attack=0.003, decay=0.04, sustain=0.3, release=0.05)
    s2 = silence(0.03) + apply_env(sine(145, 0.06, 0.45), attack=0.002, decay=0.01, sustain=0.2, release=0.04)
    combined = add(s1, s2)
    return combined

# ── rotate.wav ────────────────────────────────────────────────────────────────
# Mechanical whoosh — ascending sweep, slightly airy.
def make_rotate():
    sig = sweep(320, 740, 0.18, 0.75)
    sig2 = sweep(325, 748, 0.18, 0.30)  # slight detune
    combined = add(sig, sig2)
    return apply_env(combined, attack=0.01, decay=0.04, sustain=0.55, release=0.09)

# ── solved.wav ────────────────────────────────────────────────────────────────
# Rising arpeggio: C5 → E5 → G5 → C6 (triumphant but short)
def make_solved():
    notes = [523.25, 659.25, 783.99, 1046.50]  # C5 E5 G5 C6
    out = []
    for i, freq in enumerate(notes):
        vol = 0.60 if i < 3 else 0.80
        tone = apply_env(sine(freq, 0.12, vol),
                         attack=0.005, decay=0.03, sustain=0.65, release=0.06)
        # tiny silence between notes for clarity
        out += tone + silence(0.015)
    return out

os.makedirs('assets/audio', exist_ok=True)

print('Generating SFX...')
write_wav('assets/audio/move.wav',    make_move())
write_wav('assets/audio/blocked.wav', make_blocked())
write_wav('assets/audio/rotate.wav',  make_rotate())
write_wav('assets/audio/solved.wav',  make_solved())
print('Done.')
