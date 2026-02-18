extends Node2D

@onready var lvl = $LevelLabel





func set_health(max_health, current):
	max_health = int(max_health)
	current = int(current)
	
	$MaxHealthLabel.text = str(max_health)
	$HealthLabel.text = str(current)
	
	var pecent_health = float(current) / max_health
	$HealthBar.scale.x = pecent_health
	$HealthBar.color.g = pecent_health
	$HealthBar.color.r = 1.0 - pecent_health

func set_sprites(num):
	var file_path = "res://Assets/Pokemon/Pokemon"+str(num+1)+".png"
	$PokemonPartySprite.texture = load(file_path)
	$PokemonName.texture = load(file_path)
