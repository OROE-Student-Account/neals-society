extends Node2D

@onready var lvl = $LevelLabel
@onready var summary = $SummaryScreen


enum States { NONE, SUMMARY }
var state = States.NONE


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
	




func show_screen():
	match state:
		States.NONE:
			summary.visible = false
		States.SUMMARY:
			summary.visible = true


func _input(event):
	match state:
		States.SUMMARY:
			if event.is_action_pressed("x"):
				state = States.NONE
				show_screen()
