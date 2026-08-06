extends Node2D

@export_range(0.0, 100.0, 1.0) var level := 70.0
@export var gauge_height := 170.0


func set_level(value: float) -> void:
	level = clampf(value, 0.0, 100.0)
	queue_redraw()


func _draw() -> void:
	var track_rect := Rect2(0.0, 0.0, 24.0, gauge_height)
	draw_rect(track_rect, Color(0.08, 0.1, 0.08, 0.88), true)
	draw_rect(track_rect, Color(0.82, 0.78, 0.58, 0.95), false, 3.0)

	var inner_height := gauge_height - 8.0
	var fill_height := inner_height * level / 100.0
	draw_rect(
		Rect2(4.0, 4.0 + inner_height - fill_height, 16.0, fill_height),
		Color(0.18, 0.48, 0.68, 0.95),
		true
	)

	var font := ThemeDB.fallback_font
	for percentage in [100, 75, 50, 25, 0]:
		var tick_y: float = gauge_height * (100.0 - percentage) / 100.0
		draw_line(
			Vector2(-6.0, tick_y),
			Vector2(30.0, tick_y),
			Color(0.96, 0.9, 0.68, 1),
			2.0
		)
		draw_string(
			font,
			Vector2(36.0, tick_y + 6.0),
			"%d%%" % percentage,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			18,
			Color(0.98, 0.94, 0.78, 1)
		)

	var current_y := gauge_height * (100.0 - level) / 100.0
	draw_line(
		Vector2(-10.0, current_y),
		Vector2(32.0, current_y),
		Color(1.0, 0.72, 0.2, 1),
		4.0
	)
