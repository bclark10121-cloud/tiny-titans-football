extends SceneTree
## Shared save store check (E6.7, G10). Pulled into a game at tests/common/save_store_check.gd. Never edit it in a game.
##   godot --headless --path . -s res://tests/common/save_store_check.gd
## Prints one line per check and ends with "SAVESTORE check ok" or "SAVESTORE check FAIL". Uses its own files in user://
## and deletes them after, so it never touches the player's save.

const SaveStore := preload("res://addons/bc_common/save_store.gd")
const P := "user://_save_store_check.json"
var fails := 0

func _init() -> void:
	var store := SaveStore.new(P)
	store.erase()
	var defaults := {"v": 2, "wins": 0, "speed": 1.0, "name": "", "sound": true, "found": [], "flags": {},
		"opts": {"vol": 0.5, "big": false}}
	store.limits = {"wins": [0, 1000], "opts": {"vol": [0.0, 1.0]}}

	# a good round trip keeps every kind
	var a := defaults.duplicate(true)
	a.wins = 7; a.speed = 2.5; a.name = "Brian"; a.sound = false; a.found = ["shell", "bee"]; a.flags = {"rod": true}; a.opts = {"vol": 0.25, "big": true}
	_check(store.write(a), "a save writes")
	var b := defaults.duplicate(true)
	_check(store.load_into(b) and b.wins == 7 and typeof(b.wins) == TYPE_INT and b.speed == 2.5 and b.name == "Brian" and not b.sound
		and b.found == ["shell", "bee"] and b.flags.get("rod") == true and b.opts.vol == 0.25 and b.opts.big, "a round trip keeps every field and kind")

	# wrong kinds, unknown keys, out of range, NaN and long text
	_raw('{"v": 2, "wins": 99999, "speed": "fast", "name": "%s", "sound": "yes", "hack": 1, "found": "x", "opts": {"vol": 7, "big": 1, "extra": 2}}' % "x".repeat(5000))
	var c := defaults.duplicate(true)
	store.load_into(c)
	_check(c.wins == 1000, "a number is clamped to its limit (%s)" % c.wins)
	_check(c.speed == 1.0 and c.sound == true and c.found == [], "a value of the wrong kind keeps its default")
	_check(not c.has("hack") and not (c.opts as Dictionary).has("extra"), "unknown keys are dropped, also in nested data")
	_check(c.opts.vol == 1.0 and c.opts.big == false, "nested numbers are clamped and nested kinds checked")
	_check((c.name as String).length() == SaveStore.MAX_TEXT, "long text is capped")
	var nan := SaveStore.sanitize({"wins": NAN, "speed": INF}, defaults)
	_check(nan.wins == 0 and nan.speed == 1.0, "NaN and infinity keep the default")

	# a broken save loads the backup
	_check(store.write(a), "a good save writes again")
	a.wins = 8
	_check(store.write(a), "a newer save writes and keeps the last one as the backup")
	_raw('{"v": 2, "wins": 9')   # cut off half way
	var d := defaults.duplicate(true)
	_check(store.load_into(d) and store.restored_from_backup and d.wins == 7, "a cut-off save loads the backup (%s)" % d.wins)
	_check(store.write(d), "the next write repairs the save")
	_raw('{"v": 2, "wins": 9')
	_check(store.write(d) and SaveStore.new(P).load_into(defaults.duplicate(true)), "a cut-off save is never copied over the backup")

	# a file that is too big is refused
	store.max_bytes = 200
	_raw('{"v": 2, "name": "%s"}' % "y".repeat(500))
	var e := defaults.duplicate(true)
	store.load_into(e)
	_check(e.name != "y".repeat(500).left(SaveStore.MAX_TEXT), "a file over max_bytes is not loaded")
	store.max_bytes = 1000000

	# a save from a newer build is never loaded or overwritten
	_raw('{"v": 3, "wins": 5}')
	var f := defaults.duplicate(true)
	_check(not store.load_into(f) and store.newer_file and f.wins == 0, "a save from a newer build is not loaded")
	_check(not store.write(f) and FileAccess.get_file_as_string(P).contains('"v": 3'), "a save from a newer build is not overwritten")

	# backup codes
	var code := SaveStore.make_code({"found": ["shell"], "flags": {"rod": true}}, "XX1:")
	var r := SaveStore.read_code("  " + code + "\n", "XX1:")
	_check(r.get("found") == ["shell"], "a backup code round trip works")
	for bad: String in ["", "XX1:", "YY1:" + code.substr(4), "XX1:!!!!", "XX1:abc", "XX1:" + Marshalls.utf8_to_base64("[1,2]"), "XX1:" + Marshalls.utf8_to_base64("not json")]:
		_check(SaveStore.read_code(bad, "XX1:").is_empty(), "a bad backup code gives nothing (%s)" % bad.left(12))
	_check(SaveStore.read_code(code + "A".repeat(300000), "XX1:").is_empty(), "a huge backup code gives nothing")

	# erase removes the save and its backup
	store.newer_file = false
	store.write(a); store.write(d)
	store.erase()
	_check(not FileAccess.file_exists(P) and not FileAccess.file_exists(store.backup_path()), "erase removes the save and its backup")
	_check(not SaveStore.new(P).load_into(defaults.duplicate(true)), "an erased save does not come back from the backup")

	# disabled stores never touch a file
	var off := SaveStore.new(P)
	off.disabled = true
	_check(not off.write(a) and not FileAccess.file_exists(P), "a disabled store writes nothing")

	store.erase()
	print("SAVESTORE check %s (%d failed)" % ["ok" if fails == 0 else "FAIL", fails])
	quit(1 if fails else 0)

func _raw(txt: String) -> void:
	var f := FileAccess.open(P, FileAccess.WRITE)
	f.store_string(txt)
	f.close()

func _check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok: fails += 1
