extends Node
## Global helper for spoken announcements. Every announcement is first
## attempted through the player's own running screen reader (NVDA, via
## bin/NvdaSpeak.exe - a tiny helper that bridges to NVDA's official
## controller client DLL, since GDScript has no native FFI) so it comes out
## in NVDA's own voice/rate/verbosity the player already has tuned. If NVDA
## isn't running, it falls back to the pre-rendered clips (see
## tools/generate_voice_en.py for English, tools/generate_voice_es.py for
## Spanish) so the game is still fully voiced without a screen reader.
##
## Bilingual (English/Spanish) - GameSettings.language picks which of
## LINES_EN/LINES_ES and PHRASES_EN/PHRASES_ES every call below reads from.
## Note: forwarding Spanish text to the player's screen reader only comes out
## correctly if *their* screen reader's active voice is also set to Spanish -
## same as any other TTS-forwarding system, that's on the OS/AT config, not
## something this game can control.
##
## Menu screens don't need anything from here - native Button/OptionButton/
## HSlider controls are read automatically by NVDA/JAWS/Narrator via Godot
## 4.5+'s built-in AccessKit integration, with text supplied by Loc.gd for
## either language (see MainMenu.gd). This is only for match-flow events
## that have no on-screen control to attach to.

const LINES_EN := {
	"match_start": preload("res://audio/voice/en/match_start.wav"),
	"quick_match_start": preload("res://audio/voice/en/quick_match_start.wav"),
	"wall_match_start": preload("res://audio/voice/en/wall_match_start.wav"),
	"super_smash": preload("res://audio/voice/en/super_smash.wav"),
	"your_serve": preload("res://audio/voice/en/your_serve.wav"),
	"bot_serve": preload("res://audio/voice/en/bot_serve.wav"),
	"out": preload("res://audio/voice/en/out.wav"),
	"into_net": preload("res://audio/voice/en/into_net.wav"),
	"missed": preload("res://audio/voice/en/missed.wav"),
	"point_you": preload("res://audio/voice/en/point_you.wav"),
	"point_bot": preload("res://audio/voice/en/point_bot.wav"),
	"game_you": preload("res://audio/voice/en/game_you.wav"),
	"game_bot": preload("res://audio/voice/en/game_bot.wav"),
	"set_you": preload("res://audio/voice/en/set_you.wav"),
	"set_bot": preload("res://audio/voice/en/set_bot.wav"),
	"match_point_you": preload("res://audio/voice/en/match_point_you.wav"),
	"match_point_bot": preload("res://audio/voice/en/match_point_bot.wav"),
	"set_point_you": preload("res://audio/voice/en/set_point_you.wav"),
	"set_point_bot": preload("res://audio/voice/en/set_point_bot.wav"),
	"you_win_match": preload("res://audio/voice/en/you_win_match.wav"),
	"bot_wins_match": preload("res://audio/voice/en/bot_wins_match.wav"),
	"deuce": preload("res://audio/voice/en/deuce.wav"),
	"advantage_you": preload("res://audio/voice/en/advantage_you.wav"),
	"advantage_bot": preload("res://audio/voice/en/advantage_bot.wav"),
	"love": preload("res://audio/voice/en/love.wav"),
	"fifteen": preload("res://audio/voice/en/fifteen.wav"),
	"thirty": preload("res://audio/voice/en/thirty.wav"),
	"forty": preload("res://audio/voice/en/forty.wav"),
	"all": preload("res://audio/voice/en/all.wav"),
	"score_prefix": preload("res://audio/voice/en/score_prefix.wav"),
	"you_prefix": preload("res://audio/voice/en/you_prefix.wav"),
	"bot_prefix": preload("res://audio/voice/en/bot_prefix.wav"),
	"sets_singular": preload("res://audio/voice/en/sets_singular.wav"),
	"sets_plural": preload("res://audio/voice/en/sets_plural.wav"),
	"games_singular": preload("res://audio/voice/en/games_singular.wav"),
	"games_plural": preload("res://audio/voice/en/games_plural.wav"),
	"paused": preload("res://audio/voice/en/paused.wav"),
	"resumed": preload("res://audio/voice/en/resumed.wav"),
	"training_intro": preload("res://audio/voice/en/training_intro.wav"),
	"best_streak_prefix": preload("res://audio/voice/en/best_streak_prefix.wav"),
	"career_round_won": preload("res://audio/voice/en/career_round_won.wav"),
	"career_round_lost": preload("res://audio/voice/en/career_round_lost.wav"),
	"career_champion": preload("res://audio/voice/en/career_champion.wav"),
	"career_promoted": preload("res://audio/voice/en/career_promoted.wav"),
	"career_demoted": preload("res://audio/voice/en/career_demoted.wav"),
	"career_reset_confirm": preload("res://audio/voice/en/career_reset_confirm.wav"),
	"point_prefix": preload("res://audio/voice/en/point_prefix.wav"),
	"game_prefix": preload("res://audio/voice/en/game_prefix.wav"),
	"set_prefix": preload("res://audio/voice/en/set_prefix.wav"),
	"match_point_prefix": preload("res://audio/voice/en/match_point_prefix.wav"),
	"set_point_prefix": preload("res://audio/voice/en/set_point_prefix.wav"),
	"advantage_prefix": preload("res://audio/voice/en/advantage_prefix.wav"),
	"serves_suffix": preload("res://audio/voice/en/serves_suffix.wav"),
	"wins_match_suffix": preload("res://audio/voice/en/wins_match_suffix.wav"),
	"ready_prompt": preload("res://audio/voice/en/ready_prompt.wav"),
	"coord_prefix": preload("res://audio/voice/en/coord_prefix.wav"),
	"coord_left": preload("res://audio/voice/en/coord_left.wav"),
	"coord_middle": preload("res://audio/voice/en/coord_middle.wav"),
	"coord_right": preload("res://audio/voice/en/coord_right.wav"),
	"coord_front": preload("res://audio/voice/en/coord_front.wav"),
	"coord_back": preload("res://audio/voice/en/coord_back.wav"),
	"name_carter": preload("res://audio/voice/en/name_carter.wav"),
	"name_bennett": preload("res://audio/voice/en/name_bennett.wav"),
	"name_hayes": preload("res://audio/voice/en/name_hayes.wav"),
	"name_mercer": preload("res://audio/voice/en/name_mercer.wav"),
	"name_ellison": preload("res://audio/voice/en/name_ellison.wav"),
	"name_whitfield": preload("res://audio/voice/en/name_whitfield.wav"),
	"name_sorensen": preload("res://audio/voice/en/name_sorensen.wav"),
	"name_delgado": preload("res://audio/voice/en/name_delgado.wav"),
	"name_kowalski": preload("res://audio/voice/en/name_kowalski.wav"),
	"name_novak": preload("res://audio/voice/en/name_novak.wav"),
	"name_fontaine": preload("res://audio/voice/en/name_fontaine.wav"),
	"name_marsh": preload("res://audio/voice/en/name_marsh.wav"),
	"name_osei": preload("res://audio/voice/en/name_osei.wav"),
	"name_larsson": preload("res://audio/voice/en/name_larsson.wav"),
	"name_vance": preload("res://audio/voice/en/name_vance.wav"),
	"name_renwick": preload("res://audio/voice/en/name_renwick.wav"),
	"name_castillo": preload("res://audio/voice/en/name_castillo.wav"),
	"name_abernathy": preload("res://audio/voice/en/name_abernathy.wav"),
	"name_nakamura": preload("res://audio/voice/en/name_nakamura.wav"),
	"name_petrov": preload("res://audio/voice/en/name_petrov.wav"),
	"num_0": preload("res://audio/voice/en/num_0.wav"),
	"num_1": preload("res://audio/voice/en/num_1.wav"),
	"num_2": preload("res://audio/voice/en/num_2.wav"),
	"num_3": preload("res://audio/voice/en/num_3.wav"),
	"num_4": preload("res://audio/voice/en/num_4.wav"),
	"num_5": preload("res://audio/voice/en/num_5.wav"),
	"num_6": preload("res://audio/voice/en/num_6.wav"),
	"num_7": preload("res://audio/voice/en/num_7.wav"),
	"num_8": preload("res://audio/voice/en/num_8.wav"),
	"num_9": preload("res://audio/voice/en/num_9.wav"),
	"num_10": preload("res://audio/voice/en/num_10.wav"),
	"num_11": preload("res://audio/voice/en/num_11.wav"),
	"num_12": preload("res://audio/voice/en/num_12.wav"),
	"num_13": preload("res://audio/voice/en/num_13.wav"),
	"num_14": preload("res://audio/voice/en/num_14.wav"),
	"num_15": preload("res://audio/voice/en/num_15.wav"),
	"num_16": preload("res://audio/voice/en/num_16.wav"),
	"num_17": preload("res://audio/voice/en/num_17.wav"),
	"num_18": preload("res://audio/voice/en/num_18.wav"),
	"num_19": preload("res://audio/voice/en/num_19.wav"),
	"num_20": preload("res://audio/voice/en/num_20.wav"),
	# Wall Mode's point race has no upper cap - see Voice.gd's _play_clip()
	# for the screen-reader fallback used for anything higher still.
	"num_21": preload("res://audio/voice/en/num_21.wav"),
	"num_22": preload("res://audio/voice/en/num_22.wav"),
	"num_23": preload("res://audio/voice/en/num_23.wav"),
	"num_24": preload("res://audio/voice/en/num_24.wav"),
	"num_25": preload("res://audio/voice/en/num_25.wav"),
	"num_26": preload("res://audio/voice/en/num_26.wav"),
	"num_27": preload("res://audio/voice/en/num_27.wav"),
	"num_28": preload("res://audio/voice/en/num_28.wav"),
	"num_29": preload("res://audio/voice/en/num_29.wav"),
	"num_30": preload("res://audio/voice/en/num_30.wav"),
	"num_31": preload("res://audio/voice/en/num_31.wav"),
	"num_32": preload("res://audio/voice/en/num_32.wav"),
	"num_33": preload("res://audio/voice/en/num_33.wav"),
	"num_34": preload("res://audio/voice/en/num_34.wav"),
	"num_35": preload("res://audio/voice/en/num_35.wav"),
	"num_36": preload("res://audio/voice/en/num_36.wav"),
	"num_37": preload("res://audio/voice/en/num_37.wav"),
	"num_38": preload("res://audio/voice/en/num_38.wav"),
	"num_39": preload("res://audio/voice/en/num_39.wav"),
	"num_40": preload("res://audio/voice/en/num_40.wav"),
	"num_41": preload("res://audio/voice/en/num_41.wav"),
	"num_42": preload("res://audio/voice/en/num_42.wav"),
	"num_43": preload("res://audio/voice/en/num_43.wav"),
	"num_44": preload("res://audio/voice/en/num_44.wav"),
	"num_45": preload("res://audio/voice/en/num_45.wav"),
	"num_46": preload("res://audio/voice/en/num_46.wav"),
	"num_47": preload("res://audio/voice/en/num_47.wav"),
	"num_48": preload("res://audio/voice/en/num_48.wav"),
	"num_49": preload("res://audio/voice/en/num_49.wav"),
	"num_50": preload("res://audio/voice/en/num_50.wav"),
}

const LINES_ES := {
	"match_start": preload("res://audio/voice/es/match_start.mp3"),
	"quick_match_start": preload("res://audio/voice/es/quick_match_start.mp3"),
	"wall_match_start": preload("res://audio/voice/es/wall_match_start.mp3"),
	"super_smash": preload("res://audio/voice/es/super_smash.mp3"),
	"your_serve": preload("res://audio/voice/es/your_serve.mp3"),
	"bot_serve": preload("res://audio/voice/es/bot_serve.mp3"),
	"out": preload("res://audio/voice/es/out.mp3"),
	"into_net": preload("res://audio/voice/es/into_net.mp3"),
	"missed": preload("res://audio/voice/es/missed.mp3"),
	"point_you": preload("res://audio/voice/es/point_you.mp3"),
	"point_bot": preload("res://audio/voice/es/point_bot.mp3"),
	"game_you": preload("res://audio/voice/es/game_you.mp3"),
	"game_bot": preload("res://audio/voice/es/game_bot.mp3"),
	"set_you": preload("res://audio/voice/es/set_you.mp3"),
	"set_bot": preload("res://audio/voice/es/set_bot.mp3"),
	"match_point_you": preload("res://audio/voice/es/match_point_you.mp3"),
	"match_point_bot": preload("res://audio/voice/es/match_point_bot.mp3"),
	"set_point_you": preload("res://audio/voice/es/set_point_you.mp3"),
	"set_point_bot": preload("res://audio/voice/es/set_point_bot.mp3"),
	"you_win_match": preload("res://audio/voice/es/you_win_match.mp3"),
	"bot_wins_match": preload("res://audio/voice/es/bot_wins_match.mp3"),
	"deuce": preload("res://audio/voice/es/deuce.mp3"),
	"advantage_you": preload("res://audio/voice/es/advantage_you.mp3"),
	"advantage_bot": preload("res://audio/voice/es/advantage_bot.mp3"),
	"love": preload("res://audio/voice/es/love.mp3"),
	"fifteen": preload("res://audio/voice/es/fifteen.mp3"),
	"thirty": preload("res://audio/voice/es/thirty.mp3"),
	"forty": preload("res://audio/voice/es/forty.mp3"),
	"all": preload("res://audio/voice/es/all.mp3"),
	"score_prefix": preload("res://audio/voice/es/score_prefix.mp3"),
	"you_prefix": preload("res://audio/voice/es/you_prefix.mp3"),
	"bot_prefix": preload("res://audio/voice/es/bot_prefix.mp3"),
	"sets_singular": preload("res://audio/voice/es/sets_singular.mp3"),
	"sets_plural": preload("res://audio/voice/es/sets_plural.mp3"),
	"games_singular": preload("res://audio/voice/es/games_singular.mp3"),
	"games_plural": preload("res://audio/voice/es/games_plural.mp3"),
	"paused": preload("res://audio/voice/es/paused.mp3"),
	"resumed": preload("res://audio/voice/es/resumed.mp3"),
	"training_intro": preload("res://audio/voice/es/training_intro.mp3"),
	"best_streak_prefix": preload("res://audio/voice/es/best_streak_prefix.mp3"),
	"career_round_won": preload("res://audio/voice/es/career_round_won.mp3"),
	"career_round_lost": preload("res://audio/voice/es/career_round_lost.mp3"),
	"career_champion": preload("res://audio/voice/es/career_champion.mp3"),
	"career_promoted": preload("res://audio/voice/es/career_promoted.mp3"),
	"career_demoted": preload("res://audio/voice/es/career_demoted.mp3"),
	"career_reset_confirm": preload("res://audio/voice/es/career_reset_confirm.mp3"),
	"point_prefix": preload("res://audio/voice/es/point_prefix.mp3"),
	"game_prefix": preload("res://audio/voice/es/game_prefix.mp3"),
	"set_prefix": preload("res://audio/voice/es/set_prefix.mp3"),
	"match_point_prefix": preload("res://audio/voice/es/match_point_prefix.mp3"),
	"set_point_prefix": preload("res://audio/voice/es/set_point_prefix.mp3"),
	"advantage_prefix": preload("res://audio/voice/es/advantage_prefix.mp3"),
	"serves_suffix": preload("res://audio/voice/es/serves_suffix.mp3"),
	"wins_match_suffix": preload("res://audio/voice/es/wins_match_suffix.mp3"),
	"ready_prompt": preload("res://audio/voice/es/ready_prompt.mp3"),
	"coord_prefix": preload("res://audio/voice/es/coord_prefix.mp3"),
	"coord_left": preload("res://audio/voice/es/coord_left.mp3"),
	"coord_middle": preload("res://audio/voice/es/coord_middle.mp3"),
	"coord_right": preload("res://audio/voice/es/coord_right.mp3"),
	"coord_front": preload("res://audio/voice/es/coord_front.mp3"),
	"coord_back": preload("res://audio/voice/es/coord_back.mp3"),
	"name_carter": preload("res://audio/voice/es/name_carter.mp3"),
	"name_bennett": preload("res://audio/voice/es/name_bennett.mp3"),
	"name_hayes": preload("res://audio/voice/es/name_hayes.mp3"),
	"name_mercer": preload("res://audio/voice/es/name_mercer.mp3"),
	"name_ellison": preload("res://audio/voice/es/name_ellison.mp3"),
	"name_whitfield": preload("res://audio/voice/es/name_whitfield.mp3"),
	"name_sorensen": preload("res://audio/voice/es/name_sorensen.mp3"),
	"name_delgado": preload("res://audio/voice/es/name_delgado.mp3"),
	"name_kowalski": preload("res://audio/voice/es/name_kowalski.mp3"),
	"name_novak": preload("res://audio/voice/es/name_novak.mp3"),
	"name_fontaine": preload("res://audio/voice/es/name_fontaine.mp3"),
	"name_marsh": preload("res://audio/voice/es/name_marsh.mp3"),
	"name_osei": preload("res://audio/voice/es/name_osei.mp3"),
	"name_larsson": preload("res://audio/voice/es/name_larsson.mp3"),
	"name_vance": preload("res://audio/voice/es/name_vance.mp3"),
	"name_renwick": preload("res://audio/voice/es/name_renwick.mp3"),
	"name_castillo": preload("res://audio/voice/es/name_castillo.mp3"),
	"name_abernathy": preload("res://audio/voice/es/name_abernathy.mp3"),
	"name_nakamura": preload("res://audio/voice/es/name_nakamura.mp3"),
	"name_petrov": preload("res://audio/voice/es/name_petrov.mp3"),
	"num_0": preload("res://audio/voice/es/num_0.mp3"),
	"num_1": preload("res://audio/voice/es/num_1.mp3"),
	"num_2": preload("res://audio/voice/es/num_2.mp3"),
	"num_3": preload("res://audio/voice/es/num_3.mp3"),
	"num_4": preload("res://audio/voice/es/num_4.mp3"),
	"num_5": preload("res://audio/voice/es/num_5.mp3"),
	"num_6": preload("res://audio/voice/es/num_6.mp3"),
	"num_7": preload("res://audio/voice/es/num_7.mp3"),
	"num_8": preload("res://audio/voice/es/num_8.mp3"),
	"num_9": preload("res://audio/voice/es/num_9.mp3"),
	"num_10": preload("res://audio/voice/es/num_10.mp3"),
	"num_11": preload("res://audio/voice/es/num_11.mp3"),
	"num_12": preload("res://audio/voice/es/num_12.mp3"),
	"num_13": preload("res://audio/voice/es/num_13.mp3"),
	"num_14": preload("res://audio/voice/es/num_14.mp3"),
	"num_15": preload("res://audio/voice/es/num_15.mp3"),
	"num_16": preload("res://audio/voice/es/num_16.mp3"),
	"num_17": preload("res://audio/voice/es/num_17.mp3"),
	"num_18": preload("res://audio/voice/es/num_18.mp3"),
	"num_19": preload("res://audio/voice/es/num_19.mp3"),
	"num_20": preload("res://audio/voice/es/num_20.mp3"),
	"num_21": preload("res://audio/voice/es/num_21.mp3"),
	"num_22": preload("res://audio/voice/es/num_22.mp3"),
	"num_23": preload("res://audio/voice/es/num_23.mp3"),
	"num_24": preload("res://audio/voice/es/num_24.mp3"),
	"num_25": preload("res://audio/voice/es/num_25.mp3"),
	"num_26": preload("res://audio/voice/es/num_26.mp3"),
	"num_27": preload("res://audio/voice/es/num_27.mp3"),
	"num_28": preload("res://audio/voice/es/num_28.mp3"),
	"num_29": preload("res://audio/voice/es/num_29.mp3"),
	"num_30": preload("res://audio/voice/es/num_30.mp3"),
	"num_31": preload("res://audio/voice/es/num_31.mp3"),
	"num_32": preload("res://audio/voice/es/num_32.mp3"),
	"num_33": preload("res://audio/voice/es/num_33.mp3"),
	"num_34": preload("res://audio/voice/es/num_34.mp3"),
	"num_35": preload("res://audio/voice/es/num_35.mp3"),
	"num_36": preload("res://audio/voice/es/num_36.mp3"),
	"num_37": preload("res://audio/voice/es/num_37.mp3"),
	"num_38": preload("res://audio/voice/es/num_38.mp3"),
	"num_39": preload("res://audio/voice/es/num_39.mp3"),
	"num_40": preload("res://audio/voice/es/num_40.mp3"),
	"num_41": preload("res://audio/voice/es/num_41.mp3"),
	"num_42": preload("res://audio/voice/es/num_42.mp3"),
	"num_43": preload("res://audio/voice/es/num_43.mp3"),
	"num_44": preload("res://audio/voice/es/num_44.mp3"),
	"num_45": preload("res://audio/voice/es/num_45.mp3"),
	"num_46": preload("res://audio/voice/es/num_46.mp3"),
	"num_47": preload("res://audio/voice/es/num_47.mp3"),
	"num_48": preload("res://audio/voice/es/num_48.mp3"),
	"num_49": preload("res://audio/voice/es/num_49.mp3"),
	"num_50": preload("res://audio/voice/es/num_50.mp3"),
}

## Mirrors the phrases baked into the wav/mp3 clips above - must match
## tools/generate_voice.ps1 / tools/generate_voice_es.py's text so NVDA and
## the fallback clips never disagree about what was "said".
const PHRASES_EN := {
	"match_start": "New match. Best of three sets. Your serve.",
	"quick_match_start": "New match. First to seven, win by two.",
	"wall_match_start": "New match. First to five points, however you like - the first player to reach five doesn't win outright, but any point after that must be won by a smash to end the match. Side walls are in play - shots that would go out bounce back into play instead. Your serve.",
	"super_smash": "Super Smash!",
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
	"name_carter": "Carter", "name_bennett": "Bennett", "name_hayes": "Hayes",
	"name_mercer": "Mercer", "name_ellison": "Ellison", "name_whitfield": "Whitfield",
	"name_sorensen": "Sorensen", "name_delgado": "Delgado", "name_kowalski": "Kowalski",
	"name_novak": "Novak", "name_fontaine": "Fontaine", "name_marsh": "Marsh",
	"name_osei": "Osei", "name_larsson": "Larsson", "name_vance": "Vance",
	"name_renwick": "Renwick", "name_castillo": "Castillo", "name_abernathy": "Abernathy",
	"name_nakamura": "Nakamura", "name_petrov": "Petrov",
}

const PHRASES_ES := {
	"match_start": "Partido nuevo. Al mejor de tres sets. Tu saque.",
	"quick_match_start": "Partido nuevo. A siete puntos, con dos de ventaja.",
	"wall_match_start": "Partido nuevo. Primero a cinco puntos, como sea - el primer jugador en llegar a cinco no gana directamente, pero cualquier punto después de eso debe ganarse con un remate para terminar el partido. Las paredes laterales están en juego - los golpes que saldrían fuera rebotan y siguen en juego. Tu saque.",
	"super_smash": "¡Súper remate!",
	"your_serve": "Tu saque.",
	"bot_serve": "Saca el rival.",
	"out": "Fuera.",
	"into_net": "A la red.",
	"missed": "No devuelta.",
	"point_you": "Punto para ti.",
	"point_bot": "Punto para el rival.",
	"game_you": "Juego para ti.",
	"game_bot": "Juego para el rival.",
	"set_you": "Set para ti.",
	"set_bot": "Set para el rival.",
	"match_point_you": "Punto de partido para ti.",
	"match_point_bot": "Punto de partido para el rival.",
	"set_point_you": "Punto de set para ti.",
	"set_point_bot": "Punto de set para el rival.",
	"you_win_match": "¡Ganas el partido!",
	"bot_wins_match": "El rival gana el partido.",
	"deuce": "Iguales.",
	"advantage_you": "Ventaja para ti.",
	"advantage_bot": "Ventaja para el rival.",
	"love": "Cero.",
	"fifteen": "Quince.",
	"thirty": "Treinta.",
	"forty": "Cuarenta.",
	"all": "Iguales.",
	"score_prefix": "Marcador.",
	"you_prefix": "Tú:",
	"bot_prefix": "Rival:",
	"sets_singular": "set,",
	"sets_plural": "sets,",
	"games_singular": "juego.",
	"games_plural": "juegos.",
	"paused": "Pausado.",
	"resumed": "Reanudado.",
	"training_intro": "Modo entrenamiento. Las pelotas llegan a casillas al azar de tu lado. Llega a la casilla y pulsa Espacio para devolver. Escape vuelve al menú.",
	"best_streak_prefix": "Mejor racha:",
	"career_round_won": "¡Ronda ganada! Avanzas.",
	"career_round_lost": "Perdiste esta ronda. Torneo terminado.",
	"career_champion": "¡Campeón! ¡Ganaste el torneo!",
	"career_promoted": "¡Subes al siguiente nivel!",
	"career_demoted": "Tres derrotas en este nivel: has bajado de nivel.",
	"career_reset_confirm": "Esto borrará tu carrera de forma permanente. Pulsa Reiniciar carrera de nuevo antes de cinco segundos para confirmar.",
	"point_prefix": "Punto para",
	"game_prefix": "Juego para",
	"set_prefix": "Set para",
	"match_point_prefix": "Punto de partido para",
	"set_point_prefix": "Punto de set para",
	"advantage_prefix": "Ventaja para",
	"serves_suffix": "saca.",
	"wins_match_suffix": "gana el partido.",
	"ready_prompt": "Pulsa Enter cuando estés listo para sacar.",
	"coord_prefix": "Tu posición:",
	"coord_left": "izquierda,",
	"coord_middle": "centro,",
	"coord_right": "derecha,",
	"coord_front": "adelante.",
	"coord_back": "atrás.",
	"name_carter": "Carter", "name_bennett": "Bennett", "name_hayes": "Hayes",
	"name_mercer": "Mercer", "name_ellison": "Ellison", "name_whitfield": "Whitfield",
	"name_sorensen": "Sorensen", "name_delgado": "Delgado", "name_kowalski": "Kowalski",
	"name_novak": "Novak", "name_fontaine": "Fontaine", "name_marsh": "Marsh",
	"name_osei": "Osei", "name_larsson": "Larsson", "name_vance": "Vance",
	"name_renwick": "Renwick", "name_castillo": "Castillo", "name_abernathy": "Abernathy",
	"name_nakamura": "Nakamura", "name_petrov": "Petrov",
}

const NVDA_HELPER_PATH := "res://bin/NvdaSpeak.exe"

var _player: AudioStreamPlayer
var _queue: Array[String] = []

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.bus = "Master"
	_player.finished.connect(_on_finished)

func _lines() -> Dictionary:
	return LINES_ES if GameSettings.language == "es" else LINES_EN

func _phrases() -> Dictionary:
	return PHRASES_ES if GameSettings.language == "es" else PHRASES_EN

## Public lookup of a single phrase's raw text (current language), or "" if
## unknown - lets a caller compose its own dynamic (unclippable) sentence out
## of the same phrase pool say()/say_sequence() draw from. See
## NetworkSession.gd's LAN opponent-name composition.
func phrase(key: String) -> String:
	return _phrases().get(key, "")

## Speaks a single known line.
func say(key: String) -> void:
	say_sequence([key])

## Speaks several lines as one utterance via the screen reader (so it reads
## naturally as one sentence), or as a queued clip sequence in fallback mode.
func say_sequence(keys: Array) -> void:
	var phrases: Dictionary = _phrases()
	var parts: Array[String] = []
	for k in keys:
		var text: String = phrases.get(k, "")
		if text != "":
			parts.append(text)
	var joined := " ".join(parts)
	if joined != "" and _speak_via_screen_reader(joined):
		return
	for k in keys:
		_play_clip(k)

## Speaks arbitrary text through the screen-reader bridge only - there's no
## way to pre-render a clip for every possible tier/tournament/round/name
## combination, so unlike say()/say_sequence() this has no clip fallback. If
## no screen reader is running, this is silent by design; every *fixed*
## phrase (round won/lost, champion, etc.) still goes through say() and
## keeps its full clip fallback.
func say_dynamic(text: String) -> void:
	_speak_via_screen_reader(text)

## Speaks "You: N game(s)/set(s)." or "Bot: N game(s)/set(s)."
func say_tally(prefix_key: String, count: int, singular_key: String, plural_key: String) -> void:
	say_sequence(tally_keys(prefix_key, count, singular_key, plural_key))

## Public so callers that need to *relay* the same announcement elsewhere
## (see MatchManager.gd's LAN-mode _speak_tally()) can get the exact same key
## list without duplicating this logic.
func tally_keys(prefix_key: String, count: int, singular_key: String, plural_key: String) -> Array[String]:
	var keys: Array[String] = [prefix_key]
	var num_key := "num_%d" % count
	if _lines().has(num_key):
		keys.append(num_key)
	keys.append(singular_key if count == 1 else plural_key)
	return keys

## Returns true if a running screen reader actually spoke the text.
func _speak_via_screen_reader(text: String) -> bool:
	var exe_path: String = ProjectSettings.globalize_path(NVDA_HELPER_PATH)
	if not FileAccess.file_exists(exe_path):
		return false
	var output: Array = []
	var exit_code: int = OS.execute(exe_path, [text], output, false, false)
	return exit_code == 0

func _play_clip(key: String) -> void:
	var stream: AudioStream = _lines().get(key)
	if stream == null:
		# Wall Mode's point race has no upper cap, so a score can climb past
		# however many "num_N" clips are actually pre-rendered (currently
		# 0-50, see generate_voice_en.py/generate_voice_es.py) - rather than
		# just going silent for those, fall back to speaking the digits
		# through the screen-reader bridge so the score is still announced
		# "as far as it needs to" go, even if it's silent without a screen
		# reader running (same limitation say_dynamic() already documents).
		if key.begins_with("num_"):
			_speak_via_screen_reader(key.substr(4))
		return
	if _player.playing:
		_queue.append(key)
	else:
		_player.stream = stream
		_player.play()

func _on_finished() -> void:
	if _queue.size() > 0:
		var key: String = _queue.pop_front()
		_player.stream = _lines()[key]
		_player.play()
