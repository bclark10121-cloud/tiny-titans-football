extends RefCounted
## Shared save file for every game (G5.6, E6.4, E6.5). Pulled from game-standards/common. Never edit it in a game (G10.3).
## The game keeps a Dictionary of defaults and passes it in:
##   var store := SaveStore.new("user://my_game.json")
##   store.load_into(save)    # fills only keys that are in the defaults, with a value of the same kind
##   store.write(save)        # call after every change, and from _notification on pause, focus out and close
## Numbers come back from JSON as floats. A float for an int default is turned back into an int,
## so counters never reset on reload.

var path: String
var disabled := false   # set true in headless test bots so they never touch the player's save

func _init(save_path: String) -> void:
	path = save_path

func load_into(data: Dictionary) -> bool:
	if disabled or not FileAccess.file_exists(path): return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not d is Dictionary: return false
	var src: Dictionary = d
	for k: Variant in data.keys():
		if not src.has(k): continue
		var v: Variant = src[k]
		var t := typeof(data[k])
		if typeof(v) == t: data[k] = v
		elif t == TYPE_INT and typeof(v) == TYPE_FLOAT: data[k] = int(v)
		elif t == TYPE_FLOAT and typeof(v) == TYPE_INT: data[k] = float(v)
	return true

func write(data: Dictionary) -> bool:
	if disabled: return false
	var txt := JSON.stringify(data)
	if OS.has_feature("web"):
		# E6.4 browser: write the file directly, then force it into IndexedDB at once
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null: return false
		f.store_string(txt); f.close()
		JavaScriptBridge.force_fs_sync()
		return true
	# E6.4 Android and desktop: write a temp file, then rename it over the save
	var tmp := path + ".tmp"
	var g := FileAccess.open(tmp, FileAccess.WRITE)
	if g == null: return false
	g.store_string(txt); g.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path)) == OK

## True for the notifications where E6.5 says to save at once.
static func is_save_moment(what: int) -> bool:
	return what == Node.NOTIFICATION_APPLICATION_PAUSED or what == Node.NOTIFICATION_APPLICATION_FOCUS_OUT or what == Node.NOTIFICATION_WM_CLOSE_REQUEST
