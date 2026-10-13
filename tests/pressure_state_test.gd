extends SceneTree

const State = preload("res://scripts/pressure_state.gd")
var failures: int = 0


func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)


# Independent breadth-first search of the 343 possible indicator states.
# The solver knows the player's published wheel rules, not the generator's
# construction, its RNG or any stored solution.
func solve(start: Array[int], goal: Array[int]) -> Array:
	var frontier: Array = [[start.duplicate(), []]]
	var visited: Dictionary = { str(start): true }
	var head: int = 0
	while head < frontier.size():
		var entry: Array = frontier[head]
		head += 1
		var values: Array = entry[0]
		var path: Array = entry[1]
		if values == goal:
			return path
		for wheel in range(3):
			for direction in [-1, 1]:
				var next: Array = values.duplicate()
				match wheel:
					0:
						next[0] = posmod(next[0] + direction, 7)
						next[2] = posmod(next[2] + direction, 7)
					1:
						next[0] = posmod(next[0] + direction, 7)
						next[1] = posmod(next[1] + direction, 7)
					2:
						next[1] = posmod(next[1] + direction, 7)
						next[2] = posmod(next[2] + direction, 7)
				var key: String = str(next)
				if not visited.has(key):
					visited[key] = true
					var next_path: Array = path.duplicate()
					next_path.append([wheel, direction])
					frontier.append([next, next_path])
	return [[-1, 0]]


func snapshot(state) -> Array:
	return [state.outcome, state.gauges.duplicate(), state.targets.duplicate(true),
		state.lock_order.duplicate(), state.stage, state.seconds_left, state.danger, state.variant_id]


func _initialize() -> void:
	var state = State.new()
	check(state.outcome == State.Outcome.ACTIVE and state.stage == 0, "A new puzzle starts active without releasing a lock")
	check(state.seconds_left == 180.0 and state.danger == 12.0, "No time runs before the scene starts ticking")
	var replay = State.new()
	replay.reset(state.variant_id)
	check(state.variant_id >= 0 and snapshot(state) == snapshot(replay), "A randomly generated variant can be replayed from its displayed ID")
	var variants: Dictionary = {}
	for seed in range(120):
		state.reset(seed)
		var same = State.new()
		same.reset(seed)
		check(snapshot(state) == snapshot(same), "Seed %d is reproducible independently of global RNG" % seed)
		variants[str([state.gauges, state.targets, state.lock_order])] = true
		check(state.lock_order.size() == 3 and state.lock_order.has(0) and state.lock_order.has(1) and state.lock_order.has(2), "Seed %d uses each lock exactly once" % seed)
		for stage_index in range(3):
			var goal: Array[int] = state.current_target()
			check(goal.size() == 3 and goal != state.gauges, "Each new target requires an actual adjustment")
			for value in goal:
				check(value >= 0 and value <= 6, "All displayed target levels are within the gauge range")
			# Mutating a UI snapshot cannot change the authoritative target.
			var original: Array[int] = goal.duplicate()
			goal[0] = -999
			check(state.current_target() == original, "current_target returns an independent copy")
			var path: Array = solve(state.gauges, original)
			check(not path.is_empty() and path[0] != [-1, 0], "Seed %d stage %d has a solution from its actual preceding state" % [seed, stage_index])
			for move in path:
				state.turn(move[0], move[1])
				state.tick(0.5)
			check(state.gauges == original, "Independent solver reaches the target using public controls")
			state.release(state.lock_order[stage_index])
			check(state.stage == stage_index + 1, "A correctly aligned lock advances exactly one stage")
		check(state.outcome == State.Outcome.ESCAPED and state.current_target().is_empty(), "All generated variants finish alive after three releases")
	check(variants.size() > 100, "Attempts have many different puzzles, rather than a fixed combination")

	state.reset(42)
	var before: Array = snapshot(state)
	state.turn(-1)
	state.turn(3)
	state.turn(0, 0)
	state.turn(0, 2)
	state.release(-1)
	state.release(3)
	state.tick(-1.0)
	state.tick(0.0)
	state.tick(NAN)
	state.tick(INF)
	check(snapshot(state) == before, "Invalid controls and deltas have no effects")
	for wheel in range(3):
		state.turn(wheel, 1)
		state.turn(wheel, -1)
	check(snapshot(state) == before, "Experimenting with wheels is reversible and adds no danger")
	for index in range(7):
		state.turn(0, 1)
	check(snapshot(state) == before, "The gauge wraps from six to zero consistently")
	state.release(state.lock_order[0])
	check(state.stage == 0 and state.danger == 24.0, "Correct lock with wrong indicator alignment costs pressure but never progress")
	state.release((state.lock_order[0] + 1) % 3)
	check(state.stage == 0 and state.danger == 44.0, "Wrong lock adds the higher pressure penalty")
	state.tick(10.0)
	check(is_equal_approx(state.seconds_left, 170.0) and is_equal_approx(state.danger, 45.8), "Elapsed playtime advances countdown and ambient pressure")
	check(state.clue_text().contains("Rueda A") and state.clue_text().contains("Orden") and state.clue_text().contains("42"), "Player has the wheel rules, sequence and reproducible variant identifier")
	for index in range(3):
		var expected_line: String = "Cierre %d: I=%d · II=%d · III=%d" % [
			state.lock_order[index] + 1, state.targets[index][0], state.targets[index][1], state.targets[index][2]
		]
		check(state.clue_text().contains(expected_line), "The parcel label lists the exact target for each lock in sequence")

	state.reset(5)
	state.tick(179.0)
	check(state.outcome == State.Outcome.ACTIVE and state.seconds_left == 1.0, "The final second remains playable")
	state.tick(1.0)
	check(state.outcome == State.Outcome.DEAD and state.seconds_left == 0.0, "The deadline is fatal at exactly zero")
	check_terminal_protection(state, "dead")
	state.reset(5)
	for index in range(5):
		state.release((state.lock_order[0] + 1) % 3)
	check(state.outcome == State.Outcome.DEAD and state.danger == 100.0, "Accumulated mistakes can kill before the deadline and danger is clamped")
	check_terminal_protection(state, "pressure death")
	state.reset(7)
	state.emergency_escape()
	check(state.outcome == State.Outcome.INJURED and state.stage == 0, "Emergency escape records injury without pretending the puzzle was solved")
	check_terminal_protection(state, "injured")
	state.reset(8)
	for stage_index in range(3):
		for move in solve(state.gauges, state.current_target()):
			state.turn(move[0], move[1])
		state.release(state.lock_order[stage_index])
	check_terminal_protection(state, "escaped")
	state.reset(9)
	check(state.outcome == State.Outcome.ACTIVE and state.stage == 0 and state.seconds_left == 180.0 and state.danger == 12.0, "Restart clears death, injury and progress for a fresh attempt")
	print("Pressure puzzle rules: %d failures across 120 independently solved variants" % failures)
	quit(1 if failures else 0)


func check_terminal_protection(state, label: String) -> void:
	var before: Array = snapshot(state)
	state.turn(0)
	state.release(0)
	state.tick(1000.0)
	state.emergency_escape()
	check(snapshot(state) == before, "Terminal state '%s' preserves its outcome and all state" % label)
