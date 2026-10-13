extends SceneTree

const State = preload("res://scripts/intro_state.gd")
var failures: int = 0


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _initialize() -> void:
	call_deferred("_run")


func action_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func wait_physics(count: int) -> void:
	for frame in range(count):
		await physics_frame


func aim(intro: Node3D, from: Vector3, at: Vector3) -> void:
	intro.player.global_position = from
	intro.player.velocity = Vector3.ZERO
	intro.player.rotation = Vector3.ZERO
	intro.player.camera.look_at(at)
	await wait_physics(2)
	intro.player.ray.force_raycast_update()


func _run() -> void:
	var intro = load("res://scenes/intro.tscn").instantiate()
	root.add_child(intro)
	current_scene = intro
	await wait_physics(2)
	check(intro.menu.visible and intro.car.paused and not intro.player.enabled, "Opening menu blocks driving and walking")
	check(intro.driving and intro.story.phase == State.Phase.ARRIVAL, "Introduction begins seated in car on arrival route")
	intro._begin()
	check(not intro.menu.visible and not intro.car.paused and intro.started, "Begin enables car control")
	var car_start: Vector3 = intro.car.position
	Input.action_press("move_forward")
	await wait_physics(100)
	check(intro.car.position.z < car_start.z - 2.0 and intro.car.speed > 0.7, "Actual throttle input moves the car forward")
	intro._toggle_vehicle()
	check(intro.driving and intro.story.phase == State.Phase.ARRIVAL, "Cannot get out of moving car")

	intro._toggle_phone()
	var phone_stop: Vector3 = intro.car.position
	await wait_physics(100)
	check(intro.phone.visible and intro.car.paused and intro.car.position.is_equal_approx(phone_stop), "Phone freezes car even while throttle is held")
	check(intro.phone_text.text.contains("Clara") and intro.phone_text.text.contains("Tomás"), "Phone shows actual neighbor orders")
	Input.action_release("move_forward")
	intro._toggle_phone()
	Input.action_press("car_brake")
	await wait_physics(80)
	Input.action_release("car_brake")
	check(intro.car.is_safe_to_exit(), "Brake input brings car to safe exit speed")
	intro._toggle_vehicle()
	check(intro.driving and intro.story.phase == State.Phase.ARRIVAL, "Stopped car outside marked destination cannot advance route")

	intro._unhandled_input(action_event("ui_cancel"))
	var pause_stop: Vector3 = intro.car.position
	Input.action_press("move_forward")
	await wait_physics(100)
	check(intro.menu.visible and intro.car.paused and intro.car.position.is_equal_approx(pause_stop), "Pause freezes the car despite held throttle")
	Input.action_release("move_forward")
	intro._unhandled_input(action_event("ui_cancel"))
	check(not intro.menu.visible and not intro.car.paused, "Resume restores driving")

	intro.car.position = Vector3(3, 0.04, 0)
	intro.car.rotation = Vector3.ZERO
	intro.car.reset_motion()
	await wait_physics(2)
	intro._toggle_vehicle()
	check(not intro.driving and intro.story.phase == State.Phase.DELIVERIES and intro.player.enabled, "Park and exit enables neighborhood deliveries")
	check(not intro.packages[0].visible and not intro.packages[3].visible, "Closed trunk hides neighbor and final parcels")
	var latch: Node = null
	for child in intro.car.get_children():
		if child.has_meta("interaction") and child.get_meta("interaction") == "trunk":
			latch = child
	check(latch != null, "Trunk has interactive latch")
	await aim(intro, Vector3(3, 0.04, 4.5), intro.car.global_transform * Vector3(0, 0.66, 2.04))
	check(intro.player.get_target() == latch, "Player can reach trunk latch using actual interaction ray")
	intro._unhandled_input(action_event("interact"))
	check(intro.story.trunk_open and intro.packages[0].visible and not intro.packages[3].visible, "E opens trunk and exposes only neighbor parcels")

	for index in [1, 0, 2]:
		var package_x := 3.0 + float(index - 1) * 0.55
		await aim(intro, Vector3(package_x, 0.04, 4.5), intro.packages[index].global_position)
		check(intro.player.get_target() == intro.packages[index], "Ray reaches rear trunk parcel %d without crossing car" % index)
		intro._unhandled_input(action_event("interact"))
		check(intro.story.carried == index and not intro.packages[index].visible, "E picks requested parcel %d and removes it from trunk" % index)
		check(intro.held_package.visible, "Picked parcel appears in player's hands")
		if index == 1:
			await aim(intro, Vector3(17.7, 0.04, -3.8), Vector3(19.8, 1.225, -3.8))
			check(intro.player.get_target() == intro.world.delivery_doors[0], "Apartment doors reachable by actual interaction ray")
			intro._unhandled_input(action_event("interact"))
			check(intro.story.carried == index and intro.story.delivered.is_empty(), "Wrong door preserves carried parcel and progress")
			intro._unhandled_input(action_event("return_package"))
			check(intro.story.carried == index and not intro.packages[index].visible, "Q away from trunk cannot teleport parcel back")
		var door_z := float(index - 1) * 3.8
		await aim(intro, Vector3(17.7, 0.04, door_z), Vector3(19.8, 1.225, door_z))
		check(intro.player.get_target() == intro.world.delivery_doors[index], "Ray reaches intended apartment %d" % index)
		intro._unhandled_input(action_event("interact"))
		check(intro.story.delivered.has(index) and intro.story.carried == -1, "E correctly delivers parcel %d" % index)
		check(not intro.held_package.visible, "Delivered parcel disappears from hands")

	check(intro.story.phase == State.Phase.LAST_PACKAGE and intro.story.delivered.size() == 3, "All three real scene deliveries unlock final route")
	check(intro.packages[3].visible, "Final parcel appears after neighbors receive their orders")
	await aim(intro, Vector3(3, 0.04, 4.5), intro.packages[3].global_position)
	check(intro.player.get_target() == intro.packages[3], "Final parcel reachable using interaction ray")
	intro._unhandled_input(action_event("interact"))
	check(intro.story.phase == State.Phase.TO_HOUSE and intro.story.carried == State.LAST_PACKAGE, "E picks final package and changes destination")
	intro.player.global_position = intro.car.global_position + Vector3(2.25, 0, 0)
	intro._toggle_vehicle()
	check(intro.driving and not intro.story.trunk_open and intro.car.driving and not intro.held_package.visible, "Boarding closes trunk and returns to driving with parcel")
	intro.car.position = Vector3(3, 0.04, -60)
	intro.car.reset_motion()
	await wait_physics(2)
	check(intro.darkened, "Final journey switches neighborhood to horror atmosphere")
	intro._toggle_vehicle()
	check(not intro.driving and intro.story.phase == State.Phase.HOUSE and intro.story.carried == State.LAST_PACKAGE, "Parking at abandoned house enables final delivery")
	intro.player.global_position = Vector3(11, 0.04, -60)
	intro.player.velocity = Vector3.ZERO
	await process_frame
	await process_frame
	check(intro.in_capture and intro.story.phase == State.Phase.CAPTURED and not intro.player.enabled and intro.car.paused, "Crossing house entrance captures player and disables controls")
	check(not intro.held_package.visible and intro.story.carried == -1, "Capture consumes final package")
	await create_timer(2.4).timeout
	await process_frame
	check(not is_instance_valid(intro), "Capture transition removes introduction and its controls")
	check(is_instance_valid(current_scene) and current_scene.scene_file_path == "res://scenes/pressure_trial.tscn", "Capture fade opens the first survival trial")
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Intro scene integration: %d failures" % failures)
	quit(1 if failures else 0)
