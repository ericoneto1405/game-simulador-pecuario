extends Camera2D

@export var movement_speed := 900.0
@export var gesture_speed := 28.0
@export var zoom_step := 0.06
@export_range(0.0, 1.0, 0.05) var magnify_sensitivity := 0.5
@export var minimum_zoom := 0.18
@export var maximum_zoom := 2.0
@export var farm_size := Vector2(3200.0, 1800.0)

@onready var map_frame: Control = $"../Interface/MainLayout/Body/Content/MapFrame"
@onready var module_workspace: Control = $"../Interface/MainLayout/Body/Content/ModuleWorkspace"
@onready var map_palette: Control = $"../Interface/MainLayout/Body/Content/MapPalette"
@onready var map_palette_open_button: Control = $"../Interface/MainLayout/Body/Content/MapPaletteOpenButton"
@onready var map_interaction_bar: Control = $"../Interface/MainLayout/Body/Content/MapInteractionBar"
@onready var module_actions: Control = %ModuleActions

var last_map_rect := Rect2()
var fit_queued := false


func _ready() -> void:
	get_viewport().size_changed.connect(_queue_farm_fit)
	_queue_farm_fit()


func _process(delta: float) -> void:
	var current_map_rect := map_frame.get_global_rect()
	if current_map_rect != last_map_rect and not fit_queued:
		_queue_farm_fit()

	var direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0

	if direction != Vector2.ZERO:
		position += direction.normalized() * movement_speed * delta / zoom.x
		_clamp_position_to_map()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		if _is_screen_point_over_map(event.position):
			var softened_factor := lerpf(1.0, event.factor, magnify_sensitivity)
			_apply_zoom(softened_factor, event.position)
		return

	if event is InputEventPanGesture:
		if _is_screen_point_over_map(event.position):
			position += event.delta * gesture_speed / zoom.x
			_clamp_position_to_map()
		return

	if event is InputEventMouseButton and event.pressed:
		if not _is_screen_point_over_map(event.position):
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(1.0 + zoom_step, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(1.0 / (1.0 + zoom_step), event.position)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				_apply_zoom(1.0 + zoom_step, _map_center_on_screen())
			KEY_MINUS, KEY_KP_SUBTRACT:
				_apply_zoom(1.0 / (1.0 + zoom_step), _map_center_on_screen())
			KEY_0, KEY_KP_0:
				_queue_farm_fit()


func _queue_farm_fit() -> void:
	if fit_queued:
		return
	fit_queued = true
	call_deferred("_apply_queued_farm_fit")


func _apply_queued_farm_fit() -> void:
	fit_queued = false
	_fit_farm_to_available_area()


func _apply_zoom(factor: float, anchor_screen_position := Vector2.INF) -> void:
	if factor <= 0.0:
		return

	var anchor := anchor_screen_position
	if not is_finite(anchor.x) or not is_finite(anchor.y):
		anchor = _map_center_on_screen()
	var viewport_center := get_viewport().get_visible_rect().size / 2.0
	var world_under_anchor := position + (anchor - viewport_center) / zoom.x
	var new_zoom := clampf(
		zoom.x * factor,
		_required_cover_zoom(),
		maximum_zoom
	)
	if is_equal_approx(new_zoom, zoom.x):
		_clamp_position_to_map()
		return

	zoom = Vector2.ONE * new_zoom
	position = world_under_anchor - (anchor - viewport_center) / new_zoom
	_clamp_position_to_map()


func _fit_farm_to_available_area() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var map_rect := map_frame.get_global_rect()
	var fitted_zoom := _required_cover_zoom()
	var viewport_center := viewport_size / 2.0
	var map_center := map_rect.position + map_rect.size / 2.0
	var screen_displacement := map_center - viewport_center

	position = farm_size / 2.0 - screen_displacement / fitted_zoom
	offset = Vector2.ZERO
	zoom = Vector2.ONE * fitted_zoom
	last_map_rect = map_rect
	_clamp_position_to_map()
	reset_smoothing()


func _required_cover_zoom() -> float:
	var map_size := map_frame.get_global_rect().size
	var cover_zoom := maxf(
		maxf(map_size.x, 1.0) / farm_size.x,
		maxf(map_size.y, 1.0) / farm_size.y
	)
	return clampf(maxf(cover_zoom, minimum_zoom), minimum_zoom, maximum_zoom)


func _clamp_position_to_map() -> void:
	var viewport_center := get_viewport().get_visible_rect().size / 2.0
	var map_rect := map_frame.get_global_rect()
	var current_zoom := maxf(zoom.x, 0.001)
	var minimum_position := (viewport_center - map_rect.position) / current_zoom
	var maximum_position := farm_size - (map_rect.end - viewport_center) / current_zoom

	if minimum_position.x > maximum_position.x:
		position.x = farm_size.x / 2.0
	else:
		position.x = clampf(position.x, minimum_position.x, maximum_position.x)
	if minimum_position.y > maximum_position.y:
		position.y = farm_size.y / 2.0
	else:
		position.y = clampf(position.y, minimum_position.y, maximum_position.y)


func _is_screen_point_over_map(screen_position: Vector2) -> bool:
	if not map_frame.get_global_rect().has_point(screen_position):
		return false
	for overlay in [
		module_workspace,
		map_palette,
		map_palette_open_button,
		map_interaction_bar,
		module_actions,
	]:
		if overlay.visible and overlay.get_global_rect().has_point(screen_position):
			return false
	return true


func _map_center_on_screen() -> Vector2:
	var map_rect := map_frame.get_global_rect()
	return map_rect.position + map_rect.size / 2.0
