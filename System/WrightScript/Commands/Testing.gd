extends Reference

var main

var waiters = []

func _init(commands):
	main = commands.main

func ws_ut_assert(script, arguments):
	if not main.stack.mode == "test":
		return
	var unit_test_command = PoolStringArray(arguments).join(" ")
	print(unit_test_command)
	var testing = Testing.new()
	testing.run(unit_test_command, true)

func ws_ut_do(script, arguments):
	if not main.stack.mode == "test":
		return
	var unit_test_command = PoolStringArray(arguments).join(" ")
	print(unit_test_command)
	var testing = Testing.new()
	testing.run(unit_test_command, false)

class After extends Reference:
	var times
	var command
	var waiters
	var do_assert = false
	func _init(times, command, waiters, do_assert):
		self.times = int(times)
		self.command = command
		self.waiters = waiters
		self.do_assert = do_assert
	func tick():
		times -= 1
		if times <= 0:
			do()
	func do():
		var testing = Testing.new()
		testing.run(command, do_assert)
		waiters.erase(self)

func ws_ut_assert_after(script, arguments):
	if not main.stack.mode == "test":
		return
	_ut_command(script, arguments, true)

func ws_ut_after(script, arguments):
	if not main.stack.mode == "test":
		return
	_ut_command(script, arguments, false)

func _ut_command(script, arguments, do_assert):
	var mode = arguments.pop_front()
	var mode_parts = mode.split("=")
	mode = mode_parts[0]
	var mode_config = mode_parts[1]
	var unit_test_command = PoolStringArray(arguments).join(" ")
	var after = After.new(1, unit_test_command, waiters, do_assert)
	_add_waiter(mode, mode_config, after)

func _add_waiter(mode, mode_config, after):
	waiters.append(after)
	if mode == "lines":
		after.times = int(mode_config)
		main.connect("line_executed", after, "tick")
	elif mode == "frames":
		after.times = int(mode_config)
		main.connect("frame_drawn", after, "tick")
	elif mode == "signal":
		main.connect(mode_config, after, "do")
