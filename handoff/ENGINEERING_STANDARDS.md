# Godot 3D engineering standards (browser and Android)

Version 2026-11-14. These rules apply to every Godot 3D game Brian makes for the browser (HTML5, WebGL 2.0) and Android (phones, tablets and handhelds such as the Retroid). Brian supplied them on 2026-11-14.

This file is the same in every game repo, at `handoff/ENGINEERING_STANDARDS.md`. Never edit it for one game. The master copy lives in the private repo `game-standards`. It changes there first.

Every script, scene, shader and design choice follows these rules. Rule ids start with E: `E4.1` is section 4, rule 1. Always write the prefix. When a rule does not fit a game, the game's `STANDARDS_OVERRIDES.md` says so. An override names the rule id, what the game does instead and why. Brian approves each override. A rule with no override applies in full. Never skip a rule silently. How standards and overrides work is set out in `GAME_STANDARDS.md` section G0.

Godot version: 4.6.

## E1. GDScript and code rules

- E1.1 Godot 4 syntax only. Never use Godot 3 names (`KinematicBody`, `Spatial`, `yield`, `export`, `onready`, string-based `.connect()`). Use `CharacterBody3D`, `Node3D`, `await`, `@export`, `@onready` and callable signals (`signal_name.connect(_on_callable)`).
- E1.2 Static typing everywhere. Type every variable, array (`Array[Node3D]`), dictionary, parameter and return value (`-> void:`).
- E1.3 No idle polling. Do not write `_process` or `_physics_process` functions that poll while nothing happens. Sleeping things call `set_process(false)` and `set_physics_process(false)` in `_ready()` and wake on a signal (`Area3D.body_entered`, a timer or `VisibleOnScreenEnabler3D`).
- E1.4 Cache node references. Never call `get_node()`, `$Path` or `find_child()` inside `_process`, `_physics_process` or a busy loop. Cache them in `@onready` variables or pass them in with `@export`.
- E1.5 Squared distances. In checks that run during play, use `distance_squared_to()` instead of `distance_to()`.

## E2. Rendering and shaders

- E2.1 Renderer: `gl_compatibility` (WebGL 2.0 and OpenGL ES 3.0) on both targets. Do not rely on Forward+ features (volumetric fog, SDFGI, SSR, SSAO, SSIL or `GPUParticles3D` compute shaders).
- E2.2 Particles: `CPUParticles3D` or animated mesh flipbooks. Never `GPUParticles3D`.
- E2.3 No new materials during play. Never call `material.duplicate()` or create a `StandardMaterial3D` or `ShaderMaterial` while the game runs. Build them at load time. For per-object changes (flashes, tints, dissolve, wind sway) use an `instance uniform` and `set_instance_shader_parameter()`.
- E2.4 No see-through overdraw. Use opaque geometry where possible, or alpha scissor for foliage and cutouts. Avoid stacked alpha-blended quads.
- E2.5 Lights and shadows:
  - One `DirectionalLight3D` casts real-time shadows (orthogonal or PSSM 2 splits, 2048 atlas at most).
  - `shadow_enabled = false` on every `OmniLight3D` and `SpotLight3D`.
  - At most 8 local lights per mesh. Prefer `LightmapGI` or vertex colours for static mood.

## E3. Assets, geometry and draw calls

- E3.1 Triangle budgets:
  - Hero or player character: 3,000 to 5,000 triangles. Fewer than 40 bones.
  - Props and NPCs: 150 to 1,500 triangles each.
  - Whole visible scene: under 150,000 triangles and under 300 draw calls per frame.
- E3.2 Batching. The renderer does not batch separate `MeshInstance3D` nodes. Any repeated static prop (trees, grass, rocks, fences, coins) uses `MultiMeshInstance3D` or is merged by material.
- E3.3 Textures and materials:
  - 1 or 2 materials per mesh.
  - Pack ambient occlusion (R), roughness (G) and metallic (B) into one ORM texture.
  - 2048 x 2048 at most for atlases and terrain. 512 to 1024 for props. VRAM compression (ETC2 and ASTC) and mipmaps on.
- E3.4 Culling and level of detail:
  - Set `visibility_range_end` (hard cutoff, fade mode disabled) on every prop. Cull small details at 25 to 45 m.
  - Raise the viewport `mesh_lod_threshold` to 2.5 to 3.5 on browser and Android.
  - Every animated character has a `VisibleOnScreenEnabler3D` so its animation stops off screen. This applies when the game has characters.

## E4. Physics, navigation and memory

- E4.1 Physics engine: the default is GodotPhysics3D. Avoid Jolt on browser builds. Choose per game: when another engine suits a game better, or the game uses no physics engine, record it as an E4.1 override with the reason.
- E4.2 Physics runs at 60 Hz with physics interpolation on (`physics/common/physics_interpolation = true`), so motion is smooth on 90 and 120 Hz screens. Nodes moved every drawn frame (cameras, spinning pickups) turn interpolation off for themselves and read the smoothed transform of what they follow.
- E4.3 Primitive colliders only: box, capsule, sphere and cylinder shapes. Never use `ConcavePolygonShape3D` (trimesh) on moving bodies or complex props.
- E4.4 Navigation (when the game has it): never call `NavigationAgent3D.set_target_position()` every frame. Stagger path updates with a random 0.25 to 0.5 second timer per agent.
- E4.5 Object pooling: do not call `.instantiate()` or `.queue_free()` in active play loops for things that recur (effects, pickups, floating text). Make a pool up front and toggle `visible`, `process_mode` and collision.
- E4.6 Memory and loading:
  - Do not `preload()` large scenes, textures or audio in global scripts. Use `ResourceLoader.load_threaded_request()` for scene changes.
  - Runtime VRAM under 250 MB in the browser and under 400 MB on Android. No orphan nodes after a scene unloads.
  - Keyframe compression on for every imported `.glb` animation.

## E5. Display, safe areas and input

- E5.1 Stretch mode `canvas_items` and aspect `expand`, so the UI stays crisp.
- E5.2 Scale 3D rendering (`Viewport.scaling_3d_scale`) to 0.80 to 0.85 on browser and Android. Cap the frame rate at 60 on mobile.
- E5.3 Safe areas. Every HUD root takes its margins from `DisplayServer.get_display_safe_area()` to stay clear of camera notches, rounded corners and gesture bars. Full screen panels still cover the whole screen.
- E5.4 Three kinds of input in every game: touch, gamepad and keyboard.
  - Read movement through input actions (`Input.get_vector` or `Input.get_axis`), never raw keys.
  - Hide the on-screen touch controls when a key or gamepad input arrives. Show them again on a screen touch.
  - Every button and touch target is at least 48 x 48 logical pixels.
- E5.5 Proposed. Slow devices: cap the frame step and take up to three smaller steps per frame, so the game stays in real time when the frame rate drops.

## E6. Audio, saves and export

- E6.1 Browser export: thread support off and audio playback type Sample.
- E6.2 Start audio only after the first input from the player.
- E6.3 Music and ambient loops are `.ogg` at 96 to 128 kbps. Short sound effects are mono `.wav` at 22.05 to 32 kHz.
- E6.4 Saves go to `user://` as JSON or `ConfigFile`. Never use `.tres` or `ResourceSaver` for save data.
  - Android: write to a temp file first, then rename it over the real save.
  - Browser: write the save file directly, then call `JavaScriptBridge.force_fs_sync()`. A renamed file does not reach IndexedDB reliably.
- E6.5 Save at once on `NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_WM_CLOSE_REQUEST`. In the browser, follow E6.4 so the save reaches IndexedDB without waiting.
- E6.6 Set `quit_on_go_back = false` and handle `NOTIFICATION_WM_GO_BACK_REQUEST`: the Android back button opens or closes the in-game menu.

## Release checklist

Tick these before every release.

- [ ] No Godot 3 syntax. Every declaration typed.
- [ ] No `GPUParticles3D`. No material made during play.
- [ ] Repeated props are in a `MultiMeshInstance3D`.
- [ ] One shadow-casting light.
- [ ] HUD checked with a pretend notch. Touch targets at least 48 px.
- [ ] Touch controls hide on keyboard or gamepad input.
- [ ] Save survives a page reload in the browser.
- [ ] Back button opens the menu on Android.
- [ ] Browser export: threads off.
- [ ] `STANDARDS_OVERRIDES.md` is up to date: every override still needed, every open item still true.

## Change log

- 2026-11-14: First shared version. Text from the copy Brian supplied, with these changes only:
  - Renamed from `STANDARDS.md` to `ENGINEERING_STANDARDS.md`. Every rule id now carries the E prefix.
  - Godot version set to 4.6 to match the game standards (was 4.3 or newer).
  - E4.1: the physics engine is chosen per game. GodotPhysics3D stays the default.
  - E6.4: split into Android (temp file and rename) and browser (direct write and sync). Before, E6.4 and E6.5 disagreed for the browser.
  - E6.5: points at E6.4 for the browser.
  - E5.5 added as Proposed: frame step cap for slow devices (moved from the game standards, where it was G6.9).
