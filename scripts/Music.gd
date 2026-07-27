extends Node
## Looping background music - only ever plays on the main menu, the Career
## menu screens (Hub/name-entry/Upgrades - a separate, more ominous track),
## or while gameplay is paused (see PauseHandler.gd), never during active
## play. See tools/generate_menu_music.py and tools/generate_career_music.py
## for each track's source/license/loop-prep details - both original CC0
## compositions, not covers of any commercial song.
##
## process_mode is ALWAYS so playback keeps working (and can be started)
## while get_tree().paused is true - by default a node stops processing
## when the tree pauses, which would be exactly backwards here since pause
## is what's supposed to start the music.

const MENU_TRACK: AudioStreamMP3 = preload("res://audio/music/menu_theme.mp3")
const CAREER_TRACK: AudioStreamMP3 = preload("res://audio/music/career_theme.mp3")
const VOLUME_DB := -10.0

var _player: AudioStreamPlayer
var _current_track: AudioStreamMP3 = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	_player.bus = "Master"
	_player.volume_db = VOLUME_DB

func play_music() -> void:
	_play_track(MENU_TRACK)

## The Career Hub, new-career name entry, and Upgrades screens use this
## instead of play_music() - same looping mechanism, a separate, more
## ominous track so Career mode has its own distinct identity.
func play_career_music() -> void:
	_play_track(CAREER_TRACK)

func _play_track(track: AudioStreamMP3) -> void:
	if _current_track == track and _player.playing:
		return
	_current_track = track
	var stream: AudioStreamMP3 = track.duplicate()
	stream.loop = true
	_player.stream = stream
	_player.play()

func stop_music() -> void:
	_current_track = null
	if _player.playing:
		_player.stop()
