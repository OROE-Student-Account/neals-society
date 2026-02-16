extends Node2D

@export var is_enemy := false
@export var grammarite_name := ""
@export var move_vbox : Node = null
@export var level = 1

@onready var grammarite_info = Utils.get_grammarite_details(grammarite_name) 
@onready var health_bar = $HealthBar
@onready var anim_player = $AnimationPlayer

var health : int = 1
var max_health : int = 1

func _ready():
	health = grammarite_info["Stats"]["Health"]
	max_health = health
	$Level.text = str(level)
	
	update_health(0)
	if not is_enemy:
		$Health.text = str(health)
		$MaxHealth.text = str(max_health)


func update_moves():
	var children = move_vbox.get_children()
	for i in range(len(children)):
		children[i].text = grammarite_info["Moves"][i]["Name"]


# damage should be negative, healing should be positive
# keep this seperate for later (health bar, other stuff)
func update_health(change):
	health = clamp(health + int(change), 0, max_health)  # Clamp between 0 and max
	
	var pecent_health = float(health) / max_health
	health_bar.scale.x = pecent_health
	health_bar.color.g = pecent_health
	health_bar.color.r = 1 - pecent_health
	
	if not is_enemy:
		$Health.text = str(health)
