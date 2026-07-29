"""Generates spoken English voice-line audio for Echo Padel using edge-tts
instead of the Windows SAPI voices tools/generate_voice.ps1 used - this
machine only has two installed SAPI voices and both are female ("Microsoft
Hazel Desktop", "Microsoft Zira Desktop"), and per feedback the announcer
should sound like a cooler, faster, male voice instead. Same engine/approach
tools/generate_voice_es.py already uses for Spanish (Microsoft Edge's "Read
Aloud" neural TTS service - free, no API key, needs internet only to
generate these files once; the game itself never needs network access at
runtime since the output is committed as static assets).

Writes .wav (not edge-tts's native mp3) to the exact same paths
tools/generate_voice.ps1 used to produce, via the bundled ffmpeg binary, so
Voice.gd's LINES_EN/PHRASES_EN preload paths don't need to change at all.

LINES here is a straight port of tools/generate_voice.ps1's $lines - the two
must stay in sync (same keys, same English text) if either changes; this one
is now the actual source of the shipped clips, generate_voice.ps1 is kept
only as a no-internet-needed fallback path.

Run once (or whenever lines change): python tools/generate_voice_en.py
Requires: pip install edge-tts
"""
import asyncio
import os
import subprocess

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "audio", "voice", "en")
VOICE = "en-US-GuyNeural"
RATE = "+18%"

FFMPEG = r"C:\Users\user\AppData\Roaming\Python\Python312\site-packages\imageio_ffmpeg\binaries\ffmpeg-win-x86_64-v7.1.exe"

LINES = {
	"match_start": "New match. Best of three sets. Your serve.",
	"quick_match_start": "New match. First to seven, win by two.",
	"your_serve": "Your serve.",
	"bot_serve": "Bot serves.",
	"out": "Out.",
	"into_net": "Into the net.",
	"missed": "Not returned.",
	"point_you": "Point, you.",
	"point_bot": "Point, bot.",
	"game_you": "Game, you.",
	"game_bot": "Game, bot.",
	"set_you": "Set, you.",
	"set_bot": "Set, bot.",
	"match_point_you": "Match point, you.",
	"match_point_bot": "Match point, bot.",
	"set_point_you": "Set point, you.",
	"set_point_bot": "Set point, bot.",
	"you_win_match": "You win the match!",
	"bot_wins_match": "Bot wins the match.",
	"deuce": "Deuce.",
	"advantage_you": "Advantage, you.",
	"advantage_bot": "Advantage, bot.",
	"love": "Love.",
	"fifteen": "Fifteen.",
	"thirty": "Thirty.",
	"forty": "Forty.",
	"all": "All.",
	"score_prefix": "Score check.",
	"you_prefix": "You:",
	"bot_prefix": "Bot:",
	"sets_singular": "set,",
	"sets_plural": "sets,",
	"games_singular": "game.",
	"games_plural": "games.",
	"paused": "Paused.",
	"resumed": "Resumed.",
	"training_intro": "Training mode. Balls serve to random tiles on your side. Reach the tile and press Space to return. Escape returns to the menu.",
	"best_streak_prefix": "Best streak:",
	"career_round_won": "Round won! Advancing.",
	"career_round_lost": "You lost this round. Tournament over.",
	"career_champion": "Champion! You won the tournament!",
	"career_promoted": "You're promoted to the next tier!",
	"career_demoted": "Three losses at this tier - you've been dropped down a level.",
	"career_reset_confirm": "This will permanently erase your career. Press Reset Career again within five seconds to confirm.",
	"point_prefix": "Point,",
	"game_prefix": "Game,",
	"set_prefix": "Set,",
	"match_point_prefix": "Match point,",
	"set_point_prefix": "Set point,",
	"advantage_prefix": "Advantage,",
	"serves_suffix": "serves.",
	"wins_match_suffix": "wins the match.",
	"ready_prompt": "Press Enter when ready to serve.",
	"coord_prefix": "Your position:",
	"coord_left": "left,",
	"coord_middle": "middle,",
	"coord_right": "right,",
	"coord_front": "front.",
	"coord_back": "back.",
}

for _i in range(21):
	LINES[f"num_{_i}"] = str(_i)

# Career-mode opponent surnames (see OpponentNames.gd's LAST_NAMES - this
# list must stay in sync with that one) - a small, fixed set, so every
# possible opponent name still has full offline clip fallback.
LAST_NAMES = [
	"Carter", "Bennett", "Hayes", "Mercer", "Ellison", "Whitfield", "Sorensen",
	"Delgado", "Kowalski", "Novak", "Fontaine", "Marsh", "Osei", "Larsson",
	"Vance", "Renwick", "Castillo", "Abernathy", "Nakamura", "Petrov",
]
for _name in LAST_NAMES:
	LINES[f"name_{_name.lower()}"] = _name


async def generate() -> None:
	os.makedirs(OUT_DIR, exist_ok=True)
	import edge_tts
	for key, text in LINES.items():
		mp3_path = os.path.join(OUT_DIR, f"{key}.mp3.tmp")
		wav_path = os.path.join(OUT_DIR, f"{key}.wav")
		communicate = edge_tts.Communicate(text, VOICE, rate=RATE)
		await communicate.save(mp3_path)
		subprocess.run(
			[FFMPEG, "-y", "-i", mp3_path, "-ar", "44100", "-ac", "1", wav_path],
			check=True, capture_output=True,
		)
		os.remove(mp3_path)
		print(f"wrote {wav_path}")
	print("Done.")


if __name__ == "__main__":
	asyncio.run(generate())
