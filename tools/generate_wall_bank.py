"""Builds the sound for a ball banking off the back-wall glass (the
Down/Back+Space wall-bank shot in Ball.gd, see PlayerController.gd) -
previously silent, the reflection just happened with no accompanying sfx.

Layers two real recordings, both Freesound.org, both explicitly licensed CC0
(public domain equivalent) - verified on each sound's own page before
downloading:
  - "Glass Hit" by Ryanz-Official (from the "Metal/Glass" pack) - a tempered
    glass impact, 256ms - https://freesound.org/people/Ryanz-Official/sounds/639745/
  - "Marble Impact" by Ryanz-Official (same pack) - a marble getting struck -
    https://freesound.org/people/Ryanz-Official/sounds/639754/
A glass wall hit by a fast-moving ball has both the glass's own bright
resonant ring (the "Glass Hit" recording, used near-whole - it's already
short and clean) and a rounder, more solid impact thump underneath it (a
short slice of "Marble Impact"'s own first transient, before its "then
dropped" continuation - found via short-time RMS envelope inspection, same
technique used throughout tools/). Raw previews kept at
tools/wall_src/*.mp3, each decoded once to a matching *.wav (mono 44.1kHz)
via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 1 <name>.wav
This script only needs those decoded wavs and the stdlib - no ffmpeg/network
needed to re-run it.
"""
import os
import struct
import wave

SRC_DIR = os.path.join(os.path.dirname(__file__), "wall_src")
OUT_PATH = os.path.join(os.path.dirname(__file__), "..", "audio", "sfx", "wall_bank.wav")

GLASS_WAV = os.path.join(SRC_DIR, "glass_hit.wav")
MARBLE_WAV = os.path.join(SRC_DIR, "marble_impact.wav")

# Marble impact's first hit only (see docstring) - it's a longer recording
# with a "then dropped" second/third bounce further in that we don't want.
MARBLE_START_S = 0.055
MARBLE_END_S = 0.20
MARBLE_MIX_LEVEL = 0.55

CLIP_DUR_MS = 260
FADE_OUT_MS = 90
FADE_IN_MS = 1
PEAK_TARGET = 0.85


def load_samples(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		n = w.getnframes()
		raw = w.readframes(n)
	return [float(s) for s in struct.unpack("<%dh" % n, raw)], sr


def main() -> None:
	glass, sr = load_samples(GLASS_WAV)
	marble, marble_sr = load_samples(MARBLE_WAV)
	assert sr == marble_sr, "source sample rates must match"

	length = int(CLIP_DUR_MS / 1000 * sr)
	seg = glass[:length]
	if len(seg) < length:
		seg += [0.0] * (length - len(seg))

	marble_start_i = int(MARBLE_START_S * sr)
	marble_end_i = int(MARBLE_END_S * sr)
	marble_clip = marble[marble_start_i:marble_end_i]
	for i, s in enumerate(marble_clip):
		if i >= len(seg):
			break
		seg[i] += s * MARBLE_MIX_LEVEL

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
