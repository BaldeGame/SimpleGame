extends SceneTree

const State = preload("res://scripts/pressure_state.gd")
const TRIAL_SCENE := "res://scenes/pressure_trial.tscn"
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


func create_trial(seed: int) -> Node3D:
	set_meta("pressure_seed", seed)
	var trial = load(TRIAL_SCENE).instantiate()
	root.add_child(trial)
	current_scene = trial
	await wait_physics(2)
	return trial


func discard_trial() -> void:
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await process_frame
	await process_frame


func aim(trial: Node3D, at: Vector3, from: Vector3 = Vector3.INF) -> void:
	if from.is_finite():
		trial.player.global_position = from
	trial.player.velocity = Vector3.ZERO
	trial.player.rotation = Vector3.ZERO
	trial.player.camera.look_at(at)
	await wait_physics(2)
	trial.player.ray.force_raycast_update()


# Enumerate the published three-wheel equations. No generator solution or
# authoritative turn implementation is used to decide the player's moves.
func solve_turn_counts(values: Array[int], goal: Array[int]) -> Array[int]:
	for a in range(7):
		for b in range(7):
			for c in range(7):
				if posmod(values[0] + a + b, 7) == goal[0] and posmod(values[1] + b + c, 7) == goal[1] and posmod(values[2] + a + c, 7) == goal[2]:
					return [a, b, c]
	return []


func find_button(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node as Button
	for child in node.get_children():
		var found := find_button(child, label)
		if found != null:
			return found
	return null


func _run() -> void:
	var trial = await create_trial(42)
	check(trial.briefing.visible and not trial.started and not trial.player.enabled, "Opening briefing blocks control before the player accepts the challenge")
	var initial_time: float = trial.state.seconds_left
	await wait_physics(8)
	check(trial.state.seconds_left == initial_time and trial.state.danger == State.INITIAL_DANGER, "Briefing does not consume countdown or add pressure")
	trial._begin()
	check(trial.started and not trial.briefing.visible and trial.restrained and trial.player.enabled, "Begin permits looking while the player remains restrained")
	var seated: Vector3 = trial.player.position
	Input.action_press("move_forward")
	await wait_physics(8)
	Input.action_release("move_forward")
	check(trial.player.position.is_equal_approx(seated), "Held movement cannot walk out of the chair")
	check(trial.state.seconds_left < initial_time, "Active play starts the countdown")

	trial._toggle_pause()
	var paused_time: float = trial.state.seconds_left
	var paused_danger: float = trial.state.danger
	Input.action_press("move_forward")
	await wait_physics(8)
	Input.action_release("move_forward")
	check(trial.menu.visible and not trial.player.enabled and trial.state.seconds_left == paused_time and trial.state.danger == paused_danger, "Pause freezes time, pressure and player control")
	trial._unhandled_input(action_event("interact"))
	check(trial.state.stage == 0, "Interaction during pause cannot release a restraint")
	trial._toggle_pause()
	check(not trial.menu.visible and trial.player.enabled, "Resume restores looking and interaction")

	await aim(trial, trial.world.clue.global_position)
	check(trial.player.get_target() == trial.world.clue, "Parcel clue is reachable from the chair using the actual interaction ray")
	trial._unhandled_input(action_event("interact"))
	check(trial.clue.visible and trial.clue_body.text.contains("Rueda A") and trial.clue_body.text.contains("Orden"), "Examining the delivered package exposes playable rules and lock order")
	var reading_time: float = trial.state.seconds_left
	await wait_physics(8)
	check(trial.state.seconds_left < reading_time and not trial.player.enabled, "Reading blocks manipulation but deliberately keeps the countdown running")
	trial._unhandled_input(action_event("inspect_clue"))
	check(not trial.clue.visible and trial.player.enabled, "Tab closes the clue and restores manipulation")

	await aim(trial, trial.world.wheels[0].global_position)
	check(trial.player.get_target() == trial.world.wheels[0], "Wheel A can be selected by the seated player's ray")
	var original: Array[int] = trial.state.gauges.duplicate()
	trial._unhandled_input(action_event("interact"))
	check(trial.state.gauges[0] == posmod(original[0] + 1, 7) and trial.state.gauges[1] == original[1] and trial.state.gauges[2] == posmod(original[2] + 1, 7), "E rotates the targeted wheel and changes only its connected gauges")
	trial._unhandled_input(action_event("pressure_reverse"))
	check(trial.state.gauges == original, "Q reverses the targeted wheel without losing the previous configuration")
	var wrong_lock: int = (trial.state.lock_order[0] + 1) % 3
	await aim(trial, trial.world.locks[wrong_lock].global_position)
	check(trial.player.get_target() == trial.world.locks[wrong_lock], "The release controls are physically reachable from the chair")
	var before_error: float = trial.state.danger
	trial._unhandled_input(action_event("interact"))
	check(trial.state.stage == 0 and is_equal_approx(trial.state.danger, before_error + State.WRONG_LOCK_DANGER), "An out-of-order release raises pressure without falsely advancing progress")
	check(trial.subtitle.text.contains("equivocado"), "An incorrect release gives understandable feedback")

	for stage_index in range(3):
		var goal: Array[int] = trial.state.current_target()
		var counts: Array[int] = solve_turn_counts(trial.state.gauges, goal)
		check(counts.size() == 3, "Trial stage %d has a solution independent of the generator" % stage_index)
		if counts.size() != 3:
			break
		for wheel in range(3):
			await aim(trial, trial.world.wheels[wheel].global_position)
			check(trial.player.get_target() == trial.world.wheels[wheel], "Ray reaches wheel %d during the real solution" % wheel)
			var backwards: bool = counts[wheel] > 3
			var turns: int = 7 - counts[wheel] if backwards else counts[wheel]
			for turn in range(turns):
				trial._unhandled_input(action_event("pressure_reverse" if backwards else "interact"))
		check(trial.state.gauges == goal, "Player input reaches the displayed target for stage %d" % stage_index)
		var lock_index: int = trial.state.lock_order[stage_index]
		await aim(trial, trial.world.locks[lock_index].global_position)
		check(trial.player.get_target() == trial.world.locks[lock_index], "Ray reaches the intended lock %d" % lock_index)
		trial._unhandled_input(action_event("interact"))
		check(trial.state.stage == stage_index + 1, "Opening the aligned correct lock advances one stage")
	check(trial.state.outcome == State.Outcome.ESCAPED and not trial.restrained and trial.resolved and trial.player.is_physics_processing(), "Three real lock interactions release the player for exploration")
	check(trial.player.speed_multiplier == 1.0 and trial.player.position.is_equal_approx(trial.world.get_escape_spawn()), "Normal escape places an uninjured player clear of the console")
	await aim(trial, trial.world.evidence.global_position, Vector3(2.5, 0.02, -0.3))
	check(trial.player.get_target() == trial.world.evidence, "The previous courier's evidence is reachable by normal exploration")
	trial._unhandled_input(action_event("interact"))
	check(trial.evidence_read and trial.clue.visible and trial.clue_body.text.contains("Daniel") and trial.clue_body.text.contains("103"), "Reading evidence connects the captivity to the introduction")
	trial._toggle_clue()
	await aim(trial, trial.world.final_exit.global_position, Vector3(0.73, 0.02, -2.8))
	check(trial.player.get_target() == trial.world.final_exit, "The released service exit can be selected without crossing a wall")
	trial._unhandled_input(action_event("interact"))
	check(trial.finished and trial.result.visible and not trial.player.enabled and trial.result_body.text.contains("Daniel"), "Service exit completes the first trial and preserves discovered evidence")
	await discard_trial()

	trial = await create_trial(13)
	trial._begin()
	await aim(trial, trial.world.emergency.global_position)
	check(trial.player.get_target() == trial.world.emergency, "The emergency handle is physically reachable from the chair")
	trial._unhandled_input(action_event("interact"))
	check(trial.emergency.visible and trial.state.outcome == State.Outcome.ACTIVE and trial.restrained, "Emergency interaction asks for a decision before applying permanent injury")
	var confirm := find_button(trial.emergency, "Romper la sujeción")
	check(confirm != null, "Emergency confirmation provides a connected action button")
	if confirm != null:
		confirm.pressed.emit()
	check(trial.state.outcome == State.Outcome.INJURED and not trial.restrained and not trial.emergency.visible and trial.player.is_physics_processing(), "Confirming emergency release permits exploration with the injured outcome")
	check(is_equal_approx(trial.player.speed_multiplier, 0.65), "Injury has the promised movement penalty")
	trial._toggle_pause()
	var stopped_at: Vector3 = trial.player.position
	Input.action_press("move_forward")
	await wait_physics(8)
	Input.action_release("move_forward")
	check(trial.player.position.is_equal_approx(stopped_at), "Pause also stops an escaped player's movement")
	trial._toggle_pause()
	var same_seed: int = trial.state.variant_id
	trial._retry(false)
	await process_frame
	await process_frame
	check(not is_instance_valid(trial), "Same-configuration retry frees the old trial and its callbacks")
	trial = current_scene
	await wait_physics(2)
	check(trial.state.variant_id == same_seed and trial.state.outcome == State.Outcome.ACTIVE and trial.state.stage == 0 and trial.state.danger == State.INITIAL_DANGER, "Retry preserves the configuration and resets pressure, outcome and progress")
	check(trial.briefing.visible and trial.restrained and not trial.started and trial.player.speed_multiplier == 1.0, "Retry clears injury and returns to an untimed briefing")
	await discard_trial()

	trial = await create_trial(21)
	trial._begin()
	trial.state.seconds_left = 0.001
	await wait_physics(4)
	check(trial.state.outcome == State.Outcome.DEAD and trial.result.visible and trial.restrained and not trial.player.enabled, "Countdown expiration triggers death and disables the player")
	var dead_gauges: Array[int] = trial.state.gauges.duplicate()
	trial.player.camera.look_at(trial.world.wheels[0].global_position)
	trial.player.ray.force_raycast_update()
	trial._unhandled_input(action_event("interact"))
	trial._unhandled_input(action_event("pressure_reverse"))
	check(trial.state.gauges == dead_gauges and trial.state.outcome == State.Outcome.DEAD and trial.state.stage == 0, "Controls cannot manipulate the mechanism or undo death after timeout")
	await discard_trial()
	# Give the audio mixer time to retire the final sting playback after its
	# scene is freed; quitting within the same render frame can retain streams.
	await wait_physics(8)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Pressure trial scene integration: %d failures" % failures)
	quit(1 if failures else 0)
