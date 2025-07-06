extends Control

var peer = ENetMultiplayerPeer.new()

var port : int
var address : String

func _ready() -> void:
	for ip in IP.get_local_addresses():
		if ip.contains("192.168"):
			$"IP Addresses".text = "عنوانك الخاص بك: " + ip
		
	fill_input_fields()
	

func _on_host_button_pressed() -> void:
	get_port_and_address()
	peer.set_bind_ip(address) 
	peer.create_server(port, 1)
	multiplayer.multiplayer_peer = peer
	_add_game()
	multiplayer.peer_connected.connect(
		func(id):
			await get_tree().create_timer(1).timeout
			rpc("_add_newly_connected_game", id)
	)
	$ButtonsContainer.visible = false
	$LineEditContainer.visible = false
	$"IP Addresses".visible = false
	$"StatsMarginContainer".visible = false

func _on_join_button_pressed() -> void:
	get_port_and_address()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	$ButtonsContainer.visible = false
	$LineEditContainer.visible = false
	$"IP Addresses".visible = false
	$"StatsMarginContainer".visible = false

func _add_game(id = 1):
	var game = preload("res://scenes/game.tscn").instantiate()
	game.set_multiplayer_authority(id)
	$InstancesContainer.call_deferred("add_child", game)


func fill_input_fields():
	if FileAccess.file_exists("user://save_ip_port.json"):

		var file = FileAccess.open("user://save_ip_port.json", FileAccess.READ)
		var content = file.get_as_text()
		var save_data = JSON.parse_string(content)

		get_node("LineEditContainer/VBoxContainer/ip").text = str(save_data["address"])
		get_node("LineEditContainer/VBoxContainer/port").text = str(int(save_data["port"]))
	

@rpc
func _add_newly_connected_game(id):
	_add_game(id)


func get_port_and_address():
	port = int(get_node("LineEditContainer/VBoxContainer/port").text)
	address = get_node("LineEditContainer/VBoxContainer/ip").text
	save_port_and_address()

func save_port_and_address():
	var save_data = {
		"address": address,
		"port": port
	}

	var file = FileAccess.open("user://save_ip_port.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()
	

func _on_open_stats_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/stats.tscn")
