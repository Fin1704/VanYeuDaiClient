extends Node3D
const F := preload("res://scripts/rebirth/Form.gd")
const ACTOR := preload("res://scripts/rebirth/Duelist.gd")
const INTERFACE := preload("res://scripts/rebirth/StillwaterUI.gd")
# Keep gameplay RNG at the position reached after the old seeded map construction.
const MAP_RNG_STATE := -7507491820233601411
var player: CharacterBody3D
var camera: Camera3D
var ui: CanvasLayer
var mode := "title"
var enemies: Array[Node3D] = []
var seals: Array[Node3D] = []
var seal_done := [false,false,false]
var current_seal := -1
var encounter := false
var round_index := 0
var spawn_queue := 0
var spawn_timer := 0.0
var boss_node: Node3D
var elapsed := 0.0
var run_time := 0.0
var kills := 0
var skill_cooldowns := [0.0,0.0]
var shake := 0.0
var shake_enabled := true
var rng := RandomNumberGenerator.new()
var gold: Material
var audio: AudioStreamPlayer
var fireflies: Array[Node3D] = []
var intro_time := 0.0
var heal_count := 3
var last_mouse := Vector2.ZERO
var camera_target := Vector3.ZERO
var activated := false
var best := 0.0
var persist_progress := true
var hazard_timer := 5.0
var echo: Node3D
var combat_voices: Array[AudioStreamPlayer] = []
var sound_bank: Dictionary = {}
var voice_index := 0
var sound_clock := {}
var mouse_aim_time := -10.0
var director: RefCounted
var difficulty := 1
var boss_phase := 0
var available_upgrades: Array[Dictionary] = []
var checkpoint: Dictionary = {}
var camera_impulse := 0.0
var spawn_index := 0
var ambient_environment: Environment
var key_light: DirectionalLight3D
var vignette_strength := 0.0

func _ready() -> void:
	get_viewport().use_hdr_2d = false
	get_viewport().msaa_3d = Viewport.MSAA_4X
	rng.seed = 47029
	director = preload("res://scripts/rebirth/RunDirector.gd").new()
	director.world = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	configure_gamepad()
	setup_map()
	rng.state = MAP_RNG_STATE
	player = ACTOR.new()
	player.hero = true
	player.world = self
	player.position = Vector3(0,0.05,7)
	add_child(player)
	camera_target = player.position
	ui = CanvasLayer.new()
	ui.set_script(INTERFACE)
	ui.world = self
	add_child(ui)
	audio = AudioStreamPlayer.new()
	audio.volume_db = -15
	add_child(audio)
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -10
		add_child(voice)
		combat_voices.append(voice)
	for sound in ["swing","heavy","hit","guard","parry","dash","recall","crash","ready","surge","seal","boss","victory","ui"]:
		sound_bank[sound] = load("res://assets/audio/combat/%s.wav"%sound)
	var config := ConfigFile.new()
	if config.load("user://stillwater.cfg") == OK:
		shake_enabled = config.get_value("settings","shake",true)
		best = config.get_value("run","best",0.0)
		if persist_progress: difficulty = clampi(config.get_value("settings","difficulty",1),0,2)
		AudioServer.set_bus_mute(0,not config.get_value("settings","sound",true))
	ui.show_title()
	capture_checkpoint()

func setup_map() -> void:
	var map := get_node("StillwaterMap") as Node3D
	var environment_node := map.get_node("WorldEnvironment") as WorldEnvironment
	ambient_environment = environment_node.environment.duplicate() as Environment
	environment_node.environment = ambient_environment
	key_light = map.get_node("KeyLight") as DirectionalLight3D
	camera = map.get_node("Camera3D") as Camera3D
	camera.current = true
	seals.clear()
	for i in range(3):
		seals.append(map.get_node("SealPlatforms/Seal_%02d" % (i + 1)) as Node3D)
	fireflies.clear()
	for i in range(35):
		fireflies.append(map.get_node("Fireflies/Firefly_%02d" % (i + 1)) as Node3D)
	gold = F.material(Color("b89a61"),0.65,0.4)
	preload("res://scripts/rebirth/CourtyardDetail.gd").attach_atmosphere(self)

func _process(delta: float) -> void:
	elapsed += delta
	for i in range(fireflies.size()):
		fireflies[i].position.y += sin(elapsed*0.7+i)*delta*0.08
	for seal in seals:
		seal.get_node("Core").position.y = 1.45+sin(elapsed*2)*0.08
	update_camera(delta)
	if mode != "play": return
	director.update(delta)
	if director.cinematic_left > 0: return
	if Input.is_action_just_pressed("surge_skill"): activate_surge()
	if Input.is_action_just_pressed("wave_skill"): cast(0)
	if Input.is_action_just_pressed("burst_skill"): cast(1)
	if Input.is_action_just_pressed("wine"): heal()
	if Input.is_action_just_pressed("seal_interact"): interact()
	if Input.is_action_just_pressed("cycle_weapon") and player.action == "idle":
		player.weapon = (player.weapon+1)%3
		player.make_weapon()
	run_time += delta
	for i in range(2): skill_cooldowns[i] = maxf(0,skill_cooldowns[i]-delta)
	if encounter:
		if current_seal == 2:
			hazard_timer -= delta
			if hazard_timer <= 0:
				hazard_timer = 5.5
				var hazard := Node3D.new()
				hazard.set_script(preload("res://scripts/rebirth/SealHazard.gd"))
				hazard.world = self
				hazard.position = player.position
				add_child(hazard)
		spawn_timer -= delta
		if spawn_queue > 0 and spawn_timer <= 0 and living_enemies() < 4:
			spawn_guard()
			spawn_queue -= 1
			spawn_timer = 2.2 if difficulty == 0 else 1.8
		if spawn_queue == 0 and living_enemies() == 0 and not is_instance_valid(boss_node):
			complete_seal()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.relative.length() > 0.5: mouse_aim_time = elapsed
	if event.is_action_pressed("attack"): player.attack_buffer = 0.22
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		if mode == "title": start_run()
		elif mode == "play":
			mode = "pause"
			ui.show_pause()
		elif mode == "pause": resume()
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if mode == "play":
				mode = "pause"
				ui.show_pause()
			elif mode == "pause": resume()
		if mode != "play": return
		match event.keycode:
			KEY_F: interact()
			KEY_Q: cast(0)
			KEY_E: cast(1)
			KEY_R: heal()
			KEY_V: activate_surge()
			KEY_1,KEY_2,KEY_3:
				if player.action == "idle":
					player.weapon = event.keycode-KEY_1
					player.make_weapon()
					notify(["听雨 · 直剑","断岳 · 重刃","流萤 · 灵剑"][player.weapon],"兵刃已切换",1.4)

func start_run() -> void:
	if mode != "title": return
	Input.action_release("dash")
	Input.action_release("attack")
	mode = "play"
	activated = true
	ui.clear_modal()
	notify("第一章 · 雨歇山门", "循灯入山 · 靠近石灯按 F",4)
	capture_checkpoint()

func resume() -> void:
	Input.action_release("dash")
	mode = "play"
	ui.clear_modal()

func aim_point() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var point = Plane(Vector3.UP,0.7).intersects_ray(origin,direction)
	return point if point != null else player.position+player.facing*2

func nearest_seal() -> int:
	for i in range(seals.size()):
		if not seal_done[i] and player.position.distance_to(seals[i].position) < 2.5: return i
	return -1

func interact() -> void:
	if mode != "play" or player.dead: return
	if try_execute(): return
	if encounter: return
	var index := nearest_seal()
	if index < 0: return
	capture_checkpoint()
	current_seal = index
	spawn_index = 0
	encounter = true
	spawn_queue = 4 + round_index*2
	spawn_timer = 0.8
	hazard_timer = 4.0
	notify(["壹 · 听雨台","贰 · 照影台","叁 · 归藏台"][index],["听其刃响 · 见切可破敌势","以影为刃 · 回锋穿过敌阵","脚下生变 · 留意地面阵纹"][index],3)
	combat_sound("seal")
	burst(seals[index].position+Vector3.UP,Color("a4d9c5"),25,3)

func spawn_guard() -> void:
	var enemy := ACTOR.new()
	enemy.world = self
	enemy.kind = 2 if current_seal > 0 and spawn_queue % 3 == 0 else (round_index + spawn_queue) % 2
	var center: Vector3 = seals[current_seal].position
	if center.distance_to(player.position) > 8: center = player.position
	var chosen := center + Vector3(0,0.05,4.5)
	for attempt in range(18):
		var angle := rng.randf()*TAU
		var candidate := center+Vector3(cos(angle)*4.8,0.05,sin(angle)*4.8)
		candidate.x = clampf(candidate.x,-16,16)
		candidate.z = clampf(candidate.z,-15,14)
		if candidate.distance_to(player.position) < 3.3: continue
		var shape := SphereShape3D.new()
		shape.radius = 0.65
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform.origin = candidate+Vector3.UP*0.85
		query.collision_mask = 1|2|4
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty(): continue
		chosen = candidate
		break
	enemy.position = chosen
	add_child(enemy)
	enemies.append(enemy)
	spawn_index += 1
	enemy.action = "arrive"
	enemy.timer = 0.8
	enemy.ai_wait = 0.8
	# Telegraph the arrival with a rising body and a floor ripple before it acts.
	enemy.rig.scale *= 0.05
	create_tween().tween_property(enemy.rig,"scale",Vector3.ONE,0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ritual_pulse(chosen,Color("96c9c0"),1.3)
	burst(enemy.position,Color("9eb7ad"),10,1.6)

func living_enemies() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead: count += 1
	return count

func complete_seal() -> void:
	if current_seal < 0 or seal_done[current_seal]: return
	encounter = false
	seal_done[current_seal] = true
	seals[current_seal].get_node("Core").material_override = F.material(Color("e9c68b"),0.3,0.3,3)
	round_index += 1
	director.score += 350
	director.gain(15)
	combat_sound("seal")
	player.hp = minf(player.max_hp,player.hp+3)
	player.stamina = 100
	if round_index == 3:
		capture_checkpoint()
		begin_boss()
	else:
		mode = "upgrade"
		prepare_upgrades()
		ui.show_upgrade()

func prepare_upgrades() -> void:
	var catalog: Array[Dictionary] = [
		{"key":"blade","name":"听雨剑诀","subtitle":"刃 · 以攻破局","description":"所有兵刃伤害 +0.7\n重刃破势，灵剑连击同样受益"},
		{"key":"resolve","name":"不动如山","subtitle":"心 · 绝处逢生","description":"气血上限 +3，立即回满\n见切与掠影额外积累 5 点剑意"},
		{"key":"echo","name":"照影回澜","subtitle":"影 · 一去一返","description":"回锋伤害 +1.8，冷却缩短 25%\n留影延长 1.5 秒，归路更从容"},
		{"key":"breath","name":"长风入怀","subtitle":"息 · 行云流水","description":"体力恢复速度提升 18%\n破阵冷却缩短 20%"},
		{"key":"mercy","name":"藏锋养生","subtitle":"生 · 以战续命","description":"每次破势追斩恢复 1.2 气血\n立即获得一壶温酒"},
		{"key":"wine","name":"醉里挑灯","subtitle":"酒 · 重整旗鼓","description":"获得两壶温酒，治疗量 +2\n立即恢复 4 点气血"}
	]
	available_upgrades.clear()
	var indices := [0,1,2] if round_index == 1 else [3,4,5]
	for i in indices: available_upgrades.append(catalog[i])

func upgrade(choice: int) -> void:
	if mode != "upgrade": return
	if available_upgrades.is_empty(): prepare_upgrades()
	if choice < 0 or choice >= available_upgrades.size(): return
	var key: String = available_upgrades[choice].key
	director.bonuses[key] += 1
	match key:
		"blade": player.damage_bonus += 0.7
		"resolve":
			player.max_hp += 3
			player.hp = player.max_hp
		"mercy": heal_count += 1
		"wine":
			heal_count += 2
			player.hp = minf(player.max_hp,player.hp+4)
	resume()
	capture_checkpoint()
	combat_sound("ready")
	notify("封印已解 · 剑诀入心", "已留下检查点 · 前往下一座石灯",3)

func begin_boss() -> void:
	if is_instance_valid(boss_node) and not boss_node.dead: return
	boss_node = ACTOR.new()
	boss_node.boss = true
	boss_node.world = self
	boss_node.position = Vector3(0,0.05,-2)
	add_child(boss_node)
	enemies.append(boss_node)
	boss_phase = 1
	director.cinematic_left = 1.65
	director.cinematic_focus = boss_node.position
	boss_node.ai_wait = 1.2
	burst(boss_node.position+Vector3.UP,Color("d6b083"),28,4)
	combat_sound("boss")
	notify("无 相", "诸声皆寂，唯此一剑。",3.8)

func enter_boss_phase_two() -> void:
	if not is_instance_valid(boss_node) or boss_node.dead: return
	boss_phase = 2
	director.cinematic_left = 1.1
	director.cinematic_focus = boss_node.position
	boss_node.action = "idle"
	boss_node.ai_wait = 0.75
	boss_node.posture = minf(boss_node.posture,70)
	for bolt in get_tree().get_nodes_in_group("hostile_projectile"): bolt.queue_free()
	player.stamina = minf(100,player.stamina+25)
	ritual_pulse(boss_node.position,Color("e29c73"),4.7)
	combat_sound("boss")
	notify("无 相 · 山 雨 欲 来", "横扫、突进与剑阵 · 读势而动",3)

func melee(attacker: Node3D) -> void:
	if not attacker.hero and not attacker.boss and attacker.kind == 2:
		var bolt := Node3D.new()
		bolt.set_script(preload("res://scripts/rebirth/SpiritBolt.gd"))
		bolt.world = self
		bolt.source = attacker
		bolt.direction = attacker.locked
		bolt.position = attacker.position+Vector3.UP*0.8
		add_child(bolt)
		return
	var targets: Array = enemies if attacker.hero else [player]
	var enhanced: bool = attacker.parry_reward > 0
	var landed := false
	var reach: float = (2.4 if attacker.weapon == 1 else 1.95) if attacker.hero else attacker.melee_reach()
	for target in targets:
		if not is_instance_valid(target) or target.dead: continue
		var offset: Vector3 = target.position-attacker.position
		offset.y = 0
		var minimum_dot: float = (0.5 if attacker.combo == 3 and attacker.weapon != 1 else 0.0) if attacker.hero else attacker.melee_cone_dot()
		if offset.length() > reach or attacker.locked.dot(offset.normalized()) < minimum_dot: continue
		var query := PhysicsRayQueryParameters3D.create(attacker.position+Vector3.UP,target.position+Vector3.UP,1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
		var damage: float = (2.6 if attacker.weapon == 1 else 1.4) + attacker.damage_bonus if attacker.hero else (3.0 if attacker.boss else 1.5)
		if attacker.combo == 3: damage *= 1.5
		if enhanced: damage *= 1.5
		if target.hurt(damage,attacker):
			landed = true
			if enhanced: target.apply_posture(30)
			flash(target.position+Vector3.UP,Color("accfdb") if target.last_guarded else Color("e9d5a6"))
			if attacker.hero: target.apply_posture(30 if attacker.weapon == 1 else 18)
			if attacker.hero and attacker.weapon == 1 and not target.boss and not target.dead and target.action != "broken" and target.interrupt_resist <= 0:
				target.action = "stunned"
				target.timer = 0.25
				target.interrupt_resist = 1.3
			if attacker.hero and attacker.weapon == 2:
				attacker.stamina = minf(100,attacker.stamina+4)
	if enhanced and landed: attacker.parry_reward = 0
	if attacker.hero and attacker.weapon == 2 and attacker.combo == 3:
		var wave := Node3D.new()
		wave.set_script(preload("res://scripts/rebirth/SwordWave.gd"))
		wave.world = self
		wave.direction = attacker.locked
		wave.position = attacker.position+Vector3.UP*0.8
		add_child(wave)
	impact(0.025,0.4)

func cast(index: int) -> void:
	if mode != "play" or index < 0 or index > 1 or player.dead or director.cinematic_left > 0: return
	if skill_cooldowns[index] > 0 or player.stamina < 24 or player.action in ["guard_break","broken","execute"]: return
	if index == 0:
		if not is_instance_valid(echo):
			notify("先留雨痕", "闪避后按 Q，沿留影回锋",1.2)
			return
		var end: Vector3 = echo.position
		var origin: Vector3 = player.position
		var line := end-origin
		line.y = 0
		if line.length() < 0.7: return
		var ray := PhysicsRayQueryParameters3D.create(origin+Vector3.UP*0.7,end+Vector3.UP*0.7,1)
		var obstruction := get_world_3d().direct_space_state.intersect_ray(ray)
		if not obstruction.is_empty():
			notify("归路受阻", "雨痕与自身之间需要通路",1.2)
			return
		player.stamina -= 24
		skill_cooldowns[0] = 2.8*pow(0.75,director.bonuses.echo)
		player.action = "recall"
		player.duration = clampf(line.length()/30,0.12,0.45)
		player.recall_speed = line.length()/player.duration
		player.timer = player.duration
		player.locked = line.normalized()
		player.facing = player.locked
		player.immunity = player.duration+0.1
		player.hit_stop = 0
		var recall_hits := 0
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.dead: continue
			var t := clampf((enemy.position-origin).dot(line)/line.length_squared(),0,1)
			if enemy.position.distance_to(origin+line*t) < 1.25:
				if enemy.hurt(3.2+player.damage_bonus+director.bonuses.echo*1.8,player):
					recall_hits += 1
					enemy.apply_posture(42)
					flash(enemy.position+Vector3.UP,Color("a4e0d0"))
		echo.queue_free()
		echo = null
		combat_sound("recall")
		if recall_hits > 0: combat_event("recall",player,player)
	else:
		player.stamina -= 24
		skill_cooldowns[1] = 4.0*pow(0.8,director.bonuses.breath)
		player.action = "cast"
		player.duration = 0.28
		player.timer = 0.28
		player.immunity = 0.18
		var direction: Vector3 = (aim_point()-player.position) if elapsed-mouse_aim_time < 4 else player.facing
		direction.y = 0
		if direction.length() < 0.3: direction = player.facing
		direction = direction.normalized()
		player.facing = direction
		var pressure := Node3D.new()
		pressure.set_script(preload("res://scripts/rebirth/PressureWave.gd"))
		pressure.world = self
		pressure.direction = direction
		pressure.position = player.position
		add_child(pressure)
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.dead: continue
			var offset: Vector3 = enemy.position-player.position
			offset.y = 0
			if offset.length() < 3.8 and direction.dot(offset.normalized()) > 0.25:
				var query := PhysicsRayQueryParameters3D.create(player.position+Vector3.UP,enemy.position+Vector3.UP,1)
				if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): continue
				enemy.hurt(1.0,player)
				enemy.launch(direction,14.0)
		combat_sound("heavy")
		impact(0.12,0.4)

func heal() -> void:
	if mode != "play" or player.dead or director.cinematic_left > 0: return
	if heal_count <= 0 or player.hp >= player.max_hp: return
	heal_count -= 1
	player.hp = minf(player.max_hp,player.hp+5+director.bonuses.wine*2)
	burst(player.position+Vector3.UP,Color("b3d2a9"),18,1.5)
	notify("温酒", "气血恢复",1.4)

func fallen(actor: Node3D) -> void:
	if actor.hero:
		mode = "defeat"
		ui.show_result(false)
	else:
		kills += 1
		combat_event("kill",actor,player)
		player.stamina = minf(100,player.stamina+10)
		if actor.boss:
			director.score += 1000
			mode = "victory"
			combat_sound("victory")
			if best == 0 or run_time < best: best = run_time
			save_settings()
			ui.show_result(true)

func notify(title: String, subtitle: String, seconds := 2.5) -> void:
	if is_instance_valid(ui): ui.notify(title,subtitle,seconds)

func impact(amount: float, _pitch: float) -> void:
	shake = minf(0.24,shake+amount)

func combat_sound(sound: String) -> void:
	if DisplayServer.get_name() == "headless" or combat_voices.is_empty(): return
	var now := Time.get_ticks_msec()
	if now-int(sound_clock.get(sound,-1000)) < 40: return
	sound_clock[sound] = now
	var voice := combat_voices[voice_index%combat_voices.size()]
	voice_index += 1
	voice.stream = sound_bank.get(sound)
	voice.pitch_scale = rng.randf_range(0.94,1.06)
	voice.play()

func burst(p: Vector3, color: Color, count: int, spread: float) -> void:
	for i in range(count):
		var shard := F.box(self,p,Vector3(0.025,0.025,rng.randf_range(0.07,0.2)),F.material(color,0.4,0.4,0.5))
		var target := p + Vector3(rng.randf_range(-spread,spread),rng.randf_range(0.2,spread),rng.randf_range(-spread,spread))
		shard.rotation = Vector3(rng.randf()*3,rng.randf()*3,0)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(shard,"position",target,0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard,"scale",Vector3.ZERO,0.4).set_delay(0.1)
		tween.chain().tween_callback(shard.queue_free)

func flash(p: Vector3, color: Color) -> void:
	var hit := Node3D.new()
	hit.set_script(preload("res://scripts/rebirth/CombatImpact.gd"))
	hit.position = p
	hit.color = color
	add_child(hit)

func save_settings() -> void:
	if not persist_progress: return
	var config := ConfigFile.new()
	config.set_value("settings","shake",shake_enabled)
	config.set_value("settings","difficulty",difficulty)
	config.set_value("settings","sound",not AudioServer.is_bus_mute(0))
	config.set_value("run","best",best)
	config.save("user://stillwater.cfg")

func configure_gamepad() -> void:
	for action in ["aim_left","aim_right","aim_up","aim_down","wave_skill","burst_skill","wine","seal_interact","cycle_weapon","surge_skill"]:
		if not InputMap.has_action(action): InputMap.add_action(action,0.2)
	var sticks := [["move_left",JOY_AXIS_LEFT_X,-1.0],["move_right",JOY_AXIS_LEFT_X,1.0],["move_up",JOY_AXIS_LEFT_Y,-1.0],["move_down",JOY_AXIS_LEFT_Y,1.0],["aim_left",JOY_AXIS_RIGHT_X,-1.0],["aim_right",JOY_AXIS_RIGHT_X,1.0],["aim_up",JOY_AXIS_RIGHT_Y,-1.0],["aim_down",JOY_AXIS_RIGHT_Y,1.0]]
	for binding in sticks:
		var event := InputEventJoypadMotion.new()
		event.axis = binding[1]
		event.axis_value = binding[2]
		if not InputMap.action_has_event(binding[0],event): InputMap.action_add_event(binding[0],event)
	for binding in [["attack",JOY_BUTTON_X],["dash",JOY_BUTTON_A],["defend",JOY_BUTTON_LEFT_SHOULDER],["wave_skill",JOY_BUTTON_RIGHT_SHOULDER],["burst_skill",JOY_BUTTON_Y],["wine",JOY_BUTTON_B],["seal_interact",JOY_BUTTON_DPAD_UP],["cycle_weapon",JOY_BUTTON_DPAD_RIGHT],["surge_skill",JOY_BUTTON_RIGHT_STICK]]:
		var event := InputEventJoypadButton.new()
		event.button_index = binding[1]
		if not InputMap.action_has_event(binding[0],event): InputMap.action_add_event(binding[0],event)

func boss_pulse(attacker: Node3D) -> void:
	burst(attacker.position+Vector3.UP*0.15,Color("e7b279"),32,3.8)
	var circle := F.ring(self,attacker.position+Vector3.UP*0.2,0.5,0.035,F.material(Color("e7b279"),0,0.5,1.1))
	var tween := create_tween().set_parallel(true)
	tween.tween_property(circle,"scale",Vector3.ONE*7.6,0.35)
	tween.tween_property(circle,"transparency",1.0,0.4)
	tween.chain().tween_callback(circle.queue_free)
	if player.position.distance_to(attacker.position) < 3.8: player.hurt(3,attacker)

func prepare_shutdown() -> void:
	mode = "closing"

func leave_echo() -> void:
	if is_instance_valid(echo): echo.queue_free()
	echo = Node3D.new()
	echo.set_script(preload("res://scripts/rebirth/RainEcho.gd"))
	echo.world = self
	echo.life += director.bonuses.echo*1.5
	echo.position = player.position
	add_child(echo)

func crash(victim: Node3D, collider: Node) -> void:
	if victim.dead: return
	var force: Vector3 = victim.knockback.normalized()
	victim.hurt(2.0,player)
	victim.apply_posture(45)
	victim.knockback *= 0.12
	if collider in enemies and is_instance_valid(collider) and not collider.dead:
		collider.hurt(2.0,player)
		collider.launch(force,8)
	flash(victim.position+Vector3.UP,Color("ffe1a3"))
	combat_sound("crash")
	combat_event("crash",victim,player)
	impact(0.18,0.5)
	notify("撞 破", "借力破势",0.8)

func executable_target() -> Node3D:
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.dead and enemy.action == "broken" and enemy.position.distance_to(player.position) < 3.0: return enemy
	return null

func try_execute() -> bool:
	if mode != "play" or player.dead or director.cinematic_left > 0: return false
	var target := executable_target()
	if target == null: return false
	player.facing = (target.position-player.position).normalized()
	player.action = "execute"
	player.timer = 0.3
	player.duration = 0.3
	player.immunity = 0.4
	player.stamina = minf(100,player.stamina+30)
	combat_event("execution",target,player)
	target.immunity = 0
	target.hurt(11 if target.boss else 50,player)
	if not target.dead:
		target.posture = 0
		target.posture_grace = 1.2
		if target.boss: target.interrupt_resist = 2.0
		target.action = "stunned"
		target.timer = 0.55
	flash(target.position+Vector3.UP,Color("fbe4b6"))
	combat_sound("crash")
	impact(0.23,1.2)
	notify("追 斩", "破势终结 · 体力恢复",1.2)
	return true

func combat_event(kind: String, actor: Node3D, source: Node3D, amount := 0.0) -> void:
	director.record(kind,actor,source,amount)

func incoming_damage(amount: float, target: Node3D, source: Node3D) -> float:
	if target == player: return amount*[0.72,1.0,1.25][difficulty]
	if source == player: return amount*director.damage_multiplier()
	return amount

func run_report() -> Dictionary:
	return director.report()

func set_difficulty(value: int) -> void:
	difficulty = clampi(value,0,2)
	save_settings()

func activate_surge() -> void:
	if mode != "play" or player.dead or director.cinematic_left > 0: return
	if not director.technique_ready or player.action in ["hurt","execute","broken"]: return
	director.flow = 0
	director.surge_left = 6.0
	director.stats.surges += 1
	player.action = "execute"
	player.timer = 0.45
	player.duration = 0.45
	player.immunity = 0.75
	player.stamina = minf(100,player.stamina+35)
	player.hit_stop = 0
	player.velocity = Vector3.ZERO
	var cut := preload("res://scripts/rebirth/StillnessBurst.gd").new()
	cut.world = self
	cut.position = player.position
	add_child(cut)
	camera_impulse = 1.3
	combat_sound("surge")
	notify("万 籁 一 斩", "六息无尘 · 伤害与回气提升",2.4)
	impact(0.2,1.0)

func update_camera(delta: float) -> void:
	var target := player.position
	var desired_size := 13.0
	if mode == "title":
		target = Vector3(0,0,-1)+Vector3(sin(elapsed*0.12)*0.4,0,cos(elapsed*0.1)*0.3)
		desired_size = 25.0
	else:
		# Follow the movement direction without changing camera axes or fighting aim.
		target += player.velocity.limit_length(4.4)*0.16
		if is_instance_valid(boss_node) and not boss_node.dead:
			var offset: Vector3 = boss_node.position-player.position
			target += offset.limit_length(6)*0.28
			desired_size = clampf(14.5+offset.length()*0.12,14.5,16.5)
		elif encounter:
			desired_size = 13.4+minf(living_enemies(),4)*0.22
		if director.cinematic_left > 0:
			target = target.lerp(director.cinematic_focus,0.3)
			desired_size += 1.0
		target.x = clampf(target.x,-12.5,12.5)
		target.z = clampf(target.z,-13,11)
	camera_impulse = move_toward(camera_impulse,0,delta*2.2)
	desired_size += camera_impulse
	camera.size = lerpf(camera.size,desired_size,1-exp(-delta*3.2))
	camera_target = camera_target.lerp(target,1-exp(-delta*7))
	camera.position = camera_target+Vector3(16,22,16)
	if shake_enabled and shake > 0:
		camera.position += Vector3(sin(elapsed*83)*shake,cos(elapsed*103)*shake*0.55,0)
	shake = move_toward(shake,0,delta*1.5)
	camera.look_at(camera_target,Vector3.UP)
	if ambient_environment != null:
		var pressure := 1.0 if boss_phase == 2 and mode == "play" else 0.0
		vignette_strength = lerpf(vignette_strength,pressure,1-exp(-delta))
		ambient_environment.ambient_light_color = Color("93b9cb").lerp(Color("9ba8c7"),vignette_strength)
		key_light.light_color = Color("f6d7a8").lerp(Color("efb08b"),vignette_strength*0.7)

func ritual_pulse(origin: Vector3, tint: Color, radius: float) -> void:
	for i in range(2):
		var ring := F.ring(self,origin+Vector3.UP*(0.18+i*0.035),0.5,0.004,F.material(Color(tint,0.65),0,0.3,1.1))
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tween := create_tween().set_parallel(true)
		tween.tween_property(ring,"scale",Vector3(radius*2,1,radius*2),0.8+i*0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(ring,"transparency",1.0,0.9+i*0.18)
		tween.chain().tween_callback(ring.queue_free)

func capture_checkpoint() -> void:
	checkpoint = {"seals":seal_done.duplicate(),"round":round_index,"weapon":player.weapon,"max_hp":player.max_hp,"damage_bonus":player.damage_bonus,"wine":heal_count,"director":director.snapshot(),"position":player.position,"kills":kills}

func retry_from_checkpoint() -> void:
	if mode not in ["defeat","pause"]: return
	_retry_checkpoint.call_deferred()

func _retry_checkpoint() -> void:
	var state := checkpoint.duplicate(true)
	state["run_time"] = run_time
	state["retries"] = director.stats.retries+1
	var next: Node3D = load("res://scenes/rebirth/Stillwater.tscn").instantiate()
	next.persist_progress = persist_progress
	var tree := get_tree()
	mode = "closing"
	tree.root.add_child(next)
	tree.current_scene = next
	next.difficulty = difficulty
	next.restore_checkpoint(state)
	queue_free()

func restore_checkpoint(state: Dictionary) -> void:
	seal_done = state.get("seals",[false,false,false]).duplicate()
	round_index = state.get("round",0)
	player.weapon = state.get("weapon",0)
	player.make_weapon()
	player.max_hp = state.get("max_hp",12.0)
	player.hp = player.max_hp
	player.damage_bonus = state.get("damage_bonus",0.0)
	player.position = state.get("position",Vector3(0,0.05,7))
	player.stamina = 100
	heal_count = maxi(2,state.get("wine",3))
	kills = state.get("kills",0)
	run_time = state.get("run_time",0.0)
	director.restore(state.get("director",{}))
	director.stats.retries = state.get("retries",0)
	for i in range(3):
		if seal_done[i]: seals[i].get_node("Core").material_override = F.material(Color("e9c68b"),0.3,0.3,3)
	mode = "play"
	activated = true
	ui.clear_modal()
	camera_target = player.position
	for action in ["attack","dash","defend","move_left","move_right","move_up","move_down"]: Input.action_release(action)
	capture_checkpoint()
	if round_index == 3: begin_boss()
	else: notify("灯火犹在", "已从封印检查点归来 · 气血与体力恢复",3)
