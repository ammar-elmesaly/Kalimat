extends Control


func _on_open_stats_pressed() -> void:
	StatsUtils.previous_scene_path = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://scenes/stats.tscn")


func _on_multiplayer_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")


func _on_solo_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/solo_game.tscn")
