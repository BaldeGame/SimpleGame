extends SceneTree

const Car = preload("res://scripts/car.gd")
var car: CharacterBody3D
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _assert_ok(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		push_error("FAIL: " + message)
		failures += 1


func _frames(count: int) -> void:
	for i in range(count):
		await physics_frame


func _static_box(size: Vector3, location: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.position = location
	body.add_child(collision)
	root.add_child(body)
	return body


func _run() -> void:
	for action in ["move_forward", "move_back", "move_left", "move_right", "car_brake"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	_static_box(Vector3(200, 0.2, 200), Vector3(0, -0.1, 0))
	car = Car.new()
	car.position = Vector3(0, 0.08, 0)
	root.add_child(car)
	car.set_driving(true)
	await _frames(4)
	var start := car.position
	Input.action_press("move_forward")
	await _frames(80)
	_assert_ok(car.speed > 5.0 and car.position.z < start.z - 2.0, "W accelerates and advances in local -Z")
	Input.action_release("move_forward")
	Input.action_press("car_brake")
	await _frames(40)
	_assert_ok(absf(car.speed) < 0.05 and car.is_safe_to_exit(), "Space brakes to a safe exit speed")
	Input.action_release("car_brake")
	Input.action_press("move_forward")
	await _frames(45)
	Input.action_press("move_right")
	await _frames(20)
	_assert_ok(car.rotation.y < -0.15 and car.speed > 1.0, "D turns right while moving")
	car.paused = true
	var paused_position := car.position
	var paused_heading := car.rotation.y
	var paused_speed: float = car.speed
	await _frames(30)
	_assert_ok(car.position.is_equal_approx(paused_position) and is_equal_approx(car.rotation.y, paused_heading) and is_equal_approx(car.speed, paused_speed), "Pause freezes translation, steering and speed")
	Input.action_release("move_forward")
	Input.action_release("move_right")
	car.paused = false
	car.reset_motion()
	car.position = Vector3(0, 0.08, 0)
	car.rotation = Vector3.ZERO
	_static_box(Vector3(20, 3, 0.2), Vector3(0, 1.5, -4))
	await _frames(4)
	Input.action_press("move_forward")
	await _frames(100)
	_assert_ok(car.position.z > -2.05 and absf(car.speed) < 0.1, "Wall collision stops the car without passing through")
	var impact_z := car.position.z
	Input.action_release("move_forward")
	Input.action_press("move_back")
	await _frames(60)
	_assert_ok(car.speed < -1.0 and car.position.z > impact_z + 0.5, "S reverses away from a collision")
	Input.action_release("move_back")
	car.set_driving(false)
	var parked_position := car.position
	await _frames(20)
	_assert_ok(absf(car.speed) < 0.001 and absf(car.position.z - parked_position.z) < 0.001, "Exiting keeps the parked car still")
	car.position = Vector3(3, 0, -2)
	car.rotation.y = PI / 2.0
	_assert_ok(car.get_trunk_position().distance_to(Vector3(5.10, 0.75, -2)) < 0.001, "Trunk position follows the car world rotation")
	print("Car physics checks complete; failures: ", failures)
	quit(0 if failures == 0 else 1)
