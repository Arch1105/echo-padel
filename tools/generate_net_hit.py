"""Extracts a clean net-hit clip from a real recording, for the sound that
plays when a shot goes into the net (previously silent - Ball.gd only spoke
the "Into the net." line with no accompanying sfx).

Source recording: "Net Impact Tennis Ball Smacks Bounces" by amsaenz03,
Freesound.org - https://freesound.org/people/amsaenz03/sounds/788265/
Explicitly licensed CC0 (public domain equivalent) - verified on the sound's
own page before downloading. The raw preview is kept at
tools/net_src/amsaenz03_net_impact_hq.mp3 for provenance, decoded once to a
matching *.wav (mono 44.1kHz) via:
    ffmpeg -i amsaenz03_net_impact_hq.mp3 -ar 44100 -ac 1 amsaenz03_net_impact_hq.wav
This script only needs that decoded wav and the stdlib - no ffmpeg/network
needed to re-run it.

The source is ~5.4s of court recording with several events in it; the sharp
transient at ~1.58s followed by a distinctive rattling decay (the net
strings buzzing) is the clearest net-impact moment, found via short-time RMS
envelope inspection.
"""
import os
import struct
import wave

SRC_WAV = os.path.join(os.path.dirname(__file__), "net_src", "amsaenz03_net_impact_hq.wav")
OUT_PATH = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx", "net_hit.wav")

ONSET_APPROX_S = 1.575
PRE_ROLL_MS = 4
CLIP_DUR_MS = 350
FADE_OUT_MS = 60
FADE_IN_MS = 1
PEAK_TARGET = 0.85


def load_samples(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		n = w.getnframes()
		raw = w.readframes(n)
	return struct.unpack("<%dh" % n, raw), sr


def find_onset(samples, sr: int, t_approx: float, search_radius: float = 0.05, thresh: int = 1000) -> int:
	i_center = int(t_approx * sr)
	i0 = max(0, i_center - int(search_radius * sr))
	i1 = min(len(samples), i_center + int(search_radius * sr))
	for i in range(i0, i1):
		if abs(samples[i]) > thresh:
			return i
	return i_center


def main() -> None:
	samples, sr = load_samples(SRC_WAV)
	onset = find_onset(samples, sr, ONSET_APPROX_S)
	start = max(0, onset - int(PRE_ROLL_MS / 1000 * sr))
	length = int(CLIP_DUR_MS / 1000 * sr)
	seg = [float(s) for s in samples[start:start + length]]
	if len(seg) < length:
		seg += [0.0] * (length - len(seg))

	peak = max(1.0, max(abs(s) for s in seg))
	scale = min(1.0, (PEAK_TARGET * 32767) / peak)
	seg = [s * scale for s in seg]

	fade_in_n = int(FADE_IN_MS / 1000 * sr)
	fade_out_n = int(FADE_OUT_MS / 1000 * sr)
	for i in range(min(fade_in_n, len(seg))):
		seg[i] *= i / fade_in_n
	for i in range(min(fade_out_n, len(seg))):
		idx = len(seg) - 1 - i
		seg[idx] *= i / fade_out_n

	os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
	frames = bytearray()
	for s in seg:
		v = int(max(-32768, min(32767, s)))
		frames += struct.pack("<h", v)
	with wave.open(OUT_PATH, "wb") as f:
		f.setnchannels(1)
		f.setsampwidth(2)
		f.setframerate(sr)
		f.writeframes(bytes(frames))
	print(f"wrote {OUT_PATH} ({len(seg) / sr * 1000:.0f}ms)")


if __name__ == "__main__":
	main()
