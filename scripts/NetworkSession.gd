extends Node
## LAN multiplayer session: auto-discovery (UDP broadcast/listen - no manual
## IP entry, since typing/reading an IP address is a poor fit for a
## screen-reader-first game) pairs two devices on the same WiFi/local
## network, deterministically picks a host (lower session id), and sets up a
## Godot ENetMultiplayerPeer connection between them. No internet/external
## server involved - true internet-wide "search for any player" matchmaking
## would need at least a small rendezvous server, which is a deliberately
## separate, later phase from this LAN mode.
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

const DISCOVERY_PORT := 58271
const GAME_PORT := 58272
const DISCOVERY_BEACON_INTERVAL := 0.75
const DISCOVERY_MAGIC := "ECHOPADEL_LAN_V1"
const CONNECT_TIMEOUT := 8.0

var is_networked: bool = false
var is_host: bool = false
var opponent_name: String = ""
## Set by the caller (see OnlineModeSelect.gd) *before* begin_search() - the
## host's own value always wins once connected (see _handle_beacon()), since
## only the host actually runs the match's scoring logic. A client's own
## pre-connection preference is discarded in favor of whatever the host
## chose, so both devices always agree on which rules the match is using.
var quick_mode: bool = false
var remote_ready_received: bool = false

var _discovery_socket: PacketPeerUDP
var _beacon_timer: Timer
var _session_id: int = 0
var _local_name: String = ""
var _searching: bool = false
var _pending_connect: bool = false
var _connect_timeout_elapsed: float = 0.0

# Registered by MatchManager/PaddleCharacter at match start so RPC handlers
# know what to apply incoming input/state to - cleared when the match ends.
var _remote_paddle: PaddleCharacter = null       # host: stands in for the remote player's input
var _local_puppet_paddle: PaddleCharacter = null # client: represents the host's paddle on screen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func begin_search(local_name: String) -> void:
	_reset_state()
	is_networked = true
	_local_name = local_name
	_session_id = randi()
	_searching = true
	_discovery_socket = PacketPeerUDP.new()
	_discovery_socket.set_broadcast_enabled(true)
	var err: int = _discovery_socket.bind(DISCOVERY_PORT)
	if err != OK:
		connection_failed.emit("bind_failed")
		return
	_beacon_timer = Timer.new()
	_beacon_timer.wait_time = DISCOVERY_BEACON_INTERVAL
	_beacon_timer.timeout.connect(_send_beacon)
	add_child(_beacon_timer)
	_beacon_timer.start()
	_send_beacon()
	set_process(true)

func cancel_search() -> void:
	_reset_state()

func end_session() -> void:
	_reset_state()

func _reset_state() -> void:
	is_networked = false
	is_host = false
	_searching = false
	_pending_connect = false
	remote_ready_received = false
	if _beacon_timer:
		_beacon_timer.stop()
		_beacon_timer.queue_free()
		_beacon_timer = null
	if _discovery_socket:
		_discovery_socket.close()
		_discovery_socket = null
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	_remote_paddle = null
	_local_puppet_paddle = null
	set_process(false)

func _send_beacon() -> void:
	if not _searching:
		return
	var msg: String = "%s|%d|%s|%d" % [DISCOVERY_MAGIC, _session_id, _local_name, int(quick_mode)]
	_discovery_socket.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	_discovery_socket.put_packet(msg.to_utf8_buffer())

func _process(delta: float) -> void:
	if _searching and _discovery_socket:
		while _discovery_socket.get_available_packet_count() > 0:
			var packet: PackedByteArray = _discovery_socket.get_packet()
			var sender_ip: String = _discovery_socket.get_packet_ip()
			_handle_beacon(packet.get_string_from_utf8(), sender_ip)
	if _pending_connect:
		_connect_timeout_elapsed += delta
		if _connect_timeout_elapsed > CONNECT_TIMEOUT:
			_pending_connect = false
			connection_failed.emit("timeout")

func _handle_beacon(text: String, sender_ip: String) -> void:
	var parts: PackedStringArray = text.split("|")
	if parts.size() < 3 or parts[0] != DISCOVERY_MAGIC:
		return
	var their_id: int = int(parts[1])
	if their_id == _session_id:
		return  # our own broadcast looping back, or an astronomically unlikely id collision - ignore either way
	opponent_name = parts[2]
	var their_quick_mode: bool = parts.size() >= 4 and parts[3] == "1"
	_searching = false
	_beacon_timer.stop()
	if their_id < _session_id:
		# Becoming the client - adopt the host's mode choice, discarding our
		# own pre-connection preference (see quick_mode's doc comment above).
		quick_mode = their_quick_mode
		_become_client(sender_ip)
	else:
		_become_host()

func _become_host() -> void:
	is_host = true
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

func _become_client(host_ip: String) -> void:
	is_host = false
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_client(host_ip, GAME_PORT)
	if err != OK:
		connection_failed.emit("client_failed")
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_peer_disconnected)
	_pending_connect = true
	_connect_timeout_elapsed = 0.0

func _on_peer_connected(_id: int) -> void:
	_pending_connect = false
	role_decided.emit(is_host)
	opponent_connected.emit()

func _on_connected_to_server() -> void:
	_pending_connect = false
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

## --- Rumble relay: host -> client (their own controller, if any) ---

@rpc("authority", "reliable")
func net_rumble(weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	Sfx3D.rumble(weak_magnitude, strong_magnitude, duration)

func relay_rumble(weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	if is_networked and is_host:
		net_rumble.rpc(weak_magnitude, strong_magnitude, duration)

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
## name independently from the discovery handshake (see opponent_name), so
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

@rpc("authority", "reliable")
func net_match_over() -> void:
	get_tree().create_timer(4.0).timeout.connect(func() -> void:
		if is_networked:
			end_session()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)

func relay_match_over() -> void:
	if is_networked and is_host:
		net_match_over.rpc()

func _find_local_ball() -> Ball:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Ball")

func _find_local_match_manager() -> MatchManager:
	return get_tree().current_scene as MatchManager
