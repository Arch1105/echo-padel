"""Extracts/synthesizes seven more "emote" celebration clips for the store
(see tools/generate_emotes.py and tools/generate_emotes_2.py for the first
nine and the general approach - this batch follows the same pattern).

Sourced audio, all Freesound.org, all explicitly licensed CC0 (verified on
each sound's own page before downloading):
  - "champions_taunt": "Success Fanfare Trumpets.mp3" by FunWithSound
    https://freesound.org/people/FunWithSound/sounds/456966/
    (an original triumphant-anthem-style fanfare, NOT a cover/sample of any
    copyrighted commercial song) mixed with a synthesized "You lose! You
    lose!" voice line (edge-tts) layered over the top.
  - "sad_trombone": "wah wah sad trombone.wav" by kirbydx
    https://freesound.org/people/kirbydx/sounds/175409/
  - "mic_drop": "Mic Drop.wav" by sidequesting
    https://freesound.org/people/sidequesting/sounds/541545/
    combined with a synthesized "Mic. Drop." voice line right before the
    actual drop sound.

The rest are pure edge-tts voice lines (same engine as tools/
generate_voice_en.py, en-US-GuyNeural), each with its own rate/pitch
treatment for a distinct character - no additional sourced audio:
  - "why_so_serious": pitched up for a goofy delivery, same asetrate/atempo
    trick tools/generate_emotes_2.py used for "silly_voice".
  - "ping_pong_taunt": "This isn't like ping pong!" - a confident, punchy
    taunt delivery. NOTE: the original request described this line "in a
    Chinese accent" ("pigpork" in the request was almost certainly a
    dictation mis-transcription of "ping pong", matching this project's
    established pattern of transcription artifacts - see e.g. "Korea" for
    "Career" earlier in this project). Deliberately NOT implemented as a
    mock ethnic accent impression, which reads as an ethnic stereotype
    regardless of intent - just a normal, energetic taunt read instead. If
    "pigpork" meant something else entirely, that's an easy follow-up.
  - "too_easy_tease": "Ooh... too easy." - slower, lower-pitched, smooth
    delivery.
  - "game_over_trailer": "Game... over." - slow, deep, movie-trailer-style
    delivery.

Raw sourced previews/decoded wavs kept at tools/online_music_src/*.{mp3,wav}
for provenance, decoded via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 2 <name>.wav
This script regenerates the edge-tts lines itself (needs internet + `pip
install edge-tts`) and mixes everything via the bundled ffmpeg binary plus
the stdlib for trimming/normalizing, same division of labor as the rest of
this project's audio tooling.

Run: python tools/generate_emotes_3.py
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
	("you_lose_taunt_tts", "You lose! You lose!", "+10%", "+15Hz"),
	("why_so_serious_tts", "Why so serious?", "+0%", "+0Hz"),
	("ping_pong_taunt", "This isn't like ping pong!", "+12%", "+10Hz"),
	("mic_drop_tts", "Mic. Drop.", "-10%", "-10Hz"),
	("too_easy_tease", "Ooh... too easy.", "-15%", "-25Hz"),
	("game_over_trailer", "Game... over.", "-25%", "-40Hz"),
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


def mix(a: list[float], b: list[float], b_offset_frames: int, ch: int) -> list[float]:
	"""Additively mixes b into a, starting b at b_offset_frames into a -
	result is at least as long as whichever extends further."""
	needed = max(len(a), b_offset_frames * ch + len(b))
	out = list(a) + [0.0] * (needed - len(a))
	for i in range(len(b)):
		out[b_offset_frames * ch + i] += b[i]
	return out


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

	# why_so_serious: pitch up for a goofy delivery, same recipe as
	# generate_emotes_2.py's silly_voice.
	pitch_shift(
		os.path.join(SRC_DIR, "why_so_serious_tts.wav"),
		os.path.join(SRC_DIR, "why_so_serious_pitched.wav"),
		1.22,
	)

	sr, ch = 44100, 2

	# --- champions_taunt: fanfare's punchy opening + taunt VO layered in ---
	fanfare, fsr, fch = load_stereo(os.path.join(SRC_DIR, "funwithsound_success_fanfare_hq.wav"))
	fanfare = to_stereo(fanfare, fch)[: int(1.9 * fsr) * 2]
	taunt, tsr, tch = load_stereo(os.path.join(SRC_DIR, "you_lose_taunt_tts.wav"))
	taunt = to_stereo(taunt, tch)
	taunt = [s * 0.9 for s in taunt]  # sit slightly under the fanfare's own peak
	combined = mix(fanfare, taunt, int(0.35 * sr), ch)
	combined = normalize(combined)
	combined = fade(combined, ch, sr)
	write_wav(os.path.join(OUT_DIR, "champions_taunt.wav"), combined, sr, ch)

	# --- why_so_serious: pure pitched TTS ---
	seg, ssr, sch = load_stereo(os.path.join(SRC_DIR, "why_so_serious_pitched.wav"))
	seg = to_stereo(seg, sch)
	seg = fade(normalize(seg), ch, sr)
	write_wav(os.path.join(OUT_DIR, "why_so_serious.wav"), seg, sr, ch)

	# --- ping_pong_taunt: pure TTS, no pitch tricks ---
	seg, ssr, sch = load_stereo(os.path.join(SRC_DIR, "ping_pong_taunt.wav"))
	seg = to_stereo(seg, sch)
	seg = fade(normalize(seg), ch, sr)
	write_wav(os.path.join(OUT_DIR, "ping_pong_taunt.wav"), seg, sr, ch)

	# --- mic_drop: "Mic. Drop." VO, the actual drop thud right after ---
	vo, vsr, vch = load_stereo(os.path.join(SRC_DIR, "mic_drop_tts.wav"))
	vo = to_stereo(vo, vch)
	thud, thsr, thch = load_stereo(os.path.join(SRC_DIR, "sidequesting_mic_drop_hq.wav"))
	thud = to_stereo(thud, thch)
	vo_frames = len(vo) // ch
	combined = list(vo) + [0.0] * (int(0.05 * sr) * ch) + thud
	combined = fade(normalize(combined), ch, sr)
	write_wav(os.path.join(OUT_DIR, "mic_drop.wav"), combined, sr, ch)

	# --- too_easy_tease: pure TTS, slow/low ---
	seg, ssr, sch = load_stereo(os.path.join(SRC_DIR, "too_easy_tease.wav"))
	seg = to_stereo(seg, sch)
	seg = fade(normalize(seg), ch, sr)
	write_wav(os.path.join(OUT_DIR, "too_easy_tease.wav"), seg, sr, ch)

	# --- game_over_trailer: pure TTS, slow/deep ---
	seg, ssr, sch = load_stereo(os.path.join(SRC_DIR, "game_over_trailer.wav"))
	seg = to_stereo(seg, sch)
	seg = fade(normalize(seg), ch, sr)
	write_wav(os.path.join(OUT_DIR, "game_over_trailer.wav"), seg, sr, ch)

	# --- sad_trombone: trim the CC0 source's best window - the raw source
	# runs 5.2s including a long fading tail after the actual "womp womp"
	# phrase, longer than this batch's other clips, so cap it to match pace.
	seg, ssr, sch = load_stereo(os.path.join(SRC_DIR, "kirbydx_sad_trombone_hq.wav"))
	seg = to_stereo(seg, sch)[: int(3.2 * sr) * ch]
	seg = fade(normalize(seg), ch, sr)
	write_wav(os.path.join(OUT_DIR, "sad_trombone.wav"), seg, sr, ch)

	print("Done.")


if __name__ == "__main__":
	main()
