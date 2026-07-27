"""Procedurally generates the remaining synthesized sound-effect WAV assets
for Echo Padel. Run once (or whenever tuning sounds): python tools/generate_sfx.py
No external dependencies - stdlib only.

The bounce, racket-hit, net-hit, and crowd cheer/boo sounds are NOT
generated here - per playtest feedback they're real recordings instead (see
tools/generate_tennis_bounce.py, tools/generate_racket_hit.py,
tools/generate_net_hit.py, tools/generate_crowd_sounds.py).
"""
import math
import random
import struct
import wave
import os

SR = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")


def write_wav(path: str, samples: list[float]) -> None:
    peak = max(0.0001, max(abs(s) for s in samples))
    if peak > 1.0:
        samples = [s / peak for s in samples]
    frames = bytearray()
    for s in samples:
        v = int(max(-1.0, min(1.0, s)) * 32767)
        frames += struct.pack("<h", v)
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(bytes(frames))
    print(f"wrote {path} ({len(samples) / SR:.3f}s)")


def n_samples(duration: float) -> int:
    return int(SR * duration)


def silence(duration: float) -> list[float]:
    return [0.0] * n_samples(duration)


def sine(freq: float, duration: float, phase: float = 0.0) -> list[float]:
    n = n_samples(duration)
    return [math.sin(2 * math.pi * freq * (i / SR) + phase) for i in range(n)]


def sine_sweep(f_start: float, f_end: float, duration: float) -> list[float]:
    n = n_samples(duration)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / n
        freq = f_start + (f_end - f_start) * t
        phase += 2 * math.pi * freq / SR
        out.append(math.sin(phase))
    return out


def noise(duration: float, seed: int = 0) -> list[float]:
    rnd = random.Random(seed)
    n = n_samples(duration)
    return [rnd.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(samples: list[float], amount: float) -> list[float]:
    out = [0.0] * len(samples)
    prev = 0.0
    for i, s in enumerate(samples):
        prev = prev + amount * (s - prev)
        out[i] = prev
    return out


def env_linear(samples: list[float], attack: float, release: float) -> list[float]:
    n = len(samples)
    a = max(1, n_samples(attack))
    r = max(1, n_samples(release))
    out = list(samples)
    for i in range(min(a, n)):
        out[i] *= i / a
    for i in range(min(r, n)):
        idx = n - 1 - i
        out[idx] *= i / r
    return out


def env_exp_decay(samples: list[float], rate: float) -> list[float]:
    n = len(samples)
    return [s * math.exp(-rate * (i / SR)) for i, s in enumerate(samples)]


def mix(*layers: list[float]) -> list[float]:
    length = max(len(l) for l in layers)
    out = [0.0] * length
    for layer in layers:
        for i, s in enumerate(layer):
            out[i] += s
    return out


def scale(samples: list[float], gain: float) -> list[float]:
    return [s * gain for s in samples]


def pad_to(samples: list[float], length: int) -> list[float]:
    if len(samples) >= length:
        return samples[:length]
    return samples + [0.0] * (length - len(samples))


def make_ready_chime() -> list[float]:
    """Short two-note ascending chime - plays every time the game is
    waiting for a "ready" confirmation before serving (see MatchManager.gd/
    TrainingManager.gd), so there's a quick, non-verbal cue that reads
    faster with practice than the spoken prompt alone."""
    n1 = env_exp_decay(sine(660, 0.09), 35)
    n2 = env_exp_decay(sine(880, 0.12), 30)
    gap = n_samples(0.05)
    total_len = gap + len(n2)
    return mix(pad_to(n1, total_len), pad_to([0.0] * gap + n2, total_len))


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    write_wav(os.path.join(OUT_DIR, "ready_chime.wav"), make_ready_chime())

    print("Done.")


if __name__ == "__main__":
    main()
