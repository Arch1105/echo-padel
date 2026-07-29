class_name Emotes
extends RefCounted
## Static catalog of purchasable LAN-match emotes (see OnlineData.gd for
## ownership/coins, EmoteStore.tscn for buying, EmoteMenu.gd for playing one
## mid-match). Each is a real ~3 second CC0 music clip - see
## tools/generate_emotes.py for source/license details.

const CATALOG := [
	{"id": "afro_pop", "name_key": "emote_afro_pop", "price": 15},
	{"id": "hip_hop", "name_key": "emote_hip_hop", "price": 15},
	{"id": "eastern_folk_dance", "name_key": "emote_eastern_folk_dance", "price": 15},
]

static func find(emote_id: String) -> Dictionary:
	for entry in CATALOG:
		if entry["id"] == emote_id:
			return entry
	return {}
