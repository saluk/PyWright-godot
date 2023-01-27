extends Node2D

class DrawCommand:
	var node:Node2D
	var method
	var args
	func _init(node, method, args):
		self.node = node
		self.method = method
		self.args = args
	func draw():
		node.callv(method, args)
		
var commands := []

func clear():
	commands.clear()
	update()
	
func draw(command, args):
	commands.append(DrawCommand.new(self, command, args))
	update()
	
func _draw():
	for draw_command in commands:
		draw_command.draw()
