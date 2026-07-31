"""Extracts/synthesizes six more "emote" celebration clips for the store
(see tools/generate_emotes.py, _2.py, _3.py, and _4.py for the earlier
batches and the general approach - this one follows the same pattern).

Sourced audio, all Freesound.org, all explicitly licensed CC0 (verified on
each sound's own page before downloading):
  - "reggae_vibes": "Reggae Loop.wav" by darkzanite (crislostaudio)
    https://freesound.org/people/darkzanite/sounds/202491/
    trimmed to a clean loop-length section.
  - "pirate_shanty": "Pirate band performs 'Drunken Sailor'" by Breviceps
    https://freesound.org/s/516076/
    an actual (amateur, tipsy-sounding, on purpose) sea shanty performance -
    trimmed to its liveliest section.
  - "thunder_strike" (one of the two "surprise" emotes): "Thunderclap" by
    Fission9 - https://freesound.org/people/Fission9/sounds/534023/
    trimmed to the loud crack + the start of its rumble.
  - "level_up" (the other "surprise" emote): "Level Up" by qubodup
    https://freesound.org/people/qubodup/sounds/442943/
    a short chiptune blip, extended with a synthesized rising sparkle tail
    (same stdlib sine-sweep technique as tools/generate_super_smash_impact.py)
    since the source alone is under 2 seconds.

Two pure edge-tts voice lines (same engine/voice as the rest of this
project's voiced emotes, en-US-GuyNeural):
  - "sweaty_line": a crude joke line, pitched *up* the same way
    generate_emotes_2.py's "silly_voice" was, for a goofy comedic delivery.
  - "pirate_joke": the classic "what's a pirate's favorite letter" pun,
    pitched *down* slightly for a gruffer, salty-sea-captain read.

Raw sourced previews/decoded wavs kept at tools/online_music_src/*.{mp3,wav}
for provenance, decoded via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 2 <name>.wav
This script regenerates the edge-tts lines itself (needs internet + `pip
install edge-tts`) and mixes everything via the bundled ffmpeg binary plus
the stdlib for trimming/normalizing/synthesizing, same division of labor as
the rest of this project's audio tooling.

Run: python tools/generate_emotes_5.py
"""
import asyncio
import math
import os
import struct
import subprocess
import wave

TOOLS_DIR = os.path.dirname(__file__)
SRC_DIR = os.path.join(TOOLS_DIR, "online_music_src")
OUT_DIR = os.path.join(TOOLS_DIR, "..", "audio", "emotes")
FFMPEG = r"C:\Users\user\AppData\Roaming\Python\Python312\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"
VOICE = "en-US-GuyNeural"
SR = 44100

FADE_IN_MS = 15
FADE_OUT_MS = 180
PEAK_TARGET = 0.85

# (output key, text, rate, pitch)
TTS_LINES = [
	("sweaty_line_tts", "I have got a sweaty ball sack!", "+0%", "+0Hz"),
	("pirate_joke_tts", "What's a pirate's favorite letter? Arrr!", "+0%", "+0Hz"),
]


async def generate_tts() -> None:
	import edge_tts
	for key, text, rate, pitch in TTS_LINES:
		mp3_path = os.path.join(SRC_DIR, f"{key}.mp3")
		communicate = edge_tts.Communicate(text, VOICE, rate=rate, pitch=pitch)
		await communicate.save(mp3_path)
		print(f"tts: wrote {mp3_path}")


def to_wav(mp3_path: str, wav_path: str) -> None:
	subprocess.run(
		[FFMPEG, "-y", "-i", mp3_path, "-ar", "44100", "-ac", "2", wav_path],
		check=True, capture_output=True,
	)


def pitch_shift(in_wav: str, out_wav: str, factor: float) -> None:
	subprocess.run(
		[FFMPEG, "-y", "-i", in_wav,
			"-af", f"asetrate=44100*{factor},aresample=44100,atempo=1/{factor}",
			"-ar", "44100", "-ac", "2", out_wav],
		check=True, capture_output=True,
	)


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


def concat(a: list[float], gap_ms: float, b: list[float], sr: int, ch: int) -> list[float]:
	gap = [0.0] * (int(gap_ms / 1000 * sr) * ch)
	return a + gap + b


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


# --- synthesized sparkle tail for level_up (stdlib-only, same technique as
# tools/generate_super_smash_impact.py's sine-sweep layers) ---
def sine_sweep(f_start: float, f_end: float, duration: float) -> list[float]:
	n = int(SR * duration)
	out = []
	phase = 0.0
	for i in range(n):
		t = i / n
		freq = f_start + (f_end - f_start) * t
		phase += 2 * math.pi * freq / SR
		out.append(math.sin(phase))
	return out


def env_linear(samples: list[float], attack: float, release: float) -> list[float]:
	n = len(samples)
	a = max(1, int(SR * attack))
	r = max(1, int(SR * release))
	out = list(samples)
	for i in range(min(a, n)):
		out[i] *= i / a
	for i in range(min(r, n)):
		idx = n - 1 - i
		out[idx] *= i / r
	return out


def make_sparkle_mono(duration: float) -> list[float]:
	# Three quick ascending sine chirps, staggered, for a "power-up sparkle"
	# tail that reads as a distinct flourish rather than just noise.
	out = [0.0] * int(SR * duration)
	starts = [0.0, 0.06, 0.12]
	freqs = [(700, 1400), (1000, 2000), (1400, 2800)]
	for start_s, (f0, f1) in zip(starts, freqs):
		chirp = env_linear(sine_sweep(f0, f1, 0.22), 0.005, 0.18)
		offset_n = int(SR * start_s)
		for i, s in enumerate(chirp):
			idx = offset_n + i
			if idx < len(out):
				out[idx] += s * 0.35
	return out


def mono_to_stereo_samples(mono: list[float]) -> list[float]:
	out = []
	for s in mono:
		v = s * 32767.0
		out.append(v)
		out.append(v)
	return out


def main() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)

	print("Generating TTS lines (needs internet)...")
	asyncio.run(generate_tts())
	for key, *_ in TTS_LINES:
		to_wav(os.path.join(SRC_DIR, f"{key}.mp3"), os.path.join(SRC_DIR, f"{key}.wav"))

	pitch_shift(
		os.path.join(SRC_DIR, "sweaty_line_tts.wav"),
		os.path.join(SRC_DIR, "sweaty_line_pitched.wav"),
		1.28,
	)
	pitch_shift(
		os.path.join(SRC_DIR, "pirate_joke_tts.wav"),
		os.path.join(SRC_DIR, "pirate_joke_pitched.wav"),
		0.86,
	)

	sr, ch = 44100, 2

	# --- reggae_vibes: a clean section of the CC0 reggae loop ---
	reggae, rsr, rch = load_stereo(os.path.join(SRC_DIR, "darkzanite_reggae_hq.wav"))
	reggae = to_stereo(reggae, rch)
	reggae = trim(reggae, ch, sr, 3.5, 3.8)
	reggae = fade(normalize(reggae), ch, sr)
	write_wav(os.path.join(OUT_DIR, "reggae_vibes.wav"), reggae, sr, ch)

	# --- pirate_shanty: the liveliest section of the CC0 "Drunken Sailor"
	# performance ---
	shanty, ssr, sch = load_stereo(os.path.join(SRC_DIR, "breviceps_drunken_sailor_hq.wav"))
	shanty = to_stereo(shanty, sch)
	shanty = trim(shanty, ch, sr, 1.0, 4.5)
	shanty = fade(normalize(shanty), ch, sr)
	write_wav(os.path.join(OUT_DIR, "pirate_shanty.wav"), shanty, sr, ch)

	# --- sweaty_line: pure pitched-up TTS, same treatment as silly_voice ---
	seg, _, _ = load_stereo(os.path.join(SRC_DIR, "sweaty_line_pitched.wav"))
	seg = to_stereo(seg, 2)
	seg = fade(normalize(seg), ch, sr)
	write_wav(os.path.join(OUT_DIR, "sweaty_line.wav"), seg, sr, ch)

	# --- pirate_joke: pure pitched-down TTS ---
	seg2, _, _ = load_stereo(os.path.join(SRC_DIR, "pirate_joke_pitched.wav"))
	seg2 = to_stereo(seg2, 2)
	seg2 = fade(normalize(seg2), ch, sr)
	write_wav(os.path.join(OUT_DIR, "pirate_joke.wav"), seg2, sr, ch)

	# --- thunder_strike: the CC0 thunderclap's loud onset + early rumble ---
	thunder, tsr, tch = load_stereo(os.path.join(SRC_DIR, "fission9_thunderclap_hq.wav"))
	thunder = to_stereo(thunder, tch)
	thunder = trim(thunder, ch, sr, 0.0, 3.0)
	thunder = fade(normalize(thunder), ch, sr)
	write_wav(os.path.join(OUT_DIR, "thunder_strike.wav"), thunder, sr, ch)

	# --- level_up: the CC0 chiptune blip, then a synthesized sparkle tail ---
	blip, bsr, bch = load_stereo(os.path.join(SRC_DIR, "qubodup_level_up_hq.wav"))
	blip = to_stereo(blip, bch)
	sparkle = mono_to_stereo_samples(make_sparkle_mono(0.4))
	combined = concat(blip, 20.0, sparkle, sr, ch)
	combined = fade(normalize(combined), ch, sr)
	write_wav(os.path.join(OUT_DIR, "level_up.wav"), combined, sr, ch)

	print("Done.")


if __name__ == "__main__":
	main()
