extends Node
## Press P (or Xbox X / PS5 Square) to freeze gameplay in place, press again
## to resume. Uses Godot's built-in tree-pause rather than hand-rolling a
## freeze flag through every script: every other node in the scene (ball,
## player, bot) uses the default inherited pause behavior and simply stops
## processing, so nothing extra was needed there. This node has to be the
## one exception - it sets itself to always process so it can keep listening
## for the un-pause press while everything else is frozen.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		Voice.say("paused")
		Music.play_music()
	else:
		Voice.say("resumed")
		Music.stop_music()
	get_viewport().set_input_as_handled()
