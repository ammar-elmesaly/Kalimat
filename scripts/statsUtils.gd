extends Node


func getStats():
	if statsFileExists():
		var file = FileAccess.open("user://save_stats.json", FileAccess.READ)
		var content = file.get_as_text()
		var save_data = JSON.parse_string(content)
		return save_data
	else:
		initStats()
		return getStats()


func setStats(save_data):
	var file = FileAccess.open("user://save_stats.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()


func initStats():
	if !statsFileExists():
		var save_data = {
			"wins": 0,
			"losses": 0,
			"ties": 0,
			"used_hint": 0
		}

		var file = FileAccess.open("user://save_stats.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(save_data))
		file.close()
	else:
		return -1


func statsFileExists():
	return FileAccess.file_exists("user://save_stats.json")
