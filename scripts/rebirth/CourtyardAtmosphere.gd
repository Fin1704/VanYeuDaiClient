extends Node3D
## Gameplay remains in Stillwater; this observer animates seal and boss visuals.

const F := preload("res://scripts/rebirth/Form.gd")
const BLOOM := preload("res://scripts/rebirth/SealBloom.gd")
const INSCRIPTION := preload("res://scripts/rebirth/shaders/SealInscription.gdshader")

var world: Node3D
var seal_visuals: Array[Dictionary] = []
var court_material: ShaderMaterial
var court_visible := false
var age := 0.0
var state_check := 0.0

func _ready() -> void:
	name = "CourtyardAtmosphere"
	build_seal_armatures()
	court_material = inscription_material(-1.0)
	court_material.set_shader_parameter("strength", 0.0)
	var plane := PlaneMesh.new()
	plane.size = Vector2(9.8, 9.8)
	var inscription := F.instance(self, plane, Vector3(0, 0.139, 0), court_material)
	inscription.name = "BossCourtInscription"
	inscription.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	if not is_instance_valid(world): return
	age += delta
	state_check -= delta
	if state_check <= 0.0:
		state_check = 0.1
		update_ritual_states()
	for i in range(seal_visuals.size()):
		var visual: Dictionary = seal_visuals[i]
		var armature: Node3D = visual.armature
		var engaged: bool = visual.state == 1
		armature.rotation.y += delta * (0.42 if engaged else 0.12) * (-1.0 if i == 1 else 1.0)
		armature.position.y = 1.45 + sin(age * 1.3 + i * 2.0) * 0.045
		var halo: Node3D = visual.halo
		halo.rotation.z = sin(age * 0.4 + i) * 0.2

func inscription_material(identity: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = INSCRIPTION
	material.set_shader_parameter("identity", identity)
	return material

func build_seal_armatures() -> void:
	var crystal := F.crystal_mesh()
	for i in range(world.seals.size()):
		var seal: Node3D = world.seals[i]
		var armature := Node3D.new()
		armature.name = "JadeArmature"
		armature.position.y = 1.45
		seal.add_child(armature)
		var halo := Node3D.new()
		armature.add_child(halo)
		var light_material := F.material(Color("79b9ad"), 0.42, 0.34, 0.38)
		var outer := F.ring(halo, Vector3.ZERO, 0.58, 0.013, light_material)
		outer.rotation_degrees = Vector3(68, i * 38, 16)
		outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var inner := F.ring(halo, Vector3.ZERO, 0.43, 0.01, world.gold)
		inner.rotation_degrees = Vector3(25, 32, 55)
		inner.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for n in range(3):
			var angle := n * TAU / 3.0 + i * 0.6
			var fragment := F.instance(armature, crystal, Vector3(sin(angle) * 0.63, 0.02, cos(angle) * 0.63), light_material)
			fragment.scale = Vector3(0.43, 0.38, 0.43)
			fragment.rotation.z = sin(angle) * 0.55
			fragment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := inscription_material(float(i))
		var plane := PlaneMesh.new()
		plane.size = Vector2(5.6, 5.6)
		var glyph := F.instance(seal, plane, Vector3(0, 0.158, 0), material)
		glyph.name = "SealInscription"
		glyph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		seal_visuals.append({"armature": armature, "halo": halo, "material": material, "light_material": light_material, "state": 0})

func update_ritual_states() -> void:
	for i in range(seal_visuals.size()):
		var state := 2 if world.seal_done[i] else (1 if world.encounter and world.current_seal == i else 0)
		var visual: Dictionary = seal_visuals[i]
		if int(visual.state) == state: continue
		visual.state = state
		var complete := state == 2
		var color := Color("e8c78a") if complete else Color("8bd5c7")
		var material: ShaderMaterial = visual.material
		material.set_shader_parameter("tint", color)
		material.set_shader_parameter("strength", 0.6 if state == 1 else (0.36 if complete else 0.25))
		material.set_shader_parameter("engaged", 1.0 if state == 1 else 0.0)
		var light_material: StandardMaterial3D = visual.light_material
		light_material.albedo_color = color
		light_material.emission = color
		light_material.emission_energy_multiplier = 0.7 if complete else 0.5
		for child in world.seals[i].get_children():
			if child is OmniLight3D:
				child.light_color = color
				child.light_energy = 1.8 if complete else 2.2
		if state > 0:
			bloom(world.seals[i].position, color, 2.6 if complete else 1.85, complete)
	var boss_alive: bool = is_instance_valid(world.boss_node) and not world.boss_node.dead
	if boss_alive != court_visible:
		court_visible = boss_alive
		court_material.set_shader_parameter("strength", 0.29 if boss_alive else 0.0)
		court_material.set_shader_parameter("engaged", 1.0 if boss_alive else 0.0)
		court_material.set_shader_parameter("tint", Color("d9ae76"))
		if boss_alive: bloom(Vector3.ZERO, Color("dfbb80"), 4.0, true)

func bloom(position_value: Vector3, color: Color, radius: float, triumphant: bool) -> void:
	var effect := BLOOM.new()
	effect.position = position_value
	effect.color = color
	effect.radius = radius
	effect.triumphant = triumphant
	add_child(effect)
