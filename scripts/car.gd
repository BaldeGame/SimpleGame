class_name IntroCar
extends CharacterBody3D

## A small, deliberately forgiving car for the neighborhood introduction.
## The root scene owns entering, exiting, camera selection and pause menus.

const MAX_FORWARD_SPEED := 8.5
const MAX_REVERSE_SPEED := 3.0
const ACCELERATION := 4.5
const BRAKING := 12.0
const ROLLING_RESISTANCE := 2.1
const STEERING_RATE := 1.0
const GRAVITY := 18.0

var camera: Camera3D
var speed := 0.0
var driving := false
var paused := false
var sensitivity := 0.002
var _wheel_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	floor_snap_length = 0.3
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.94, 1.50, 3.84)
	var collider := CollisionShape3D.new()
	collider.position.y = 0.77
	collider.shape = shape
	add_child(collider)
	_build_car()
	camera = Camera3D.new()
	camera.name = "DriverCamera"
	camera.position = Vector3(-0.38, 1.40, -0.24)
	camera.fov = 78.0
	camera.near = 0.04
	add_child(camera)


func _unhandled_input(event: InputEvent) -> void:
	if not driving or paused or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		camera.rotation.y = clampf(camera.rotation.y - event.relative.x * sensitivity, -1.05, 1.05)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -0.55, 0.55)


func _physics_process(delta: float) -> void:
	if paused:
		return
	if driving:
		var throttle := Input.get_axis("move_back", "move_forward")
		if Input.is_action_pressed("car_brake"):
			speed = move_toward(speed, 0.0, BRAKING * delta)
		elif throttle > 0.0:
			var acceleration := BRAKING if speed < -0.05 else ACCELERATION
			speed = move_toward(speed, MAX_FORWARD_SPEED, acceleration * delta)
		elif throttle < 0.0:
			var acceleration := BRAKING if speed > 0.05 else ACCELERATION * 0.65
			speed = move_toward(speed, -MAX_REVERSE_SPEED, acceleration * delta)
		else:
			speed = move_toward(speed, 0.0, ROLLING_RESISTANCE * delta)
		var steering := Input.get_axis("move_left", "move_right")
		var steering_factor := clampf(absf(speed) / 2.5, 0.0, 1.0)
		rotate_y(-steering * STEERING_RATE * steering_factor * signf(speed) * delta)
	else:
		speed = 0.0
	var forward := -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	# A collision removes the blocked part of our speed, avoiding constant wheelspin
	# and making a bump easy to recover from with reverse.
	if driving:
		var actual_speed := Vector3(velocity.x, 0.0, velocity.z).dot(forward)
		if absf(actual_speed) < absf(speed):
			speed = actual_speed
	for wheel in _wheel_meshes:
		wheel.rotate_object_local(Vector3.UP, -speed * delta / 0.36)


func set_driving(value: bool) -> void:
	driving = value
	if camera != null and value:
		camera.rotation = Vector3.ZERO
	if not value:
		reset_motion()


func reset_motion() -> void:
	speed = 0.0
	velocity = Vector3.ZERO


func is_safe_to_exit() -> bool:
	return absf(speed) < 0.7


func get_trunk_position() -> Vector3:
	return global_transform * Vector3(0.0, 0.75, 2.10)


func _build_car() -> void:
	var paint := _material(Color(0.10, 0.30, 0.32), 0.32, 0.45)
	var dark_paint := _material(Color(0.065, 0.20, 0.23), 0.35, 0.45)
	var rubber := _material(Color(0.035, 0.04, 0.045), 0.9)
	var chrome := _material(Color(0.55, 0.59, 0.60), 0.25, 0.8)
	var interior := _material(Color(0.095, 0.11, 0.12), 0.95)
	var seat := _material(Color(0.24, 0.20, 0.17), 0.95)
	var glass := _material(Color(0.32, 0.48, 0.51, 0.16), 0.18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var light := _material(Color(1.0, 0.91, 0.64), 0.3)
	light.emission_enabled = true
	light.emission = Color(1.0, 0.82, 0.38)
	light.emission_energy_multiplier = 1.2
	var red := _material(Color(0.60, 0.035, 0.035), 0.3)
	red.emission_enabled = true
	red.emission = Color(0.32, 0.015, 0.01)

	_box("Body", Vector3(1.84, 0.46, 3.62), Vector3(0, 0.69, 0), paint)
	_box("Hood", Vector3(1.74, 0.20, 1.04), Vector3(0, 1.0, -1.27), dark_paint)
	_box("Trunk", Vector3(1.74, 0.20, 0.77), Vector3(0, 1.0, 1.43), paint)
	_box("Roof", Vector3(1.63, 0.10, 1.83), Vector3(0, 1.79, 0.18), paint)
	_box("FrontBumper", Vector3(1.85, 0.15, 0.13), Vector3(0, 0.56, -1.87), rubber)
	_box("RearBumper", Vector3(1.85, 0.15, 0.13), Vector3(0, 0.56, 1.87), rubber)
	_box("Grille", Vector3(0.76, 0.20, 0.035), Vector3(0, 0.77, -1.83), interior)
	for side in [-1.0, 1.0]:
		_box("Headlight", Vector3(0.39, 0.20, 0.045), Vector3(side * 0.64, 0.81, -1.84), light)
		_box("TailLight", Vector3(0.38, 0.17, 0.04), Vector3(side * 0.64, 0.83, 1.84), red)
		_box("Door", Vector3(0.05, 0.43, 1.70), Vector3(side * 0.91, 0.97, 0.14), paint)
		_box("DoorHandle", Vector3(0.035, 0.045, 0.18), Vector3(side * 0.96, 1.10, 0.42), chrome)
		_box("Window", Vector3(0.025, 0.49, 1.64), Vector3(side * 0.815, 1.49, 0.18), glass)
		_box("CenterPillar", Vector3(0.075, 0.63, 0.075), Vector3(side * 0.81, 1.45, 0.31), dark_paint)
		var front_pillar := _box("FrontPillar", Vector3(0.065, 0.73, 0.075), Vector3(side * 0.81, 1.44, -0.69), paint)
		front_pillar.rotation.x = -0.25
		var rear_pillar := _box("RearPillar", Vector3(0.065, 0.70, 0.075), Vector3(side * 0.81, 1.45, 1.04), paint)
		rear_pillar.rotation.x = 0.24
		_box("MirrorArm", Vector3(0.18, 0.04, 0.04), Vector3(side * 0.96, 1.31, -0.51), rubber)
		_box("Mirror", Vector3(0.14, 0.15, 0.24), Vector3(side * 1.06, 1.31, -0.51), dark_paint)
		for axle in [-1.18, 1.21]:
			var wheel := _cylinder("Wheel", 0.36, 0.20, Vector3(side * 0.91, 0.38, axle), rubber)
			wheel.rotation.z = PI / 2.0
			_wheel_meshes.append(wheel)
			var hub := _cylinder("WheelHub", 0.20, 0.215, Vector3(side * 0.91, 0.38, axle), chrome)
			hub.rotation.z = PI / 2.0

	var front_glass := _box("Windshield", Vector3(1.52, 0.61, 0.025), Vector3(0, 1.47, -0.69), glass)
	front_glass.rotation.x = -0.25
	var back_glass := _box("RearWindow", Vector3(1.52, 0.61, 0.025), Vector3(0, 1.47, 1.04), glass)
	back_glass.rotation.x = 0.24
	_box("Dashboard", Vector3(1.54, 0.16, 0.38), Vector3(0, 1.12, -0.63), interior)
	_box("DashboardTrim", Vector3(1.51, 0.035, 0.045), Vector3(0, 1.17, -0.42), chrome)
	for side in [-1.0, 1.0]:
		_box("SeatBase", Vector3(0.65, 0.15, 0.61), Vector3(side * 0.40, 0.93, 0.16), seat)
		_box("SeatBack", Vector3(0.65, 0.63, 0.12), Vector3(side * 0.40, 1.27, 0.47), seat)
	_box("BackSeat", Vector3(1.42, 0.37, 0.47), Vector3(0, 1.07, 0.97), seat)
	var wheel_ring := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.14
	ring.outer_radius = 0.19
	wheel_ring.mesh = ring
	wheel_ring.material_override = rubber
	wheel_ring.position = Vector3(-0.38, 1.20, -0.47)
	wheel_ring.rotation.x = 1.05
	add_child(wheel_ring)
	_box("SteeringSpoke", Vector3(0.32, 0.045, 0.045), Vector3(-0.38, 1.20, -0.47), interior)
	_box("Radio", Vector3(0.24, 0.10, 0.025), Vector3(0.20, 1.17, -0.43), rubber)
	_box("RadioDisplay", Vector3(0.16, 0.045, 0.012), Vector3(0.20, 1.185, -0.413), _material(Color(0.38, 0.70, 0.49)))
	_box("RearPlate", Vector3(0.48, 0.17, 0.03), Vector3(0, 0.70, 1.865), _material(Color(0.88, 0.86, 0.75)))
	_box("TrunkHandle", Vector3(0.18, 0.045, 0.035), Vector3(0, 1.00, 1.83), chrome)


func _material(color: Color, roughness: float = 0.7, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _box(node_name: String, size: Vector3, location: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = location
	instance.material_override = material
	add_child(instance)
	return instance


func _cylinder(node_name: String, radius: float, height: float, location: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = location
	instance.material_override = material
	add_child(instance)
	return instance
