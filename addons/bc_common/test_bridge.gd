extends RefCounted
## Shared browser test bridge (G7.6). Pulled from game-standards/common. Never edit it in a game (G10.3).
## Only in a web build opened with the whole-word ?test flag (G7.8): publishes the game state as window.<name> about 8 times a second
## and hands the game one action at a time from window.<name>_cmd. Does nothing anywhere else.
##   var bridge := TestBridge.new("lofi")
##   func _process(dt): var c := bridge.tick(dt, _test_state)    # _test_state returns a Dictionary
##                      if c != "": _on_menu(c)

var state_name: String
var enabled := false
var _t := 0.0

func _init(name: String) -> void:
	state_name = name
	enabled = has_flag("test")

## True only in a web build whose page address carries the flag as a whole word: ?test, ?test=1 or &test (G7.8).
## ?contest or ?latest do not count. Always false on Android and desktop. Use it for every other test switch too:
##   var fast := bridge.enabled and TestBridge.has_flag("fast")
static func has_flag(flag: String) -> bool:
	if not OS.has_feature("web") or not flag.is_valid_identifier(): return false
	# Godot hands a browser true back as the number 1, so ask the page for text and compare that.
	var v: Variant = JavaScriptBridge.eval("String(new URLSearchParams(window.location.search).has('%s'))" % flag, true)
	return str(v) == "true"

func tick(dt: float, build_state: Callable, every := 0.12) -> String:
	if not enabled: return ""
	_t -= dt
	if _t > 0.0: return ""
	_t = every
	var d: Dictionary = build_state.call()
	JavaScriptBridge.eval("window.%s=%s;" % [state_name, JSON.stringify(d)])
	var cmd := str(JavaScriptBridge.eval("window.%s_cmd || ''" % state_name))
	if cmd != "": JavaScriptBridge.eval("window.%s_cmd='';" % state_name)
	return cmd
