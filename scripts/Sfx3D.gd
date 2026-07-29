extends Node
## Global helper for true 3D positional sound effects. Every one-shot sound
## plays through a throwaway AudioStreamPlayer3D so it's panned/attenuated by
## the active AudioListener3D (set on the human player - see
## PlayerController.gd) using Godot's real 3D audio engine rather than 2D
## stereo panning.
##
## Kept deliberately sparse per playtest feedback: only the sounds that
## directly carry gameplay information (a racket hit, a bounce) get 3D
## positioning. Everything else that used to layer on top - a continuous
## ball-tracking drone, a charge-up tone, footstep ticks, distinct fault
## stingers - turned out to bury those cues instead of helping. Point
## outcomes now get a single non-positional cheer/boo instead of several
## different fault-specific sounds.
##
## Godot's 3D audio does NOT do true HRTF binaural rendering - it panics
## left/right well but, like most game engines, can't reliably distinguish
## "in front of me" from "behind me" at the same distance (the same "cone of
## confusion" that affects real HRTF too). On a small court, raw distance-
## based volume falloff turned out to be just as ambiguous, since your own
## far tile and the opponent's near tile can end up roughly equidistant from
## wherever you're currently standing. So instead of leaning on panning/
## distance to carry that information, two deliberate, position-independent
## cues carry it instead:
##   - which SIDE a sound happened on -> routed through a different audio
##     bus. Your own side is clear/full-range (Master); the opponent's side
##     is muffled and a little quieter (DISTANT_BUS, low-pass filtered) -
##     mimicking how real distant sounds lose their high end, but exaggerated
##     into an unmistakable, always-consistent cue rather than left to
##     subtle/variable real distance attenuation.
##   - which ROW within your own side -> a full octave pitch jump via
##     row_pitch_multiplier(), not a subtle interval - deep should sound
##     unmistakably different from short, not just "a bit higher."
##
## Bounce, racket, net, wall-bank, and crowd sounds are real recordings (see
## tools/generate_tennis_bounce.py, tools/generate_racket_hit.py,
## tools/generate_net_hit.py, tools/generate_wall_bank.py,
## tools/generate_crowd_sounds.py, tools/generate_drop_shot.py for source/
## license/trim details) - all explicitly CC0. The bounce is a small pool of
## isolated clips picked at random for natural variety (same array-of-
## variants pattern Bash Royale used for footsteps). The racket sounds are
## each a specific, dedicated recording rather than interchangeable
## variants - "hit" (a clean return), "smash" (the dedicated smash button -
## see PlayerController.gd/BotAI.gd - layered with a synthesized boom/
## shimmer for extra weight, see tools/generate_smash_impact.py), "mishit"
## (a weak, under-powered return that "dollies" up into an easy, slow ball -
## see Ball.gd), and "drop_shot" (the dedicated drop-shot button - see
## PlayerController.gd - a genuinely soft racket tap, from a different source
## recording than the other three so it reads as its own distinct sound, not
## a re-pitched one). Crowd cheer/boo replaced the earlier procedurally-
## synthesized versions per feedback asking for something more realistic.

const BOUNCE_SOUNDS := [
	preload("res://audio/sfx/tennis_bounce_00.wav"),
	preload("res://audio/sfx/tennis_bounce_01.wav"),
	preload("res://audio/sfx/tennis_bounce_02.wav"),
]

const SOUNDS := {
	"bounce_locate": BOUNCE_SOUNDS,
	"bounce_second": BOUNCE_SOUNDS,
	"hit": preload("res://audio/sfx/racket_hit.wav"),
	"smash": preload("res://audio/sfx/smash_impact.wav"),
	"mishit": preload("res://audio/sfx/racket_mishit.wav"),
	"drop_shot": preload("res://audio/sfx/drop_shot.wav"),
	"net_hit": preload("res://audio/sfx/net_hit.wav"),
	"wall_bank": preload("res://audio/sfx/wall_bank.wav"),
	"cheer": preload("res://audio/sfx/cheer.wav"),
	"boo": preload("res://audio/sfx/boo.wav"),
	"ready_chime": preload("res://audio/sfx/ready_chime.wav"),
	"afro_pop": preload("res://audio/emotes/afro_pop.wav"),
	"hip_hop": preload("res://audio/emotes/hip_hop.wav"),
	"eastern_folk_dance": preload("res://audio/emotes/eastern_folk_dance.wav"),
	"silly_voice": preload("res://audio/emotes/silly_voice.wav"),
	"uk_drill": preload("res://audio/emotes/uk_drill.wav"),
	"villain_laugh": preload("res://audio/emotes/villain_laugh.wav"),
	"chiptune_victory": preload("res://audio/emotes/chiptune_victory.wav"),
	"airhorn_hype": preload("res://audio/emotes/airhorn_hype.wav"),
	"latin_party": preload("res://audio/emotes/latin_party.wav"),
}

## Sounds happening on your own side play on this bus (full range, no cut).
const NEAR_BUS := "Master"
## Sounds happening on the opponent's side play on this bus instead - a
## deliberately muffled, quieter "that's over there" cue that doesn't depend
## on exact distance or panning to read correctly.
const DISTANT_BUS := "Distant"
const DISTANT_LOWPASS_HZ := 900.0
const DISTANT_VOLUME_DB := -6.0

const DEFAULT_MAX_DISTANCE := 30.0
const DEFAULT_UNIT_SIZE := 2.0

## Row 0 (nearest the net) vs row 1 (nearest the back wall, on a 2-row-deep
## side) map to a full octave apart - not a subtle interval - so each row
## reads as an unmistakably different "note" instead of blurring together.
const ROW_PITCH_TABLE := [1.0, 2.0]

func _ready() -> void:
	if AudioServer.get_bus_index(DISTANT_BUS) == -1:
		var idx: int = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, DISTANT_BUS)
		AudioServer.set_bus_send(idx, NEAR_BUS)
		AudioServer.set_bus_volume_db(idx, DISTANT_VOLUME_DB)
		var lpf := AudioEffectLowPassFilter.new()
		lpf.cutoff_hz = DISTANT_LOWPASS_HZ
		AudioServer.add_bus_effect(idx, lpf)

func play_at(sound_name: String, global_pos: Vector3, volume_db: float = 0.0, pitch: float = 1.0,
		bus: String = NEAR_BUS, max_distance: float = DEFAULT_MAX_DISTANCE) -> void:
	var entry = SOUNDS.get(sound_name)
	if entry == null:
		push_warning("Sfx3D: unknown sound '%s'" % sound_name)
		return
	var stream: AudioStream = entry[randi() % entry.size()] if entry is Array else entry
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch
	player.max_distance = max_distance
	player.unit_size = DEFAULT_UNIT_SIZE
	player.bus = bus
	get_tree().current_scene.add_child(player)
	player.global_position = global_pos
	player.play()
	player.finished.connect(player.queue_free)

## Non-positional sting (cheer/boo) - a point outcome isn't a location cue,
## so it just plays centered rather than through the 3D listener.
func play_ui(sound_name: String, volume_db: float = 0.0) -> void:
	var entry = SOUNDS.get(sound_name)
	if entry == null:
		push_warning("Sfx3D: unknown sound '%s'" % sound_name)
		return
	var stream: AudioStream = entry[randi() % entry.size()] if entry is Array else entry
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = NEAR_BUS
	get_tree().current_scene.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

## row_index: 0 (nearest the net) .. Court.ROWS-1 (nearest the back wall),
## on whichever side the sound is occurring.
func row_pitch_multiplier(row_index: int) -> float:
	return ROW_PITCH_TABLE[clampi(row_index, 0, ROW_PITCH_TABLE.size() - 1)]

## Controller rumble - a second, non-audio channel for the same events as
## play_at()/play_ui(), which matters for a blind player as genuine haptic
## accessibility feedback, not just game-feel polish. Deliberately only used
## for events on the player's own side (their hit, their own-side bounces,
## point outcomes) - the opponent's side stays audio-only, same as it stays
## on the muffled Distant bus rather than Near. Respects Settings' vibration
## toggle (GameSettings.vibration_enabled) - checked centrally here so every
## call site gets it for free. Note: Godot's Input.start_joy_vibration only
## reaches some controllers on Windows - reports of "no rumble at all" even
## with this on are usually a DirectInput-only controller (common for some
## PS4/PS5 pads over certain connections) rather than a bug here; Xbox
## controllers (XInput) are the most reliable.
func rumble(weak_magnitude: float, strong_magnitude: float, duration: float) -> void:
	if not GameSettings.vibration_enabled:
		return
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)

## A three-stage "wind-up, big hit, long rolling aftershock" pattern for the
## smash shot - the longest, strongest rumble in the game, reflecting how
## much harder it hits than a normal shot.
func rumble_smash() -> void:
	rumble(0.5, 0.3, 0.06)
	await get_tree().create_timer(0.07).timeout
	rumble(1.0, 1.0, 0.18)
	await get_tree().create_timer(0.16).timeout
	rumble(0.55, 0.75, 0.45)
