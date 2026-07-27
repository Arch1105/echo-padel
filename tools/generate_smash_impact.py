"""Builds the dedicated smash-impact sound: the real racket-smash recording
(see tools/generate_racket_hit.py - "Tennis smash" by gprosser, Freesound,
CC0) layered with a procedurally-synthesized sub-bass boom and a bright
shimmer tail (same stdlib-only synthesis technique as tools/generate_sfx.py)
for extra weight/drama, since a smash is now its own dedicated, deliberately
hard-to-return mechanic rather than just a harder-charged normal hit.

Run once (or whenever tuning): python tools/generate_smash_impact.py
No network needed - reads the already-generated audio/sfx/racket_smash.wav.
"""
import math
import os
import random
import struct
import wave

SR = 44100
RACKET_SMASH_PATH = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx", "racket_smash.wav")
OUT_PATH = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx", "smash_impact.wav")


def n_samples(duration: float) -> int:
	return int(SR * duration)


def sine(freq: float, duration: float) -> list[float]:
	n = n_samples(duration)
	return [math.sin(2 * math.pi * freq * (i / SR)) for i in range(n)]


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


def env_exp_decay(samples: list[float], rate: float) -> list[float]:
	return [s * math.exp(-rate * (i / SR)) for i, s in enumerate(samples)]


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


def scale(samples: list[float], gain: float) -> list[float]:
	return [s * gain for s in samples]


def mix(*layers: list[float]) -> list[float]:
	length = max(len(l) for l in layers)
	out = [0.0] * length
	for layer in layers:
		for i, s in enumerate(layer):
			out[i] += s
	return out


def pad_to(samples: list[float], length: int) -> list[float]:
	if len(samples) >= length:
		return samples[:length]
	return samples + [0.0] * (length - len(samples))


def load_wav(path: str) -> tuple[list[float], int]:
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		n = w.getnframes()
		raw = w.readframes(n)
	samples = struct.unpack("<%dh" % n, raw)
	return [s / 32767.0 for s in samples], sr


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


def main() -> None:
	racket, sr = load_wav(RACKET_SMASH_PATH)
	assert sr == SR, "racket_smash.wav must be 44.1kHz"

	# Deep sub-bass "boom" under the racket crack for extra weight.
	boom = env_exp_decay(sine_sweep(140, 45, 0.35), 9)
	# A quick bright noise burst right at the transient, for extra "crack".
	crack = env_exp_decay(lowpass(noise(0.05, 7), 0.9), 60)
	# A short rising-then-falling shimmer tail trailing after the hit, so it
	# reads as a bigger, more dramatic event than a plain racket sound alone.
	shimmer = env_linear(lowpass(noise(0.4, 13), 0.15), 0.02, 0.35)
	shimmer_tone = env_linear(sine_sweep(2000, 3200, 0.25), 0.02, 0.2)

	total_len = max(len(racket), len(boom), len(shimmer))
	layered = mix(
		pad_to(racket, total_len),
		pad_to(scale(boom, 0.8), total_len),
		pad_to(scale(crack, 0.5), total_len),
		pad_to(scale(shimmer, 0.18), total_len),
		pad_to(scale(shimmer_tone, 0.12), total_len),
	)
	write_wav(OUT_PATH, layered)


if __name__ == "__main__":
	main()
