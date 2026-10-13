extends SceneTree

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var lab = load("res://scenes/delivery_lab.tscn").instantiate()
	root.add_child(lab)
	await physics_frame
	check(lab.menu.visible and not lab.player.enabled, "Menu blocks movement")
	lab._begin()
	var interact := InputEventAction.new()
	interact.action = "interact"
	interact.pressed = true
	for index in [1, 0, 2]:
		var x := float(index - 1) * 1.5
		lab.player.position = Vector3(x, 0.05, 1.3)
		lab.player.camera.look_at(Vector3(x, 1.0, -0.7))
		await physics_frame
		lab.player.ray.force_raycast_update()
		check(lab.player.get_target() == lab.packages[index], "Ray must reach package")
		lab._unhandled_input(interact)
		check(lab.state.carried == index, "E collects targeted package")
		check(not lab.packages[index].visible, "Carried package disappears from bank")
		var door_x := float(index - 1) * 3.6
		lab.player.position = Vector3(door_x, 0.05, -2.5)
		lab.player.camera.look_at(Vector3(door_x, 1.4, -4.8))
		await physics_frame
		lab.player.ray.force_raycast_update()
		lab._unhandled_input(interact)
		check(lab.state.delivered.has(index), "E delivers at targeted door")
	check(lab.state.is_complete(), "Scene supports complete delivery loop")
	lab.player.position = Vector3(0, 0.05, 1.3)
	lab.player.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	for frame in range(100):
		await physics_frame
	Input.action_release("move_forward")
	check(lab.player.position.z > 0.0, "Bank collision blocks walking through it")
	lab._set_menu(true)
	check(not lab.player.enabled and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Pause releases cursor")
	lab.queue_free()
	await process_frame
	print("Scene integration: %d failures" % failures)
	quit(1 if failures else 0)
