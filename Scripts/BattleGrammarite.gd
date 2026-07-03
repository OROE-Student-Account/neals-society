extends Node2D

@export var is_enemy := false
@export var move_vbox : Node = null


var grammarite_name = ""
var nickname = ""
var level = 1
var grammarite_info = null
var item = ""
@onready var health_bar = $HealthBar
@onready var anim_player = $AnimationPlayer

var health : int = 1
var max_health : int = 1

func _ready():
	setup()

func setup():
	
	if not is_enemy:
		var first_grammarite = Utils.get_party()[0]
		grammarite_name = first_grammarite["Name"]
		grammarite_info = Utils.get_grammarite_details(grammarite_name)
		nickname = first_grammarite["Nickname"]
		level = int(first_grammarite["Level"])
		health = first_grammarite["Health"]
		item = first_grammarite["Item"]
		max_health = Utils.max_hp(grammarite_name, level)
		if item == "Colon":
			max_health *= 1.1
			max_health = int(10 + max_health)
		
		for i in range(4):
			var move_info = Utils.get_move(first_grammarite["Moves"][i])
			move_info["Name"] = first_grammarite["Moves"][i]
			grammarite_info["Moves"][i] = move_info
	else:
		grammarite_info = Utils.get_grammarite_details(grammarite_name) 
		max_health = Utils.max_hp(grammarite_name, level)
		health = max_health
	
	$Level.text = "lvl "+str(int(level))
	if nickname == "":
		$Name.text = grammarite_name
	else:
		$Name.text = nickname
	
	var grammadex_num = str(Utils.get_poke_num(grammarite_name)+1)
	$Grammarite.texture = load("res://Assets/Pokemon/Pokemon"+grammadex_num+".png")
	
	update_health(0)
	$Health.text = str(health)
	$MaxHealth.text = str(max_health)


func update_moves():
	var children = move_vbox.get_children()
	for i in range(len(children)):
		children[i].text = grammarite_info["Moves"][i]["Name"]




# damage should be negative, healing should be positive
func update_health(change):
	health = clamp(health + int(change), 0, max_health)  # Clamp between 0 and max
	
	var pecent_health = float(health) / max_health
	health_bar.scale.x = pecent_health
	health_bar.color.g = pecent_health
	health_bar.color.r = HEALTH_BAR_R - pecent_health
	
	$Health.text = str(health)




const HEALTH_BAR_R = 1.3 # also in party slot, maybe fix somehow
