extends Reference

var main

func _init(commands):
	main = commands.main

func ws_pause(script, arguments):
	# Need to add priority
	if main.get_tree():
		return main.get_tree().create_timer(int(arguments[0])/60.0 * Commands.PAUSE_MULTIPLIER)

# TODO handle saving
#VALUE('ticks','How many ticks (1/60 of a second) before the command will be run'),
#VALUE('command','The name of a macro to be run after the timer runs out'),
class PWTimer extends Node:
	var scr
	var macro
	var timeleft
	func _init(scr, macro, timeleft):
		self.scr = scr
		self.macro = macro
		self.timeleft = timeleft
	func execute():
		Commands.call_macro(macro, scr, [])
	func _process(dt):
		timeleft -= dt
		scr.stack.variables.set_val("_timer_value_"+self.macro, str(timeleft * 60.0))
		if timeleft <= 0:
			self.execute()
			queue_free()

func ws_timer(script, arguments):
	var seconds = WSExpression.GV(arguments[0]) / 60.0
	var macro = arguments[1]
	var pwt = PWTimer.new(script, macro, seconds)
	main.add_child(pwt)
