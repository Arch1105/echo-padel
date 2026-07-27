"""Prepares the menu/pause background music track for looping.

Source: "Cuban Ensemble Mood Style Happy Band Dance Cinematic Music 120Bpm"
by szegvari, Freesound.org - https://freesound.org/people/szegvari/sounds/619557/
Explicitly licensed CC0 (public domain equivalent) - verified on the sound's
own page before downloading. This is an ORIGINAL instrumental composition,
not a cover/instrumental of any copyrighted commercial song - covers of
famous songs (even instrumental-only) remain protected by the underlying
composition copyright and would need an actual sync/mechanical license,
which isn't something free or available to just download.

The raw preview is kept at tools/music_src/szegvari_cuban_ensemble_hq.mp3
for provenance, decoded once to tools/music_src/full.wav (stereo 44.1kHz)
via:
    ffmpeg -i szegvari_cuban_ensemble_hq.mp3 -ar 44100 -ac 2 full.wav
This script only needs that decoded wav and the stdlib - no ffmpeg/network
needed to re-run it.

Trims the near-silent trailing tail and applies short fades at both ends so
looping (Music.gd sets AudioStreamMP3.loop = true) doesn't click at the
seam - the track wasn't specifically produced to loop, so this is a
reasonable, not a perfectly beat-matched, loop point.
"""
import os
import struct
import wave

SRC_WAV = os.path.join(os.path.dirname(__file__), "music_src", "full.wav")
OUT_WAV = os.path.join(os.path.dirname(__file__), "music_src", "menu_music_trimmed.wav")

TRIM_END_MS = 300
FADE_IN_MS = 80
FADE_OUT_MS = 300


def main() -> None:
	with wave.open(SRC_WAV, "rb") as w:
		sr = w.getframerate()
		ch = w.getnchannels()
		n = w.getnframes()
		raw = w.readframes(n)

	samples = struct.unpack("<%dh" % (n * ch), raw)
	trim_end_n = int(TRIM_END_MS / 1000 * sr)
	total_frames = n - trim_end_n
	frames = [list(samples[i * ch:i * ch + ch]) for i in range(total_frames)]

	fade_in_n = int(FADE_IN_MS / 1000 * sr)
	fade_out_n = int(FADE_OUT_MS / 1000 * sr)
	for i in range(min(fade_in_n, len(frames))):
		mult = i / fade_in_n
		frames[i] = [s * mult for s in frames[i]]
	for i in range(min(fade_out_n, len(frames))):
		idx = len(frames) - 1 - i
		mult = i / fade_out_n
		frames[idx] = [s * mult for s in frames[idx]]

	out_samples = []
	for frame in frames:
		for s in frame:
			out_samples.append(int(max(-32768, min(32767, s))))

	with wave.open(OUT_WAV, "wb") as f:
		f.setnchannels(ch)
		f.setsampwidth(2)
		f.setframerate(sr)
		f.writeframes(struct.pack("<%dh" % len(out_samples), *out_samples))
	print(f"wrote {OUT_WAV} ({total_frames / sr:.2f}s)")


if __name__ == "__main__":
	main()
