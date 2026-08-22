extends Area2D

signal selected(animal: Area2D)

const CATTLE_TEXTURE := preload("res://assets/animals/cattle-topdown.png")
const BREED_TEXTURES := {
	"nelore": preload("res://assets/animals/breeds/nelore.png"),
	"nelore_pintado": preload("res://assets/animals/breeds/nelore_pintado.png"),
	"guzera": preload("res://assets/animals/breeds/guzera.png"),
	"brahman": preload("res://assets/animals/breeds/brahman.png"),
	"tabapua": preload("res://assets/animals/breeds/tabapua.png"),
	"sindi": preload("res://assets/animals/breeds/sindi.png"),
	"angus": preload("res://assets/animals/breeds/angus.png"),
	"hereford": preload("res://assets/animals/breeds/hereford.png"),
	"brangus": preload("res://assets/animals/breeds/brangus.png"),
	"braford": preload("res://assets/animals/breeds/braford.png"),
	"senepol": preload("res://assets/animals/breeds/senepol.png"),
}
const BREED_NAMES := {
	"nelore": "Nelore",
	"nelore_pintado": "Nelore Pintado",
	"guzera": "Guzerá",
	"brahman": "Brahman",
	"tabapua": "Tabapuã",
	"sindi": "Sindi",
	"angus": "Angus",
	"hereford": "Hereford",
	"brangus": "Brangus",
	"braford": "Braford",
	"senepol": "Senepol",
}

const CATEGORY_NAMES := {
	"female_calves": "Bezerra",
	"male_calves": "Bezerro",
	"heifers": "Novilha",
	"cows": "Vaca",
	"steers": "Garrote",
	"oxen": "Boi",
	"bulls": "Touro",
}

const CATEGORY_SCALE := {
	"female_calves": 0.069,
	"male_calves": 0.075,
	"heifers": 0.096,
	"cows": 0.111,
	"steers": 0.102,
	"oxen": 0.12,
	"bulls": 0.123,
}

const BREED_SCALE := {
	"sindi": 0.88,
	"brahman": 1.06,
	"brangus": 1.04,
	"guzera": 1.03,
}

var animal_index := 0
var animal_id := ""
var category := "cows"
var breed := "nelore"
var age_days := 0
var weight_kg := 0.0
var activity := "pastando"
var target_position := Vector2.ZERO
var activity_time_left := 0.0
var movement_speed := 68.0
var selected_visual := false

var _sprite: Sprite2D
var _selection_ring: Line2D


func _ready() -> void:
	input_pickable = true

	_selection_ring = Line2D.new()
	_selection_ring.width = 2.0
	_selection_ring.default_color = Color(1.0, 0.78, 0.2, 0.95)
	_selection_ring.closed = true
	for point_index in range(24):
		var angle := TAU * float(point_index) / 24.0
		_selection_ring.add_point(Vector2(cos(angle) * 15.0, sin(angle) * 24.0))
	_selection_ring.visible = false
	add_child(_selection_ring)

	_sprite = Sprite2D.new()
	_sprite.texture = CATTLE_TEXTURE
	add_child(_sprite)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(27.0, 42.0)
	collision.shape = shape
	add_child(collision)

	input_event.connect(_on_input_event)
	_apply_category_visual()


var animal_data: Dictionary = {}
var genotype := {}

func configure(index: int, new_category: String, animal_data: Dictionary = {}) -> void:
	animal_index = index
	animal_id = str(animal_data.get("id", "BOV-%04d" % index))
	category = new_category if CATEGORY_NAMES.has(new_category) else "cows"
	breed = str(animal_data.get("breed", "nelore"))
	genotype = animal_data.get("genotype", {})
	if not BREED_TEXTURES.has(breed):
		breed = "nelore"
	age_days = int(animal_data.get("age_days", 0))
	weight_kg = float(animal_data.get("weight_kg", 0.0))
	if is_node_ready():
		_apply_category_visual()
		_apply_visual_genotype()

func _apply_visual_genotype() -> void:
	# Apply coat color based on genotype
	var coat: Dictionary = genotype.get("coat_color", {})
	if not coat.is_empty():
		var locus_1: Array = coat.get("locus_1", ["W", "W"])
		# Dominant W = white/light, recessive w = darker color
		var dominant_count = 0
		for allele in locus_1:
			if allele == allele.to_upper():
				dominant_count += 1
		# If mostly dominant, use normal breed texture
		# If mostly recessive, darken or modify
		if dominant_count >= 2:
			# Standard breed texture
			_sprite.modulate = Color.WHITE
		else:
			# Slightly modify color for recessive traits
			_sprite.modulate = Color(0.8, 0.8, 0.8, 1.0)
	
	# Apply horn type based on genotype
	var horn: Dictionary = genotype.get("horn_type", {})
	if not horn.is_empty():
		var locus_1: Array = horn.get("locus_1", ["P", "p"])
		var has_chifres = false
		for allele in locus_1:
			if allele == allele.to_upper() and allele == "P":
				has_chifres = true
				break
		# Visual indication of horn status could be added here
		# For now, just modulate based on horn type
		if has_chifres:
			_sprite.modulate = Color.WHITE
		else:
			# Polled animals - slight visual difference
			_sprite.modulate = Color(0.95, 0.95, 0.95, 1.0)


func set_activity(new_activity: String, destination: Vector2, duration: float) -> void:
	activity = new_activity
	target_position = destination
	activity_time_left = duration


func advance(delta: float) -> bool:
	activity_time_left = maxf(activity_time_left - delta, 0.0)

	if activity in ["caminhando", "bebendo"]:
		var direction := target_position - position
		if direction.length() > 5.0:
			position += direction.normalized() * minf(movement_speed * delta, direction.length())
			rotation = lerp_angle(rotation, direction.angle() + PI / 2.0, minf(delta * 5.0, 1.0))
		else:
			activity_time_left = minf(activity_time_left, 1.8 if activity == "bebendo" else 0.0)
	elif activity == "pastando":
		rotation += sin(Time.get_ticks_msec() * 0.002 + animal_index) * delta * 0.035
	elif activity == "descansando":
		rotation = lerp_angle(rotation, 0.0, minf(delta * 0.5, 1.0))

	return activity_time_left <= 0.0


func set_selected(value: bool) -> void:
	selected_visual = value
	if is_instance_valid(_selection_ring):
		_selection_ring.visible = value
	z_index = 8 if value else 3


func set_active_visual(value: bool) -> void:
	visible = value
	input_pickable = value
	if not value:
		set_selected(false)


func category_name() -> String:
	return str(CATEGORY_NAMES.get(category, "Bovino"))


func breed_name() -> String:
	return str(BREED_NAMES.get(breed, "Nelore"))


func breed_texture_path() -> String:
	var texture: Texture2D = BREED_TEXTURES.get(breed, CATTLE_TEXTURE)
	return texture.resource_path


func activity_name() -> String:
	return activity.capitalize()


func _apply_category_visual() -> void:
	if not is_instance_valid(_sprite):
		return
	var texture: Texture2D = BREED_TEXTURES.get(breed, CATTLE_TEXTURE)
	var visual_scale := (
		float(CATEGORY_SCALE.get(category, 0.111))
		* float(BREED_SCALE.get(breed, 1.0))
	)
	_sprite.texture = texture
	_sprite.scale = Vector2.ONE * visual_scale
	_sprite.modulate = Color.WHITE


func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		selected.emit(self)
		get_viewport().set_input_as_handled()
