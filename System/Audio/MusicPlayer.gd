extends Node

var audio_player:AudioStreamPlayer
var playing = false
var loop = true
var playing_path

var MUSIC_VOLUME = 0.01

func _ready():
	audio_player = AudioStreamPlayer.new()
	audio_player.connect("finished", self, "_player_finished")
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
	var stream
	if SoundFileCache.has_cached([path]):
		stream = SoundFileCache.get_cached([path])
	else:
		var audio_data = _load_music_data(path)
		if audio_data:
			stream = AudioStreamOGGVorbis.new()
			stream.data = audio_data
		if not stream and path!=null:
			stream = ResourceLoader.load(path)
		SoundFileCache.set_get_cached([path], stream)
	if stream:
		audio_player.stream = stream
		audio_player.volume_db = linear2db(MUSIC_VOLUME)
		audio_player.play(0)

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

# SAVE/LOAD
var save_properties = [
	"playing", "loop", "playing_path"
]
func save_node(data):
	if playing:
		data["song_position"] = audio_player.get_playback_position()

func load_node(tree, saved_data:Dictionary):
	pass

func after_load(tree, saved_data:Dictionary):
	_load_audio_stream(playing_path)
	if "song_position" in saved_data:
		audio_player.seek(saved_data["song_position"])
