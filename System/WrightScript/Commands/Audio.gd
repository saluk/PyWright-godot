extends Reference

var main
var command

func _init(commands):
	main = commands.main
	command = commands

func ws_mus(script, arguments):
	MusicPlayer.play_music(
		Filesystem.path_join("music",PoolStringArray(arguments).join(" ")), 
		script.root_path
	)
	
func ws_sfx(script, arguments):
	SoundPlayer.play_sound(
		Filesystem.path_join("sfx", PoolStringArray(arguments).join(" ")), 
		script.root_path
	)
