extends Node2D

@onready var lvl = $LevelLabel


enum States { NONE, SUMMARY }
var state = States.NONE


func set_health(max_health: int, current: int):

	var pecent_health = min(1, float(current) / max_health)
	$HealthBar.scale.x = pecent_health
	$HealthBar.color.g = pecent_health
	$HealthBar.color.r = HEALTH_BAR_R - pecent_health
	
	var percent_health = max(0, ((HEALTH_BAR_LEN+HEALTH_BAR_LEN_DIFF) * pecent_health - HEALTH_BAR_LEN_DIFF) / HEALTH_BAR_LEN)
	
	$HealthBar2.scale.x = percent_health
	$HealthBar2.color.g = pecent_health
	$HealthBar2.color.r = HEALTH_BAR_R - pecent_health
	if current <= 0:
		kill()

func set_sprites(index):
	var slot_data = Utils.get_party()[index]
	var num = Utils.get_poke_num(slot_data["Name"])
	
	$PokemonPartySprite.texture = load("res://Assets/Pokemon/Pokemon"+str(num+1)+".png")
	if slot_data["Nickname"] == "":
		$GrammariteName.text = slot_data["Name"]
	else:
		$GrammariteName.text = slot_data["Nickname"]

func kill():
	$AnimationPlayer.stop()
	$PokemonPartySprite.modulate = DEAD_COLOR

func show_screen():
	match state:
		States.NONE:
			$SummaryScreen.visible = false
		States.SUMMARY:
			$SummaryScreen.visible = true

func _input(event):
	if state == States.SUMMARY and event.is_action_pressed("x"):
		state = States.NONE
		show_screen()


const HEALTH_BAR_R = 1.3 # also in battle grammarite, maybe fix somehow

const DEAD_COLOR = Color(1,0.3,0.3,0.85)
const HEALTH_BAR_LEN = 57
const HEALTH_BAR_LEN_DIFF = 4
