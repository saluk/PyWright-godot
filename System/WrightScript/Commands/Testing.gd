extends Reference

var main

var waiters = []

func _init(commands):
	main = commands.main

func ws_ut_assert(script, arguments):
	var unit_test_command = PoolStringArray(arguments).join(" ")
	print(unit_test_command)
	var testing = Testing.new()
	testing.run_assert(unit_test_command)
	
class After:
	var times
	var command
	var waiters
	func _init(times, command, waiters):
		self.times = int(times)
		self.command = command
		self.waiters = waiters
	func tick():
		times -= 1
		if times <= 0:
			do()
	func do():
		var testing = Testing.new()
		testing.run_assert(command)
		waiters.erase(self)

func ws_ut_after(script, arguments):
	var parts = Commands.keywords(arguments, true)
	var kw = parts[0]
	arguments = parts[1]
	var unit_test_command = PoolStringArray(arguments).join(" ")
	if "lines" in kw:
		var after = After.new(kw["lines"], unit_test_command, waiters)
		waiters.append(after)
		main.connect("line_executed", after, "tick")
	elif "frames" in kw:
		var after = After.new(kw["frames"], unit_test_command, waiters)
		waiters.append(after)
		main.connect("frame_drawn", after, "tick")
	elif "signal" in kw:
		var after = After.new(1, unit_test_command, waiters)
		waiters.append(after)
		main.connect(kw["signal"], after, "do")
