extends Reference

var main

func _init(commands):
	main = commands.main

# TODO handle saving
#VALUE('ticks','How many ticks (1/60 of a second) before the command will be run'),
#VALUE('command','The name of a macro to be run after the timer runs out'),
class PWTimer extends Node:
	var scr
	var macro
	var timeleft
	var z = -1
	var script_name
	var wait_signal = null
	signal PWTIMER_FINISHED
	func _init(scr, macro, timeleft, wait=false):
		self.scr = scr
		self.macro = macro
		self.timeleft = timeleft
		if wait:
			wait_signal = "PWTIMER_FINISHED"
	func _ready():
		Pauseable.new(self)
	func execute():
		if macro:
			print("timer executing")
			Commands.call_macro(macro, scr, [])
	func _process(dt):
		timeleft -= dt
		if macro:
			scr.stack.variables.set_val("_timer_value_"+self.macro, str(timeleft * 60.0))
		if timeleft <= 0:
			self.execute()
			emit_signal("PWTIMER_FINISHED")
			queue_free()

# Add script to execute
# TODO add pausing everything or just the script, along with the priority
#    @category([VALUE('ticks','How many ticks (1/60 of a second) to wait'),
#TOKEN('all','Pause EVERYTHING','default behavior pauses script execution but lets animation continue'),
#TOKEN('script','Pause only the script','this is the default behavior'),
#KEYWORD('priority','Fine tune what gets paused and what doesnt.','10000 (such a high number for priority means that most objects will not be paused')
#],type="animation")
func ws_pause(script, arguments):
	# Need to add priority
	if main.get_tree():
		var t = PWTimer.new(script, null, WSExpression.GV(arguments[0]) / 60.0, true)
		script.screen.add_child(t)
		t.script_name = "pause_timer"
		return t

func ws_timer(script, arguments):
	var seconds = WSExpression.GV(arguments[0]) / 60.0
	var macro = arguments[1]
	var pwt = PWTimer.new(script, macro, seconds)
	var removed = Commands.keywords(arguments, true)
	pwt.script_name = removed[0].get("name", "timer")
	pwt.name = pwt.script_name
	script.screen.add_child(pwt)
