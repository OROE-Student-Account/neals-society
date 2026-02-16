extends Node2D
class_name BattleManager

@export var player_grammarite: Node2D 
@export var enemy_grammarite: Node2D  
@export var battle_ui: Node2D          


signal battle_ended(player_won: bool)

enum BattleState { PLAYER_TURN, ENEMY_TURN, ANIMATING, BATTLE_END }
var current_state = BattleState.PLAYER_TURN

func _ready():
	# Connect to battle UI
	if battle_ui:
		battle_ui.move_selected.connect(_on_player_move_selected)
	
	start_battle()

func start_battle():
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
	
	battle_ui.set_info_text("Enemy's turn")
	await get_tree().create_timer(1.0).timeout
	
	# pick random move
	var moves = enemy_grammarite.grammarite_info["Moves"]
	var random_move = moves[randi() % moves.size()]
	
	await execute_attack(enemy_grammarite, player_grammarite, random_move)

func execute_attack(attacker: Node2D, defender: Node2D, move: Dictionary):
	current_state = BattleState.ANIMATING
	
	battle_ui.set_info_text(attacker.grammarite_name+" used "+move["Name"]+"!")
	
	await get_tree().create_timer(0.9).timeout
	# Check accuracy
	var accuracy = move.get("Accuracy", 0) # If no accuracy included, auto miss
	var hit_roll = randf()
	
	if hit_roll > accuracy:
		battle_ui.set_info_text("The attack missed!")
		await get_tree().create_timer(1.0).timeout
		return
	
	attacker.anim_player.play("Attack")
	
	var crit = false
	
	# Calculate damage
	var attack_level = attacker.level
	var base_damage = move.get("Damage", 0) # if no damage included, no damage
	var attack_stat = attacker.grammarite_info["Stats"]["Attack"]
	var defense_stat = defender.grammarite_info["Stats"]["Defense"]
	var effectiveness = 1
	if len(defender.grammarite_info["Stats"]["Types"]) == 2:
		effectiveness = Utils.get_damage_multiplier(move["Type"], defender.grammarite_info["Stats"]["Types"][0], defender.grammarite_info["Stats"]["Types"][1])
	else:
		effectiveness =  Utils.get_damage_multiplier(move["Type"], defender.grammarite_info["Stats"]["Types"][0])
	
	
	var damage = (((2*attack_level) / 5 + 2) * base_damage * attack_stat / defense_stat) / 50 + 2
	
	# Makes the type chart matter
	damage *= effectiveness
	# Add some randomness (85% to 100% of calculated damage)
	damage = damage * randf_range(0.85, 1.0)
	# same type attack bonus
	if move["Type"] == attacker.grammarite_info["Stats"]["Types"][0] or move["Type"] == attacker.grammarite_info["Stats"]["Types"][1]:
		damage *= 1.5
	# crit
	if randf() > 0.95:
		damage *= 2.0
		crit = true
		
	# no negative damage
	damage = max(0, int(damage)) 
	
	# Apply damage
	defender.update_health(-damage)
	
	if crit:
		battle_ui.set_info_text("It crits!")
	elif effectiveness > 1:
		battle_ui.set_info_text("It is super effective!")
	elif effectiveness < 1:
		battle_ui.set_info_text("It is not very effective.")
	else:
		battle_ui.set_info_text("It hits!")
	
	
	# Wait for animation and message display
	await get_tree().create_timer(0.9).timeout

func end_battle(player_won: bool):
	current_state = BattleState.BATTLE_END
	
	if player_won:
		battle_ui.set_info_text("You won!")
	else:
		battle_ui.set_info_text("You lost!")
	
	battle_ended.emit(player_won)
	
	await get_tree().create_timer(2.0).timeout
	Utils.get_scene_manager().transition_exit_battle()
