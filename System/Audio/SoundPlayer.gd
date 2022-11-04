extends Node

var players = []
var playing = false
var loop = true
var playing_path

func _ready():
	for i in range(1):
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		players.append(audio_player)

func _load_audio_stream(path):
	var stream
	var loader = AudioLoader.new()
	#if path!=null:
	#	stream = ResourceLoader.load(path)
	#	pass
	if not stream:
		stream = loader.loadfile(path)
		pass
	if stream:
		# Somewhere determine whether or not to loop the sound
		var next_player = players.pop_front()
		next_player.stream = stream
		next_player.play(0)
		next_player.name = path
		players.append(next_player)
	
func play_sound(path, current_path):
	#path = Filesystem.lookup_file(path, root_path)
	path = Filesystem.lookup_file(path, current_path, ["oggi", "ogg", "mp3", "wav"])
	if not path:
		print("couldn't find path ", path)
		return
	playing = true
	playing_path = path
	var audio_stream = _load_audio_stream(path)
