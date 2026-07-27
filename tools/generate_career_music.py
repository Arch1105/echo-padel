"""Prepares the Career-menu background music track (CareerHub/CareerMenu/
CareerUpgrades - see Music.gd) - separate from the main-menu theme, deliberately
darker and more ominous, since Career mode is where the stakes ("three losses
demotes you a tier") actually live.

Source: "Epic Dark Fantasy" by Daniel Prellball, Freesound.org -
https://freesound.org/people/Daniel%20Prellball/sounds/701688/
Explicitly licensed CC0 (public domain equivalent) - verified on the sound's
own page before downloading. An original orchestral/choral composition (not
a cover or derivative of any specific copyrighted theme) - tagged by its own
creator as dramatic/menacing/sinister, which is the "ominous, devious" mood
asked for without reproducing any actual copyrighted melody (e.g. Halo's).

The raw preview is kept at tools/career_music_src/
daniel_prellball_epic_dark_fantasy_hq.mp3 for provenance, decoded once to
tools/career_music_src/full.wav (stereo 44.1kHz) via:
    ffmpeg -i daniel_prellball_epic_dark_fantasy_hq.mp3 -ar 44100 -ac 2 full.wav
This script only needs that decoded wav and the stdlib - no ffmpeg/network
needed to re-run it.

The track (~103s) doesn't fade out on its own - it just stops mid-phrase -
so a proper fade-out is added here (Music.gd loops it, so an abrupt cut
would click/jar at the loop seam otherwise). A short fade-in smooths the
very first sample too, though the track already has a natural quiet-to-swell
opening in its first ~2 seconds that's kept as-is.
"""
import os
import struct
import wave

SRC_WAV = os.path.join(os.path.dirname(__file__), "career_music_src", "full.wav")
OUT_WAV = os.path.join(os.path.dirname(__file__), "career_music_src", "career_music_trimmed.wav")

FADE_IN_MS = 30
FADE_OUT_MS = 1500


def main() -> None:
	with wave.open(SRC_WAV, "rb") as w:
		sr = w.getframerate()
		ch = w.getnchannels()
		n = w.getnframes()
		raw = w.readframes(n)

	samples = struct.unpack("<%dh" % (n * ch), raw)
	frames = [list(samples[i * ch:i * ch + ch]) for i in range(n)]

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
	print(f"wrote {OUT_WAV} ({n / sr:.2f}s)")


if __name__ == "__main__":
	main()
