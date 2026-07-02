extends Node2D


@export var base: Texture2D = null
@export var grass_overlay_texture: Texture2D = null
@export var anim: Texture2D = null

const GrassStepEffect = preload("res://Scenes/GrassStepEffect.tscn")

@export_group("Encounter Data")
@export var encounter_level: int = 1
@export var encounter_types: Array[String] = []


var grass_overlay: Node2D = null

func _ready() -> void:
	# 1. Force the Manager node itself to participate in Y-Sorting
	self.y_sort_enabled = true
	
	var player = Utils.get_player()
	if player:
		player.connect("player_moving_signal", Callable(self, "player_exiting_grass"))
	
	for grass in get_children():
		if grass is Node2D:
			grass.get_node("Node2D/Sprite2D").texture = base
			# 2. Force each individual grass tile to pass Y-sorting down to its children
			grass.y_sort_enabled = true
			
		var area = grass.get_node_or_null("Area2D")
		if area:
			area.body_entered.connect(_on_grass_body_entered.bind(grass))

func player_exiting_grass() -> void:
	if is_instance_valid(grass_overlay):
		grass_overlay.queue_free()

func player_in_grass(grass_node: Node2D) -> void:
	var offset_pos = Vector2(0, 1)
	
	grass_overlay = Node2D.new()
	grass_overlay.y_sort_enabled = false
	
	# 1. ADD the offset to push its Y-sorting position 1 pixel lower (in front of the player)
	grass_overlay.position += offset_pos
	
	var texture_overlay = TextureRect.new()
	texture_overlay.texture = grass_overlay_texture
	# 2. SUBTRACT the offset to pull the visual texture back up into perfect alignment
	texture_overlay.position -= offset_pos
	
	var grass_step_effect = GrassStepEffect.instantiate()
	grass_step_effect.sprite_frames = SpriteFrames.new()
	grass_step_effect.sprite_frames.set_animation_loop("default", false)
	for i in range(4):
		var atlas = AtlasTexture.new()
		atlas.atlas = anim
		atlas.region = Rect2(16*i,0,16,16)
		grass_step_effect.sprite_frames.add_frame("default", atlas)
	
	# 3. SUBTRACT here too so the particle animation aligns with the texture
	grass_step_effect.position -= offset_pos
	
	grass_overlay.add_child(texture_overlay)
	grass_overlay.add_child(grass_step_effect)
	grass_overlay.modulate = Color(1.353, 1.353, 1.353)
	
	grass_node.add_child(grass_overlay)

func _on_grass_body_entered(_body: Node2D, grass_node: Node2D) -> void:
	var anim_player = grass_node.get_node_or_null("AnimationPlayer")
	if anim_player:
		anim_player.play("Stepped")
	
	player_in_grass(grass_node)
	encounter_grammarite(0.1, grass_node)

func encounter_grammarite(chance: float, grass_node: Node2D) -> void:
	var player = Utils.get_player()
	if player.walk_speed > 4:
		chance *= 2
	
	if randf() < chance:
		player.set_physics_process(false)
		
		var dialogue_root = grass_node.get_node_or_null("DialogueRoot")
		if dialogue_root:
			Utils.get_scene_manager().transition_to_dialogue(dialogue_root)
		else:
			push_error("DialogueRoot node is missing from grass node: " + grass_node.name)
			player.set_physics_process(true)
