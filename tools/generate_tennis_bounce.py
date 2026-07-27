"""Extracts clean, isolated single-bounce clips from a real tennis-ball
recording for the bounce_locate/bounce_second sound effects, replacing the
earlier procedurally-synthesized versions per playtest feedback ("make it
sound like an actual tennis ball").

Source recording: "Tennis Ball Bounce" (sound #584) by Joseph SARDIN,
bigsoundbank.com - https://bigsoundbank.com/detail-0584-tennis-ball-bounce.html
Released under CC0 (public domain equivalent): free for commercial and
personal use worldwide, no attribution required. The original mp3 is kept
at tools/tennis_src/bigsoundbank_0584_tennis_ball_bounce.mp3 for provenance,
decoded once to tools/tennis_src/full.wav (mono 44.1kHz) via:
    ffmpeg -i bigsoundbank_0584_tennis_ball_bounce.mp3 -ar 44100 -ac 1 full.wav
This script only needs that decoded wav and the stdlib - no ffmpeg/network
needed to re-run it.

The source is 37 seconds of a person repeatedly bouncing a tennis ball, each
bounce well isolated (~1.6s+ apart). This picks three clean individual
bounces from different points in the recording (for natural variety - see
Sfx3D.SOUNDS, which already picks a random entry from a list), auto-detects
each one's precise onset, trims to a short one-shot, normalizes level, and
applies a tiny fade-in/out so looping/one-shot playback has no clicks.

Run whenever the trim points need adjusting: python tools/generate_tennis_bounce.py
"""
import math
import os
import struct
import wave

SRC_WAV = os.path.join(os.path.dirname(__file__), "tennis_src", "full.wav")
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")

# Approximate timestamps (seconds) of three well-isolated bounces in the
# source recording, picked from different points so the trio doesn't sound
# like a loop. Found via short-time RMS envelope peak-picking.
BOUNCE_TIMESTAMPS = [3.375, 10.530, 12.350]

PRE_ROLL_MS = 3
CLIP_DUR_MS = 110
FADE_OUT_MS = 18
FADE_IN_MS = 1
PEAK_TARGET = 0.85  # fraction of full scale


def load_samples(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		n = w.getnframes()
		raw = w.readframes(n)
	return struct.unpack("<%dh" % n, raw), sr


def find_onset(samples, sr: int, t_approx: float, search_radius: float = 0.08, thresh: int = 1500) -> int:
	i_center = int(t_approx * sr)
	i0 = max(0, i_center - int(search_radius * sr))
	i1 = min(len(samples), i_center + int(search_radius * sr))
	for i in range(i0, i1):
		if abs(samples[i]) > thresh:
			return i
	return i_center


def extract_clip(samples, sr: int, t_approx: float) -> list[float]:
	onset = find_onset(samples, sr, t_approx)
	start = onset - int(PRE_ROLL_MS / 1000 * sr)
	length = int(CLIP_DUR_MS / 1000 * sr)
	seg = [float(s) for s in samples[start:start + length]]

	peak = max(1.0, max(abs(s) for s in seg))
	scale = (PEAK_TARGET * 32767) / peak
	seg = [s * scale for s in seg]

	fade_in_n = int(FADE_IN_MS / 1000 * sr)
	fade_out_n = int(FADE_OUT_MS / 1000 * sr)
	for i in range(min(fade_in_n, len(seg))):
		seg[i] *= i / fade_in_n
	for i in range(min(fade_out_n, len(seg))):
		idx = len(seg) - 1 - i
		seg[idx] *= i / fade_out_n
	return seg


def write_wav(path: str, samples: list[float], sr: int) -> None:
	frames = bytearray()
	for s in samples:
		v = int(max(-32768, min(32767, s)))
		frames += struct.pack("<h", v)
	with wave.open(path, "wb") as f:
		f.setnchannels(1)
		f.setsampwidth(2)
		f.setframerate(sr)
		f.writeframes(bytes(frames))
	print(f"wrote {path} ({len(samples) / sr * 1000:.0f}ms)")


def main() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)
	samples, sr = load_samples(SRC_WAV)
	for i, t in enumerate(BOUNCE_TIMESTAMPS):
		clip = extract_clip(samples, sr, t)
		write_wav(os.path.join(OUT_DIR, f"tennis_bounce_{i:02d}.wav"), clip, sr)
	print("Done.")


if __name__ == "__main__":
	main()
