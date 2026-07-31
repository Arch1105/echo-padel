"""Extracts 18 more "song genre" emotes for the store - by far the biggest
batch yet (see tools/generate_emotes.py through _6.py for the general
approach). Two of these (kpop_wave, rnb_smooth) were the user's own picks;
the other 16 are assistant's discretion, chosen to cover a wide spread of
genres not already represented in the catalog (see Emotes.gd's CATALOG for
what's already there: afro_pop, hip_hop, eastern_folk_dance, uk_drill,
latin_party, reggae_vibes, pirate_shanty, country_twang, disco_groove, etc.)

Sourced audio, all Freesound.org, all explicitly licensed CC0 (verified on
each sound's own page before downloading):
  - kpop_wave: "Digital dreams 120 BPM D Minor" by Bangerloops
  - rnb_smooth: "RnB 120 bpm.wav" by BaDoink
  - jazz_lounge: "Smooth Jazz 120 BPM.wav" by BaDoink
  - classical_strings: "Song of Angels in the Snow..." by szegvari
  - blues_riff: "Blue Sloop.wav" by BaDoink
  - funk_fever: "Rockin Rhythm B7 ~ Funk.wav" by BaDoink
  - rock_riff: "Flux Rocker.wav" by BaDoink
  - edm_pulse: "Formant 130.wav" by BaDoink
  - metal_riff: "Synth Metal Rock Loop.wav" by furbyguy
  - flamenco_fire: "buleria_guitar.wav" by miguelgc96
  - soul_groove: "Soul Beat" by Seth_Makes_Sounds
  - polka_party: "crazy accordions loop" by LagMusics
  - techno_pulse: "Techno 120 E.wav" by BaDoink
  - punk_energy: "Punk_Rock_Short31.wav" by bainmack
  - house_beat: "Club House Beat SFX.wav" by BaDoink
  - dubstep_wobble: "DubDonk120a.wav" by BaDoink
  - arabian_nights: "Primitive Snake Charmer Melody" by simonjsounds
  - waltz_ballroom: "Orchestral Waltz.wav" by dominictreis

BaDoink alone accounts for 9 of these - an extremely prolific CC0
contributor (1300+ uploads) whose tracks have checked out CC0 every time
across this and earlier batches, covering a huge genre spread consistently
at clean BPMs.

Raw sourced previews/decoded wavs kept at tools/online_music_src/*.{mp3,wav}
for provenance, decoded via:
    ffmpeg -i <name>.mp3 -ar 44100 -ac 2 <name>.wav

Run: python tools/generate_emotes_7.py
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


# (output emote id, source wav filename, trim start seconds, trim length seconds)
TRACKS = [
	("kpop_wave", "bangerloops_digital_dreams_hq.wav", 2.0, 4.0),
	("rnb_smooth", "badoink_rnb_120_hq.wav", 5.0, 4.0),
	("jazz_lounge", "badoink_smooth_jazz_120_hq.wav", 5.0, 4.5),
	("classical_strings", "szegvari_angels_snow_hq.wav", 10.0, 4.5),
	("blues_riff", "badoink_blue_sloop_hq.wav", 5.0, 4.0),
	("funk_fever", "badoink_rockin_rhythm_funk_hq.wav", 5.0, 4.0),
	("rock_riff", "badoink_flux_rocker_hq.wav", 5.0, 4.0),
	("edm_pulse", "badoink_formant_130_hq.wav", 5.0, 4.0),
	("metal_riff", "furbyguy_synth_metal_rock_hq.wav", 2.0, 4.0),
	("flamenco_fire", "miguelgc96_buleria_guitar_hq.wav", 0.0, 4.0),
	("soul_groove", "seth_soul_beat_hq.wav", 10.0, 4.0),
	("polka_party", "lagmusics_crazy_accordions_hq.wav", 5.0, 4.0),
	("techno_pulse", "badoink_techno_120e_hq.wav", 5.0, 4.0),
	("punk_energy", "bainmack_punk_rock_short31_hq.wav", 5.0, 4.0),
	("house_beat", "badoink_club_house_beat_hq.wav", 15.0, 4.0),
	("dubstep_wobble", "badoink_dubdonk120a_hq.wav", 0.5, 4.0),
	("arabian_nights", "simonjsounds_snake_charmer_hq.wav", 0.0, 4.5),
	("waltz_ballroom", "dominictreis_orchestral_waltz_hq.wav", 3.0, 4.5),
]


def main() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)
	sr, ch = 44100, 2
	for emote_id, src_name, start_s, length_s in TRACKS:
		samples, ssr, sch = load_stereo(os.path.join(SRC_DIR, src_name))
		samples = to_stereo(samples, sch)
		samples = trim(samples, ch, sr, start_s, length_s)
		samples = fade(normalize(samples), ch, sr)
		write_wav(os.path.join(OUT_DIR, f"{emote_id}.wav"), samples, sr, ch)
	print("Done.")


if __name__ == "__main__":
	main()
