"""Extracts six more 3-second "emote" celebration clips (see
tools/generate_emotes.py for the first three and the general approach).

Sources, all Freesound.org, all explicitly licensed CC0 (verified on each
sound's own page before downloading) - none are covers of any copyrighted
commercial song:
  - "silly_voice": synthesized via edge-tts (en-US-GuyNeural, the same voice
    already used for the announcer - see tools/generate_voice_en.py) saying
    "That's funny!" three times, then pitch-shifted up (ffmpeg asetrate/
    atempo) for a goofier, more "silly" character than a plain TTS reading.
  - "uk_drill": "Karma | UK Drill Instrumental" by kontraamusic
    https://freesound.org/people/kontraamusic/sounds/788432/
  - "villain_laugh": "Evil Laugh MUAHAHA.wav" by WannyManny
    https://freesound.org/people/WannyManny/sounds/626796/
  - "chiptune_victory": "WinSquare.wav" by Fupicat
    https://freesound.org/people/Fupicat/sounds/527650/
  - "airhorn_hype": "Airhorn" by jacksonacademyashmore
    https://freesound.org/people/jacksonacademyashmore/sounds/414208/
    Only ~1.6s on its own, so this one is a double-honk (the clip repeated
    twice with a short gap) rather than a single extracted window, to fill
    the full 3 seconds with something that still reads as a deliberate hype
    cue rather than a stretched/looped single blast.
  - "latin_party": "DrumJam Latin Surround" by szegvari
    https://freesound.org/people/szegvari/sounds/641568/ (downmixed from its
    original 6-channel surround master to stereo via ffmpeg -ac 2, same as
    every other source here)

Raw previews/decoded wavs kept at tools/online_music_src/*.{mp3,wav} for
provenance, decoded via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 2 <name>.wav
The silly_voice pitch-up was applied once via:
    ffmpeg -i silly_voice_tts.wav -af "asetrate=44100*1.28,aresample=44100,atempo=1/1.28" -ar 44100 -ac 2 silly_voice_pitched.wav
This script only needs those decoded wavs and the stdlib - no ffmpeg/network
needed to re-run it.
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
SIMPLE_SOURCES = [
	("silly_voice_pitched.wav", 0.0, "silly_voice.wav"),
	("kontraamusic_karma_drill_hq.wav", 28.75, "uk_drill.wav"),
	("wannymanny_evil_laugh_hq.wav", 0.75, "villain_laugh.wav"),
	("fupicat_winsquare_hq.wav", 0.0, "chiptune_victory.wav"),
	("szegvari_latin_drumjam_hq.wav", 1.5, "latin_party.wav"),
]

AIRHORN_SRC = "jacksonacademyashmore_airhorn_hq.wav"
AIRHORN_OUT = "airhorn_hype.wav"
AIRHORN_GAP_MS = 120


def load_stereo(path: str):
	with wave.open(path, "rb") as w:
		sr = w.getframerate()
		ch = w.getnchannels()
		n = w.getnframes()
		raw = w.readframes(n)
	samples = struct.unpack("<%dh" % (n * ch), raw)
	return samples, sr, ch


def normalize_and_fade(seg: list[float], ch: int, sr: int) -> list[float]:
	peak = max(1, max(abs(s) for s in seg))
	scale = (PEAK_TARGET * 32767) / peak
	seg = [s * scale for s in seg]
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


def extract_clip(samples, sr: int, ch: int, start_s: float) -> list[float]:
	start = int(start_s * sr) * ch
	length = int(CLIP_DUR_S * sr) * ch
	seg = list(samples[start:start + length])
	if len(seg) < length:
		seg += [0] * (length - len(seg))
	return normalize_and_fade(seg, ch, sr)


def build_airhorn(samples, sr: int, ch: int) -> list[float]:
	gap = [0] * (int(AIRHORN_GAP_MS / 1000 * sr) * ch)
	honk = list(samples)
	combined = honk + gap + honk
	target_len = int(CLIP_DUR_S * sr) * ch
	if len(combined) < target_len:
		combined += [0] * (target_len - len(combined))
	else:
		combined = combined[:target_len]
	return normalize_and_fade(combined, ch, sr)


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
	for filename, start_s, out_name in SIMPLE_SOURCES:
		samples, sr, ch = load_stereo(os.path.join(SRC_DIR, filename))
		clip = extract_clip(samples, sr, ch, start_s)
		write_wav(os.path.join(OUT_DIR, out_name), clip, sr, ch)

	samples, sr, ch = load_stereo(os.path.join(SRC_DIR, AIRHORN_SRC))
	clip = build_airhorn(samples, sr, ch)
	write_wav(os.path.join(OUT_DIR, AIRHORN_OUT), clip, sr, ch)

	print("Done.")


if __name__ == "__main__":
	main()
