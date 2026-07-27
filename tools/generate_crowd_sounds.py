"""Extracts trimmed crowd cheer/boo clips from real recordings, replacing
the earlier procedurally-synthesized cheer.wav/boo.wav.

Source recordings, both Freesound.org, both explicitly licensed CC0 (public
domain equivalent) - verified on each sound's own page before downloading:
  - "Crowd Cheering" by SoundsExciting - https://freesound.org/people/SoundsExciting/sounds/365132/
  - "Crowd Boo.wav" by a deleted Freesound user (id 2104797) - https://freesound.org/people/deleted_user_2104797/sounds/324893/
Raw previews kept at tools/crowd_src/*.mp3 for provenance, each decoded once
to a matching *.wav (mono 44.1kHz) via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 1 <name>.wav
This script only needs those decoded wavs and the stdlib - no ffmpeg/network
needed to re-run it.

Both source clips run longer than needed for a quick point/game/set-win
sting, so each is trimmed down (found via short-time RMS envelope
inspection) with a short fade in/out. The cheer keeps its natural quiet
opening rather than starting mid-swell - per feedback, a straight-in-loud
cheer read as harsh; starting from where it's genuinely still quiet and
running through its full build to peak reads like a few fans starting and
the rest of the crowd catching on, closer to a real reaction.
"""
import os
import struct
import wave

SRC_DIR = os.path.join(os.path.dirname(__file__), "crowd_src")
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx")

# (source wav filename, output filename, start second, end second, peak target)
CLIPS = [
	("cheer.wav", "cheer.wav", 0.05, 3.6, 0.85),
	("boo.wav", "boo.wav", 0.6, 3.6, 0.85),
]

FADE_IN_MS = 60
FADE_OUT_MS = 350


def load_samples(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		n = w.getnframes()
		raw = w.readframes(n)
	return struct.unpack("<%dh" % n, raw), sr


def main() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)
	for in_name, out_name, start_s, end_s, peak_target in CLIPS:
		samples, sr = load_samples(os.path.join(SRC_DIR, in_name))
		start_i = int(start_s * sr)
		end_i = int(end_s * sr)
		seg = [float(s) for s in samples[start_i:end_i]]

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

		out_path = os.path.join(OUT_DIR, out_name)
		frames = bytearray()
		for s in seg:
			v = int(max(-32768, min(32767, s)))
			frames += struct.pack("<h", v)
		with wave.open(out_path, "wb") as f:
			f.setnchannels(1)
			f.setsampwidth(2)
			f.setframerate(sr)
			f.writeframes(bytes(frames))
		print(f"wrote {out_path} ({len(seg) / sr:.2f}s)")


if __name__ == "__main__":
	main()
