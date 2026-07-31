"""Extracts two more "song genre" emotes for the store (see
tools/generate_emotes.py through _5.py for the general approach - this one
follows the same pattern, just no TTS lines this time).

Sourced audio, both Freesound.org, both explicitly licensed CC0 (verified on
each sound's own page before downloading):
  - "country_twang": "Banjo in country samples" by Vladies
    https://freesound.org/people/Vladies/sounds/761691/
    a short country composition (flute, banjo, deep bass) - trimmed to its
    liveliest banjo section.
  - "disco_groove": "Disco funk loops 001 remix 1 long loop with drums
    120 bpm" by josefpres - https://freesound.org/people/josefpres/sounds/567959/
    a long (2:08) disco/funk loop pack - trimmed to one clean groove section.

Raw sourced previews/decoded wavs kept at tools/online_music_src/*.{mp3,wav}
for provenance, decoded via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 2 <name>.wav

Run: python tools/generate_emotes_6.py
"""
import os
import struct
import wave

TOOLS_DIR = os.path.dirname(__file__)
SRC_DIR = os.path.join(TOOLS_DIR, "online_music_src")
OUT_DIR = os.path.join(TOOLS_DIR, "..", "audio", "emotes")

FADE_IN_MS = 15
FADE_OUT_MS = 180
PEAK_TARGET = 0.85


def load_stereo(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		ch = w.getnchannels()
		n = w.getnframes()
		raw = w.readframes(n)
	samples = list(struct.unpack("<%dh" % (n * ch), raw))
	return samples, sr, ch


def to_stereo(samples, ch: int) -> list[float]:
	if ch == 2:
		return [float(s) for s in samples]
	out = []
	for s in samples:
		out.append(float(s))
		out.append(float(s))
	return out


def trim(seg: list[float], ch: int, sr: int, start_s: float, length_s: float) -> list[float]:
	start = int(start_s * sr) * ch
	end = start + int(length_s * sr) * ch
	return seg[start:min(end, len(seg))]


def fade(seg: list[float], ch: int, sr: int) -> list[float]:
	frames = len(seg) // ch
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


def normalize(seg: list[float]) -> list[float]:
	peak = max(1.0, max(abs(s) for s in seg))
	scale = (PEAK_TARGET * 32767) / peak
	return [s * scale for s in seg]


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
	sr, ch = 44100, 2

	# --- country_twang: most of the short (16.8s) CC0 country composition,
	# skipping a brief lead-in ---
	country, csr, cch = load_stereo(os.path.join(SRC_DIR, "vladies_banjo_country_hq.wav"))
	country = to_stereo(country, cch)
	country = trim(country, ch, sr, 0.6, 4.0)
	country = fade(normalize(country), ch, sr)
	write_wav(os.path.join(OUT_DIR, "country_twang.wav"), country, sr, ch)

	# --- disco_groove: a clean section well into the CC0 disco/funk loop,
	# past any intro/count-in ---
	disco, dsr, dch = load_stereo(os.path.join(SRC_DIR, "josefpres_disco_funk_hq.wav"))
	disco = to_stereo(disco, dch)
	disco = trim(disco, ch, sr, 8.0, 4.0)
	disco = fade(normalize(disco), ch, sr)
	write_wav(os.path.join(OUT_DIR, "disco_groove.wav"), disco, sr, ch)

	print("Done.")


if __name__ == "__main__":
	main()
