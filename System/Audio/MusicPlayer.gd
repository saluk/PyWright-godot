extends Node

var audio_player:AudioStreamPlayer
var playing = false
var playing_path
var root_path = ""

var music_volume:float

func add_player():
	if is_instance_valid(audio_player):
		audio_player.queue_free()
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
		add_player()
		audio_player.stream = stream
		music_volume = get_volume()
		audio_player.volume_db = linear2db(music_volume * Configuration.user.global_volume)
		audio_player.play(0)

func get_volume():
	var main = get_tree().get_nodes_in_group("Main")[0]
	music_volume = float(main.stack.variables.get_int("_music_fade",100))
	music_volume = float(music_volume/100.0)
	return music_volume

func alter_volume():
	get_volume()
	if playing and is_instance_valid(audio_player):
		var pos = audio_player.get_playback_position()
		playing = false
		audio_player.stop()
		audio_player.volume_db = linear2db(music_volume * Configuration.user.global_volume)
		audio_player.play(pos)
		playing = true

func stop_music():
	playing = false
	if is_instance_valid(audio_player):
		audio_player.queue_free()

func play_music(path, root_path, force=false):
	self.root_path = root_path
	var found_path = Filesystem.lookup_file(path, root_path, ["ogg"])
	if not found_path:
		GlobalErrors.log_error("Couldn't find music file %s" % path)
		stop_music()
	if playing and playing_path == found_path and not force:
		print("already playing this song")
		return
	playing = true
	playing_path = found_path
	_load_audio_stream(found_path)

func _player_finished():
	var main = get_tree().get_nodes_in_group("Main")[0]
	if playing:
		var music_loop_track = main.stack.variables.get_string("_music_loop","")
		if music_loop_track:
			music_loop_track = Filesystem.path_join("music", music_loop_track)
			play_music(music_loop_track, root_path, true)
			return
		if not is_instance_valid(audio_player):
			_load_audio_stream(playing_path)
		else:
			audio_player.play(0)

# SAVE/LOAD
var save_properties = [
	"playing", "root_path", "playing_path", "music_volume"
]
func save_node(data):
	if playing and is_instance_valid(audio_player):
		data["song_position"] = audio_player.get_playback_position()

func load_node(tree, saved_data:Dictionary):
	pass

func after_load(tree, saved_data:Dictionary):
	_load_audio_stream(playing_path)
	if "song_position" in saved_data:
		audio_player.seek(saved_data["song_position"])
