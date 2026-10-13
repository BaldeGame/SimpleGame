extends Node3D

const State = preload("res://scripts/delivery_state.gd")
const Player = preload("res://scripts/player.gd")
var state = State.new()
var player: CharacterBody3D
var packages: Array[StaticBody3D] = []
var objective: Label
var hint: Label
var subtitle: Label
var inventory: Label
var menu: PanelContainer
var resume_button: Button
var started := false
var feedback_time := 0.0

func _ready() -> void:
	_setup_input()
	_build_room()
	_build_interface()
	player = Player.new()
	player.position = Vector3(0, 0.05, 3)
	add_child(player)
	_set_menu(true)
	_refresh_packages()

func _setup_input() -> void:
	var bindings := {
		"move_forward": KEY_W, "move_back": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D,
		"interact": KEY_E, "return_package": KEY_Q,
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key := InputEventKey.new()
			key.physical_keycode = bindings[action]
			InputMap.action_add_event(action, key)

func _box(size: Vector3, at: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh.material_override = material
	body.add_child(mesh)
	var collider := CollisionShape3D.new()
	var collision_shape := BoxShape3D.new()
	collision_shape.size = size
	collider.shape = collision_shape
	body.add_child(collider)
	add_child(body)
	return body

func _sign(text: String, at: Vector3, size: int = 48) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = size
	label.pixel_size = 0.006
	label.modulate = Color("#f5e9ce")
	label.outline_size = 5
	add_child(label)
	return label

func _build_room() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#17242a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#ead9bf")
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_color = Color("#ffe4ba")
	sun.light_energy = 0.8
	add_child(sun)
	_box(Vector3(12, 0.2, 12), Vector3(0, -0.1, 0), Color("#796f5c"))
	_box(Vector3(12, 3.6, 0.2), Vector3(0, 1.8, -5), Color("#435b59"))
	_box(Vector3(0.2, 3.6, 12), Vector3(-6, 1.8, 0), Color("#354c4d"))
	_box(Vector3(0.2, 3.6, 12), Vector3(6, 1.8, 0), Color("#354c4d"))
	_box(Vector3(12, 3.6, 0.2), Vector3(0, 1.8, 6), Color("#435b59"))
	_sign("EDIFICIO LOS CEDROS", Vector3(0, 3.1, -4.84), 64)
	var names := ["CLARA", "BRUNO", "TOMÁS"]
	for i in range(3):
		var x := float(i - 1) * 3.6
		var door := _box(Vector3(1.5, 2.5, 0.12), Vector3(x, 1.25, -4.8), Color("#855a39"))
		door.set_meta("interaction", "door")
		door.set_meta("door", str(101 + i))
		_sign(str(101 + i) + "\n" + names[i], Vector3(x, 2.0, -4.71), 40)
		_box(Vector3(0.08, 0.08, 0.12), Vector3(x + 0.55, 1.1, -4.68), Color("#e4b46c"))
	_box(Vector3(4.5, 0.7, 0.85), Vector3(0, 0.35, -0.7), Color("#3d3830"))
	var colors := [Color("#e1bd80"), Color("#b87553"), Color("#a7b78b")]
	for i in range(3):
		var x := float(i - 1) * 1.5
		var package := _box(Vector3(0.75, 0.55, 0.6), Vector3(x, 1.0, -0.7), colors[i])
		package.set_meta("interaction", "package")
		package.set_meta("order", i)
		packages.append(package)
		var tag := _sign(str(101 + i), Vector3(x, 1.05, -0.385), 32)
		tag.reparent(package)

func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f5ead4"))
	parent.add_child(label)
	return label

func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	var top := VBoxContainer.new()
	top.position = Vector2(28, 24)
	root.add_child(top)
	_label(top, "UNA ENTREGA MÁS", 18)
	objective = _label(top, "", 28)
	inventory = _label(top, "", 18)
	var cross := _label(root, "+", 24)
	cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 28
	bottom.offset_right = -28
	bottom.offset_top = -150
	bottom.offset_bottom = -20
	root.add_child(bottom)
	hint = _label(bottom, "", 22)
	subtitle = _label(bottom, "", 20)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(bottom, "WASD · Moverse     Ratón · Mirar     E · Interactuar     Q · Devolver al banco     Esc · Pausa", 16)
	menu = PanelContainer.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.offset_left = -300
	menu.offset_right = 300
	menu.offset_top = -220
	menu.offset_bottom = 220
	root.add_child(menu)
	var margin := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	menu.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	_label(column, "UNA ENTREGA MÁS", 34)
	_label(column, "01 / Los encargos", 24)
	var description := _label(column, "Escena de prueba · PC\nEntrega las tres cajas en su puerta.\nEl carro, la casa y el terror llegarán después.", 18)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_button = Button.new()
	resume_button.text = "Comenzar"
	resume_button.pressed.connect(_begin)
	column.add_child(resume_button)
	var restart := Button.new()
	restart.text = "Reiniciar entregas"
	restart.pressed.connect(_restart)
	column.add_child(restart)
	_label(column, "Sensibilidad del ratón", 16)
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.005
	sensitivity.step = 0.0001
	sensitivity.value = 0.002
	sensitivity.value_changed.connect(func(value: float): player.sensitivity = value)
	column.add_child(sensitivity)
	var quit := Button.new()
	quit.text = "Salir"
	quit.pressed.connect(func(): get_tree().quit())
	column.add_child(quit)

func _begin() -> void:
	started = true
	resume_button.text = "Continuar"
	_set_menu(false)

func _set_menu(open: bool) -> void:
	menu.visible = open
	player.enabled = not open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	if open:
		resume_button.grab_focus()

func _restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(menu) and is_instance_valid(player):
		_set_menu(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_menu(not menu.visible if started else true)
		get_viewport().set_input_as_handled()
	if menu.visible:
		return
	if event.is_action_pressed("return_package"):
		_feedback(state.return_order())
		_refresh_packages()
	if event.is_action_pressed("interact"):
		var target: Node = player.get_target()
		if target == null:
			return
		if target.get_meta("interaction") == "package":
			_feedback(state.take_order(int(target.get_meta("order"))))
		else:
			_feedback(state.deliver(str(target.get_meta("door"))))
		_refresh_packages()

func _feedback(message: String) -> void:
	subtitle.text = message
	feedback_time = 9.0

func _refresh_packages() -> void:
	for i in range(packages.size()):
		var active: bool = state.carried != i and not state.delivered.has(i)
		packages[i].visible = active
		packages[i].collision_layer = 1 if active else 0
	if state.is_complete():
		objective.text = "Entregas completas · 3/3"
		inventory.text = "Fin de esta prueba. Esc para reiniciar o salir."
	else:
		objective.text = "Entrega los encargos · %d/3" % state.delivered.size()
		inventory.text = "Manos libres · Recoge una caja del banco." if state.carried == -1 else "Llevas: " + str(State.ORDERS[state.carried]["item"]) + " · Puerta " + str(State.ORDERS[state.carried]["door"])

func _process(delta: float) -> void:
	if menu.visible:
		hint.text = ""
		return
	feedback_time = maxf(feedback_time - delta, 0)
	if feedback_time == 0:
		subtitle.text = ""
	var target: Node = player.get_target()
	hint.text = ""
	if target != null:
		if target.get_meta("interaction") == "package":
			var index: int = int(target.get_meta("order"))
			hint.text = "E · Recoger " + str(State.ORDERS[index]["item"])
		else:
			hint.text = "E · Entregar / llamar · " + str(target.get_meta("door"))
