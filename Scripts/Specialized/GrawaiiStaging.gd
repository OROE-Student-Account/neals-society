extends CanvasLayer
## Local staging fade. It never invokes the SceneManager's scene-change callbacks.
signal covered
var active := false
var curtain: ColorRect

func _ready() -> void:
	curtain = ColorRect.new()
	curtain.name = "Curtain"
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color(0, 0, 0, 0)
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	curtain.hide()
	add_child(curtain)

func _input(_event: InputEvent) -> void:
	if active: get_viewport().set_input_as_handled()

func fade_to(setup: Callable, spawn: Vector2, direction := Vector2.UP) -> bool:
	if active: return false
	active = true
	var player = Utils.get_player()
	var was_processing: bool = player.is_physics_processing()
	var was_stopped: bool = player.stop_input
	player.set_physics_process(false)
	player.stop_input = true
	curtain.show()
	var fade = create_tween()
	fade.tween_property(curtain, "color:a", 1.0, 0.4)
	await fade.finished
	var changed: bool = setup.call()
	if changed:
		player.set_spawn(spawn, direction)
		player.facing_direction = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN].find(direction)
		player.player_state = player.PlayerState.IDLE
		player.sprite.position = Vector2(16, 0)
		player.camera.position = Vector2(8, 8)
		player.camera.reset_smoothing()
		player.camera.force_update_scroll()
		player.stop_input = true
	covered.emit()
	await get_tree().create_timer(0.15).timeout
	fade = create_tween()
	fade.tween_property(curtain, "color:a", 0.0, 0.4)
	await fade.finished
	curtain.hide()
	player.stop_input = was_stopped
	player.set_physics_process(was_processing)
	active = false
	return changed
