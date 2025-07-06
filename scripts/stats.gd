extends Control

func _ready() -> void:
	if StatsUtils.statsFileExists():
		showStats()
	else:
		
		# initialize file
		StatsUtils.initStats()
		# then show stats
		showStats()
		
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func showStats():
	var save_data = StatsUtils.getStats()
	var statsContainer = get_node("StatsMarginContainer/VBoxContainer")
	
	statsContainer.get_node("wins").text = "فوز: " + str(int(save_data["wins"]))
	statsContainer.get_node("losses").text = "خسارة: " + str(int(save_data["losses"]))
	statsContainer.get_node("ties").text = "تعادل: " + str(int(save_data["ties"]))
	statsContainer.get_node("used_hint").text = "استخدمت مساعدة: " + str(int(save_data["used_hint"]))
