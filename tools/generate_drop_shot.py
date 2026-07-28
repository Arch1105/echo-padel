"""Extracts a clean, isolated "soft racket tap" clip for the drop shot /
dink mechanic (see PlayerController.gd's dedicated drop-shot button,
Ball.gd's is_drop_shot handling) - deliberately a different recording from
tools/generate_racket_hit.py's hit/smash/mishit set, so it reads as its own
distinct sound rather than a re-used/re-pitched one.

Source recording, Freesound.org, explicitly licensed CC0 (verified on the
sound's own page before downloading):
  - "Tennis Bounces on Racket" by jamesdrake89
    https://freesound.org/people/jamesdrake89/sounds/662257/
    A ~27s recording of a ball being bounced repeatedly on the racket
    strings - a genuinely soft, isolated "tap" character, unlike the other
    three (harder) racket recordings already in use. One clean onset is
    extracted from partway through, where the bounce is a clear, moderate
    tap with silence either side (bounces land roughly every ~0.55-0.6s, so
    this stays well clear of its neighbors).

Raw preview kept at tools/drop_shot_src/*.mp3 for provenance, decoded once
to a matching *.wav (mono 44.1kHz) via:
    ffmpeg -i jamesdrake89_tennis_bounces_on_racket_hq.mp3 -ar 44100 -ac 1 jamesdrake89_tennis_bounces_on_racket_hq.wav
This script only needs that decoded wav and the stdlib - no ffmpeg/network
needed to re-run it.
"""
import os
import struct
import wave

SRC_DIR = os.path.join(os.path.dirname(__file__), "drop_shot_src")
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")

SOURCE_FILE = "jamesdrake89_tennis_bounces_on_racket_hq.wav"
ONSET_APPROX_S = 10.52
OUT_NAME = "drop_shot.wav"
PEAK_TARGET = 0.75

PRE_ROLL_MS = 4
CLIP_DUR_MS = 260
FADE_OUT_MS = 60
FADE_IN_MS = 1


def load_samples(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		n = w.getnframes()
		raw = w.readframes(n)
	return struct.unpack("<%dh" % n, raw), sr


def find_onset(samples, sr: int, t_approx: float, search_radius: float = 0.05, thresh: int = 800) -> int:
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

	# Unlike generate_racket_hit.py's sources (already hot recordings that
	# only ever need attenuating down to their peak_target), this source is a
	# quiet home recording - scale can go above 1.0 to actually reach
	# peak_target, not just clamp down to it.
	peak = max(1.0, max(abs(s) for s in seg))
	scale = (peak_target * 32767) / peak
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
	samples, sr = load_samples(os.path.join(SRC_DIR, SOURCE_FILE))
	clip = extract_clip(samples, sr, ONSET_APPROX_S, PEAK_TARGET)
	write_wav(os.path.join(OUT_DIR, OUT_NAME), clip, sr)
	print("Done.")


if __name__ == "__main__":
	main()
