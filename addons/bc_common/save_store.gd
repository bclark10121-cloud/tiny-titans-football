extends RefCounted
## Shared save file for every game (G5.6, E6.4, E6.5, E6.7). Pulled from game-standards/common. Never edit it in a game (G10.3).
## The game keeps a Dictionary of defaults and passes it in:
##   var store := SaveStore.new("user://my_game.json")
##   store.limits = {"wins": [0, 100000]}   # optional: clamp number fields (nested dictionaries take a nested Dictionary)
##   store.load_into(save)    # fills only keys that are in the defaults, with a value of the same kind
##   store.write(save)        # call after every change, and from _notification on pause, focus out and close
## Save files and backup codes are untrusted (E6.7):
##   - only keys in the defaults load, each of the same kind. Numbers must be finite and are clamped to limits.
##   - text, lists and free-form dictionaries are capped. A file over max_bytes is refused.
##   - a file whose "v" is higher than the defaults' "v" came from a newer build. It is not loaded and never overwritten.
##   - the last good save is kept next to the save as <path>.bak. A save that will not read loads the backup instead.
## Numbers come back from JSON as floats. A float for an int default is turned back into an int,
## so counters never reset on reload.

const MAX_TEXT := 2000      # characters in one text field
const MAX_ITEMS := 10000    # entries in one list or free-form dictionary
const MAX_DEPTH := 8        # nesting in free-form data

var path: String
var disabled := false             # set true in headless test bots so they never touch the player's save
var max_bytes := 1000000          # a save file bigger than this is refused
var limits: Dictionary = {}       # key -> [min, max] for number fields, or a Dictionary for a nested Dictionary default
var restored_from_backup := false # true when the save would not read and the backup loaded instead
var newer_file := false           # true when the save came from a newer build. write() then refuses

func _init(save_path: String) -> void:
	path = save_path

## Fills data from the save file, or from its backup when the save will not read. Returns true when a file loaded.
func load_into(data: Dictionary) -> bool:
	restored_from_backup = false
	newer_file = false
	if disabled: return false
	var src: Variant = _read_dict(path)
	if src == null:
		src = _read_dict(backup_path())
		restored_from_backup = src != null
	if src == null: return false
	var file: Dictionary = src
	if data.has("v") and _is_number(file.get("v")) and int(file.v) > int(data.v):
		newer_file = true
		push_warning("save %s comes from a newer build (v %d). Not loaded and not overwritten" % [path, int(file.v)])
		return false
	var clean := sanitize(file, data, limits)
	for k: Variant in clean.keys():
		if str(k) != "v": data[k] = clean[k]
	return true

## Writes the save. Keeps the last good save as the backup first. Refuses while newer_file is true.
func write(data: Dictionary) -> bool:
	if disabled or newer_file: return false
	var txt := JSON.stringify(data)
	if txt.length() > max_bytes:
		push_error("save %s is %d bytes, over max_bytes. Not written" % [path, txt.length()])
		return false
	var old: Variant = _read_text_if_dict(path)
	if old != null and str(old) != txt:
		_store(backup_path(), str(old))
	if OS.has_feature("web"):
		# E6.4 browser: write the file directly, then force it into IndexedDB at once
		if not _store(path, txt): return false
		JavaScriptBridge.force_fs_sync()
		return true
	# E6.4 Android and desktop: write a temp file, then rename it over the save
	var tmp := path + ".tmp"
	if not _store(tmp, txt): return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path)) == OK

## Deletes the save, its backup and any temp file. Use it for every "delete save" button (E6.7).
func erase() -> void:
	for p: String in [path, backup_path(), path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	if OS.has_feature("web"): JavaScriptBridge.force_fs_sync()

func backup_path() -> String:
	return path + ".bak"

## True for the notifications where E6.5 says to save at once.
static func is_save_moment(what: int) -> bool:
	return what == Node.NOTIFICATION_APPLICATION_PAUSED or what == Node.NOTIFICATION_APPLICATION_FOCUS_OUT or what == Node.NOTIFICATION_WM_CLOSE_REQUEST

## Returns a copy of defaults with every value from src that has a known key and the same kind (E6.7).
## Numbers must be finite and are clamped to limits. Text is capped. Lists and dictionaries with an empty
## default are free-form: kept, but capped in size and depth. Dictionaries with keys in the default are read
## with the same rules, key by key.
static func sanitize(src: Dictionary, defaults: Dictionary, lims: Dictionary = {}) -> Dictionary:
	var out := defaults.duplicate(true)
	for k: Variant in defaults.keys():
		if not src.has(k): continue
		var d: Variant = defaults[k]
		var v: Variant = src[k]
		var lim: Variant = lims.get(k)
		match typeof(d):
			TYPE_BOOL:
				if v is bool: out[k] = v
			TYPE_INT:
				if _is_number(v): out[k] = int(_clamp(float(v), lim))
			TYPE_FLOAT:
				if _is_number(v): out[k] = _clamp(float(v), lim)
			TYPE_STRING:
				if v is String: out[k] = (v as String).left(MAX_TEXT)
			TYPE_DICTIONARY:
				if v is Dictionary:
					var dd: Dictionary = d
					if dd.is_empty(): out[k] = _clean_free(v, 0)
					else: out[k] = sanitize(v, dd, lim if lim is Dictionary else {})
			TYPE_ARRAY:
				if v is Array: out[k] = _clean_free(v, 0)
			_:
				if typeof(v) == typeof(d): out[k] = v
	return out

## Reads a backup code such as "HH3:<base64 JSON>". Returns {} when the code is wrong in any way.
## Check the result with sanitize and the game's own ids before using it (E6.7).
static func read_code(code: String, prefix: String, max_len: int = 200000) -> Dictionary:
	var c := code.strip_edges()
	if not c.begins_with(prefix) or c.length() > max_len: return {}
	var raw := c.substr(prefix.length()).replace("\n", "").replace("\r", "").replace(" ", "")
	if raw.is_empty(): return {}
	var re := RegEx.new()
	re.compile("^[A-Za-z0-9+/]+={0,2}$")
	if re.search(raw) == null or raw.length() % 4 != 0: return {}
	var d: Variant = _parse(Marshalls.base64_to_utf8(raw))
	return d if d is Dictionary else {}

## Makes a backup code from data: prefix plus base64 JSON.
static func make_code(data: Dictionary, prefix: String) -> String:
	return prefix + Marshalls.utf8_to_base64(JSON.stringify(data))

static func _is_number(v: Variant) -> bool:
	if v is int: return true
	if v is float: return is_finite(v)
	return false

static func _clamp(x: float, lim: Variant) -> float:
	if lim is Array and (lim as Array).size() == 2 and _is_number(lim[0]) and _is_number(lim[1]):
		return clampf(x, float(lim[0]), float(lim[1]))
	return clampf(x, -1.0e15, 1.0e15)

## Keeps free-form data, capped: finite numbers, short text, at most MAX_ITEMS entries, at most MAX_DEPTH deep.
static func _clean_free(v: Variant, depth: int) -> Variant:
	if depth > MAX_DEPTH: return null
	if v is float: return v if is_finite(v) else 0.0
	if v is String: return (v as String).left(MAX_TEXT)
	if v is Array:
		var a: Array = []
		for item: Variant in (v as Array).slice(0, MAX_ITEMS): a.append(_clean_free(item, depth + 1))
		return a
	if v is Dictionary:
		var o: Dictionary = {}
		for key: Variant in (v as Dictionary).keys().slice(0, MAX_ITEMS):
			o[str(key).left(MAX_TEXT)] = _clean_free(v[key], depth + 1)
		return o
	if v is bool or v is int or v == null: return v
	return null

## The file as a Dictionary, or null when it is missing, too big or not a JSON object.
func _read_dict(p: String) -> Variant:
	var t: Variant = _read_text_if_dict(p)
	return null if t == null else _parse(str(t))

## The file's text when it is a JSON object within max_bytes, else null.
func _read_text_if_dict(p: String) -> Variant:
	if not FileAccess.file_exists(p): return null
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null or f.get_length() > max_bytes: return null
	var t := f.get_as_text()
	f.close()
	return t if _parse(t) is Dictionary else null

static func _store(p: String, txt: String) -> bool:
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f == null: return false
	f.store_string(txt)
	f.close()
	return true

## Parses JSON without printing an engine error on bad input, so a broken save or code never shows as a console error.
static func _parse(t: String) -> Variant:
	var j := JSON.new()
	return j.data if j.parse(t) == OK else null
