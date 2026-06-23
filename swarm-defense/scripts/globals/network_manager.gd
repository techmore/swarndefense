extends Node

enum ConnectionRole { NONE, HOST, CLIENT, DEDICATED_SERVER }

var role: ConnectionRole = ConnectionRole.NONE
var player_id: int = 1

signal player_connected(id: int)
signal player_disconnected(id: int)
signal server_disconnected()

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    multiplayer.connection_failed.connect(_on_connection_failed)

func host_game(port: int = 8060, max_players: int = 16) -> bool:
    var peer = ENetMultiplayerPeer.new()
    var err = peer.create_server(port, max_players)
    if err != OK:
        push_error("Failed to host: ", err)
        return false
    multiplayer.multiplayer_peer = peer
    role = ConnectionRole.HOST
    player_id = multiplayer.get_unique_id()
    return true

func join_game(address: String, port: int = 8060) -> bool:
    var peer = ENetMultiplayerPeer.new()
    var err = peer.create_client(address, port)
    if err != OK:
        push_error("Failed to join: ", err)
        return false
    multiplayer.multiplayer_peer = peer
    role = ConnectionRole.CLIENT
    return true

func disconnect_from_server() -> void:
    multiplayer.multiplayer_peer = null
    role = ConnectionRole.NONE
    player_id = 1

func is_server() -> bool:
    return role == ConnectionRole.HOST or role == ConnectionRole.DEDICATED_SERVER

func is_host() -> bool:
    return role == ConnectionRole.HOST

func _on_peer_connected(id: int) -> void:
    player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
    player_disconnected.emit(id)

func _on_connected_to_server() -> void:
    player_id = multiplayer.get_unique_id()

func _on_server_disconnected() -> void:
    role = ConnectionRole.NONE
    server_disconnected.emit()

func _on_connection_failed() -> void:
    disconnect_from_server()
