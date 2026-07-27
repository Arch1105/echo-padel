extends Node
## Looping background music - only ever plays on the main menu or while
## gameplay is paused (see PauseHandler.gd), never during active play. See
## tools/generate_menu_music.py for the track's source/license/loop-prep
## details - an original CC0 composition, not a cover of any commercial
## song.
##
## process_mode is ALWAYS so playback keeps working (and can be started)
## while get_tree().paused is true - by default a node stops processing
## when the tree pauses, which would be exactly backwards here since pause
## is what's supposed to start the music.

const TRACK: AudioStreamMP3 = preload("res://audio/music/menu_theme.mp3")
const VOLUME_DB := -10.0

var _player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)
	_player.bus = "Master"
	var stream: AudioStreamMP3 = TRACK.duplicate()
	stream.loop = true
	_player.stream = stream
	_player.volume_db = VOLUME_DB

func play_music() -> void:
	if not _player.playing:
		_player.play()

func stop_music() -> void:
	if _player.playing:
		_player.stop()
