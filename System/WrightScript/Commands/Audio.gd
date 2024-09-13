extends Reference

var main

func _init(commands):
	main = commands.main

# We always reset the _music_loop value, which means if you want a looping track
# you always have to call it AFTER the mus command
func ws_mus(script, arguments):
	if not len(arguments):
		MusicPlayer.stop_music()
		main.stack.variables.del_val("_music_loop")
	else:
		var song = Commands.join(arguments)
		main.stack.variables.set_val("_music_loop", song)
		MusicPlayer.play_music(
			Filesystem.path_join("music",song), 
			script.root_path
		)

# TODO add arguments:
# after=, volumee=
func ws_sfx(script, arguments):
	var volume = 1.0
	var result = Commands.keywords(arguments, true)
	var kw = result[0]
	arguments = result[1]
	if "volume" in kw:
		volume = float(kw["volume"])/100.0
	SoundPlayer.play_sound(
		Filesystem.path_join("sfx", Commands.join(arguments)), 
		script.root_path,
		volume
	)
