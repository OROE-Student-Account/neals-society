extends Node2D
class_name BattleManager

@export var player_grammarite: Node2D 
@export var enemy_grammarite: Node2D  
@export var battle_ui: Node2D     
@export var evolve_screen: Node2D     

var trainer = "random"


signal battle_ended(player_won: bool)

enum BattleState { PLAYER_TURN, ENEMY_TURN, ANIMATING, BATTLE_END }
var current_state = BattleState.PLAYER_TURN

func _ready():
	# Connect to battle UI
	evolve_screen.visible = false
	if battle_ui:
		battle_ui.move_selected.connect(_on_player_move_selected)
	
	start_battle()


func start_battle():
	current_state = BattleState.PLAYER_TURN


func _on_player_move_selected(move_index: int):
	if current_state != BattleState.PLAYER_TURN:
		return  # Ignore if not player's turn
	
	if move_index != -1:
		var player_move = player_grammarite.grammarite_info["Moves"][move_index]
		await execute_attack(player_grammarite, enemy_grammarite, player_move)
	else:
		await execute_attack(player_grammarite, enemy_grammarite, { "Name": "Struggle" })
	
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
	
	if move["Name"] != "Struggle":
		# Check accuracy
		var accuracy = move.get("Accuracy", 0) # If no accuracy included, auto miss
		var hit_roll = randf()
		var defense_stat = calc_stat(defender.grammarite_info["Stats"]["Defense"], defender.level)/6
		
		accuracy *= 1 - (defense_stat/100)
		
		if hit_roll > accuracy:
			battle_ui.set_info_text("The attack missed!")
			await get_tree().create_timer(1.0).timeout
			return
		
		attacker.anim_player.play("Attack")
		
		var crit = false
		
		# Calculate damage
		var attack_level = attacker.level
		var base_damage = move.get("Damage", 0) # if no damage included, no damage
		var attack_stat = calc_stat(attacker.grammarite_info["Stats"]["Attack"], attack_level)
		var effectiveness = 1
		if len(defender.grammarite_info["Stats"]["Types"]) == 2:
			effectiveness = Utils.get_damage_multiplier(move["Type"], defender.grammarite_info["Stats"]["Types"][0], defender.grammarite_info["Stats"]["Types"][1])
		else:
			effectiveness =  Utils.get_damage_multiplier(move["Type"], defender.grammarite_info["Stats"]["Types"][0])
		
		
		var damage = (((2*attack_level) / 5 + 2) * base_damage * attack_stat ) / 50 + 2
		
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
		
	else:
		attacker.update_health(-int(15*randf_range(0.85, 1.0)))
		defender.update_health(-int(7*randf_range(6.0/7.0, 1.1))) # 6 or 7 damage 
		
		attacker.anim_player.play("Attack")
		
		battle_ui.set_info_text(attacker.grammarite_name+ " hurts itself.")
	
	var party = Utils.get_party()
	party[0]["Health"] = player_grammarite.health
	Utils.set_party(party)
	# Wait for animation and message display
	await get_tree().create_timer(0.9).timeout

func calc_stat(base, level):
	return 5 + 0.02 * level * (14 + base) 


func throw_book(book_name):
	if current_state != BattleState.PLAYER_TURN or trainer != "random": return
	current_state = BattleState.ANIMATING
	
	
	battle_ui.set_info_text("You threw a "+book_name+"!")
	
	
	
	
	get_parent().get_node("BookAnimation/AnimationPlayer").play("ThrowBook")
	
	await get_tree().create_timer(0.6).timeout
	
	get_parent().get_node("BookAnimation/AnimationPlayer").play("BookShake")
	
	await get_tree().create_timer(0.6).timeout
	
	
	var base_chance = enemy_grammarite.max_health / (enemy_grammarite.max_health + 3 * enemy_grammarite.health)
	var caught = randf()
	
	if book_name == "Chapter Book":
		base_chance *= 1.5
	
	
	if caught < base_chance:
		battle_ui.set_info_text("You caught it!")
		await get_tree().create_timer(0.6).timeout
		# enemy_grammarite goes to your storage
		end_battle(true)
		return
	
	battle_ui.set_info_text("It broke free.")
	await get_tree().create_timer(0.6).timeout
	
	
	
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

func end_battle(player_won: bool):
	current_state = BattleState.BATTLE_END
	
	if player_won:
		battle_ui.set_info_text("You won!")
		await get_tree().create_timer(1.65).timeout
		var party = Utils.get_party()
		var xp = 0
		
		if trainer != "random":
			xp = Utils.get_trainer(trainer)["XP"]
		else:
			xp = enemy_grammarite.level
		
		# TODO: FIX ALL OF THIS
		if fmod(party[0]["Level"], 1.0) + xp*0.01 > 1.0:
			battle_ui.set_info_text("Your Grammarite leveled up!")
			await get_tree().create_timer(1.5).timeout
			if Utils.can_evolve(player_grammarite.grammarite_name, player_grammarite.level):
				var old_name = party[0]["Name"]
				var new_name = Utils.get_name_from_num(1 + Utils.get_poke_num(old_name))
				party[0]["Name"] = new_name
				
				evolve_screen.visible = true
				evolve_screen.get_node("NinePatchRect/Label").text ="WHAT? "+old_name+" is evolving!"
				evolve_screen.get_node("Sprite2D").texture = load("res://Assets/Pokemon/Pokemon"+str(Utils.get_poke_num(old_name)+1)+".png")
				evolve_screen.get_node("AnimationPlayer").play("Evolve")
				await get_tree().create_timer(1.4).timeout
				evolve_screen.get_node("Sprite2D").texture = load("res://Assets/Pokemon/Pokemon"+str(Utils.get_poke_num(new_name)+1)+".png")
				evolve_screen.get_node("NinePatchRect/Label").text = old_name+" evolved into "+new_name+"!"
				await get_tree().create_timer(2.2).timeout
		
		party[0]["Level"] += 0.01 * xp
		if party[0]["Level"] > 100: party[0]["Level"] = 100
		Utils.set_party(party)
	else:
		battle_ui.set_info_text("You lost!")
		await get_tree().create_timer(1.8).timeout
	
	battle_ended.emit(player_won)
	
	Utils.get_scene_manager().transition_exit_battle()
