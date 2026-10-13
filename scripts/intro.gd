extends Node3D

const Story = preload("res://scripts/intro_state.gd")
const Driver = preload("res://scripts/car.gd")
const Walker = preload("res://scripts/player.gd")
const World = preload("res://scripts/intro_world.gd")
const Soundtrack = preload("res://scripts/intro_audio.gd")
const BUILDING_STOP := Vector3(3.0, 0, 0)
const HOUSE_STOP := Vector3(3.0, 0, -60)

var story = Story.new()
var car: CharacterBody3D
var player: CharacterBody3D
var world: Node3D
var audio: Node
var driving := true
var started := false
var in_capture := false
var darkened := false
var feedback_time := 0.0
var trunk_lid: Node3D
var packages: Array[Node3D] = []
var held_package: Node3D
var objective: Label
var inventory: Label
var hint: Label
var subtitle: Label
var controls: Label
var speedometer: Label
var menu: PanelContainer
var phone: PanelContainer
var phone_text: Label
var resume_button: Button
var fade: ColorRect
var hud: Array[Control] = []

func _ready() -> void:
	_bind_keys()
	world = World.new()
	add_child(world)
	player = Walker.new()
	player.position = Vector3(5.2, 0.04, 24)
	add_child(player)
	car = Driver.new()
	car.position = Vector3(0, 0.04, 24)
	car.set_meta("interaction", "car")
	add_child(car)
	_build_trunk()
	_build_held_package()
	audio = Soundtrack.new()
	add_child(audio)
	_build_ui()
	car.set_driving(true)
	car.camera.current = true
	player.set_physics_process(false)
	_update_packages()
	_update_ui()
	_apply_controls()

func _bind_keys() -> void:
	var bindings := {
		"move_forward": KEY_W, "move_back": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D,
		"interact": KEY_E, "return_package": KEY_Q,
		"vehicle": KEY_F, "phone": KEY_TAB, "car_brake": KEY_SPACE,
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key := InputEventKey.new()
			key.physical_keycode = bindings[action]
			InputMap.action_add_event(action, key)

func _build_trunk() -> void:
	var latch := world.box(Vector3(1.3, 0.28, 0.16), Vector3(0, 0.66, 2.04), Color("#28454b"), car) as StaticBody3D
	latch.set_meta("interaction", "trunk")
	trunk_lid = world.box(Vector3(1.65, 0.07, 0.72), Vector3(0, 1.08, 1.5), Color("#215356"), car, false)
	var shelf: Node3D = world.box(Vector3(1.9, 0.07, 0.8), Vector3(0, 0.7, 2.5), Color("#3c403c"), car, false)
	shelf.name = "TrunkShelf"
	var colors := [Color("#ecd8a3"), Color("#b66d52"), Color("#acb57a"), Color("#77766b")]
	for i in range(4):
		var x := float(i - 1) * 0.55 if i < 3 else 0.0
		var package := world.box(Vector3(0.43, 0.35, 0.48), Vector3(x, 0.93, 2.5), colors[i], car) as StaticBody3D
		package.set_meta("interaction", "package")
		package.set_meta("order", i)
		packages.append(package)
		world.sign_text(str(101 + i) if i < 3 else "17", Vector3(0, 0, 0.245), 25, 0, package)
	world.sign_text("E · BAÚL", Vector3(0, 0.63, 2.135), 26, 0, car)

func _build_held_package() -> void:
	held_package = world.box(Vector3(0.42, 0.3, 0.36), Vector3(0.3, -0.42, -0.65), Color("#d2b889"), player.camera, false)
	held_package.rotation_degrees = Vector3(5, -10, -4)
	held_package.visible = false

func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f6ecda"))
	label.add_theme_color_override("font_shadow_color", Color("#172328"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label

func _panel(parent: Node, width: float, height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -width / 2
	panel.offset_right = width / 2
	panel.offset_top = -height / 2
	panel.offset_bottom = height / 2
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#18282ef5")
	style.border_color = Color("#b89c6a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _column(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	return column

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	var top := VBoxContainer.new()
	top.position = Vector2(26, 22)
	top.custom_minimum_size.x = 880
	root.add_child(top)
	hud.append(top)
	_label(top, "UNA ENTREGA MÁS   /   PRÓLOGO", 17)
	objective = _label(top, "", 25)
	inventory = _label(top, "", 17)
	speedometer = _label(top, "", 17)
	var crosshair := _label(root, "+", 22)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.append(crosshair)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 26
	bottom.offset_right = -26
	bottom.offset_top = -150
	bottom.offset_bottom = -18
	root.add_child(bottom)
	hud.append(bottom)
	hint = _label(bottom, "", 22)
	subtitle = _label(bottom, "", 20)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls = _label(bottom, "", 16)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(fade)
	menu = _panel(root, 620, 530)
	var column := _column(menu)
	_label(column, "UNA ENTREGA MÁS", 34)
	_label(column, "Una vuelta por el barrio", 24)
	var description := _label(column, "Trae los encargos de tus vecinos.\nEstaciona en Los Cedros y abre el baúl.\nDespués queda una última dirección.", 18)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resume_button = _button(column, "Comenzar", _begin)
	_button(column, "Probar La presión directamente", _start_trial)
	_button(column, "Reiniciar el prólogo", _restart)
	_label(column, "Sensibilidad del ratón", 16)
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.005
	sensitivity.step = 0.0001
	sensitivity.value = 0.002
	sensitivity.value_changed.connect(func(value: float): player.sensitivity = value; car.sensitivity = value)
	column.add_child(sensitivity)
	_label(column, "Volumen de la radio y ambiente", 16)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = 0.35
	volume.value_changed.connect(audio.set_volume)
	column.add_child(volume)
	_button(column, "Salir", func(): get_tree().quit())
	phone = _panel(root, 560, 580)
	var phone_column := _column(phone)
	_label(phone_column, "MENSAJES DEL BARRIO", 26)
	_label(phone_column, "Tu ruta · Los Cedros", 17)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 370
	phone_column.add_child(scroll)
	phone_text = _label(scroll, "", 19)
	phone_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	phone_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(phone_column, "Guardar teléfono · Tab", _toggle_phone)
	phone.visible = false

func _start_trial() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var error := get_tree().change_scene_to_file("res://scenes/pressure_trial.tscn")
	if error != OK:
		in_capture = false
		fade.color = Color(0, 0, 0, 0)
		menu.visible = true
		_feedback("No se pudo abrir la prueba. Puedes volver a intentarlo desde el menú.")
		_apply_controls()

func _begin() -> void:
	started = true
	menu.visible = false
	resume_button.text = "Continuar"
	audio.set_mode("radio" if not darkened else "dread")
	_apply_controls()
	_feedback("Ya casi llegas. Los Cedros queda a la derecha. Tab abre los mensajes.")

func _apply_controls() -> void:
	var blocked := not started or menu.visible or phone.visible or in_capture
	car.paused = blocked
	player.enabled = not blocked and not driving
	player.set_physics_process(not driving and not in_capture)
	player.collision_layer = 0 if driving else 1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if blocked else Input.MOUSE_MODE_CAPTURED
	for element in hud:
		element.visible = not blocked
	if menu.visible:
		resume_button.grab_focus()

func _toggle_phone() -> void:
	if menu.visible or in_capture or not started:
		return
	phone.visible = not phone.visible
	phone_text.text = story.phone_messages()
	_apply_controls()

func _restart() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(menu) and not in_capture:
		menu.visible = true
		phone.visible = false
		_apply_controls()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not in_capture:
		if phone.visible:
			phone.visible = false
		else:
			menu.visible = not menu.visible if started else true
		_apply_controls()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("phone"):
		_toggle_phone()
	if menu.visible or phone.visible or in_capture or not started:
		return
	if event.is_action_pressed("vehicle"):
		_toggle_vehicle()
	if event.is_action_pressed("return_package") and not driving:
		if player.global_position.distance_to(car.get_trunk_position()) < 3.1:
			_feedback(story.return_order())
			_update_packages()
		else:
			_feedback("Acércate al baúl para dejar el encargo.")
	if event.is_action_pressed("interact") and not driving:
		var target: Node = player.get_target()
		if target != null:
			_interact(target)

func _feedback(message: String) -> void:
	subtitle.text = message
	feedback_time = 10.0

func _interact(target: Node) -> void:
	match str(target.get_meta("interaction", "")):
		"car":
			_toggle_vehicle()
		"trunk":
			_feedback(story.toggle_trunk())
		"package":
			var index: int = int(target.get_meta("order"))
			_feedback(story.take_last_package() if index == Story.LAST_PACKAGE else story.take_order(index))
		"door":
			_feedback(story.deliver(str(target.get_meta("door"))))
	_update_packages()
	_update_ui()

func _destination() -> Vector3:
	return HOUSE_STOP if story.phase >= Story.Phase.TO_HOUSE else BUILDING_STOP

func _exit_position() -> Vector3:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.75
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	for offset in [Vector3(2.25, 0, 0), Vector3(-2.25, 0, 0), Vector3(0, 0, 3.7)]:
		var candidate: Vector3 = car.global_transform * offset
		candidate.y = 0.06
		query.transform = Transform3D(Basis(), candidate + Vector3(0, 0.88, 0))
		if get_world_3d().direct_space_state.intersect_shape(query).is_empty():
			return candidate
	return Vector3.INF

func _toggle_vehicle() -> void:
	if driving:
		if not car.is_safe_to_exit():
			_feedback("Frena con Espacio antes de bajar.")
			return
		var distance: float = Vector2(car.position.x - _destination().x, car.position.z - _destination().z).length()
		if distance > 8:
			_feedback("Estaciona cerca de la dirección marcada para bajar.")
			return
		var exit_at := _exit_position()
		if not exit_at.is_finite():
			_feedback("No hay espacio para bajar. Mueve el carro un poco.")
			return
		if story.phase == Story.Phase.ARRIVAL:
			_feedback(story.arrive_at_building())
		elif story.phase == Story.Phase.TO_HOUSE:
			if story.carried != Story.LAST_PACKAGE:
				_feedback("Recoge el último paquete del baúl.")
				return
			_feedback(story.arrive_at_house())
		driving = false
		car.set_driving(false)
		player.global_position = exit_at
		player.rotation = Vector3(0, -PI / 2, 0)
		player.camera.rotation = Vector3.ZERO
		player.camera.current = true
		_update_packages()
		_apply_controls()
	else:
		if player.global_position.distance_to(car.global_position) > 3.9:
			_feedback("Acércate al carro para subir.")
			return
		if story.phase < Story.Phase.TO_HOUSE:
			_feedback("Primero termina las entregas y recoge el último paquete.")
			return
		if story.phase == Story.Phase.TO_HOUSE and story.carried != Story.LAST_PACKAGE:
			_feedback("El último paquete sigue en el baúl.")
			return
		story.trunk_open = false
		driving = true
		car.set_driving(true)
		car.camera.current = true
		_update_packages()
		_apply_controls()
	_update_ui()

func _update_packages() -> void:
	for index in range(packages.size()):
		var available: bool
		if index == Story.LAST_PACKAGE:
			available = story.is_complete() and story.carried != index and story.phase <= Story.Phase.TO_HOUSE
		else:
			available = not story.delivered.has(index) and story.carried != index and story.phase == Story.Phase.DELIVERIES
		packages[index].visible = available and story.trunk_open
		packages[index].collision_layer = 1 if packages[index].visible else 0
	car.get_node("TrunkShelf").visible = story.trunk_open
	trunk_lid.position.y = 1.65 if story.trunk_open else 1.08
	trunk_lid.rotation.x = -0.9 if story.trunk_open else 0.0
	held_package.visible = story.carried >= 0 and not driving and not in_capture

func _update_ui() -> void:
	objective.text = story.objective()
	inventory.text = story.carrying_text()
	controls.text = "W/S · Acelerar / reversa     A/D · Girar     Espacio · Frenar     F · Bajar     Tab · Mensajes     Esc · Pausa" if driving else "WASD · Caminar     Ratón · Mirar     E · Interactuar     F · Subir     Q · Devolver al baúl     Tab · Mensajes"

func _process(delta: float) -> void:
	if not started or menu.visible or phone.visible or in_capture:
		return
	feedback_time = maxf(0, feedback_time - delta)
	if feedback_time == 0:
		subtitle.text = ""
	_update_ui()
	hint.text = ""
	if driving:
		var distance: float = Vector2(car.position.x - _destination().x, car.position.z - _destination().z).length()
		speedometer.text = "%d km/h · Destino a %d m" % [roundi(absf(car.speed) * 3.6), roundi(distance)]
		if distance < 8:
			hint.text = "Espacio · Frenar    F · Estacionar y bajar"
		if story.phase == Story.Phase.TO_HOUSE and car.position.z < -38 and not darkened:
			darkened = true
			world.darken()
			audio.set_mode("dread")
	else:
		speedometer.text = ""
		var target: Node = player.get_target()
		if target != null:
			match str(target.get_meta("interaction", "")):
				"trunk":
					hint.text = "E · Cerrar baúl" if story.trunk_open else "E · Abrir baúl"
				"car":
					hint.text = "F · Subir al carro"
				"package":
					var index: int = int(target.get_meta("order"))
					hint.text = "E · Recoger " + (Story.HOUSE_ADDRESS if index == Story.LAST_PACKAGE else str(Story.ORDERS[index]["item"]))
				"door":
					hint.text = "E · Tocar y entregar · " + str(target.get_meta("door"))
		if story.phase == Story.Phase.HOUSE:
			if player.position.distance_to(Vector3(8, 0, -60)) < 4:
				hint.text = "La puerta está entreabierta. Acércate y entra."
			if player.position.x > 10.5 and player.position.x < 20 and absf(player.position.z + 60) < 5:
				_capture()

func _capture() -> void:
	in_capture = true
	_feedback(story.enter_house())
	world.show_capture()
	audio.set_mode("sting")
	_apply_controls()
	_update_packages()
	_update_ui()
	var tween := create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), 2.2)
	tween.tween_callback(_start_trial)
