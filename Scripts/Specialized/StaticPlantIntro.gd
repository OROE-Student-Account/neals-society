extends AnimatedSprite2D
## Starts defeated Static's existing dialogue once per visit to the plant.

var intro_started := false

func start_cutscene() -> void:
	if intro_started:
		return
	var manager = Utils.get_scene_manager()
	var player = Utils.get_player()
	if manager == null or player == null:
		return
	intro_started = true
	# Let the player finish their tile step and any active conversation first.
	while player.is_moving or manager.menu.screen_loaded != manager.menu.ScreenLoaded.NOTHING:
		await get_tree().process_frame
	manager.transition_to_dialogue($DialogueRoot)

var confrontation_started := false

func walk_to_commander() -> void:
	if confrontation_started:
		return
	var manager = Utils.get_scene_manager()
	var player = Utils.get_player()
	var commander = get_parent().get_node("sorted stuff/final_room/Commander Isold")
	confrontation_started = true
	# Dialogue completion enables movement; lock it again for the staged walk.
	player.set_physics_process(false)
	manager.menu.screen_loaded = manager.menu.ScreenLoaded.DIALOGUE
	player.is_moving = false
	player.percent_moved_to_next_tile = 0.0
	player.sprite.position = Vector2(16, 0)
	player.camera.position = Vector2(8, 8)
	# Stand two tiles to Isold's left, preserving the player's current grid.
	var desired: Vector2 = commander.global_position + Vector2(-32, 0)
	var goal := Vector2i(roundi((desired.x - player.global_position.x) / 16.0), roundi((desired.y - player.global_position.y) / 16.0))
	var route := _find_route(player, goal)
	if route.is_empty() and goal != Vector2i.ZERO:
		_cancel_walk(player, manager)
		return
	for destination in route:
		# Recheck each segment in case an obstacle moved after planning.
		if not _step_clear(player, player.global_position, destination):
			_cancel_walk(player, manager)
			return
		var direction: Vector2 = (destination - player.global_position).normalized()
		var animation := "WalkUp"
		if direction.x > 0: animation = "WalkRight"
		elif direction.x < 0: animation = "WalkLeft"
		elif direction.y > 0: animation = "WalkDown"
		player.animate(animation)
		var tween := create_tween()
		tween.tween_property(player, "global_position", destination, 16.0 / 60.0)
		await tween.finished
	player.initial_position = player.position
	player.input_direction = Vector2.RIGHT
	player.facing_direction = player.FacingDirection.RIGHT
	player.player_state = player.PlayerState.IDLE
	for state in ["Idle", "Walk", "Turn"]:
		player.anim_tree.set("parameters/" + state + "/blend_position", Vector2.RIGHT)
	player.anim_state.start("Idle")
	player.animate("TurnRight")
	commander.get_node("AnimationPlayer").play("TurnLeft")
	await get_tree().create_timer(0.2).timeout
	manager.menu.screen_loaded = manager.menu.ScreenLoaded.NOTHING
	commander.used_up = true
	Utils.update_trainer_attacked(commander.name, true, "PowerPlant")
	manager.transition_to_dialogue(commander.get_node("DialogueRoot"))

func _find_route(player, goal: Vector2i) -> Array[Vector2]:
	var origin: Vector2 = player.global_position
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var previous: Dictionary = {Vector2i.ZERO: Vector2i.ZERO}
	var index := 0
	while index < queue.size() and index < 1024:
		var cell := queue[index]
		index += 1
		if cell == goal:
			var route: Array[Vector2] = []
			while cell != Vector2i.ZERO:
				route.push_front(origin + Vector2(cell) * 16.0)
				cell = previous[cell]
			return route
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if previous.has(next) or absi(next.x) > 16 or absi(next.y) > 16:
				continue
			if _step_clear(player, origin + Vector2(cell) * 16.0, origin + Vector2(next) * 16.0):
				previous[next] = cell
				queue.append(next)
	return []

func _step_clear(player, from: Vector2, to: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 14)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, from + Vector2(8, 8))
	query.motion = to - from
	query.collision_mask = player.ray.collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]
	var space = player.get_world_2d().direct_space_state
	var fractions = space.cast_motion(query)
	if fractions[0] < 1.0:
		return false
	query.transform.origin = to + Vector2(8, 8)
	query.motion = Vector2.ZERO
	return space.intersect_shape(query, 1).is_empty()

func _cancel_walk(player, manager) -> void:
	# Never push through an obstacle or leave controls locked if no route exists.
	player.initial_position = player.position
	player.input_direction = Vector2.ZERO
	player.anim_state.start("Idle")
	player.anim_tree.active = true
	player.player_state = player.PlayerState.IDLE
	player.set_physics_process(true)
	manager.menu.screen_loaded = manager.menu.ScreenLoaded.NOTHING
	confrontation_started = false
	intro_started = false
	push_warning("Static cutscene: no clear route to Isold. Move obstacles or retry from another tile.")
