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
]

static func find(emote_id: String) -> Dictionary:
	for entry in CATALOG:
		if entry["id"] == emote_id:
			return entry
	return {}
