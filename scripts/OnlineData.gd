extends Node
## LAN-only coin/emote economy - a completely separate save from CareerData
## (see user://online_save.json vs user://career_save.json), since it's tied
## to LAN match wins, not career progress. Winning a networked match awards
## coins (see MatchManager.gd's _win_match(), NetworkSession.gd's
## net_match_over(), both of which pick COINS_PER_WIN or COINS_PER_QUICK_WIN
## based on quick_mode) - coins are spent in EmoteStore.tscn on emotes,
## played back during a match via EmoteMenu.gd/NetworkSession.play_emote().

const SAVE_PATH := "user://online_save.json"
const COINS_PER_WIN := 5
## Quick Online Mode is a much faster win (a single race to 7, no games/
## sets), so it pays out less per feedback, to keep the two modes' coin
## rates roughly comparable per minute rather than Quick Mode being a
## strictly faster way to the same reward.
const COINS_PER_QUICK_WIN := 2

var coins: int = 0
var owned_emotes: Array[String] = []

func _ready() -> void:
	load_data()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", 0))
	owned_emotes.clear()
	for e in parsed.get("owned_emotes", []):
		owned_emotes.append(str(e))

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("OnlineData: could not write save file")
		return
	file.store_string(JSON.stringify({"coins": coins, "owned_emotes": owned_emotes}, "\t"))
	file.close()

func add_coins(amount: int) -> void:
	coins += amount
	save_data()

func owns_emote(emote_id: String) -> bool:
	return owned_emotes.has(emote_id)

## Returns false (no-op) if already owned or too poor - callers should check
## the return value before announcing success.
func buy_emote(emote_id: String, price: int) -> bool:
	if owns_emote(emote_id) or coins < price:
		return false
	coins -= price
	owned_emotes.append(emote_id)
	save_data()
	return true
