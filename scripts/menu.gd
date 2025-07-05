extends Control

var peer = ENetMultiplayerPeer.new()

const PORT = 6502
const ADDRESS = "localhost"


func _on_host_button_pressed() -> void:
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	_add_game()
	multiplayer.peer_connected.connect(
		func(id):
			await get_tree().create_timer(1).timeout
			rpc("_add_newly_connected_game", id)
	)
	$ButtonsContainer.visible = false

func _on_join_button_pressed() -> void:
	peer.create_client(ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	$ButtonsContainer.visible = false


func _add_game(id = 1):
	var game = preload("res://scenes/game.tscn").instantiate()
	game.set_multiplayer_authority(id)
	$InstancesContainer.call_deferred("add_child", game)


@rpc
func _add_newly_connected_game(id):
	_add_game(id)
