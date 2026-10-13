extends Node
class_name QuestTrigger

@export var quest_id: int = 0

# Updates the overarching status (e.g., "Started", "Incoming")
func set_progress(progress_state: String) -> void:
	Utils.set_quest_progress(progress_state, quest_id)

# Completes a specific step in an "Objective" style quest
func complete_objective(objective_index: int) -> void:
	Utils.update_quest_objective(quest_id, objective_index, true)

# Adds to the tally of a "Count" style quest
func add_to_count(amount: int = 1) -> void:
	Utils.update_quest_count(quest_id, amount)
