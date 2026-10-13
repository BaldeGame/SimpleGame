extends SceneTree

const State = preload("res://scripts/delivery_state.gd")
var failures := 0

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	var state = State.new()
	state.deliver("101")
	check(state.delivered.is_empty(), "Empty hands must not complete a delivery")
	state.take_order(-1)
	state.take_order(99)
	check(state.carried == -1, "Invalid package rejected")
	state.take_order(0)
	state.take_order(1)
	check(state.carried == 0, "Cannot carry two packages")
	state.deliver("103")
	check(state.carried == 0 and state.delivered.is_empty(), "Wrong door must preserve package")
	state.return_order()
	check(state.carried == -1, "Return restores empty hands")
	for index in [2, 0, 1]:
		state.take_order(index)
		state.deliver(str(State.ORDERS[index]["door"]))
		state.take_order(index)
		check(state.carried == -1, "Delivered package cannot be collected again")
	check(state.is_complete() and state.delivered.size() == 3, "Any order completes exactly once")
	print("Delivery rules: %d failures" % failures)
	quit(1 if failures else 0)
