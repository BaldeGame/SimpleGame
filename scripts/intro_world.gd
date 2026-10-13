extends Node3D

var environment: Environment
var sunlight: DirectionalLight3D
var house_door: Node3D
var delivery_doors: Array[StaticBody3D] = []
var screen: Label3D

func box(size: Vector3, at: Vector3, color: Color, parent: Node = self, solid := true) -> Node3D:
	var body: Node3D = StaticBody3D.new() if solid else Node3D.new()
	body.position = at
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material_override = material
	body.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var collider := BoxShape3D.new()
		collider.size = size
		collision.shape = collider
		body.add_child(collision)
	parent.add_child(body)
	return body

func sign_text(text: String, at: Vector3, size := 40, facing := -PI / 2, parent: Node = self) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.rotation.y = facing
	label.font_size = size
	label.pixel_size = 0.006
	label.outline_size = 4
	label.modulate = Color("#f4dfb6")
	parent.add_child(label)
	return label

func _ready() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#8ca7b1")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#eedcbd")
	environment.ambient_light_energy = 0.65
	var sky := WorldEnvironment.new()
	sky.environment = environment
	add_child(sky)
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48, -25, 0)
	sunlight.light_color = Color("#ffdaa2")
	sunlight.light_energy = 0.9
	add_child(sunlight)
	_build_street()
	_build_apartments()
	_build_house()

func _build_street() -> void:
	box(Vector3(70, 0.2, 130), Vector3(0, -0.1, -30), Color("#647559"))
	box(Vector3(12, 0.06, 120), Vector3(0, -0.025, -25), Color("#474e54"), self, false)
	for z in range(-76, 31, 8):
		box(Vector3(0.13, 0.01, 3), Vector3(0, 0.013, z), Color("#dfd7b4"), self, false)
	box(Vector3(1.5, 0.06, 120), Vector3(7, -0.025, -25), Color("#aca895"), self, false)
	box(Vector3(1.5, 0.06, 120), Vector3(-7, -0.025, -25), Color("#aca895"), self, false)
	box(Vector3(0.2, 1.2, 130), Vector3(-28, 0.6, -30), Color("#3c5346"))
	box(Vector3(0.2, 1.2, 130), Vector3(28, 0.6, -30), Color("#3c5346"))
	box(Vector3(56, 1.2, 0.2), Vector3(0, 0.6, 35), Color("#3c5346"))
	box(Vector3(56, 1.2, 0.2), Vector3(0, 0.6, -90), Color("#3c5346"))
	for z in [21, 10, -15, -30, -45, -76]:
		box(Vector3(0.3, 4.2, 0.3), Vector3(-9, 2.1, z), Color("#6e6750"), self, false)
		box(Vector3(2.8, 1.7, 2.8), Vector3(-9, 4.4, z), Color("#577b54"), self, false)
		box(Vector3(0.15, 3.8, 0.15), Vector3(6.9, 1.9, z), Color("#39434b"))
		box(Vector3(0.8, 0.15, 0.5), Vector3(6.5, 3.8, z), Color("#e9d7a4"), self, false)
	# Neighboring homes make the beginning feel inhabited.
	for z in [16, -16, -32]:
		box(Vector3(9, 5.5, 8), Vector3(-17, 2.75, z), Color("#aa8870"))
		box(Vector3(9.8, 0.45, 8.8), Vector3(-17, 5.6, z), Color("#785f50"), self, false)
		for offset in [-2.5, 2.5]:
			box(Vector3(0.04, 1.5, 1.3), Vector3(-12.47, 3.3, z + offset), Color("#ced2b7"), self, false)
	# Parking bay: large enough for a forgiving first drive.
	box(Vector3(0.06, 0.015, 10), Vector3(5.7, 0.02, 0), Color("#f4d188"), self, false)
	for z in [-5, 5]:
		box(Vector3(3.5, 0.015, 0.06), Vector3(4, 0.02, z), Color("#f4d188"), self, false)
	sign_text("LOS CEDROS\nESTACIONA AQUÍ", Vector3(7.6, 2.4, 4.3), 44)
	sign_text("CALLE DEL OLMO 17\nSIGUE RECTO", Vector3(7.6, 2.3, -24), 36)
	var signpost := box(Vector3(0.1, 2.6, 0.1), Vector3(7.6, 1.3, -24), Color("#6a614e"))
	signpost.collision_layer = 0

func _build_apartments() -> void:
	var wall := Color("#657b72")
	box(Vector3(12, 0.08, 12), Vector3(14, 0, 0), Color("#b7a78b"), self, false)
	box(Vector3(0.2, 7, 12), Vector3(20, 3.5, 0), wall)
	for z in [-6.0, 6.0]:
		box(Vector3(12, 7, 0.2), Vector3(14, 3.5, z), wall)
	for z in [-3.7, 3.7]:
		box(Vector3(0.2, 7, 4.6), Vector3(8, 3.5, z), wall)
	box(Vector3(0.2, 4.2, 2.8), Vector3(8, 4.9, 0), wall)
	sign_text("LOS CEDROS", Vector3(7.83, 3.7, 0), 60)
	box(Vector3(12.4, 0.3, 12.4), Vector3(14, 7.1, 0), Color("#45594e"), self, false)
	var names := ["CLARA", "BRUNO", "TOMÁS"]
	for i in range(3):
		var z := float(i - 1) * 3.8
		var door := box(Vector3(0.12, 2.45, 1.45), Vector3(19.8, 1.225, z), Color("#9c6d46")) as StaticBody3D
		door.set_meta("interaction", "door")
		door.set_meta("door", str(101 + i))
		delivery_doors.append(door)
		sign_text(str(101 + i) + "\n" + names[i], Vector3(19.71, 1.95, z), 34)
		box(Vector3(0.1, 0.1, 0.08), Vector3(19.65, 1.0, z - 0.5), Color("#e4be74"), self, false)
	sign_text("Gracias por traer los encargos.\nEl ascensor sigue en reparación.", Vector3(19.65, 3.3, 0), 32)
	# A quiet lived-in vestibule: plant, mailboxes and notice board.
	box(Vector3(0.8, 0.65, 0.8), Vector3(9.4, 0.325, -4.8), Color("#ad7960"))
	box(Vector3(1.2, 1.3, 1.2), Vector3(9.4, 1.25, -4.8), Color("#4c7656"), self, false)
	for x in [10.5, 11.5, 12.5]:
		box(Vector3(0.7, 0.6, 0.3), Vector3(x, 1.3, -5.8), Color("#414b50"), self, false)
	box(Vector3(2.6, 1.6, 0.04), Vector3(14, 1.8, -5.85), Color("#8e6f45"), self, false)
	sign_text("REUNIÓN DE VECINOS\nViernes · 7:00 p. m.\nTraigan algo para compartir.", Vector3(14, 1.8, -5.8), 24, 0)

func _build_house() -> void:
	var wall := Color("#5a5b55")
	box(Vector3(13, 0.1, 12), Vector3(14.5, 0, -60), Color("#756d5e"), self, false)
	box(Vector3(0.2, 4.5, 12), Vector3(21, 2.25, -60), wall)
	for z in [-66.0, -54.0]:
		box(Vector3(13, 4.5, 0.2), Vector3(14.5, 2.25, z), wall)
	for z in [-63.7, -56.3]:
		box(Vector3(0.2, 4.5, 4.6), Vector3(8, 2.25, z), wall)
	box(Vector3(0.2, 1.8, 2.8), Vector3(8, 3.6, -60), wall)
	box(Vector3(13.8, 0.4, 12.8), Vector3(14.5, 4.7, -60), Color("#343c3c"), self, false)
	sign_text("17", Vector3(7.81, 2.4, -57.5), 52)
	for z in [-63.7, -56.3]:
		box(Vector3(0.04, 1.5, 1.9), Vector3(7.86, 2.0, z), Color("#252d31"), self, false)
		for offset in [-0.45, 0.45]:
			box(Vector3(0.12, 0.2, 2.1), Vector3(7.8, 2.0 + offset, z), Color("#817052"), self, false)
	house_door = Node3D.new()
	house_door.position = Vector3(8, 0, -61.2)
	house_door.rotation.y = 0.65
	add_child(house_door)
	box(Vector3(0.12, 2.6, 2.4), Vector3(0, 1.3, 1.2), Color("#4e3f32"), house_door, false)
	box(Vector3(2.0, 0.15, 1.4), Vector3(15, 0.9, -60), Color("#403b32"))
	for x in [14.3, 15.7]:
		box(Vector3(0.12, 0.9, 0.12), Vector3(x, 0.45, -60), Color("#403b32"), self, false)
	box(Vector3(0.12, 1.5, 2.4), Vector3(20.8, 1.8, -60), Color("#080e13"), self, false)
	screen = sign_text("", Vector3(20.7, 1.8, -60), 40)

func darken() -> void:
	environment.background_color = Color("#17272d")
	environment.ambient_light_color = Color("#78939a")
	environment.ambient_light_energy = 0.2
	sunlight.light_energy = 0.22

func show_capture() -> void:
	screen.text = "TE ESTABA\nESPERANDO."
	house_door.rotation.y = 0
