class_name Emotes
extends RefCounted
## Static catalog of purchasable LAN-match emotes (see OnlineData.gd for
## ownership/coins, EmoteStore.tscn for buying, EmoteMenu.gd for playing one
## mid-match). Each is a real ~3 second CC0 clip - see tools/generate_
## emotes.py and tools/generate_emotes_2.py for source/license details.

const CATALOG := [
	{"id": "afro_pop", "name_key": "emote_afro_pop", "price": 15},
	{"id": "hip_hop", "name_key": "emote_hip_hop", "price": 15},
	{"id": "eastern_folk_dance", "name_key": "emote_eastern_folk_dance", "price": 15},
	{"id": "silly_voice", "name_key": "emote_silly_voice", "price": 15},
	{"id": "uk_drill", "name_key": "emote_uk_drill", "price": 15},
	{"id": "villain_laugh", "name_key": "emote_villain_laugh", "price": 15},
	{"id": "chiptune_victory", "name_key": "emote_chiptune_victory", "price": 15},
	{"id": "airhorn_hype", "name_key": "emote_airhorn_hype", "price": 15},
	{"id": "latin_party", "name_key": "emote_latin_party", "price": 15},
	{"id": "sad_trombone", "name_key": "emote_sad_trombone", "price": 2},
	{"id": "mic_drop", "name_key": "emote_mic_drop", "price": 3},
	{"id": "why_so_serious", "name_key": "emote_why_so_serious", "price": 4},
	{"id": "ping_pong_taunt", "name_key": "emote_ping_pong_taunt", "price": 5},
	{"id": "game_over_trailer", "name_key": "emote_game_over_trailer", "price": 7},
	{"id": "too_easy_tease", "name_key": "emote_too_easy_tease", "price": 8},
	{"id": "champions_taunt", "name_key": "emote_champions_taunt", "price": 10},
	{"id": "sarcastic_clap", "name_key": "emote_sarcastic_clap", "price": 2},
	{"id": "gg_chime", "name_key": "emote_gg_chime", "price": 3},
	{"id": "record_scratch", "name_key": "emote_record_scratch", "price": 4},
	{"id": "robot_target", "name_key": "emote_robot_target", "price": 5},
	{"id": "reggae_vibes", "name_key": "emote_reggae_vibes", "price": 8},
	{"id": "pirate_shanty", "name_key": "emote_pirate_shanty", "price": 8},
	{"id": "sweaty_line", "name_key": "emote_sweaty_line", "price": 3},
	{"id": "pirate_joke", "name_key": "emote_pirate_joke", "price": 4},
	{"id": "thunder_strike", "name_key": "emote_thunder_strike", "price": 5},
	{"id": "level_up", "name_key": "emote_level_up", "price": 4},
	{"id": "country_twang", "name_key": "emote_country_twang", "price": 8},
	{"id": "disco_groove", "name_key": "emote_disco_groove", "price": 8},
	{"id": "kpop_wave", "name_key": "emote_kpop_wave", "price": 8},
	{"id": "rnb_smooth", "name_key": "emote_rnb_smooth", "price": 8},
	{"id": "jazz_lounge", "name_key": "emote_jazz_lounge", "price": 8},
	{"id": "classical_strings", "name_key": "emote_classical_strings", "price": 8},
	{"id": "blues_riff", "name_key": "emote_blues_riff", "price": 8},
	{"id": "funk_fever", "name_key": "emote_funk_fever", "price": 8},
	{"id": "rock_riff", "name_key": "emote_rock_riff", "price": 8},
	{"id": "edm_pulse", "name_key": "emote_edm_pulse", "price": 8},
	{"id": "metal_riff", "name_key": "emote_metal_riff", "price": 8},
	{"id": "flamenco_fire", "name_key": "emote_flamenco_fire", "price": 8},
	{"id": "soul_groove", "name_key": "emote_soul_groove", "price": 8},
	{"id": "polka_party", "name_key": "emote_polka_party", "price": 8},
	{"id": "techno_pulse", "name_key": "emote_techno_pulse", "price": 8},
	{"id": "punk_energy", "name_key": "emote_punk_energy", "price": 8},
	{"id": "house_beat", "name_key": "emote_house_beat", "price": 8},
	{"id": "dubstep_wobble", "name_key": "emote_dubstep_wobble", "price": 8},
	{"id": "arabian_nights", "name_key": "emote_arabian_nights", "price": 8},
	{"id": "waltz_ballroom", "name_key": "emote_waltz_ballroom", "price": 8},
]

static func find(emote_id: String) -> Dictionary:
	for entry in CATALOG:
		if entry["id"] == emote_id:
			return entry
	return {}
