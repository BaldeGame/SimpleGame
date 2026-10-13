extends CharacterBody3D

const WALK_SPEED := 3.5
const GRAVITY := 18.0
var sensitivity := 0.002
var camera: Camera3D
var ray: RayCast3D
var enabled := false

func _ready() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.75
	var body := CollisionShape3D.new()
	body.shape = capsule
	body.position.y = 0.875
	add_child(body)
	camera = Camera3D.new()
	camera.position.y = 1.6
	camera.fov = 75
	add_child(camera)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.8)
	ray.enabled = true
	ray.add_exception(self)
	camera.add_child(ray)

func _unhandled_input(event: InputEvent) -> void:
	if enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -1.35, 1.35)

func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	if enabled:
		var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		direction = (transform.basis * Vector3(axis.x, 0, axis.y)).normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	move_and_slide()

func get_target() -> Node:
	if not ray.is_colliding():
		return null
	var target := ray.get_collider() as Node
	if target != null and target.has_meta("interaction"):
		return target
	return null
