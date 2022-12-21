extends Reference

var main

func _init(commands):
	main = commands.main

func ws_mus(script, arguments):
	if not len(arguments):
		MusicPlayer.stop_music()
	else:
		MusicPlayer.play_music(
			Filesystem.path_join("music",Commands.join(arguments)), 
			script.root_path
		)

# TODO add arguments:
# after=, volumee=
func ws_sfx(script, arguments):
	SoundPlayer.play_sound(
		Filesystem.path_join("sfx", Commands.join(arguments)), 
		script.root_path
	)
