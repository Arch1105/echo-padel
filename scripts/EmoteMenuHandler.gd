extends Node
## Left Shift (or a controller's left bumper) opens the in-match emote menu
## (see EmoteMenu.tscn/gd) during a LAN match - a separate button from smash/
## ready (B), which was already claimed by two other meanings. LAN-only (see
## OnlineData.gd/Emotes.gd) - inert during Play/Training/Career.
##
## Reuses the same tree-pause trick PauseHandler.gd already established:
## process_mode ALWAYS so this node (and the overlay it spawns, also ALWAYS)
## keeps working while get_tree().paused freezes the actual match underneath.

var _menu: EmoteMenu = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if not NetworkSession.is_networked:
		return
	if _menu != null:
		return
	if not event.is_action_pressed("emote_menu"):
		return
	_menu = preload("res://scenes/EmoteMenu.tscn").instantiate()
	add_child(_menu)
	_menu.closed.connect(_on_menu_closed)
	get_tree().paused = true
	get_viewport().set_input_as_handled()

func _on_menu_closed() -> void:
	if _menu:
		_menu.queue_free()
		_menu = null
	get_tree().paused = false
