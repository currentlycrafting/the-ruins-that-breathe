extends Node

signal connected_to_server
signal connection_failed
signal room_joined(room_code: String, player_id: int, map_seed: int, players: Dictionary)
signal room_join_rejected(reason: String)
signal player_joined(player_id: int, player_name: String, pos: Vector2, tile: Vector2i)
signal player_left(player_id: int)
signal remote_player_state(player_id: int, pos: Vector2, tile: Vector2i, anim: String, direction: String)
signal remote_player_clicked(player_id: int, tile: Vector2i)
signal remote_key_collected(player_id: int, key_tile: Vector2i)
signal remote_level_started(stage: int, map_seed: int)
signal remote_weapon_dropped(player_id: int, weapon_key: String, world_position: Vector2, drop_uid: String)
signal remote_weapon_picked(player_id: int, drop_uid: String)
signal remote_charged_attack_fx(player_id: int, fx_world_pos: Vector2)

const DEFAULT_PORT: int = 10000
const DEFAULT_MAX_PLAYERS_PER_ROOM: int = 24
const SERVER_STATE_EPSILON: float = 1.0

var is_dedicated_server: bool = false
var room_code: String = ""
var player_name: String = "Player"
var local_player_id: int = 0
var max_players_per_room: int = DEFAULT_MAX_PLAYERS_PER_ROOM

# room_code -> {
#   "seed": int,
#   "stage": int,
#   "players": {
#      peer_id: {"name": String, "pos": Vector2, "tile": Vector2i, "anim": String, "direction": String}
#   }
# }
var rooms: Dictionary = {}
var peer_to_room: Dictionary = {}


func _ready() -> void:
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# Run dedicated server with:
	# godot --headless --path . -- --server
	if OS.get_cmdline_user_args().has("--server"):
		start_server()


func start_server() -> void:
	if is_dedicated_server:
		print("Multiplayer server already started.")
		return

	is_dedicated_server = true

	var port: int = DEFAULT_PORT
	var env_port: String = OS.get_environment("PORT")
	if env_port.is_valid_int():
		port = int(env_port)
	var env_max_players: String = OS.get_environment("MAX_PLAYERS_PER_ROOM")
	if env_max_players.is_valid_int():
		max_players_per_room = maxi(2, int(env_max_players))

	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	var err: Error = peer.create_server(port, "0.0.0.0")
	if err != OK:
		push_error("Failed to start WebSocket server on 0.0.0.0:%s. Error: %s" % [port, err])
		is_dedicated_server = false
		return

	multiplayer.multiplayer_peer = peer
	print("MULTIPLAYER SERVER STARTED ON 0.0.0.0:%s" % port)


func connect_to_server(url: String, desired_room_code: String, desired_player_name: String) -> void:
	room_code = desired_room_code.strip_edges().to_upper()
	player_name = desired_player_name.strip_edges()
	if player_name == "":
		player_name = "Player"

	var peer: WebSocketMultiplayerPeer = WebSocketMultiplayerPeer.new()
	var err: Error = peer.create_client(url)
	if err != OK:
		push_error("Failed to connect to %s. Error: %s" % [url, err])
		connection_failed.emit()
		return

	multiplayer.multiplayer_peer = peer


func disconnect_from_server() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	room_code = ""
	local_player_id = 0


func _on_connected_to_server() -> void:
	local_player_id = multiplayer.get_unique_id()
	connected_to_server.emit()
	server_join_room.rpc_id(1, room_code, player_name)


func _on_connection_failed() -> void:
	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("Disconnected from multiplayer server.")


func _on_peer_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		player_left.emit(peer_id)
		return

	if not peer_to_room.has(peer_id):
		return

	_remove_player_from_room(peer_id, true)


@rpc("any_peer", "reliable")
func server_join_room(code: String, desired_player_name: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()
	code = code.strip_edges().to_upper()
	desired_player_name = desired_player_name.strip_edges()

	if code == "":
		code = "ROOM"
	if desired_player_name == "":
		desired_player_name = "Player %s" % sender_id

	if peer_to_room.has(sender_id):
		var existing_room_code: String = str(peer_to_room[sender_id])
		if existing_room_code != code:
			_remove_player_from_room(sender_id, true)

	if not rooms.has(code):
		var seed_value: int = abs(hash(code + "_" + str(Time.get_unix_time_from_system())))
		rooms[code] = {
			"seed": seed_value,
			"stage": 1,
			"players": {}
		}

	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]
	var is_rejoin: bool = players.has(sender_id)
	if not is_rejoin and players.size() >= max_players_per_room:
		client_room_join_rejected.rpc_id(sender_id, "Room is full (%s players max)." % max_players_per_room)
		return

	players[sender_id] = {
		"name": desired_player_name,
		"pos": Vector2.ZERO,
		"tile": Vector2i.ZERO,
		"anim": "idle",
		"direction": "forward"
	}

	peer_to_room[sender_id] = code

	client_room_joined.rpc_id(
		sender_id,
		code,
		sender_id,
		int(room["seed"]),
		players
	)

	if is_rejoin:
		return

	for other_id in players.keys():
		if int(other_id) == sender_id:
			continue

		var new_player_data: Dictionary = players[sender_id]
		client_player_joined.rpc_id(
			int(other_id),
			sender_id,
			desired_player_name,
			new_player_data["pos"],
			new_player_data["tile"]
		)


@rpc("authority", "reliable")
func client_room_join_rejected(reason: String) -> void:
	room_join_rejected.emit(reason)


@rpc("authority", "reliable")
func client_room_joined(code: String, assigned_id: int, map_seed: int, players: Dictionary) -> void:
	room_code = code
	local_player_id = assigned_id
	room_joined.emit(code, assigned_id, map_seed, players)


@rpc("authority", "reliable")
func client_player_joined(player_id: int, new_player_name: String, pos: Vector2, tile: Vector2i) -> void:
	player_joined.emit(player_id, new_player_name, pos, tile)


@rpc("authority", "reliable")
func client_player_left(player_id: int) -> void:
	player_left.emit(player_id)


func send_player_state(pos: Vector2, tile: Vector2i, anim: String, direction: String) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		return

	server_player_state.rpc_id(1, pos, tile, anim, direction)


@rpc("any_peer", "unreliable_ordered")
func server_player_state(pos: Vector2, tile: Vector2i, anim: String, direction: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()
	if not peer_to_room.has(sender_id):
		return

	var code: String = str(peer_to_room[sender_id])
	if not rooms.has(code):
		return

	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]

	if not players.has(sender_id):
		return

	var previous_state: Dictionary = players[sender_id]
	var is_shoot_anim: bool = anim.begins_with("shoot_")
	if not is_shoot_anim \
		and Vector2(previous_state.get("pos", Vector2.ZERO)).distance_to(pos) < SERVER_STATE_EPSILON \
		and Vector2i(previous_state.get("tile", Vector2i.ZERO)) == tile \
		and str(previous_state.get("anim", "")) == anim \
		and str(previous_state.get("direction", "")) == direction:
		return

	players[sender_id]["pos"] = pos
	players[sender_id]["tile"] = tile
	players[sender_id]["anim"] = anim
	players[sender_id]["direction"] = direction

	for other_id in players.keys():
		if int(other_id) == sender_id:
			continue
		client_player_state.rpc_id(int(other_id), sender_id, pos, tile, anim, direction)


@rpc("authority", "unreliable_ordered")
func client_player_state(player_id: int, pos: Vector2, tile: Vector2i, anim: String, direction: String) -> void:
	remote_player_state.emit(player_id, pos, tile, anim, direction)


func send_clicked_tile(tile: Vector2i) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		return

	server_clicked_tile.rpc_id(1, tile)


@rpc("any_peer", "reliable")
func server_clicked_tile(tile: Vector2i) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()
	if not peer_to_room.has(sender_id):
		return

	var code: String = str(peer_to_room[sender_id])
	if not rooms.has(code):
		return

	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]

	for other_id in players.keys():
		if int(other_id) == sender_id:
			continue
		client_clicked_tile.rpc_id(int(other_id), sender_id, tile)


@rpc("authority", "reliable")
func client_clicked_tile(player_id: int, tile: Vector2i) -> void:
	remote_player_clicked.emit(player_id, tile)


func send_key_collected(key_tile: Vector2i) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		return

	server_key_collected.rpc_id(1, key_tile)


@rpc("any_peer", "reliable")
func server_key_collected(key_tile: Vector2i) -> void:
	if not multiplayer.is_server():
		return

	var sender_id: int = multiplayer.get_remote_sender_id()
	if not peer_to_room.has(sender_id):
		return

	var code: String = str(peer_to_room[sender_id])
	if not rooms.has(code):
		return

	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]

	for other_id in players.keys():
		if int(other_id) == sender_id:
			continue
		client_key_collected.rpc_id(int(other_id), sender_id, key_tile)


@rpc("authority", "reliable")
func client_key_collected(player_id: int, key_tile: Vector2i) -> void:
	remote_key_collected.emit(player_id, key_tile)


func send_level_started(stage: int, map_seed: int) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		return
	server_level_started.rpc_id(1, stage, map_seed)


func send_weapon_dropped(weapon_key: String, world_position: Vector2, drop_uid: String) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		return
	server_weapon_dropped.rpc_id(1, weapon_key, world_position, drop_uid)


func send_weapon_picked(drop_uid: String) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		return
	server_weapon_picked.rpc_id(1, drop_uid)


func send_charged_attack_fx(fx_world_pos: Vector2) -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.is_server():
		return
	server_charged_attack_fx.rpc_id(1, fx_world_pos)


@rpc("any_peer", "reliable")
func server_level_started(stage: Variant, map_seed: Variant) -> void:
	if not multiplayer.is_server():
		return
	var parsed_stage: int = 1
	var parsed_seed: int = 0
	if stage is int:
		parsed_stage = int(stage)
	elif stage is String and String(stage).is_valid_int():
		parsed_stage = int(stage)
	if map_seed is int:
		parsed_seed = int(map_seed)
	elif map_seed is String and String(map_seed).is_valid_int():
		parsed_seed = int(map_seed)
	var sender_id: int = multiplayer.get_remote_sender_id()
	if not peer_to_room.has(sender_id):
		return
	var code: String = str(peer_to_room[sender_id])
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	room["stage"] = parsed_stage
	room["seed"] = parsed_seed
	var players: Dictionary = room["players"]
	for other_id in players.keys():
		if int(other_id) == sender_id:
			continue
		client_level_started.rpc_id(int(other_id), parsed_stage, parsed_seed)


@rpc("any_peer", "reliable")
func server_weapon_dropped(weapon_key: String, world_position: Vector2, drop_uid: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if not peer_to_room.has(sender_id):
		return
	var code: String = str(peer_to_room[sender_id])
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]
	for other_id in players.keys():
		if int(other_id) == sender_id:
			continue
		client_weapon_dropped.rpc_id(int(other_id), sender_id, weapon_key, world_position, drop_uid)


@rpc("authority", "reliable")
func client_weapon_dropped(player_id: int, weapon_key: String, world_position: Vector2, drop_uid: String) -> void:
	remote_weapon_dropped.emit(player_id, weapon_key, world_position, drop_uid)


@rpc("any_peer", "reliable")
func server_weapon_picked(drop_uid: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if not peer_to_room.has(sender_id):
		return
	var code: String = str(peer_to_room[sender_id])
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]
	for other_id in players.keys():
		if int(other_id) == sender_id:
			continue
		client_weapon_picked.rpc_id(int(other_id), sender_id, drop_uid)


@rpc("authority", "reliable")
func client_weapon_picked(player_id: int, drop_uid: String) -> void:
	remote_weapon_picked.emit(player_id, drop_uid)


@rpc("any_peer", "reliable")
func server_charged_attack_fx(fx_world_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if not peer_to_room.has(sender_id):
		return
	var code: String = str(peer_to_room[sender_id])
	if not rooms.has(code):
		return
	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]
	for other_id in players.keys():
		if int(other_id) == sender_id:
			continue
		client_charged_attack_fx.rpc_id(int(other_id), sender_id, fx_world_pos)


@rpc("authority", "reliable")
func client_charged_attack_fx(player_id: int, fx_world_pos: Vector2) -> void:
	remote_charged_attack_fx.emit(player_id, fx_world_pos)


@rpc("authority", "reliable")
func client_level_started(stage: int, map_seed: int) -> void:
	remote_level_started.emit(stage, map_seed)


func _remove_player_from_room(peer_id: int, notify_room: bool) -> void:
	if not peer_to_room.has(peer_id):
		return

	var code: String = str(peer_to_room[peer_id])
	peer_to_room.erase(peer_id)

	if not rooms.has(code):
		return

	var room: Dictionary = rooms[code]
	var players: Dictionary = room["players"]
	if not players.has(peer_id):
		return

	players.erase(peer_id)

	if notify_room:
		for other_id in players.keys():
			client_player_left.rpc_id(int(other_id), peer_id)

	if players.is_empty():
		rooms.erase(code)
