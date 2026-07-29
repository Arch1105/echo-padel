"""Extracts three 3-second "emote" celebration clips for Echo Padel's LAN-
only coin/store system (see OnlineData.gd, EmoteMenu.gd) - each a short,
energetic snippet of a real CC0 track, not a full song, since these only
ever play for 3 seconds after a point/set/match win.

Source recordings, all Freesound.org, all explicitly licensed CC0 (verified
on each sound's own page before downloading) - none are covers of any
copyrighted commercial song, all original compositions:
  - "afro_pop": "Kemet | Afro Instrumental" by kontraamusic
    https://freesound.org/people/kontraamusic/sounds/788623/
  - "hip_hop": "Moonwalk (trap sample)" by Tery1031
    https://freesound.org/people/Tery1031/sounds/747451/
  - "eastern_folk_dance": "Village Wedding" by code_box
    https://freesound.org/people/code_box/sounds/522620/
    Requested as "Romanian traditional dance music" specifically - Freesound
    turned up nothing tagged Romanian under CC0, so this (an energetic
    Eastern European/klezmer wedding-dance piece, the closest available
    match in the same regional folk-dance tradition) was used instead. Not
    a literal substitute, flagged here for the record.

Raw previews kept at tools/online_music_src/*.mp3 for provenance, each
decoded once to a matching *.wav (stereo 44.1kHz) via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 2 <name>.wav
This script only needs those decoded wavs and the stdlib - no ffmpeg/network
needed to re-run it. Extraction windows (where in each source the 3-second
clip starts) were picked by scanning for the loudest/most energetic 3-second
window in each source file.
"""
import os
import struct
import wave

SRC_DIR = os.path.join(os.path.dirname(__file__), "online_music_src")
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "emotes")

CLIP_DUR_S = 3.0
FADE_IN_MS = 30
FADE_OUT_MS = 180
PEAK_TARGET = 0.85

# (source wav filename, clip start in seconds, output filename)
SOURCES = [
	("kontraamusic_kemet_afro_hq.wav", 16.0, "afro_pop.wav"),
	("tery1031_moonwalk_trap_hq.wav", 10.0, "hip_hop.wav"),
	("code_box_village_wedding_hq.wav", 17.5, "eastern_folk_dance.wav"),
]


def load_stereo(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		ch = w.getnchannels()
		n = w.getnframes()
		raw = w.readframes(n)
	samples = struct.unpack("<%dh" % (n * ch), raw)
	return samples, sr, ch


def extract_clip(samples, sr: int, ch: int, start_s: float) -> list[int]:
	start = int(start_s * sr) * ch
	length = int(CLIP_DUR_S * sr) * ch
	seg = list(samples[start:start + length])
	if len(seg) < length:
		seg += [0] * (length - len(seg))

	peak = max(1, max(abs(s) for s in seg))
	scale = (PEAK_TARGET * 32767) / peak
	seg = [s * scale for s in seg]

	frames = length // ch
	fade_in_n = int(FADE_IN_MS / 1000 * sr)
	fade_out_n = int(FADE_OUT_MS / 1000 * sr)
	for i in range(min(fade_in_n, frames)):
		mult = i / fade_in_n
		for c in range(ch):
			seg[i * ch + c] *= mult
	for i in range(min(fade_out_n, frames)):
		idx = frames - 1 - i
		mult = i / fade_out_n
		for c in range(ch):
			seg[idx * ch + c] *= mult
	return seg


def write_wav(path: str, samples: list[float], sr: int, ch: int) -> None:
	frames = bytearray()
	for s in samples:
		v = int(max(-32768, min(32767, s)))
		frames += struct.pack("<h", v)
	with wave.open(path, "wb") as f:
		f.setnchannels(ch)
		f.setsampwidth(2)
		f.setframerate(sr)
		f.writeframes(bytes(frames))
	print(f"wrote {path} ({len(samples) / ch / sr * 1000:.0f}ms)")


def main() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)
	for filename, start_s, out_name in SOURCES:
		samples, sr, ch = load_stereo(os.path.join(SRC_DIR, filename))
		clip = extract_clip(samples, sr, ch, start_s)
		write_wav(os.path.join(OUT_DIR, out_name), clip, sr, ch)
	print("Done.")


if __name__ == "__main__":
	main()
