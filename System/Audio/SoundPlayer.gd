extends Node

var players = []
var playing = false
var loop = true
var playing_path

var SOUND_VOLUME = 0.01
var NUM_PLAYERS = 100

class AudioStreamProgress extends AudioStreamPlayer:
	var path:String

func _ready():
	for i in range(NUM_PLAYERS):
		var audio_player = AudioStreamProgress.new()
		add_child(audio_player)
		players.append(audio_player)

func _load_audio_stream(path):
	var stream
	if SoundFileCache.has_cached([path]):
		stream = SoundFileCache.get_cached([path])
	else:
		#if path!=null:
		#	stream = ResourceLoader.load(path)
		#	pass
		if not stream:
			if ResourceLoader.exists(path):
				stream = load(path)
				stream.loop = false
			else:
				# Uses an extension to load more audio types
				# TODO not really needed if we are converting everything
				var loader = AudioLoader.new()
				print(" -- LOADING SOUND FILE --")
				stream = loader.loadfile(path)
		SoundFileCache.set_get_cached([path], stream)
	if stream:
		# Somewhere determine whether or not to loop the sound
		var next_player:AudioStreamPlayer = get_free_player()
		next_player.stream = stream
		next_player.volume_db = linear2db(SOUND_VOLUME)
		next_player.play(0)
		next_player.name = path
		next_player.path = path
		return next_player
		
func get_free_player() -> AudioStreamPlayer:
	for check_player in players:
		if not check_player.playing:
			return check_player
	var next_player:AudioStreamPlayer = players.pop_front()
	players.append(next_player)
	return next_player
	
func play_sound(path, current_path):
	#path = Filesystem.lookup_file(path, root_path)
	path = Filesystem.lookup_file(path, current_path, ["ogg", "mp3", "wav", "oggi"])
	if not path:
		print("couldn't find path ", path)
		return
	playing = true
	playing_path = path
	var audio_stream = _load_audio_stream(path)

# TODO implement stop_sounds
func stop_sounds():
	pass


# SAVE/LOAD
var save_properties = [
	"playing", "loop", "playing_path"
]
func save_node(data):
	var save_players = []
	for player in players:
		if player.playing:
			var d = {
				"position": player.get_playback_position(),
				"path": player.path
			}
			save_players.append(d)
	data["audio_players"] = save_players

func load_node(tree, saved_data:Dictionary):
	pass

func after_load(tree, saved_data:Dictionary):
	var load_number = NUM_PLAYERS
	for player in saved_data["audio_players"]:
		if player["path"]:
			var next_player = _load_audio_stream(player["path"])
			next_player.seek(player["position"])
		load_number -= 1
		if load_number <= 0:
			return
