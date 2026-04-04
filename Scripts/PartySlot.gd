extends Node2D

@onready var lvl = $LevelLabel


enum States { NONE, SUMMARY }
var state = States.NONE


func set_health(max_health, current):
	max_health = int(max_health)
	current = int(current)
	
	var pecent_health = float(current) / max_health
	$HealthBar.scale.x = pecent_health
	$HealthBar.color.g = pecent_health
	$HealthBar.color.r = 1.0 - pecent_health
	
	var percent_health = max(0, (61 * pecent_health - 4) / 57)
	
	$HealthBar2.scale.x = percent_health
	$HealthBar2.color.g = pecent_health
	$HealthBar2.color.r = 1.0 - pecent_health

func set_sprites(num):
	var file_path = "res://Assets/Pokemon/Pokemon"+str(num+1)+".png"
	$PokemonPartySprite.texture = load(file_path)
	$GrammariteName.text = Utils.get_name_from_num(num)





func show_screen():
	match state:
		States.NONE:
			$SummaryScreen.visible = false
		States.SUMMARY:
			$SummaryScreen.visible = true


func _input(event):
	match state:
		States.SUMMARY:
			if event.is_action_pressed("x"):
				state = States.NONE
				show_screen()
