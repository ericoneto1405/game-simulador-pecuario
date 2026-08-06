extends AnimatedSprite2D

const WORK_SPRITE_SHEET := preload("res://assets/characters/people-work-v3.png")
const WALK_SPRITE_SHEET := preload("res://assets/characters/people-walk-v3.png")
const FRAME_COLUMNS := 4
const FRAME_WIDTH := 320.0
const ROW_BOUNDS := [0.0, 320.0, 640.0, 960.0, 1280.0]
const HUMAN_VISUAL_SCALE := 0.09

@export_range(0, 3) var action_row := 0
@export_range(1.0, 12.0, 0.5) var work_fps := 5.0


func _ready() -> void:
	scale = Vector2.ONE * HUMAN_VISUAL_SCALE
	_add_character_shadow()
	sprite_frames = SpriteFrames.new()
	_add_animation_frames("walk", WALK_SPRITE_SHEET, 6.0)
	_add_animation_frames("work", WORK_SPRITE_SHEET, work_fps)
	animation = "work"
	frame = action_row % FRAME_COLUMNS
	stop()


func _add_character_shadow() -> void:
	var shadow := Polygon2D.new()
	shadow.name = "CharacterShadow"
	shadow.z_index = -1
	shadow.position = Vector2(0.0, 125.0)
	shadow.polygon = PackedVector2Array([
		Vector2(-72.0, 0.0),
		Vector2(-52.0, -18.0),
		Vector2(0.0, -26.0),
		Vector2(52.0, -18.0),
		Vector2(72.0, 0.0),
		Vector2(52.0, 16.0),
		Vector2(0.0, 23.0),
		Vector2(-52.0, 16.0),
	])
	shadow.color = Color(0.04, 0.035, 0.025, 0.32)
	add_child(shadow)


func _add_animation_frames(
	animation_name: String,
	atlas_texture: Texture2D,
	animation_speed: float
) -> void:
	sprite_frames.add_animation(animation_name)
	sprite_frames.set_animation_loop(animation_name, true)
	sprite_frames.set_animation_speed(animation_name, animation_speed)
	var row_start: float = ROW_BOUNDS[action_row]
	var row_height: float = ROW_BOUNDS[action_row + 1] - row_start
	for column in range(FRAME_COLUMNS):
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = atlas_texture
		frame_texture.region = Rect2(
			column * FRAME_WIDTH,
			row_start,
			FRAME_WIDTH,
			row_height
		)
		sprite_frames.add_frame(animation_name, frame_texture)


func start_walk() -> void:
	frame = action_row % FRAME_COLUMNS
	play("walk")


func start_work() -> void:
	frame = action_row % FRAME_COLUMNS
	play("work")


func stop_work() -> void:
	stop()
	animation = "work"
	frame = action_row % FRAME_COLUMNS
