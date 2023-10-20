extends Node

var builtin:BuiltinConfig
var user:UserConfig

func init_config():
	builtin = preload("res://System/Config/BuiltinConfig.tres")
	if File.new().file_exists("user://config.tres"):
		user = load("user://config.tres")
	if not user:
		user = UserConfig.new()
	save_config()

func save_config():
	ResourceSaver.save("user://config.tres", user)
	
func _ready():
	init_config()
