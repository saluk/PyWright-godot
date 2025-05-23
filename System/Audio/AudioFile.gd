extends Object
class_name AudioFile

# Supports wav, ogg, and mp3
# TODO resampling?

static func load_data(path:String) -> PackedByteArray:
	var file = FileAccess.open(path, FileAccess.READ)
	var buffer = file.get_buffer(file.get_length())
	file.close()
	if buffer:
		return buffer
	return PackedByteArray([])

static func load_stream(path:String) -> AudioStream:
	var stream:AudioStream

	if path!=null and ResourceLoader.exists(path):
		stream = ResourceLoader.load(path)
		if stream:
			return stream

	#var audio_data = load_data(path)
	for cls in [AudioStreamOggVorbis, AudioStreamMP3, AudioStreamWAV]:
		stream = cls.load_from_file(path)
		if stream:
			return stream
	return null

static func load(path:String) -> AudioStream:
	if not path:
		return null
	if SoundFileCache.has_cached([path]):
		return SoundFileCache.get_cached([path])
	else:
		var stream = load_stream(path)
		SoundFileCache.set_get_cached([path], stream)
		return stream
