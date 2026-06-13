extends Node2D

@export var source_texture: Texture2D
@export var region: Rect2 = Rect2(0, 0, 64, 64)

@export_group("Phase 1: Slow V-Crack")
@export var v_split_distance: float = 12.0
@export var v_duration: float = 1.4

@export_group("Phase 2: Quick Parallel Split")
@export var full_split_distance: float = 30.0
@export var split_duration: float = 0.25
@export var overlap_time: float = 0.1         # How many seconds before Phase 2 ends the blast should trigger

@export_group("Phase 3: Expansion & Blast")
@export var pixel_spread: float = 3.0
@export var blast_force: float = 40.0
@export var expand_duration: float = 1.0

var pixel_sprites: Array[Sprite2D] = []
var center_offset: Vector2

func _ready() -> void:
	if not source_texture:
		push_error("Please assign a source_texture in the Inspector!")
		return
	
	var image: Image = source_texture.get_image()
	
	var white_img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white_img.set_pixel(0, 0, Color.WHITE)
	var pixel_texture: ImageTexture = ImageTexture.create_from_image(white_img)
	
	center_offset = region.size / 2.0

	for y in range(region.size.y):
		for x in range(region.size.x):
			var src_x: int = int(region.position.x) + x
			var src_y: int = int(region.position.y) + y
			
			if src_x >= image.get_width() or src_y >= image.get_height():
				continue
				
			var color: Color = image.get_pixel(src_x, src_y)
			
			if color.a <= 0.01:
				continue
				
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture = pixel_texture
			sprite.modulate = color
			
			sprite.position = Vector2(x, y) - center_offset
			sprite.set_meta("orig_pos", sprite.position)
			
			add_child(sprite)
			pixel_sprites.append(sprite)

func explode() -> void:
	# --- PHASE 1: Slow, dramatic V-shape crack ---
	var tween1: Tween = create_tween().set_parallel(true)
	
	for sprite in pixel_sprites:
		var orig_pos: Vector2 = sprite.get_meta("orig_pos")
		var is_left_half: bool = orig_pos.x < 0
		
		var tear_influence: float = 1.0 - ((orig_pos.y + center_offset.y) / region.size.y)
		var split_offset: Vector2 = Vector2(-v_split_distance, 0) if is_left_half else Vector2(v_split_distance, 0)
		
		var phase1_pos: Vector2 = orig_pos + (split_offset * tear_influence)
		
		tween1.tween_property(sprite, "position", phase1_pos, v_duration) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN_OUT)
			
	await tween1.finished
	
	# --- PHASE 2: Quick, violent parallel rip ---
	var tween2: Tween = create_tween().set_parallel(true)
	
	for sprite in pixel_sprites:
		var orig_pos: Vector2 = sprite.get_meta("orig_pos")
		var is_left_half: bool = orig_pos.x < 0
		
		var phase2_offset: Vector2 = Vector2(-full_split_distance, 0) if is_left_half else Vector2(full_split_distance, 0)
		var phase2_pos: Vector2 = orig_pos + phase2_offset
		
		tween2.tween_property(sprite, "position", phase2_pos, split_duration) \
			.set_trans(Tween.TRANS_QUAD) \
			.set_ease(Tween.EASE_OUT)
			
	# Instead of awaiting tween2 to finish completely, we wait for a slightly shorter timer
	var wait_time: float = max(0.0, split_duration - overlap_time)
	await get_tree().create_timer(wait_time).timeout
	
	# Cut Phase 2 short right here! The pixels freeze instantly wherever they are mid-snap
	tween2.kill()
	
	# --- PHASE 3: Uniform grid expansion + subtle radial blast ---
	var tween3: Tween = create_tween().set_parallel(true)
	
	for sprite in pixel_sprites:
		var orig_pos: Vector2 = sprite.get_meta("orig_pos")
		var is_left_half: bool = orig_pos.x < 0
		
		var phase2_offset: Vector2 = Vector2(-full_split_distance, 0) if is_left_half else Vector2(full_split_distance, 0)
		var push_dir: Vector2 = orig_pos.normalized()
		
		var phase3_pos: Vector2 = (orig_pos * pixel_spread) + phase2_offset + (push_dir * blast_force)
		
		# Because tween2 was killed, tween3 smoothly grabs the pixels from their current mid-air positions
		tween3.tween_property(sprite, "position", phase3_pos, expand_duration) \
			.set_trans(Tween.TRANS_EXPO) \
			.set_ease(Tween.EASE_OUT)
			
		tween3.tween_property(sprite, "modulate:a", 0.0, expand_duration) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN)
			
	await tween3.finished
	queue_free()
