extends Node

var audio_player:AudioStreamPlayer
var playing = false
var loop = true
var playing_path

var MUSIC_VOLUME = 0.1

func _ready():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
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
	if audio_data:
		stream = AudioStreamOGGVorbis.new()
		stream.data = audio_data
	if not stream and path!=null:
		stream = ResourceLoader.load(path)
	if stream:
		audio_player.stream = stream
		audio_player.connect("finished", self, "_player_finished")
		audio_player.play(0)
		audio_player.volume_db = MUSIC_VOLUME

func stop_music():
	playing = false
	audio_player.stop()
	
func play_music(path, root_path):
	path = Filesystem.lookup_file(path, root_path)
	if not path:
		print("couldn't find path ", path)
		stop_music()
	if playing and playing_path == path:
		print("already playing this song")
		return
	playing = true
	playing_path = path
	var audio_stream = _load_audio_stream(path)

func _player_finished():
	if loop and playing:
		audio_player.play(0)
