"""Builds the Super Smash impact sound - a distinctly *more powerful*
variant of tools/generate_smash_impact.py's regular smash sound, for LAN
Wall Mode's one-per-game power move (see PlayerController.gd/Ball.gd).

Same base ingredient (the real "Tennis smash" racket recording by gprosser,
Freesound, CC0 - see tools/generate_racket_hit.py) and the same stdlib-only
procedural-layering technique as the regular smash, just turned up: a
deeper/louder/longer sub-bass boom, a bigger crack, a wider/longer shimmer
tail, and one new layer the regular smash doesn't have - a short rising
"power surge" swoosh right before the hit, so it reads as something bigger
building up rather than just a louder version of the same sound.

Run once (or whenever tuning): python tools/generate_super_smash_impact.py
No network needed - reads the already-generated audio/sfx/racket_smash.wav.
"""
import math
import os
import random
import struct
import wave

SR = 44100
RACKET_SMASH_PATH = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx", "racket_smash.wav")
OUT_PATH = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx", "super_smash_impact.wav")


def n_samples(duration: float) -> int:
	return int(SR * duration)


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


def offset(samples: list[float], lead_silence: float) -> list[float]:
	return [0.0] * n_samples(lead_silence) + samples


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

	# A quick rising swoosh leading into the hit - not present on the regular
	# smash - so this reads as something building up rather than just a
	# louder version of the same impact.
	surge = env_linear(lowpass(noise(0.16, 21), 0.35), 0.02, 0.05)
	surge_tone = env_linear(sine_sweep(250, 950, 0.16), 0.01, 0.03)
	racket_delayed = offset(racket, 0.14)

	# Deeper, louder, longer sub-bass boom than the regular smash's.
	boom = env_exp_decay(sine_sweep(160, 35, 0.55), 6)
	# A bigger, brighter crack right at the transient.
	crack = env_exp_decay(lowpass(noise(0.06, 7), 0.92), 45)
	# A wider, longer shimmer tail for extra drama.
	shimmer = env_linear(lowpass(noise(0.55, 13), 0.15), 0.02, 0.5)
	shimmer_tone = env_linear(sine_sweep(1600, 3600, 0.35), 0.02, 0.3)

	hit_start = n_samples(0.14)
	total_len = hit_start + max(len(racket), len(boom), len(shimmer), len(crack))
	layered = mix(
		pad_to(surge, total_len),
		pad_to(scale(surge_tone, 0.5), total_len),
		pad_to(racket_delayed, total_len),
		pad_to(offset(scale(boom, 1.1), 0.14), total_len),
		pad_to(offset(scale(crack, 0.7), 0.14), total_len),
		pad_to(offset(scale(shimmer, 0.28), 0.14), total_len),
		pad_to(offset(scale(shimmer_tone, 0.2), 0.14), total_len),
	)
	write_wav(OUT_PATH, layered)


if __name__ == "__main__":
	main()
