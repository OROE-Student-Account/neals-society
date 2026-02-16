extends Node2D

@onready var lvl = $LevelLabel





func set_health(max, current):
	max = int(max)
	current = int(current)
	
	$MaxHealthLabel.text = str(max)
	$HealthLabel.text = str(current)
	
	var pecent_health = float(current) / max
	$HealthBar.scale.x = pecent_health
	$HealthBar.color.g = pecent_health
	$HealthBar.color.r = 1.0 - pecent_health
