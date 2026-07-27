"""Extracts clean, normalized racket-hit clips from real recordings, one
each for a clean hit, a smash, and a weak mishit - replacing the earlier
procedurally-synthesized "hit" sound and the earlier random-pool-of-3
approach (feedback: one standard hit sound, not three interchangeable
variants; the other two recordings instead became dedicated sounds for the
new smash and mishit mechanics).

Source recordings, all Freesound.org, all explicitly licensed CC0 (public
domain equivalent) - verified on each sound's own page before downloading:
  - "Tennis-Ball-Hit" by kletton97 -> normal hit (plainest of the three)
    https://freesound.org/people/kletton97/sounds/710041/
  - "Tennis smash" by gprosser -> smash (already the punchiest/loudest)
    https://freesound.org/people/gprosser/sounds/412863/
  - "Hit a ball" by Breviceps -> mishit (already the softest/shortest)
    https://freesound.org/people/Breviceps/sounds/457039/
Raw previews kept at tools/racket_src/*.mp3 for provenance, each decoded
once to a matching *.wav (mono 44.1kHz) via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 1 <name>.wav
This script only needs those decoded wavs and the stdlib - no ffmpeg/network
needed to re-run it.
"""
import os
import struct
import wave

SRC_DIR = os.path.join(os.path.dirname(__file__), "racket_src")
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")

# (source wav filename, approximate onset in seconds - found by inspecting
# the short-time RMS envelope of each source file, output filename, peak
# target as a fraction of full scale - mishit is deliberately quieter/softer
# so it reads as a weak return even before Ball.gd's own volume_db drop).
SOURCES = [
	("kletton97_tennis_ball_hit_hq.wav", 0.463, "racket_hit.wav", 0.88),
	("gprosser_tennis_smash_hq.wav", 0.0, "racket_smash.wav", 0.95),
	("breviceps_hit_a_ball_hq.wav", 0.012, "racket_mishit.wav", 0.55),
]

PRE_ROLL_MS = 3
CLIP_DUR_MS = 320
FADE_OUT_MS = 40
FADE_IN_MS = 1


def load_samples(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		n = w.getnframes()
		raw = w.readframes(n)
	return struct.unpack("<%dh" % n, raw), sr


def find_onset(samples, sr: int, t_approx: float, search_radius: float = 0.05, thresh: int = 1200) -> int:
	i_center = int(t_approx * sr)
	i0 = max(0, i_center - int(search_radius * sr))
	i1 = min(len(samples), i_center + int(search_radius * sr))
	for i in range(i0, i1):
		if abs(samples[i]) > thresh:
			return i
	return i_center


def extract_clip(samples, sr: int, t_approx: float, peak_target: float) -> list[float]:
	onset = find_onset(samples, sr, t_approx)
	start = max(0, onset - int(PRE_ROLL_MS / 1000 * sr))
	length = int(CLIP_DUR_MS / 1000 * sr)
	seg = [float(s) for s in samples[start:start + length]]
	if len(seg) < length:
		seg += [0.0] * (length - len(seg))

	peak = max(1.0, max(abs(s) for s in seg))
	scale = min(1.0, (peak_target * 32767) / peak)
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
	for filename, t_approx, out_name, peak_target in SOURCES:
		samples, sr = load_samples(os.path.join(SRC_DIR, filename))
		clip = extract_clip(samples, sr, t_approx, peak_target)
		write_wav(os.path.join(OUT_DIR, out_name), clip, sr)
	print("Done.")


if __name__ == "__main__":
	main()
