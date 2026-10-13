extends Node2D

func breaker():
	Utils.update_obstacle("final_room", true, "PowerPlant")
	Utils.update_obstacle("CaveBlockade", true, "Town")
