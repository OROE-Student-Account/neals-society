extends Node2D

@export var target_sprite: Sprite2D

@export_group("Expansion & Blast")
@export var pixel_spread: float = 3.0    # Scales the gaps along the skewed axes
@export var blast_force: float = 40.0   # A true, un-skewed circular push in world space
@export var expand_duration: float = 1.0

var pixel_sprites: Array[Sprite2D] = []

func _ready() -> void:
	if not target_sprite:
		push_error("Please assign a target_sprite in the Inspector!")
		return
	
	var source_texture = target_sprite.texture
	if not source_texture:
		return
		
	var image: Image = source_texture.get_image()
	
	# Automatically handle whether the target sprite uses a region or the full texture
	var region: Rect2 = Rect2(Vector2.ZERO, source_texture.get_size())
	if target_sprite.region_enabled:
		region = target_sprite.region_rect
	
	var white_img: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white_img.set_pixel(0, 0, Color.WHITE)
	var pixel_texture: ImageTexture = ImageTexture.create_from_image(white_img)

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
			
			# 1. Calculate the pixel's local position relative to the sprite's origin
			var local_pos: Vector2 = Vector2(x, y)
			if target_sprite.centered:
				local_pos -= region.size / 2.0
			local_pos += target_sprite.offset
			
			# 2. Multiply by global_transform to inherit position, rotation, scale, and skew
			var global_orig_pos: Vector2 = target_sprite.global_transform * local_pos
			
			# Position the pixel in world space
			sprite.global_position = global_orig_pos
			sprite.set_meta("global_orig_pos", global_orig_pos)
			
			add_child(sprite)
			pixel_sprites.append(sprite)

func explode() -> void:
	if not target_sprite: 
		return
	
	# Hide the original sprite instantly so it looks like it shattered
	target_sprite.visible = false
	
	var global_center: Vector2 = target_sprite.global_position
	var tween: Tween = create_tween().set_parallel(true)
	
	for sprite in pixel_sprites:
		var global_orig_pos: Vector2 = sprite.get_meta("global_orig_pos")
		
		# Get a true, normalized global direction vector pointing away from the center
		var push_dir: Vector2 = (global_orig_pos - global_center).normalized()
		if push_dir == Vector2.ZERO:
			push_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		
		# Math breakdown:
		# 1. (global_orig_pos - global_center) * pixel_spread -> Expands the pixels out 
		#    along their already skewed and rotated relative vectors.
		# 2. + (push_dir * blast_force) -> Adds a perfectly uniform world-space circular push.
		var global_spread_vec: Vector2 = (global_orig_pos - global_center) * pixel_spread
		var global_target_pos: Vector2 = global_center + global_spread_vec + (push_dir * blast_force)
		
		# Animate using global_position so the manager node's own position doesn't interfere
		tween.tween_property(sprite, "global_position", global_target_pos, expand_duration) \
			.set_trans(Tween.TRANS_EXPO) \
			.set_ease(Tween.EASE_OUT)
			
		tween.tween_property(sprite, "modulate:a", 0.0, expand_duration) \
			.set_trans(Tween.TRANS_SINE) \
			.set_ease(Tween.EASE_IN)
			
	await tween.finished
	queue_free()
