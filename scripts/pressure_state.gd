class_name PressureState
extends RefCounted

# The scene owns input, presentation and pause. These deterministic rules can
# also be run by a future multiplayer authority without depending on nodes.
enum Outcome { ACTIVE, ESCAPED, INJURED, DEAD }

const GAUGE_LEVELS: int = 7
const TOTAL_SECONDS: float = 180.0
const INITIAL_DANGER: float = 12.0
const DANGER_PER_SECOND: float = 0.18
const WRONG_LOCK_DANGER: float = 20.0
const MISALIGNED_DANGER: float = 12.0
const WHEEL_EFFECTS: Array = [[0, 2], [0, 1], [1, 2]]

var outcome: Outcome = Outcome.ACTIVE
var gauges: Array[int] = [0, 0, 0]
var targets: Array = []
var lock_order: Array[int] = [0, 1, 2]
var stage: int = 0
var seconds_left: float = TOTAL_SECONDS
var danger: float = INITIAL_DANGER
var variant_id: int = 0


func _init() -> void:
	reset()


func reset(seed: int = -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed < 0:
		rng.randomize()
		variant_id = rng.randi_range(0, 2147483646)
	else:
		variant_id = seed
	rng.seed = variant_id
	outcome = Outcome.ACTIVE
	stage = 0
	seconds_left = TOTAL_SECONDS
	danger = INITIAL_DANGER
	gauges.clear()
	for index in range(3):
		gauges.append(rng.randi_range(0, GAUGE_LEVELS - 1))
	lock_order = [0, 1, 2]
	# Explicit shuffle keeps all randomness in this generator, rather than the
	# global RNG used by Array.shuffle().
	for index in range(2, 0, -1):
		var other: int = rng.randi_range(0, index)
		var previous: int = lock_order[index]
		lock_order[index] = lock_order[other]
		lock_order[other] = previous
	targets.clear()
	var previous_target: Array[int] = gauges.duplicate()
	for index in range(3):
		var candidate: Array[int] = previous_target.duplicate()
		while candidate == previous_target or targets.has(candidate):
			candidate = previous_target.duplicate()
			for wheel in range(3):
				var turns: int = rng.randi_range(-2, 2)
				for affected in WHEEL_EFFECTS[wheel]:
					candidate[affected] = posmod(candidate[affected] + turns, GAUGE_LEVELS)
		targets.append(candidate)
		previous_target = candidate


func current_target() -> Array[int]:
	if stage >= targets.size():
		return []
	var result: Array[int] = []
	result.assign(targets[stage])
	return result


func turn(wheel: int, direction: int = 1) -> String:
	if outcome != Outcome.ACTIVE:
		return "La prueba terminó."
	if wheel < 0 or wheel >= WHEEL_EFFECTS.size() or direction not in [-1, 1]:
		return "Ese movimiento no es válido."
	for affected in WHEEL_EFFECTS[wheel]:
		gauges[affected] = posmod(gauges[affected] + direction, GAUGE_LEVELS)
	return "Rueda %s: %s un nivel." % [
		["A", "B", "C"][wheel], "sube" if direction > 0 else "baja"
	]


func release(lock: int) -> String:
	if outcome != Outcome.ACTIVE:
		return "La prueba terminó."
	if lock < 0 or lock >= 3:
		return "Ese cierre no existe."
	if lock != lock_order[stage]:
		_add_danger(WRONG_LOCK_DANGER)
		return "Cierre equivocado. La presión subió. Revisa el orden del albarán."
	if gauges != current_target():
		_add_danger(MISALIGNED_DANGER)
		return "Los indicadores no coinciden. La presión subió."
	stage += 1
	if stage == 3:
		outcome = Outcome.ESCAPED
		return "El último cierre cede. Estás libre y sin lesiones."
	return "Cierre %d liberado. Lee la siguiente línea del albarán." % (lock + 1)


func tick(delta: float) -> void:
	if outcome != Outcome.ACTIVE or not is_finite(delta) or delta <= 0.0:
		return
	seconds_left = maxf(0.0, seconds_left - delta)
	_add_danger(delta * DANGER_PER_SECOND)
	if seconds_left <= 0.0:
		outcome = Outcome.DEAD


func emergency_escape() -> String:
	if outcome != Outcome.ACTIVE:
		return "La prueba terminó."
	outcome = Outcome.INJURED
	return "Fuerzas la sujeción y escapas. El brazo queda lesionado: moverte será más lento."


func clue_text() -> String:
	var target_lines: PackedStringArray = []
	for index in range(targets.size()):
		target_lines.append("Cierre %d: I=%d · II=%d · III=%d" % [
			lock_order[index] + 1, targets[index][0], targets[index][1], targets[index][2]
		])
	return (
		"ALBARÁN · %06d\n\n" % variant_id
		+ "Rueda A → I y III\nRueda B → I y II\nRueda C → II y III\n\n"
		+ "Cada giro cambia un nivel. Después de 6 vuelve a 0. Puedes girar en ambos sentidos.\n\n"
		+ "Orden de los cierres: %d → %d → %d\n\n" % [
			lock_order[0] + 1, lock_order[1] + 1, lock_order[2] + 1
		]
		+ "\n".join(target_lines) + "\n\n"
		+ "Ajusta I, II y III al objetivo de cada línea ANTES de abrir su cierre.\n"
		+ "Girar es reversible. Abrir con valores u orden incorrectos aumenta la presión."
	)


func _add_danger(amount: float) -> void:
	danger = clampf(danger + amount, 0.0, 100.0)
	if danger >= 100.0:
		outcome = Outcome.DEAD
