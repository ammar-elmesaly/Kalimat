extends Control

var peer = ENetMultiplayerPeer.new()

var port : int
var address : String

func _ready() -> void:
	for ip in IP.get_local_addresses():
		$"IP Addresses".text += ip + '\n'

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
	print("Server ready on IPs: ", IP.get_local_addresses())

func _on_join_button_pressed() -> void:
	get_port_and_address()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer
	$ButtonsContainer.visible = false
	$LineEditContainer.visible = false
	$"IP Addresses".visible = false

func _add_game(id = 1):
	var game = preload("res://scenes/game.tscn").instantiate()
	game.set_multiplayer_authority(id)
	$InstancesContainer.call_deferred("add_child", game)


@rpc
func _add_newly_connected_game(id):
	_add_game(id)


func get_port_and_address():
	port = int(get_node("LineEditContainer/VBoxContainer/port").text)
	address = get_node("LineEditContainer/VBoxContainer/ip").text
