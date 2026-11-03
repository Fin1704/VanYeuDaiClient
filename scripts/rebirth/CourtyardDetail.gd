extends RefCounted

static func attach_atmosphere(world: Node3D) -> void:
	var atmosphere := preload("res://scripts/rebirth/CourtyardAtmosphere.gd").new()
	atmosphere.world = world
	world.get_node("StillwaterMap").add_child(atmosphere)
