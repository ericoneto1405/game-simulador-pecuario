extends Node2D

signal selection_changed(summary: String)

const CATTLE_VISUAL := preload("res://scripts/cattle_visual.gd")
const UPDATE_GROUP_COUNT := 4
const CATEGORY_ORDER := [
	"female_calves",
	"male_calves",
	"heifers",
	"cows",
	"steers",
	"oxen",
	"bulls",
]

var actual_herd_size := 0
var pasture_polygon := PackedVector2Array()
var pasture_center := Vector2.ZERO
var water_point := Vector2.ZERO
var selected_index := -1
var managed_movement_active := false
var managed_target := Vector2.ZERO

var _animals: Array[Area2D] = []
var _pooled_animals: Array[Area2D] = []
var _rng := RandomNumberGenerator.new()
var _update_group := 0


func _ready() -> void:
	_rng.seed = 6303


func _process(delta: float) -> void:
	if _animals.is_empty():
		return

	for animal_index in range(_update_group, _animals.size(), UPDATE_GROUP_COUNT):
		var animal := _animals[animal_index]
		if animal.advance(delta * UPDATE_GROUP_COUNT):
			if managed_movement_active:
				animal.set_activity("descansando", animal.position, 60.0)
			else:
				_choose_next_activity(animal)
	_update_group = (_update_group + 1) % UPDATE_GROUP_COUNT


func sync_herd(
	herd_size: int,
	categories: Dictionary,
	center: Vector2,
	polygon: PackedVector2Array,
	pond_position: Vector2,
	individual_animals: Array = []
) -> void:
	actual_herd_size = individual_animals.size() if not individual_animals.is_empty() else maxi(herd_size, 0)
	pasture_center = center
	pasture_polygon = polygon.duplicate()
	water_point = pond_position

	if actual_herd_size <= 0:
		clear_herd()
		return

	var visible_count := actual_herd_size
	while _animals.size() > visible_count:
		var removed: Area2D = _animals.pop_back()
		removed.set_active_visual(false)
		_pooled_animals.append(removed)
	while _animals.size() < visible_count:
		var animal: Area2D
		if _pooled_animals.is_empty():
			animal = CATTLE_VISUAL.new()
			add_child(animal)
			animal.selected.connect(_on_animal_selected)
		else:
			animal = _pooled_animals.pop_back()
		animal.set_active_visual(true)
		_animals.append(animal)

	var category_sequence := _build_category_sequence(categories)
	for visual_index in range(visible_count):
		var animal := _animals[visual_index]
var animal_data: Dictionary = (
			individual_animals[visual_index]
			if not individual_animals.is_empty()
			else {}
		)
	// Include genotype for visual trait display
	if not animal_data.is_empty() and animal_data.has_key("genotype"):
		animal_data["genotype_copy"] = animal_data["genotype"].duplicate(true)
	var source_index := mini(
			floori(float(visual_index) * float(category_sequence.size()) / float(visible_count)),
			category_sequence.size() - 1
		)
		var category_name := (
			str(animal_data.get("category", "cows"))
			if not animal_data.is_empty()
			else category_sequence[source_index]
		)
		animal.configure(visual_index + 1, category_name, animal_data)
		if not _point_belongs_to_pasture(animal.position):
			animal.position = _random_pasture_point()
			animal.movement_speed = 140.0
			animal.set_activity("caminhando", _random_pasture_point(), 12.0)
		elif animal.activity_time_left <= 0.0:
			_choose_next_activity(animal)

	if selected_index >= visible_count:
		selected_index = -1
	_update_selection()


func clear_herd() -> void:
	for animal in _animals:
		animal.set_active_visual(false)
		_pooled_animals.append(animal)
	_animals.clear()
	actual_herd_size = 0
	selected_index = -1
	_update_group = 0
	managed_movement_active = false
	managed_target = Vector2.ZERO
	selection_changed.emit("A fazenda está sem bovinos.")


func select_lot() -> void:
	selected_index = -1
	_update_selection()
	selection_changed.emit(
		"Lote selecionado | %d bovinos | %d exibidos no mapa" % [
			actual_herd_size,
			_animals.size(),
		]
	)


func select_animal(index: int) -> void:
	if index < 0 or index >= _animals.size():
		select_lot()
		return
	selected_index = index
	_update_selection()
	var animal := _animals[index]
	selection_changed.emit(
		"%s | %s | %s | %d meses | %.1f kg | %s" % [
			animal.animal_id,
			animal.breed_name(),
			animal.category_name(),
			floori(float(animal.age_days) / 30.0),
			animal.weight_kg,
			animal.activity_name(),
		]
	)


func visual_count() -> int:
	return _animals.size()


func pooled_visual_count() -> int:
	return _pooled_animals.size()


func update_batch_size() -> int:
	if _animals.is_empty():
		return 0
	return maxi(ceili(float(_animals.size()) / float(UPDATE_GROUP_COUNT)), 1)


func animals() -> Array[Area2D]:
	return _animals


func start_managed_movement(target: Vector2) -> void:
	managed_movement_active = true
	managed_target = target
	var columns := maxi(ceili(sqrt(float(maxi(_animals.size(), 1)))), 1)
	for animal_index in range(_animals.size()):
		var row := animal_index / columns
		var column := animal_index % columns
		var destination := target + Vector2(
			(float(column) - float(columns - 1) / 2.0) * 34.0,
			(float(row) - 1.0) * 42.0
		)
		var animal := _animals[animal_index]
		animal.movement_speed = 165.0
		animal.set_activity("caminhando", destination, 60.0)


func end_managed_movement() -> void:
	managed_movement_active = false
	managed_target = Vector2.ZERO
	for animal in _animals:
		animal.activity_time_left = 0.0


func _build_category_sequence(categories: Dictionary) -> Array[String]:
	var sequence: Array[String] = []
	for category_name in CATEGORY_ORDER:
		for _animal_index in range(maxi(int(categories.get(category_name, 0)), 0)):
			sequence.append(category_name)
	if sequence.is_empty():
		sequence.append("cows")
	return sequence


func _choose_next_activity(animal: Area2D) -> void:
	animal.movement_speed = 68.0
	var roll := _rng.randf()
	if roll < 0.42:
		animal.set_activity("pastando", animal.position, _rng.randf_range(5.0, 10.0))
	elif roll < 0.67:
		animal.set_activity("caminhando", _random_pasture_point(), _rng.randf_range(4.0, 8.0))
	elif roll < 0.83:
		animal.set_activity("bebendo", _random_water_point(), _rng.randf_range(5.0, 9.0))
	else:
		animal.set_activity("descansando", animal.position, _rng.randf_range(6.0, 12.0))


func _random_pasture_point() -> Vector2:
	if pasture_polygon.size() < 3:
		return pasture_center + Vector2(
			_rng.randf_range(-220.0, 220.0),
			_rng.randf_range(-150.0, 150.0)
		)

	var bounds := Rect2(pasture_polygon[0], Vector2.ZERO)
	for polygon_point in pasture_polygon:
		bounds = bounds.expand(polygon_point)
	for _attempt in range(40):
		var candidate := Vector2(
			_rng.randf_range(bounds.position.x, bounds.end.x),
			_rng.randf_range(bounds.position.y, bounds.end.y)
		)
		if Geometry2D.is_point_in_polygon(candidate, pasture_polygon):
			return candidate
	return pasture_center


func _point_belongs_to_pasture(point: Vector2) -> bool:
	if pasture_polygon.size() < 3:
		return point.distance_to(pasture_center) <= 320.0
	return Geometry2D.is_point_in_polygon(point, pasture_polygon)


func _random_water_point() -> Vector2:
	var candidate := water_point + Vector2(
		_rng.randf_range(-75.0, 75.0),
		_rng.randf_range(-45.0, 45.0)
	)
	return candidate if _point_belongs_to_pasture(candidate) else water_point


func _on_animal_selected(animal: Area2D) -> void:
	select_animal(_animals.find(animal))


func _update_selection() -> void:
	for animal_index in range(_animals.size()):
		_animals[animal_index].set_selected(animal_index == selected_index)
