extends Node

const NET_SCRIPT: Script = preload("res://scripts/Net.gd")

var net_node: Node = null


func _ready() -> void:
	print("Server scene ready.")

	net_node = get_node_or_null("/root/Net")

	# Fallback so this scene still works if Net was not added as an AutoLoad yet.
	if net_node == null:
		net_node = NET_SCRIPT.new()
		net_node.name = "Net"
		get_tree().root.add_child(net_node)
		await get_tree().process_frame

	if bool(net_node.get("is_dedicated_server")):
		print("Server already running from Net.gd.")
		return

	net_node.call("start_server")
