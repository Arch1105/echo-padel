extends Node
## LAN multiplayer session: direct "Create Room" / "Join Room" connection
## between two devices on the same WiFi/local network, using a Godot
## ENetMultiplayerPeer. No internet/external server involved - true
## internet-wide "search for any player" matchmaking would need at least a
## small rendezvous server, which is a deliberately separate, later phase
## from this LAN mode.
##
## Earlier versions of this file used zero-config UDP broadcast discovery
## instead (so neither player ever had to read/type a network address) - it
## worked in testing, but repeatedly failed to find a real match on at least
## one real household network across several separate fix attempts (broadcast
## targeting, then progressively longer timeouts). Broadcast packets
## (255.255.255.255) are commonly blocked or not forwarded by consumer
## routers/access points in a way that a normal direct connection to a known
## address is not, which fits that pattern of symptoms. This version sidesteps
## broadcast entirely: whoever creates a room is unambiguously the host (no
## more "lowest random id wins" race), and the "room code" the other player
## types in is a short number (the host's own last IP octet - see
## local_room_code()/_resolve_room_code()) that resolves to a direct
## connection, not a broadcast, so it isn't subject to the same failure mode.
##
## Everything gameplay-relevant is host-authoritative: the host runs the
## real Ball/MatchManager simulation exactly as single-player; the client is
## a "thin" peer that sends its input and replays whatever the host tells it
## happened, through the exact same Sfx3D/Voice call sites the host uses -
## see Ball.gd's _play_and_relay()/_rumble_and_relay() and MatchManager.gd's
## _speak(). Tile coordinates (current_col/current_row_local) never need
## translating between host and client - each device's own "Player" node is
## always its own local human, "Bot" is always the remote opponent, on both
## ends, symmetrically. Only continuous *world* positions (the ball) and
## "you"/"bot" perspective in spoken announcements need flipping when they
## cross from host to client - both handled right here, at that one boundary.

signal role_decided(is_host: bool)
signal opponent_connected
signal connection_failed(reason: String)
signal opponent_disconnected

const GAME_PORT := 58272
## Also covers "nobody joined the room in time" on the hosting side, and
## "that room code didn't answer" on the joining side - opening the game
## connection can trigger its own fresh Windows Firewall prompt on a device
## that hasn't been asked before (including right after an auto-update,
## since the .exe file itself changed), and two non-technical players
## coordinating "ok, create a room... ok, now I'll type the code in" over
## voice/text can genuinely take a couple of minutes - so this is
## deliberately generous rather than a tight timer.
const CONNECT_TIMEOUT := 180.0

var is_networked: bool = false
var is_host: bool = false
var opponent_name: String = ""
## Set by the caller (see OnlineModeSelect.gd) *before* create_room() - only
## meaningful on the host, since only the host actually runs the match's
## scoring logic. Whoever joins adopts the host's choice instead of their own
## pre-connection preference once connected (see net_room_info()), so both
## devices always agree on which rules the match is using.
var quick_mode: bool = false
## Same set-before-create_room()/host-wins pattern as quick_mode above - a
## third LAN mode (see OnlineModeSelect.gd) that keeps regular games/sets
## scoring but turns the court's side walls interactive (see Ball.gd's class
## doc comment). Mutually exclusive with quick_mode in the UI (only one mode
## button is ever picked), but nothing here enforces that - it's just never
## offered as a combination.
var wall_mode: bool = false
var remote_ready_received: bool = false

var _local_name: String = ""
var _pending_connect: bool = false
var _connect_timeout_elapsed: float = 0.0

# Registered by MatchManager/PaddleCharacter at match start so RPC handlers
# know what to apply incoming input/state to - cleared when the match ends.
var _remote_paddle: PaddleCharacter = null       # host: stands in for the remote player's input
var _local_puppet_paddle: PaddleCharacter = null # client: represents the host's paddle on screen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## The short code shown/spoken to the hosting player as their "room code" -
## just this device's own last IP octet (e.g. "64" instead of the full
## "192.168.1.64"), since two devices on the same WiFi/LAN almost always
## share the same first three octets already - the joining device fills
## those back in itself (see _resolve_room_code()) using its own detected
## address, the same way a human would reasonably assume "we're on the same
## network, so the first part must be the same". Returns "" if no address
## could be found at all (see _local_ipv4()).
static func local_room_code() -> String:
	var ip: String = _local_ipv4()
	if ip == "":
		return ""
	return ip.split(".")[3]

## This device's own private LAN-range IPv4 address (192.168.x.x / 10.x.x.x
## / 172.16-31.x.x), from a "normal-looking" network adapter, since a device
## can have several addresses at once (WiFi, Ethernet, VPN, virtual adapters
## from Hyper-V/VirtualBox/WSL etc.) and only the one actually shared with
## the other player's device over WiFi/LAN is useful here. Returns "" if
## nothing plausible was found (e.g. no network connection at all).
static func _local_ipv4() -> String:
	var preferred: Array[String] = []
	var fallback: Array[String] = []
	var deprioritized_keywords := ["virtual", "vmware", "vbox", "hyper-v", "loopback", "tunnel", "docker", "wsl", "bluetooth"]
	for iface in IP.get_local_interfaces():
		var iface_label: String = "%s %s" % [iface.get("name", ""), iface.get("friendly", "")]
		var is_deprioritized: bool = false
		for keyword in deprioritized_keywords:
			if iface_label.to_lower().find(keyword) != -1:
				is_deprioritized = true
				break
		for addr in iface.get("addresses", []):
			var ip: String = str(addr).split("/")[0]
			if _is_private_ipv4(ip):
				if is_deprioritized:
					fallback.append(ip)
				else:
					preferred.append(ip)
	if not preferred.is_empty():
		return preferred[0]
	if not fallback.is_empty():
		return fallback[0]
	return ""

static func _is_private_ipv4(ip: String) -> bool:
	var octets: PackedStringArray = ip.split(".")
	if octets.size() != 4:
		return false
	if ip.begins_with("169.254.") or ip.begins_with("127."):
		return false
	if ip.begins_with("192.168.") or ip.begins_with("10."):
		return true
	if ip.begins_with("172."):
		var second: int = int(octets[1])
		return second >= 16 and second <= 31
	return false

## Turns whatever the player typed into Join Room into a real address to
## connect to. Accepts either the short code from local_room_code() (just
## digits - combined with this device's own detected subnet, since both
## devices being on the same WiFi/LAN means that part should already match)
## or, as a fallback for the rare case that assumption is wrong, a full
## dotted address typed in directly. Returns "" if it can't be resolved at
## all (bad input, or this device has no network address of its own either).
static func _resolve_room_code(code: String) -> String:
	var trimmed: String = code.strip_edges()
	if trimmed.find(".") != -1:
		return trimmed
	if not trimmed.is_valid_int():
		return ""
	var last_octet: int = int(trimmed)
	if last_octet < 0 or last_octet > 255:
		return ""
	var own_ip: String = _local_ipv4()
	if own_ip == "":
		return ""
	var own_octets: PackedStringArray = own_ip.split(".")
	return "%s.%s.%s.%d" % [own_octets[0], own_octets[1], own_octets[2], last_octet]

## Becomes the host - starts listening immediately and waits for the other
## player to Join Room with the address from local_room_code().
func create_room(local_name: String) -> void:
	_reset_state()
	is_networked = true
	is_host = true
	_local_name = local_name
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_server(GAME_PORT, 1)
	if err != OK:
		connection_failed.emit("server_failed")
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	_pending_connect = true
	_connect_timeout_elapsed = 0.0
	set_process(true)

## Becomes the client, connecting directly to another device's room code.
func join_room(local_name: String, room_code: String) -> void:
	_reset_state()
	is_networked = true
	is_host = false
	_local_name = local_name
	var target_ip: String = _resolve_room_code(room_code)
	if target_ip == "":
		is_networked = false
		is_host = false
		connection_failed.emit("invalid_code")
		return
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_client(target_ip, GAME_PORT)
	if err != OK:
		connection_failed.emit("client_failed")
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_peer_disconnected)
	_pending_connect = true
	_connect_timeout_elapsed = 0.0
	set_process(true)

func cancel_search() -> void:
	_reset_state()

func end_session() -> void:
	_reset_state()

func _reset_state() -> void:
	is_networked = false
	is_host = false
	_pending_connect = false
	remote_ready_received = false
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_remote_paddle = null
	_local_puppet_paddle = null
	set_process(false)

func _process(delta: float) -> void:
	if _pending_connect:
		_connect_timeout_elapsed += delta
		if _connect_timeout_elapsed > CONNECT_TIMEOUT:
			_pending_connect = false
			connection_failed.emit("timeout")

## Host side: a peer has reached the ENet server, but role_decided/
## opponent_connected don't fire until the name/mode handshake below
## finishes (see submit_name()), so both devices always know each other's
## name and are using the same scoring rules before the match scene loads.
func _on_peer_connected(_id: int) -> void:
	_pending_connect = false

func _on_connected_to_server() -> void:
	_pending_connect = false
	submit_name.rpc(_local_name)

@rpc("any_peer", "reliable")
func submit_name(their_name: String) -> void:
	if not is_host:
		return
	opponent_name = their_name
	net_room_info.rpc_id(multiplayer.get_remote_sender_id(), _local_name, quick_mode, wall_mode)
	role_decided.emit(is_host)
	opponent_connected.emit()

## Client side: the host's reply to submit_name() above - carries the host's
## name and which scoring/court rules to use (see quick_mode's/wall_mode's
## doc comments).
@rpc("authority", "reliable")
func net_room_info(host_name: String, host_quick_mode: bool, host_wall_mode: bool) -> void:
	opponent_name = host_name
	quick_mode = host_quick_mode
	wall_mode = host_wall_mode
	role_decided.emit(is_host)
	opponent_connected.emit()

func _on_connection_failed() -> void:
	_pending_connect = false
	connection_failed.emit("connect_failed")

func _on_peer_disconnected(_id: int = 0) -> void:
	if is_networked:
		opponent_disconnected.emit()

## --- Registration (called by match-scene nodes at _ready()) ---

func register_remote_paddle(node: PaddleCharacter) -> void:
	_remote_paddle = node

func register_local_puppet_paddle(node: PaddleCharacter) -> void:
	_local_puppet_paddle = node

## --- Input relay: client -> host ---

@rpc("any_peer", "reliable")
func submit_move(delta_col: int, delta_row: int) -> void:
	if is_host and _remote_paddle:
		_remote_paddle.move(delta_col, delta_row)

@rpc("any_peer", "reliable")
func submit_hit(shape: Dictionary) -> void:
	if is_host and _remote_paddle and _remote_paddle.ball:
		_remote_paddle.ball.attempt_hit("bot", _remote_paddle.current_col, _remote_paddle.current_row_local, shape)

@rpc("any_peer", "reliable")
func submit_ready() -> void:
	if is_host:
		remote_ready_received = true

func consume_remote_ready() -> bool:
	if remote_ready_received:
		remote_ready_received = false
		return true
	return false

## --- Puppet paddle position relay: host -> client ---

@rpc("authority", "unreliable_ordered")
func net_paddle_position(col: int, row_local: int) -> void:
	if _local_puppet_paddle:
		_local_puppet_paddle.current_col = col
		_local_puppet_paddle.current_row_local = row_local
		_local_puppet_paddle.puppet_snap(true)

func relay_paddle_position(col: int, row_local: int) -> void:
	if is_networked and is_host:
		net_paddle_position.rpc(col, row_local)

## --- Ready-prompt relay: host -> client (both players confirm every point) ---

@rpc("authority", "reliable")
func net_await_ready() -> void:
	var mm: MatchManager = _find_local_match_manager()
	if mm:
		mm.client_show_ready_prompt()

func relay_await_ready() -> void:
	if is_networked and is_host:
		net_await_ready.rpc()

## --- Cheer/boo relay: host -> client (flipped - my opponent's cheer is my boo) ---

@rpc("authority", "reliable")
func net_cheer_or_boo(host_side_won: bool) -> void:
	Sfx3D.play_ui("cheer" if not host_side_won else "boo")

func relay_cheer_or_boo(host_side_won: bool) -> void:
	if is_networked and is_host:
		net_cheer_or_boo.rpc(host_side_won)

## --- Score-state sync: host -> client, already swapped by the caller ---
## (see MatchManager.gd's _sync_network_score()) so the client's own
## unmodified announcement code reads it correctly from its own perspective.

@rpc("authority", "reliable")
func net_score_sync(p_you: int, p_bot: int, g_you: int, g_bot: int, s_you: int, s_bot: int,
		serve_you: bool, tiebreak: bool, tb_you: int, tb_bot: int) -> void:
	var mm: MatchManager = _find_local_match_manager()
	if mm:
		mm.client_apply_score_sync(p_you, p_bot, g_you, g_bot, s_you, s_bot, serve_you, tiebreak, tb_you, tb_bot)

func relay_score_sync(p_you: int, p_bot: int, g_you: int, g_bot: int, s_you: int, s_bot: int,
		serve_you: bool, tiebreak: bool, tb_you: int, tb_bot: int) -> void:
	if is_networked and is_host:
		net_score_sync.rpc(p_you, p_bot, g_you, g_bot, s_you, s_bot, serve_you, tiebreak, tb_you, tb_bot)

## --- Ball state relay: host -> client (see Ball.gd's is_puppet handling) ---

@rpc("authority", "unreliable_ordered")
func net_ball_transform(pos: Vector3, is_dolly: bool, hit_window_open: bool, target_side_is_player: bool) -> void:
	var ball: Ball = _find_local_ball()
	if ball:
		ball.puppet_apply_transform(pos, is_dolly, hit_window_open, target_side_is_player)

func relay_ball_transform(pos: Vector3, is_dolly: bool, hit_window_open: bool, target_side_is_player: bool) -> void:
	if is_networked and is_host:
		# Mirrored for the client's own perspective - see class doc comment.
		var mirrored_pos: Vector3 = Vector3(pos.x, pos.y, -pos.z)
		net_ball_transform.rpc(mirrored_pos, is_dolly, hit_window_open, not target_side_is_player)

## --- One-shot sound relay: host -> client ---

@rpc("authority", "reliable")
func net_sound(sound_name: String, pos: Vector3, volume_db: float, pitch: float, bus: String) -> void:
	Sfx3D.play_at(sound_name, pos, volume_db, pitch, bus)

func relay_sound(sound_name: String, pos: Vector3, volume_db: float, pitch: float, bus: String) -> void:
	if is_networked and is_host:
		var mirrored_pos: Vector3 = Vector3(pos.x, pos.y, -pos.z)
		var mirrored_bus: String = Sfx3D.DISTANT_BUS if bus == Sfx3D.NEAR_BUS else Sfx3D.NEAR_BUS
		net_sound.rpc(sound_name, mirrored_pos, volume_db, pitch, mirrored_bus)

## --- Visual-only effect relay: host -> client (fireworks / bounce flash) ---

@rpc("authority", "reliable")
func net_visual_effect(effect_name: String, pos: Vector3) -> void:
	var ball: Ball = _find_local_ball()
	if ball:
		ball.puppet_play_visual_effect(effect_name, pos)

func relay_visual_effect(effect_name: String, pos: Vector3) -> void:
	if is_networked and is_host:
		var mirrored_pos: Vector3 = Vector3(pos.x, pos.y, -pos.z)
		net_visual_effect.rpc(effect_name, mirrored_pos)

## --- Rumble relay: host -> client (their own controller, if any). The host
## already rumbles locally for its own "you" actions (see Ball.gd/
## MatchManager.gd) - these two relay a "bot"-side (i.e. the client's own)
## rumble-worthy event to the client, so their own controller vibrates too,
## same as it already hears/sees those events relayed. ---

@rpc("authority", "reliable")
func net_rumble(weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	Sfx3D.rumble(weak_magnitude, strong_magnitude, duration)

func relay_rumble(weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	if is_networked and is_host:
		net_rumble.rpc(weak_magnitude, strong_magnitude, duration)

@rpc("authority", "reliable")
func net_rumble_smash() -> void:
	Sfx3D.rumble_smash()

func relay_rumble_smash() -> void:
	if is_networked and is_host:
		net_rumble_smash.rpc()

## --- Voice/announcement relay: host -> client, with you/bot perspective flip ---

## Maps a fixed "opponent did X" key to the phrase spoken before the name
## (e.g. "point_bot" -> "point_prefix", so it reads "Point, <name>." - the
## exact same shape Career mode already uses for its surname clips).
const NAMED_BOT_KEYS := {
	"point_bot": "point_prefix", "game_bot": "game_prefix", "set_bot": "set_prefix",
	"match_point_bot": "match_point_prefix", "set_point_bot": "set_point_prefix",
	"advantage_bot": "advantage_prefix",
}

## Speaks an already-local-perspective key list (i.e. flipped for whichever
## device is speaking, if it's the client). Whenever the announcement is
## about the opponent - a "_bot"-suffixed event, "bot_serve", or a "bot_
## prefix" tally - substitutes the real opponent name in place of the
## generic "Bot" wording. Both devices already know their own opponent's
## name independently from the room-connection handshake (see opponent_name),
## so
## no name text ever needs to cross the network here - only the existing
## relay's timing cue does, same as before this substitution existed.
func speak_local_keys(keys: Array) -> void:
	if not is_networked or keys.is_empty():
		Voice.say_sequence(keys)
		return
	if keys.size() == 1 and NAMED_BOT_KEYS.has(keys[0]):
		Voice.say_dynamic("%s %s" % [Voice.phrase(NAMED_BOT_KEYS[keys[0]]), opponent_name])
		return
	if keys.size() == 1 and keys[0] == "bot_serve":
		Voice.say_dynamic("%s %s" % [opponent_name, Voice.phrase("serves_suffix")])
		return
	if keys[0] == "bot_prefix":
		var parts: Array[String] = [opponent_name]
		for i in range(1, keys.size()):
			parts.append(Voice.phrase(keys[i]))
		Voice.say_dynamic(" ".join(parts))
		return
	Voice.say_sequence(keys)

@rpc("authority", "reliable")
func net_speak(keys: Array) -> void:
	var flipped: Array = []
	for k in keys:
		flipped.append(flip_you_bot_key(k))
	speak_local_keys(flipped)

func relay_speak(keys: Array) -> void:
	if is_networked and is_host:
		net_speak.rpc(keys)

@rpc("authority", "reliable")
func net_speak_dynamic(text: String) -> void:
	Voice.say_dynamic(text)

func relay_speak_dynamic(text: String) -> void:
	if is_networked and is_host:
		net_speak_dynamic.rpc(text)

static func flip_you_bot_key(key: String) -> String:
	var swaps := {
		"you_win_match": "bot_wins_match", "bot_wins_match": "you_win_match",
		"you_prefix": "bot_prefix", "bot_prefix": "you_prefix",
		"your_serve": "bot_serve", "bot_serve": "your_serve",
	}
	if swaps.has(key):
		return swaps[key]
	if key.ends_with("_you"):
		return key.substr(0, key.length() - 4) + "_bot"
	if key.ends_with("_bot"):
		return key.substr(0, key.length() - 4) + "_you"
	return key

## --- Match lifecycle relay: host -> client ---

## host_won: from the HOST's own "you"/"bot" perspective - so on the client
## receiving this, host_won == true means *I* (the client) lost, and
## host_won == false means I won (see OnlineData.gd's LAN-only coin award,
## mirrored here for whichever device the host's MatchManager didn't already
## award it to directly in _win_match()).
@rpc("authority", "reliable")
func net_match_over(host_won: bool) -> void:
	if not host_won:
		var coins: int = OnlineData.COINS_PER_QUICK_WIN if quick_mode else OnlineData.COINS_PER_WIN
		OnlineData.add_coins(coins)
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if is_networked:
			end_session()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

## --- Emote relay: either side -> the other (see EmoteMenu.gd) - unlike the
## rest of this file, this isn't host-authoritative, since either player can
## trigger their own celebration regardless of host/client role. ---

## Call this locally when the player picks an emote - plays it right away on
## this device and tells the opponent's device to play it too.
func play_emote(emote_id: String) -> void:
	Sfx3D.play_ui(emote_id)
	if is_networked:
		net_play_emote.rpc(emote_id)

@rpc("any_peer", "reliable")
func net_play_emote(emote_id: String) -> void:
	Sfx3D.play_ui(emote_id)
	Voice.say_dynamic("%s %s" % [opponent_name, Loc.t("emote_celebrates_suffix")])

func relay_match_over(host_won: bool) -> void:
	if is_networked and is_host:
		net_match_over.rpc(host_won)

func _find_local_ball() -> Ball:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Ball")

func _find_local_match_manager() -> MatchManager:
	return get_tree().current_scene as MatchManager
