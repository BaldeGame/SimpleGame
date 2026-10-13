extends Node3D

## The first trial is assembled from simple meshes so the playable rules remain
## readable even before the final art is available. Interactions live on bodies.
var wheels: Array[StaticBody3D] = []
var locks: Array[StaticBody3D] = []
var emergency: StaticBody3D
var clue: StaticBody3D
var evidence: StaticBody3D
var final_exit: StaticBody3D
var _gauge_labels: Array[Label3D] = []
var _target_labels: Array[Label3D] = []
var _needles: Array[Node3D] = []
var _wheel_visuals: Array[Node3D] = []
var _lock_lights: Array[MeshInstance3D] = []
var _restraints: Array[Node3D] = []
var _danger_lamps: Array[OmniLight3D] = []
var _danger_bar: Node3D
var _danger_label: Label3D
var _exit_leaf: Node3D
var _exit_sign: Label3D
var _chair: Node3D
var _pressure_arms: Array[Node3D] = []
var _danger := 0.0
var _released := false
var _elapsed := 0.0

func _ready() -> void:
	_build_environment()
	_build_room()
	_build_chair()
	_build_console()
	_build_story_props()
	set_gauges([0, 0, 0], [0, 0, 0])
	set_danger(0.0)

func _process(delta: float) -> void:
	_elapsed += delta
	for lamp in _danger_lamps:
		lamp.light_energy = 0.12 + _danger * (0.45 + 0.25 * sin(_elapsed * (3.0 + _danger * 6.0)))

func _material(color: Color, glow := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	if glow > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material

func _box(size: Vector3, at: Vector3, color: Color, parent: Node = self, solid := true, glow := 0.0) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.position = at
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = _material(color, glow)
	body.add_child(visual)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
	parent.add_child(body)
	return body

func _cylinder(radius: float, height: float, at: Vector3, color: Color, parent: Node = self, glow := 0.0) -> Node3D:
	var node := Node3D.new()
	node.position = at
	var visual := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	visual.mesh = mesh
	visual.material_override = _material(color, glow)
	node.add_child(visual)
	parent.add_child(node)
	return node

func _text(value: String, at: Vector3, font_size := 34, color := Color("#e8e3d2"), parent: Node = self, pixel_size := 0.003) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.position = at
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = 4
	label.no_depth_test = false
	parent.add_child(label)
	return label

func _light(at: Vector3, color: Color, energy: float, radius: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = color
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = false
	add_child(light)
	return light

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#080d13")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#607e91")
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -20, 0)
	key.light_color = Color("#8cb5c4")
	key.light_energy = 0.35
	add_child(key)
	_light(Vector3(0, 2.7, 1.6), Color("#bfd8d6"), 1.5, 5.0)
	_light(Vector3(2.7, 2.4, -2.2), Color("#b4cbb1"), 0.8, 4.0)
	_light(Vector3(0, 2.7, -7), Color("#8fc1a0"), 0.35, 4.0)
	for x in [-2.9, 2.9]:
		_danger_lamps.append(_light(Vector3(x, 2.35, 0.2), Color("#e14635"), 0.1, 4.5))

func _build_room() -> void:
	var concrete := Color("#343c42")
	_box(Vector3(8.2, 0.2, 14.0), Vector3(0, -0.1, -2.0), Color("#252d30"))
	_box(Vector3(8.2, 0.15, 14.0), Vector3(0, 3.45, -2.0), Color("#252c31"))
	for x in [-4.0, 4.0]:
		_box(Vector3(0.2, 3.4, 14.0), Vector3(x, 1.7, -2.0), concrete)
	_box(Vector3(8.0, 3.4, 0.2), Vector3(0, 1.7, 4.8), concrete)
	# A doorway leads to a short service passage once the restraints open.
	for x in [-2.45, 2.45]:
		_box(Vector3(3.1, 3.4, 0.2), Vector3(x, 1.7, -5.1), concrete)
	_box(Vector3(1.8, 0.85, 0.2), Vector3(0, 2.975, -5.1), concrete)
	_box(Vector3(8.0, 3.4, 0.2), Vector3(0, 1.7, -8.8), concrete)
	for x in [-3.7, 3.7]:
		_box(Vector3(0.12, 0.10, 9.4), Vector3(x, 2.95, -0.15), Color("#796a55"), self, false)
		for z in [-3.0, 0.5, 3.6]:
			_box(Vector3(0.28, 0.25, 0.20), Vector3(x, 2.95, z), Color("#4a4c4d"), self, false)
	for x in [-2.9, 2.9]:
		_box(Vector3(0.40, 0.18, 0.14), Vector3(x, 2.35, 0.2), Color("#ba493a"), self, false, 0.5)
	_box(Vector3(2.0, 0.06, 0.35), Vector3(0, 3.12, 1.35), Color("#cbd7d0"), self, false, 0.4)
	# Floor seams and old service-room markings add scale without visual clutter.
	for z in [-4.0, -2.0, 0.0, 2.0, 4.0]:
		_box(Vector3(7.8, 0.006, 0.025), Vector3(0, 0.005, z), Color("#151c20"), self, false)
	for x in [-0.95, 0.95]:
		_box(Vector3(0.05, 0.012, 2.3), Vector3(x, 0.01, 1.6), Color("#9b8645"), self, false)
	_text("UNA ENTREGA MÁS", Vector3(0, 2.9, -4.98), 34, Color("#717e7f"))
	_text("SALIDA DE SERVICIO", Vector3(0, 2.6, -4.87), 28, Color("#afd2b5"))
	_exit_leaf = Node3D.new()
	_exit_leaf.position = Vector3(-0.85, 0, -5.00)
	add_child(_exit_leaf)
	_box(Vector3(1.7, 2.5, 0.10), Vector3(0.85, 1.25, 0), Color("#44514c"), _exit_leaf, false)
	_box(Vector3(0.12, 0.09, 0.14), Vector3(1.50, 1.1, 0.09), Color("#b8ac7d"), _exit_leaf, false)
	final_exit = _box(Vector3(1.7, 2.5, 0.06), Vector3(0, 1.25, -4.88), Color("#44514c")) as StaticBody3D
	final_exit.name = "ServiceExit"
	final_exit.get_child(0).visible = false
	final_exit.set_meta("interaction", "exit")
	_exit_sign = _text("CERRADO", Vector3(0, 1.75, -4.80), 30, Color("#c7a17e"))
	# An ordinary radio and observation lens imply a person watching the trial.
	_box(Vector3(0.6, 0.40, 0.30), Vector3(-2.6, 2.35, -4.85), Color("#151d22"), self, false)
	for i in range(5):
		_box(Vector3(0.44, 0.014, 0.02), Vector3(-2.6, 2.22 + i * 0.045, -4.68), Color("#566169"), self, false)
	var lens := _cylinder(0.055, 0.09, Vector3(2.9, 2.6, -4.80), Color("#cc4438"), self, 0.5)
	lens.rotation.x = PI / 2.0
	_box(Vector3(0.25, 0.17, 0.3), Vector3(2.9, 2.6, -4.96), Color("#121c23"), self, false)

func _build_chair() -> void:
	_chair = Node3D.new()
	_chair.position = Vector3(0, 0, 2.3)
	add_child(_chair)
	var steel := Color("#4d565a")
	_box(Vector3(0.75, 0.14, 0.8), Vector3(0, 0.75, 0), Color("#30393d"), _chair, false)
	_box(Vector3(0.75, 1.10, 0.10), Vector3(0, 1.27, 0.43), Color("#3d4649"), _chair, false)
	for x in [-0.39, 0.39]:
		_box(Vector3(0.10, 0.75, 0.10), Vector3(x, 0.375, 0.25), steel, _chair, false)
		_box(Vector3(0.12, 0.12, 0.95), Vector3(x, 1.03, -0.03), steel, _chair, false)
		_restraints.append(_box(Vector3(0.20, 0.16, 0.25), Vector3(x, 1.1, -0.24), Color("#776f5c"), _chair, false))
	_restraints.append(_box(Vector3(0.8, 0.12, 0.08), Vector3(0, 0.97, -0.34), Color("#706953"), _chair, false))
	for side in [-1.0, 1.0]:
		var approach := Node3D.new()
		approach.position = Vector3(side * 0.55, 0.78, 1.35)
		add_child(approach)
		_box(Vector3(0.10, 0.12, 0.85), Vector3.ZERO, Color("#625b4b"), approach, false)
		_box(Vector3(0.28, 0.20, 0.12), Vector3(-side * 0.07, 0, 0.43), Color("#a18e65"), approach, false)
		_pressure_arms.append(approach)

func _build_console() -> void:
	var panel := Color("#28373e")
	_box(Vector3(2.08, 1.65, 0.16), Vector3(0, 1.36, 0.18), panel)
	_box(Vector3(2.3, 0.15, 0.85), Vector3(0, 0.50, 0.22), Color("#3f4b4f"))
	for x in [-0.9, 0.9]:
		_box(Vector3(0.12, 0.5, 0.12), Vector3(x, 0.25, 0.22), Color("#38464c"))
	_text("LA PRESIÓN", Vector3(0, 2.27, 0.285), 43, Color("#ded5af"))
	var roman := ["I", "II", "III"]
	var wheel_names := ["A", "B", "C"]
	for index in range(3):
		var x := float(index - 1) * 0.65
		_text(roman[index], Vector3(x, 2.01, 0.30), 32, Color("#d8dedb"))
		var dial := _cylinder(0.21, 0.055, Vector3(x, 1.69, 0.30), Color("#afbbba"))
		dial.rotation.x = PI / 2.0
		var face := _cylinder(0.18, 0.020, Vector3(x, 1.69, 0.338), Color("#17262d"))
		face.rotation.x = PI / 2.0
		for tick in range(7):
			var angle := deg_to_rad(-130.0 + tick * 43.333)
			var mark := _box(Vector3(0.016, 0.045, 0.007), Vector3(x + sin(angle) * 0.144, 1.69 + cos(angle) * 0.144, 0.355), Color("#d0c7a8"), self, false)
			mark.rotation.z = -angle
		var needle := Node3D.new()
		needle.position = Vector3(x, 1.69, 0.37)
		add_child(needle)
		_box(Vector3(0.018, 0.14, 0.01), Vector3(0, 0.063, 0), Color("#edb95b"), needle, false, 0.15)
		_needles.append(needle)
		_gauge_labels.append(_text("0", Vector3(x, 1.40, 0.33), 35, Color("#f1d482")))
		_target_labels.append(_text("OBJETIVO 0", Vector3(x, 1.27, 0.33), 18, Color("#c0d3d7")))
		var wheel := StaticBody3D.new()
		wheel.position = Vector3(x, 1.07, 0.45)
		wheel.name = "Wheel" + wheel_names[index]
		wheel.set_meta("interaction", "wheel")
		wheel.set_meta("index", index)
		add_child(wheel)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.43, 0.33, 0.17)
		collision.shape = shape
		wheel.add_child(collision)
		var visual := Node3D.new()
		wheel.add_child(visual)
		var ring := _cylinder(0.15, 0.09, Vector3.ZERO, Color("#7f9fa5"), visual)
		ring.rotation.x = PI / 2.0
		var hub := _cylinder(0.10, 0.10, Vector3(0, 0, 0.02), Color("#223941"), visual)
		hub.rotation.x = PI / 2.0
		_box(Vector3(0.027, 0.21, 0.04), Vector3(0, 0, 0.08), Color("#d8c392"), visual, false)
		_box(Vector3(0.21, 0.027, 0.04), Vector3(0, 0, 0.08), Color("#d8c392"), visual, false)
		_wheel_visuals.append(visual)
		wheels.append(wheel)
		_text(wheel_names[index], Vector3(x, 0.87, 0.51), 29, Color("#dfe9e5"))
		var lock_control := _box(Vector3(0.42, 0.18, 0.16), Vector3(x, 0.65, 0.55), Color("#4d5558")) as StaticBody3D
		lock_control.name = "Release" + str(index + 1)
		lock_control.set_meta("interaction", "lock")
		lock_control.set_meta("index", index)
		locks.append(lock_control)
		var status := _box(Vector3(0.055, 0.045, 0.02), Vector3(x - 0.155, 0.65, 0.644), Color("#e8a25b"), self, false, 0.4)
		_lock_lights.append(status.get_child(0) as MeshInstance3D)
		_text(str(index + 1), Vector3(x + 0.025, 0.65, 0.642), 20, Color("#e9d9b8"))
	_text("GIRA A / B / C · LIBERA 1 / 2 / 3", Vector3(0, 0.35, 0.66), 21, Color("#91a9b1"))
	# Off-side emergency handle remains distinct from the puzzle controls.
	_box(Vector3(0.32, 0.8, 0.20), Vector3(1.13, 1.3, 0.28), Color("#3d3531"), self, false)
	emergency = _box(Vector3(0.20, 0.25, 0.18), Vector3(1.12, 1.40, 0.60), Color("#bd5140")) as StaticBody3D
	emergency.name = "EmergencyRelease"
	emergency.set_meta("interaction", "emergency")
	_text("EMERGENCIA", Vector3(1.16, 1.69, 0.54), 19, Color("#edbda1"))
	_text("SALIDA CON COSTE", Vector3(1.16, 1.16, 0.54), 16, Color("#d9b29c"))
	_box(Vector3(1.70, 0.10, 0.08), Vector3(0, 2.51, 0.28), Color("#36282a"), self, false)
	_danger_bar = _box(Vector3(1.68, 0.06, 0.02), Vector3(0, 2.51, 0.33), Color("#b34432"), self, false, 0.25)
	_danger_label = _text("PRESIÓN 0 %", Vector3(0, 2.69, 0.31), 25, Color("#d3bb9e"))

func _build_story_props() -> void:
	# The parcel brought from the prologue contains the only reliable directions.
	_box(Vector3(0.67, 0.08, 0.63), Vector3(-1.25, 0.90, 0.52), Color("#485259"), self, false)
	_box(Vector3(0.08, 0.90, 0.08), Vector3(-1.25, 0.45, 0.52), Color("#434b4e"), self, false)
	clue = _box(Vector3(0.50, 0.28, 0.38), Vector3(-1.12, 1.05, 0.62), Color("#927952")) as StaticBody3D
	clue.name = "DeliveredParcel"
	clue.set_meta("interaction", "clue")
	_box(Vector3(0.08, 0.29, 0.385), Vector3(0, 0, 0.008), Color("#c6b88b"), clue, false)
	_text("TU PAQUETE", Vector3(-1.12, 1.34, 0.84), 20, Color("#d9cda7"))
	_text("17 · OLMO", Vector3(0.10, 0.01, 0.20), 16, Color("#343531"), clue, 0.002)
	_box(Vector3(1.25, 0.10, 0.75), Vector3(2.50, 0.90, -2.15), Color("#61564a"))
	for x in [2.00, 3.00]:
		_box(Vector3(0.09, 0.86, 0.65), Vector3(x, 0.43, -2.15), Color("#3e4445"), self, false)
	evidence = _box(Vector3(0.55, 0.12, 0.38), Vector3(2.5, 1.015, -2.0), Color("#c3bba0")) as StaticBody3D
	evidence.name = "PreviousCourierEvidence"
	evidence.set_meta("interaction", "evidence")
	for offset in [-0.12, 0, 0.12]:
		_box(Vector3(0.36, 0.006, 0.025), Vector3(0, 0.065, offset), Color("#686960"), evidence, false)
	_text("REGISTRO DE ENTREGAS", Vector3(2.5, 1.52, -2.05), 25, Color("#c9c9ad"))
	_text("RUTA 17", Vector3(-2.5, 1.6, -3.8), 34, Color("#788784"))
	for i in range(3):
		_box(Vector3(0.65, 0.42, 0.52), Vector3(-2.7, 0.21 + i * 0.42, -3.4), Color("#6b6656"), self, false)
		_box(Vector3(0.10, 0.43, 0.53), Vector3(-2.7, 0.21 + i * 0.42, -3.4), Color("#827a5c"), self, false)
	# Abstract approach beam changes position as pressure rises; no construction
	# detail is needed to understand that the situation is getting worse.
	_box(Vector3(1.80, 0.12, 0.13), Vector3(0, 2.9, 1.05), Color("#514d44"), self, false)

func set_gauges(gauges: Array[int], target: Array[int]) -> void:
	for index in range(mini(3, gauges.size())):
		_gauge_labels[index].text = str(gauges[index])
		var matches := index < target.size() and gauges[index] == target[index]
		_gauge_labels[index].modulate = Color("#a6e6c0") if matches else Color("#f1d482")
		_needles[index].rotation.z = -deg_to_rad(-130.0 + float(gauges[index]) * 43.333)
		if index < target.size():
			_target_labels[index].text = "OBJETIVO " + str(target[index])

func animate_wheel(index: int, direction: int) -> void:
	if index < 0 or index >= _wheel_visuals.size():
		return
	var visual := _wheel_visuals[index]
	var tween := create_tween()
	tween.tween_property(visual, "rotation:z", visual.rotation.z - float(direction) * TAU / 7.0, 0.16)

func set_danger(value: float) -> void:
	_danger = clampf(value, 0.0, 1.0)
	for arm in _pressure_arms:
		arm.position.y = lerpf(0.78, 1.06, _danger)
		arm.position.z = lerpf(1.35, 1.73, _danger)
	if is_instance_valid(_danger_bar):
		_danger_bar.scale.x = maxf(0.015, _danger)
		_danger_bar.position.x = -0.84 + 0.84 * _danger
	if is_instance_valid(_danger_label):
		_danger_label.text = "PRESIÓN " + str(roundi(_danger * 100.0)) + " %"
		_danger_label.modulate = Color("#f27960") if _danger > 0.70 else Color("#d3bb9e")

func release_lock(index: int) -> void:
	if index < 0 or index >= locks.size():
		return
	_lock_lights[index].material_override = _material(Color("#81dab3"), 0.5)
	locks[index].set_meta("released", true)
	var tween := create_tween()
	tween.tween_property(locks[index], "position:z", 0.49, 0.15)
	if index < _restraints.size():
		var restraint := _restraints[index]
		tween.parallel().tween_property(restraint, "rotation:z", 0.7 if index == 0 else -0.7, 0.3)

func release_restraints() -> void:
	if _released:
		return
	_released = true
	for restraint in _restraints:
		restraint.visible = false
	for arm in _pressure_arms:
		arm.visible = false
	for index in range(locks.size()):
		release_lock(index)
	# The exit marker moves onto the door frame so its collider no longer blocks
	# the open passage, while remaining available to the interaction ray.
	final_exit.position.x = 0.73
	var collision := final_exit.get_child(1) as CollisionShape3D
	(collision.shape as BoxShape3D).size = Vector3(0.26, 0.7, 0.18)
	_exit_sign.position = Vector3(0.73, 1.76, -4.73)
	_exit_sign.font_size = 22
	_exit_sign.text = "SALIR"
	_exit_sign.modulate = Color("#bde3c4")
	var tween := create_tween()
	tween.tween_property(_exit_leaf, "rotation:y", -0.95, 0.8)
	set_danger(0.0)

func get_escape_spawn() -> Vector3:
	return Vector3(2.0, 0.0, 1.45)
