extends Node2D
class_name BattleManager

@export var player_grammarite: Node2D  # Your Grammarite node
@export var enemy_grammarite: Node2D   # Enemy Grammarite node
@export var battle_ui: Node2D          # Your Battle.gd node

signal battle_ended(player_won: bool)

enum BattleState { PLAYER_TURN, ENEMY_TURN, ANIMATING, BATTLE_END }
var current_state = BattleState.PLAYER_TURN

func _ready():
	# Connect to battle UI
	if battle_ui:
		battle_ui.move_selected.connect(_on_player_move_selected)
	
	start_battle()

func start_battle():
	print("Player: ", player_grammarite.grammarite_name, " (", player_grammarite.health, " HP)")
	print("Enemy: ", enemy_grammarite.grammarite_name, " (", enemy_grammarite.health, " HP)")
	current_state = BattleState.PLAYER_TURN

func _on_player_move_selected(move_index: int):
	if current_state != BattleState.PLAYER_TURN:
		return  # Ignore if not player's turn
	
	var player_move = player_grammarite.grammarite_info["Moves"][move_index]
	await execute_attack(player_grammarite, enemy_grammarite, player_move)
	
	# Check if enemy fainted
	if enemy_grammarite.health <= 0:
		end_battle(true)
		return
	
	# Enemy's turn
	await enemy_turn()
	
	# Check if player fainted
	if player_grammarite.health <= 0:
		end_battle(false)
		return
	
	# Back to player's turn
	current_state = BattleState.PLAYER_TURN
	battle_ui.input_state = battle_ui.InputState.ACTION_BUTTONS
	battle_ui.show_correct_menu()

func enemy_turn():
	current_state = BattleState.ENEMY_TURN
	
	print("\nEnemy's turn...")
	await get_tree().create_timer(1.0).timeout
	
	# pick random move
	var moves = enemy_grammarite.grammarite_info["Moves"]
	var random_move = moves[randi() % moves.size()]
	
	await execute_attack(enemy_grammarite, player_grammarite, random_move)

func execute_attack(attacker: Node2D, defender: Node2D, move: Dictionary):
	current_state = BattleState.ANIMATING
	
	print("\n", attacker.grammarite_name, " used ", move["Name"], "!")
	
	# Check accuracy
	var accuracy = move.get("Accuracy", 0) # If no accuracy, auto miss
	var hit_roll = randf()
	
	if hit_roll > accuracy:
		print("The attack missed!")
		await get_tree().create_timer(1.0).timeout
		return
	
	# Calculate damage
	var base_damage = move.get("Damage", 0) # if no damage, too bad
	var attack_stat = attacker.grammarite_info["Stats"].get("Attack")
	
	# Simple formula = base damage * (attack / 10)
	var damage = base_damage * (attack_stat / 10.0)
	
	# Add some randomness (90% to 100% of calculated damage)
	damage = damage * randf_range(0.9, 1.0)
	# no negative damage
	damage = max(0, int(damage)) 
	
	# Apply damage
	defender.update_health(-damage)
	
	print(defender.grammarite_name, " took ", damage, " damage!")
	print(defender.grammarite_name, " has ", defender.health, " HP remaining")
	
	attacker.anim_player.play("Attack")
	# Wait for animation/message display
	await get_tree().create_timer(1.5).timeout

func end_battle(player_won: bool):
	current_state = BattleState.BATTLE_END
	
	if player_won:
		print("\n=== YOU WON! ===")
		print(enemy_grammarite.grammarite_name, " fainted!")
	else:
		print("\n=== YOU LOST! ===")
		print(player_grammarite.grammarite_name, " fainted!")
	
	battle_ended.emit(player_won)
	
	await get_tree().create_timer(2.0).timeout
	Utils.get_scene_manager().transition_exit_battle()
