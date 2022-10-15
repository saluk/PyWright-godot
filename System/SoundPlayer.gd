extends Node

var players = []
var playing = false
var loop = true
var playing_path

func _ready():
	for i in range(5):
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		players.append(audio_player)
	
func _load_music_data(path):
	if not path:
		return null
	var file = File.new()
	var buffer
	if file.open(path, File.READ) == OK:
		buffer = file.get_buffer(file.get_len())
	file.close()
	if buffer:
		return buffer

func _load_audio_stream(path):
	var audio_data = _load_music_data(path)
	var stream
	#if audio_data:
	#	if path.ends_with(".ogg"):
	#		stream = AudioStreamOGGVorbis.new()
	#	elif path.ends_with(".wav"):
	#		stream = AudioStreamSample.new()
	#	stream.data = audio_data
	if not stream and path!=null:
		stream = ResourceLoader.load(path)
	if stream:
		if "loop" in stream:
			stream.loop = false
		var next_player = players.pop_front()
		next_player.stream = stream
		next_player.play(0)
		next_player.name = path
		players.append(next_player)
	
func play_sound(path, root_path):
	path = Filesystem.lookup_file(path, root_path)
	if not path:
		print("couldn't find path ", path)
		return
	playing = true
	playing_path = path
	var audio_stream = _load_audio_stream(path)
