extends Node3D

const Rules = preload("res://scripts/pressure_state.gd")
const Room = preload("res://scripts/pressure_world.gd")
const Walker = preload("res://scripts/player.gd")
const Soundtrack = preload("res://scripts/intro_audio.gd")

var state = Rules.new()
var player: CharacterBody3D
var world: Node3D
var audio: Node
var started := false
var restrained := true
var evidence_read := false
var finished := false
var resolved := false
var feedback_time := 0.0
var taunt_time := 18.0
var taunt_index := 0
var title: Label
var objective: Label
var gauges_text: Label
var timer_text: Label
var danger_bar: ProgressBar
var hint: Label
var subtitle: Label
var controls: Label
var crosshair: Label
var briefing: PanelContainer
var menu: PanelContainer
var clue: PanelContainer
var clue_body: Label
var emergency: PanelContainer
var result: PanelContainer
var result_title: Label
var result_body: Label
var pause_button: Button
var fade: ColorRect
var hud: Array[Control] = []
var status_box: Control

func _ready() -> void:
	if get_tree().has_meta("pressure_seed"):
		state.reset(int(get_tree().get_meta("pressure_seed")))
		get_tree().remove_meta("pressure_seed")
	_bind_keys()
	world = Room.new()
	add_child(world)
	player = Walker.new()
	player.position = Vector3(0, 0.05, 2.3)
	add_child(player)
	player.camera.current = true
	player.camera.fov = 82
	player.set_physics_process(false)
	audio = Soundtrack.new()
	add_child(audio)
	_build_ui()
	_refresh()
	_apply_controls()

func _bind_keys() -> void:
	var bindings := {
		"move_forward": KEY_W, "move_back": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D,
		"interact": KEY_E, "pressure_reverse": KEY_Q,
		"inspect_clue": KEY_TAB,
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var key := InputEventKey.new()
			key.physical_keycode = bindings[action]
			InputMap.action_add_event(action, key)

func _label(parent: Node, text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#eee6d6"))
	label.add_theme_color_override("font_shadow_color", Color("#081118"))
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
	style.bg_color = Color("#101c25fa")
	style.border_color = Color("#a8794e")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _column(panel: PanelContainer) -> VBoxContainer:
	var margin := MarginContainer.new()
	for edge in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	margin.add_child(column)
	return column

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _wrapped(parent: Node, text: String, size: int) -> Label:
	var label := _label(parent, text, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)
	var top := VBoxContainer.new()
	top.position = Vector2(24, 20)
	top.custom_minimum_size.x = 820
	root.add_child(top)
	hud.append(top)
	title = _label(top, "UNA ENTREGA MÁS   /   LA PRESIÓN", 17)
	objective = _label(top, "", 25)
	gauges_text = _label(top, "", 18)
	var right := VBoxContainer.new()
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -280
	right.offset_right = -24
	right.offset_top = 24
	root.add_child(right)
	status_box = right
	timer_text = _label(right, "", 31)
	_label(right, "PRESIÓN DEL MECANISMO", 16)
	danger_bar = ProgressBar.new()
	danger_bar.min_value = 0
	danger_bar.max_value = 100
	danger_bar.show_percentage = true
	danger_bar.custom_minimum_size = Vector2(256, 20)
	right.add_child(danger_bar)
	crosshair = _label(root, "+", 24)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.append(crosshair)
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -145
	bottom.offset_bottom = -16
	root.add_child(bottom)
	hud.append(bottom)
	hint = _label(bottom, "", 21)
	subtitle = _wrapped(bottom, "", 19)
	controls = _label(bottom, "", 16)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(fade)
	briefing = _panel(root, 650, 475)
	var brief := _column(briefing)
	_label(brief, "TE ESTABA ESPERANDO.", 31)
	_wrapped(brief, "Despiertas sujeto a una silla. El paquete está abierto frente a ti. Dentro hay una etiqueta que explica el mecanismo.", 21)
	_wrapped(brief, "Tres ruedas. Tres cierres. Cada giro afecta dos manómetros. Iguala los valores de la etiqueta y libera los cierres en el orden indicado.", 20)
	_wrapped(brief, "Tienes tres minutos. Un cierre equivocado aumenta la presión. Observa primero; los giros se pueden deshacer.", 19)
	_button(brief, "Abrir los ojos · Comenzar la prueba", _begin)
	_button(brief, "Volver al barrio", _return_to_intro)
	menu = _panel(root, 590, 485)
	var pause := _column(menu)
	_label(pause, "PAUSA", 30)
	pause_button = _button(pause, "Continuar", _toggle_pause)
	_button(pause, "Reintentar esta configuración", func(): _retry(false))
	_button(pause, "Otra configuración", func(): _retry(true))
	_label(pause, "Sensibilidad", 17)
	var sensitivity := HSlider.new()
	sensitivity.min_value = 0.0005
	sensitivity.max_value = 0.005
	sensitivity.step = 0.0001
	sensitivity.value = player.sensitivity
	sensitivity.value_changed.connect(func(value: float): player.sensitivity = value)
	pause.add_child(sensitivity)
	_label(pause, "Volumen", 17)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 1
	volume.step = 0.05
	volume.value = 0.35
	volume.value_changed.connect(audio.set_volume)
	pause.add_child(volume)
	_button(pause, "Volver al barrio", _return_to_intro)
	_button(pause, "Salir", func(): get_tree().quit())
	menu.visible = false
	clue = _panel(root, 680, 580)
	var sheet := _column(clue)
	_label(sheet, "ETIQUETA DENTRO DEL PAQUETE", 26)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 365
	sheet.add_child(scroll)
	clue_body = _wrapped(scroll, "", 20)
	clue_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(sheet, "El tiempo sigue mientras lees. Esc abre la pausa.", 17)
	_button(sheet, "Cerrar etiqueta · Tab", _toggle_clue)
	clue.visible = false
	emergency = _panel(root, 600, 365)
	var escape := _column(emergency)
	_label(escape, "LIBERARTE A LA FUERZA", 28)
	_wrapped(escape, "Puedes romper la sujeción y salir de la silla, pero te dejará una lesión. Caminarás más despacio durante la exploración.", 21)
	_label(escape, "El tiempo sigue. Esta decisión cambia tu salida.", 17)
	_button(escape, "Romper la sujeción", _emergency_escape)
	_button(escape, "Seguir resolviendo", func(): emergency.visible = false; _apply_controls())
	emergency.visible = false
	result = _panel(root, 650, 450)
	var end := _column(result)
	result_title = _label(end, "", 31)
	result_body = _wrapped(end, "", 21)
	_button(end, "Reintentar esta configuración", func(): _retry(false))
	_button(end, "Otra configuración", func(): _retry(true))
	_button(end, "Volver al barrio", _return_to_intro)
	_button(end, "Salir", func(): get_tree().quit())
	result.visible = false

func _begin() -> void:
	started = true
	briefing.visible = false
	audio.set_mode("dread")
	_feedback("ALTAVOZ: Trajiste todo lo que necesitaba. Ahora veamos si sabes usarlo.")
	_apply_controls()

func _paused() -> bool:
	return not started or briefing.visible or menu.visible or result.visible or finished

func _apply_controls() -> void:
	var blocked: bool = _paused() or clue.visible or emergency.visible or state.outcome == Rules.Outcome.DEAD
	player.enabled = not blocked
	player.set_physics_process(not restrained and not blocked)
	player.collision_layer = 1 if not restrained else 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if blocked else Input.MOUSE_MODE_CAPTURED
	for element in hud:
		element.visible = not briefing.visible and not menu.visible and not result.visible and not clue.visible and not emergency.visible
	status_box.visible = not menu.visible and not result.visible
	crosshair.visible = not blocked
	if menu.visible:
		pause_button.grab_focus()

func _toggle_pause() -> void:
	if not started or result.visible or finished:
		return
	menu.visible = not menu.visible
	if menu.visible:
		clue.visible = false
		emergency.visible = false
	_apply_controls()

func _toggle_clue() -> void:
	if not started or menu.visible or result.visible or finished:
		return
	clue.visible = not clue.visible
	emergency.visible = false
	clue_body.text = state.clue_text() if restrained else _evidence_text()
	_apply_controls()

func _retry(new_variant: bool) -> void:
	if not new_variant:
		get_tree().set_meta("pressure_seed", state.variant_id)
	else:
		get_tree().remove_meta("pressure_seed")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene()

func _return_to_intro() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/intro.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(menu) and started and not result.visible:
		menu.visible = true
		_apply_controls()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("inspect_clue"):
		_toggle_clue()
	if _paused() or clue.visible or emergency.visible:
		return
	var target: Node = player.get_target()
	if target == null:
		return
	if event.is_action_pressed("interact"):
		_interact(target, 1)
	elif event.is_action_pressed("pressure_reverse"):
		_interact(target, -1)

func _interact(target: Node, direction: int = 1) -> void:
	var kind := str(target.get_meta("interaction", ""))
	if state.outcome == Rules.Outcome.ACTIVE:
		match kind:
			"wheel":
				var index: int = int(target.get_meta("index"))
				_feedback(state.turn(index, direction))
				world.animate_wheel(index, direction)
			"lock":
				if direction < 0:
					return
				var index: int = int(target.get_meta("index"))
				var old_stage: int = state.stage
				_feedback(state.release(index))
				if state.stage > old_stage:
					world.release_lock(index)
			"clue":
				_toggle_clue()
			"emergency":
				if direction < 0:
					return
				emergency.visible = true
				_apply_controls()
	else:
		match kind:
			"evidence":
				evidence_read = true
				_toggle_clue()
			"exit":
				_finish_exploration()
	_refresh()
	_check_outcome()

func _emergency_escape() -> void:
	if state.outcome != Rules.Outcome.ACTIVE:
		return
	_feedback(state.emergency_escape())
	emergency.visible = false
	_check_outcome()
	_refresh()

func _feedback(message: String) -> void:
	subtitle.text = message
	feedback_time = 7.0

func _evidence_text() -> String:
	if not evidence_read:
		return "La etiqueta ya no te sirve. Hay una libreta junto a la puerta de servicio. Tal vez alguien haya salido de esa silla antes."
	return "LIBRETA DEL REPARTIDOR\n\n«Me llamo Daniel. También traje un paquete a la casa 17. Encontré etiquetas con nombres de Los Cedros. Alguien conoce nuestras rutas.\n\nSi sales de la primera silla, busca la puerta de servicio. No entregues nada más.»\n\nDebajo hay un recibo con el número del apartamento 103."

func _refresh() -> void:
	var target: Array[int] = state.current_target()
	world.set_gauges(state.gauges, target)
	world.set_danger(state.danger / 100.0)
	danger_bar.value = state.danger
	var seconds: int = maxi(0, ceili(state.seconds_left))
	timer_text.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	if state.outcome == Rules.Outcome.ACTIVE:
		objective.text = "Libera los tres cierres · %d/3" % state.stage
		gauges_text.text = "Manómetros: %d · %d · %d     Objetivo: %d · %d · %d" % [state.gauges[0], state.gauges[1], state.gauges[2], target[0], target[1], target[2]]
		controls.text = "Ratón · Mirar     E · Girar / accionar     Q · Giro inverso     Tab · Etiqueta     Esc · Pausa"
	else:
		objective.text = "Busca una salida en el sótano."
		gauges_text.text = "Lesión: caminarás más despacio." if state.outcome == Rules.Outcome.INJURED else "Saliste ileso de la silla."
		timer_text.text = "LIBRE" if state.outcome != Rules.Outcome.DEAD else "00:00"
		controls.text = "WASD · Caminar     Ratón · Mirar     E · Examinar / salir     Tab · Notas     Esc · Pausa"

func _process(delta: float) -> void:
	if _paused():
		return
	if state.outcome == Rules.Outcome.ACTIVE:
		state.tick(delta)
		taunt_time -= delta
		if taunt_time <= 0 and not clue.visible and not emergency.visible:
			var taunts := ["Cada vez que fuerzas un cierre, yo también aprieto.", "No fue casualidad que quedara ese paquete.", "La etiqueta estaba en tus manos desde el principio."]
			_feedback("ALTAVOZ: " + str(taunts[taunt_index % taunts.size()]))
			taunt_index += 1
			taunt_time = 22.0
	_refresh()
	_check_outcome()
	feedback_time = maxf(0, feedback_time - delta)
	if feedback_time == 0:
		subtitle.text = ""
	hint.text = ""
	if clue.visible or emergency.visible or resolved and restrained:
		return
	var target: Node = player.get_target()
	if target != null:
		match str(target.get_meta("interaction", "")):
			"wheel":
				hint.text = "Rueda " + ["A", "B", "C"][int(target.get_meta("index"))] + " · E +1   Q −1"
			"lock":
				hint.text = "E · Intentar liberar cierre " + str(int(target.get_meta("index")) + 1)
			"clue":
				hint.text = "E / Tab · Leer la etiqueta del paquete"
			"emergency":
				hint.text = "E · Examinar salida de emergencia"
			"evidence":
				hint.text = "E · Leer libreta de otro repartidor"
			"exit":
				hint.text = "E · Abrir puerta de servicio"

func _check_outcome() -> void:
	if state.outcome == Rules.Outcome.ACTIVE or resolved:
		return
	resolved = true
	clue.visible = false
	emergency.visible = false
	if state.outcome == Rules.Outcome.DEAD:
		audio.set_mode("sting")
		result_title.text = "NO SALISTE DE LA SILLA."
		result_body.text = "El tiempo se agotó." if state.seconds_left <= 0 else "La presión llegó al límite. Los cierres equivocados tuvieron un costo."
		result_body.text += "\n\nPuedes reintentar esta misma configuración o enfrentarte a otra."
		fade.color = Color(0, 0, 0, 0.88)
		result.visible = true
		_apply_controls()
	else:
		restrained = false
		world.release_restraints()
		player.position = world.get_escape_spawn()
		player.velocity = Vector3.ZERO
		player.rotation = Vector3.ZERO
		player.camera.rotation = Vector3.ZERO
		player.speed_multiplier = 0.65 if state.outcome == Rules.Outcome.INJURED else 1.0
		_feedback("Saliste con una lesión. Hay una libreta junto a la puerta de servicio." if state.outcome == Rules.Outcome.INJURED else "Los cierres cedieron. Hay una libreta junto a la puerta de servicio.")
		_apply_controls()

func _finish_exploration() -> void:
	finished = true
	result_title.text = "SALISTE DE LA PRIMERA PRUEBA."
	result_body.text = "Sobreviviste con una lesión." if state.outcome == Rules.Outcome.INJURED else "Sobreviviste sin lesiones."
	result_body.text += "\n\nDaniel pasó por esta silla antes que tú. El recibo apunta al apartamento 103." if evidence_read else "\n\nDejaste una libreta sin leer. Todavía hay algo que descubrir en el sótano."
	result_body.text += "\n\nLa puerta de servicio conduce más adentro de la casa. Continuará…"
	result.visible = true
	fade.color = Color(0, 0, 0, 0.72)
	_apply_controls()
