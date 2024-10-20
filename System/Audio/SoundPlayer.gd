extends Node

var players = []

var playing_path

var cur_volume = 1.0

var SOUND_VOLUME = 1.0
var NUM_PLAYERS = 30

var default_min_repeat_delay := 0.05  # How many seconds before allowed to play the same sound again
var files_playing = {}

class AudioStreamProgress extends AudioStreamPlayer:
	var path:String

class PlayingFile extends Reference:
	var key:String
	var played_at:int
	var player:AudioStreamProgress
	var repeat_delay:float
	func _init(key, played_at, player, repeat_delay):
		self.key = key
		self.played_at = played_at
		self.player = player
		self.repeat_delay = repeat_delay

func _ready():
	for i in range(NUM_PLAYERS):
		var audio_player = AudioStreamProgress.new()
		add_child(audio_player)
		audio_player.name = "audio channel %d" % i
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
		if not stream:
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
		next_player.volume_db = linear2db(SOUND_VOLUME * Configuration.user.global_volume * cur_volume)
		next_player.play(0)
		if next_player.stream is AudioStreamSample:
			next_player.stream.loop_mode = AudioStreamSample.LOOP_DISABLED
		elif next_player.stream is AudioStreamMP3:
			(next_player.stream as AudioStreamMP3).loop = false
		elif next_player.stream is AudioStreamOGGVorbis:
			next_player.stream.set_loop(false)
		next_player.name = path
		next_player.path = path
		return next_player

func alter_volume():
	for player in players:
		if player.playing:
			player.volume_db = linear2db(SOUND_VOLUME * Configuration.user.global_volume * cur_volume)

func get_free_player() -> AudioStreamPlayer:
	for check_player in players:
		if not check_player.playing:
			return check_player
	var next_player:AudioStreamPlayer = players.pop_front()
	players.append(next_player)
	return next_player

func play_sound(path, current_path, volume=1.0, min_repeat=null):
	if not min_repeat:
		min_repeat = default_min_repeat_delay
	var key = current_path+path
	if key in files_playing:
		var elapsed = (Time.get_ticks_msec()-files_playing[key].played_at)/1000.0
		if elapsed >= files_playing[key].repeat_delay:
			files_playing.erase(key)
		else:
			return
	cur_volume = volume
	#path = Filesystem.lookup_file(path, root_path)
	var found = Filesystem.lookup_file(path, current_path, ["ogg", "mp3", "wav", "oggi"])
	if not found:
		print("couldn't find path ", path, ">", current_path)
		return
	playing_path = path
	var audio_stream = _load_audio_stream(found)
	if audio_stream:
		files_playing[key] = PlayingFile.new(key, Time.get_ticks_msec(), audio_stream, min_repeat)
		audio_stream.connect("finished", self, "sound_finished", [key])

func sound_finished(key):
	if key in files_playing:
		files_playing.erase(key)

# TODO implement stop_sounds
func stop_sounds():
	pass


# SAVE/LOAD
# FIXME save files playing
var save_properties = [
	"playing_path"
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
