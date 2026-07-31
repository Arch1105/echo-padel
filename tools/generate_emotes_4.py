"""Extracts/synthesizes four more "emote" celebration clips for the store
(see tools/generate_emotes.py, _2.py, and _3.py for the earlier batches and
the general approach - this one follows the same pattern).

Sourced audio, all Freesound.org, all explicitly licensed CC0 (verified on
each sound's own page before downloading):
  - "gg_chime": "Achievement Happy Beeps Jingle" by CogFireStudios
    https://freesound.org/people/CogFireStudios/sounds/619838/
    followed by a synthesized "Good game!" voice line (edge-tts).
  - "sarcastic_clap": "golfclap.aif" by mattheos
    https://freesound.org/people/mattheos/sounds/116769/
    ("a classic golf clap... three people clapping, clearly unimpressed" -
    the source's own description) - trimmed to its clapping section.
  - "record_scratch": "Record Scratch #6" by musicvision31
    https://freesound.org/people/musicvision31/sounds/431779/
    followed by a synthesized "...and that happened." voice line, for the
    classic "record scratch, freeze frame" meme beat.

The fourth is a pure edge-tts voice line (same engine as tools/
generate_voice_en.py, en-US-GuyNeural), pitched *down* this time (unlike
generate_emotes_3.py's goofy pitch-up treatments) for a deeper, more
robotic/dramatic character - no additional sourced audio:
  - "robot_target": "Target... eliminated." - same asetrate/atempo pitch
    trick as the rest of this project's pitch-shifted clips, just with a
    factor below 1.0 instead of above it.

Raw sourced previews/decoded wavs kept at tools/online_music_src/*.{mp3,wav}
for provenance, decoded via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 2 <name>.wav
This script regenerates the edge-tts lines itself (needs internet + `pip
install edge-tts`) and mixes everything via the bundled ffmpeg binary plus
the stdlib for trimming/normalizing, same division of labor as the rest of
this project's audio tooling.

Run: python tools/generate_emotes_4.py
"""
import asyncio
import os
import struct
import subprocess
import wave

TOOLS_DIR = os.path.dirname(__file__)
SRC_DIR = os.path.join(TOOLS_DIR, "online_music_src")
OUT_DIR = os.path.join(TOOLS_DIR, "..", "audio", "emotes")
FFMPEG = r"C:\Users\user\AppData\Roaming\Python\Python312\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"
VOICE = "en-US-GuyNeural"

FADE_IN_MS = 15
FADE_OUT_MS = 180
PEAK_TARGET = 0.85

# (output key, text, rate, pitch)
TTS_LINES = [
	("gg_chime_tts", "Good game!", "+5%", "+5Hz"),
	("record_scratch_tts", "...and that happened.", "-5%", "-5Hz"),
	("robot_target_tts", "Target... eliminated.", "-10%", "-10Hz"),
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


def main() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)

	print("Generating TTS lines (needs internet)...")
	asyncio.run(generate_tts())
	for key, *_ in TTS_LINES:
		to_wav(os.path.join(SRC_DIR, f"{key}.mp3"), os.path.join(SRC_DIR, f"{key}.wav"))

	pitch_shift(
		os.path.join(SRC_DIR, "robot_target_tts.wav"),
		os.path.join(SRC_DIR, "robot_target_pitched.wav"),
		0.82,
	)

	sr, ch = 44100, 2

	# --- gg_chime: achievement jingle, then "Good game!" ---
	jingle, jsr, jch = load_stereo(os.path.join(SRC_DIR, "cogfirestudios_achievement_hq.wav"))
	jingle = to_stereo(jingle, jch)
	vo, vsr, vch = load_stereo(os.path.join(SRC_DIR, "gg_chime_tts.wav"))
	vo = to_stereo(vo, vch)
	combined = concat(jingle, 120.0, vo, sr, ch)
	combined = fade(normalize(combined), ch, sr)
	write_wav(os.path.join(OUT_DIR, "gg_chime.wav"), combined, sr, ch)

	# --- sarcastic_clap: trim the CC0 golf-clap source to its clapping
	# section - the raw 18s file has some lead-in before the clapping
	# actually starts and keeps going well past what a ~3s emote needs.
	clap, csr, cch = load_stereo(os.path.join(SRC_DIR, "mattheos_golf_clap_hq.wav"))
	clap = to_stereo(clap, cch)
	start = int(1.0 * sr) * ch
	end = start + int(3.5 * sr) * ch
	clap = clap[start:end]
	clap = fade(normalize(clap), ch, sr)
	write_wav(os.path.join(OUT_DIR, "sarcastic_clap.wav"), clap, sr, ch)

	# --- record_scratch: the CC0 scratch, then "...and that happened." ---
	scratch, scsr, scch = load_stereo(os.path.join(SRC_DIR, "musicvision31_record_scratch_hq.wav"))
	scratch = to_stereo(scratch, scch)
	vo2, v2sr, v2ch = load_stereo(os.path.join(SRC_DIR, "record_scratch_tts.wav"))
	vo2 = to_stereo(vo2, v2ch)
	combined2 = concat(scratch, 80.0, vo2, sr, ch)
	combined2 = fade(normalize(combined2), ch, sr)
	write_wav(os.path.join(OUT_DIR, "record_scratch.wav"), combined2, sr, ch)

	# --- robot_target: pure pitched-down TTS ---
	seg, ssr, sch = load_stereo(os.path.join(SRC_DIR, "robot_target_pitched.wav"))
	seg = to_stereo(seg, sch)
	seg = fade(normalize(seg), ch, sr)
	write_wav(os.path.join(OUT_DIR, "robot_target.wav"), seg, sr, ch)

	print("Done.")


if __name__ == "__main__":
	main()
