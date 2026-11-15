extends RefCounted
## Shared browser test bridge (G7.6). Pulled from game-standards/common. Never edit it in a game (G10.3).
## Only in a web build opened with ?test: publishes the game state as window.<name> about 8 times a second
## and hands the game one action at a time from window.<name>_cmd. Does nothing anywhere else.
##   var bridge := TestBridge.new("lofi")
##   func _process(dt): var c := bridge.tick(dt, _test_state)    # _test_state returns a Dictionary
##                      if c != "": _on_menu(c)

var state_name: String
var enabled := false
var _t := 0.0

func _init(name: String) -> void:
	state_name = name
	if OS.has_feature("web"):
		enabled = str(JavaScriptBridge.eval("window.location.search")).contains("test")

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
