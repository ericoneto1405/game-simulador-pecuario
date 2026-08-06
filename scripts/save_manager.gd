class_name SaveManager

const SAVE_VERSION := 18
const CALENDAR_365_SAVE_VERSION := 15
const SAVE_PATH := "user://fazenda_save.json"


static func serialize_vector2(value: Vector2) -> Array:
	return [value.x, value.y]


static func deserialize_vector2(value) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


static func serialize_vector2_array(points: PackedVector2Array) -> Array:
	var serialized: Array = []
	for point in points:
		serialized.append(serialize_vector2(point))
	return serialized


static func deserialize_vector2_array(serialized_points) -> PackedVector2Array:
	var result := PackedVector2Array()
	if serialized_points is Array:
		for serialized_point in serialized_points:
			result.append(deserialize_vector2(serialized_point))
	return result


static func serialize_construction_job(
	construction_job_active: bool,
	construction_job_data: Dictionary,
	construction_job_name: String,
	construction_job_target: Vector2,
	construction_job_started_unix_utc: int,
	construction_job_completes_unix_utc: int,
	construction_job_duration_seconds: float,
	current_server_unix_utc: int
) -> Dictionary:
	if not construction_job_active or construction_job_data.is_empty():
		return {}
	var server_now := current_server_unix_utc
	var remaining_seconds := construction_job_duration_seconds
	if construction_job_completes_unix_utc > 0 and server_now > 0:
		remaining_seconds = maxf(
			float(construction_job_completes_unix_utc - server_now),
			0.0
		)
	return {
		"name": construction_job_name,
		"data": construction_job_data.duplicate(true),
		"target": serialize_vector2(construction_job_target),
		"started_unix_utc": construction_job_started_unix_utc,
		"completes_unix_utc": construction_job_completes_unix_utc,
		"remaining_seconds": remaining_seconds,
	}


static func serialize_built_structures(
	built_structures: Array,
	cost_breakdown_fn: Callable,
	labor_rate_fn: Callable
) -> Array:
	var serialized: Array = []
	for structure in built_structures:
		var type_name := str(structure.get("type", ""))
		var total_cost := int(structure.get("cost", 0))
		var fallback_breakdown: Dictionary = cost_breakdown_fn.call(
			total_cost, labor_rate_fn.call(type_name)
		)
		var entry := {
			"type": type_name,
			"cost": total_cost,
			"material_cost": int(structure.get("material_cost", fallback_breakdown["material"])),
			"labor_cost": int(structure.get("labor_cost", fallback_breakdown["labor"])),
		}
		if structure.has("points"):
			var serialized_points: Array = []
			for point in structure["points"]:
				serialized_points.append([point.x, point.y])
			entry["points"] = serialized_points
			entry["full_perimeter"] = bool(structure.get("full_perimeter", false))
		if structure.has("position"):
			var structure_position: Vector2 = structure["position"]
			entry["position"] = [structure_position.x, structure_position.y]
			entry["rotation"] = float(structure.get("rotation", 0.0))
			entry["open"] = bool(structure.get("open", false))
			entry["hinge_pivot"] = bool(structure.get("hinge_pivot", false))
		if structure.has("rect"):
			var structure_rect: Rect2 = structure["rect"]
			entry["rect"] = [
				structure_rect.position.x,
				structure_rect.position.y,
				structure_rect.size.x,
				structure_rect.size.y,
			]
		serialized.append(entry)
	return serialized


static func build_save_data(
	state: Dictionary,
	built_structures: Array,
	cost_breakdown_fn: Callable,
	labor_rate_fn: Callable,
	construction_job_data: Dictionary,
	current_server_unix_utc: int,
	vegetation_state: Dictionary
) -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"perimeter_built": state.get("perimeter_built", false),
		"full_farm_perimeter_built": state.get("full_farm_perimeter_built", false),
		"division_created": state.get("division_created", false),
		"division_orientation": state.get("division_orientation", 0),
		"division_position": state.get("division_position", 0.0),
		"gate_installed": state.get("gate_installed", false),
		"gate_open": state.get("gate_open", false),
		"gate_center_position": state.get("gate_center_position", 0.0),
		"herd_created": state.get("herd_created", false),
		"herd_size": state.get("herd_size", 0),
		"herd_animals": state.get("herd_animals", []),
		"next_animal_id": state.get("next_animal_id", 1),
		"herd_pasture": state.get("herd_pasture", 1),
		"current_day": state.get("current_day", 1),
		"day_of_year": state.get("day_of_year", 1),
		"current_year": state.get("current_year", 1),
		"server_unix_utc_at_save": current_server_unix_utc,
		"last_processed_server_unix_utc": state.get("last_processed_server_unix_utc", 0),
		"server_timezone": state.get("server_timezone", "America/Bahia"),
		"forage_1": state.get("forage_1", 100.0),
		"forage_2": state.get("forage_2", 100.0),
		"average_weight_kg": state.get("average_weight_kg", 300.0),
		"body_condition": state.get("body_condition", 3.0),
		"hunger": state.get("hunger", 0.0),
		"thirst": state.get("thirst", 0.0),
		"health": state.get("health", 100.0),
		"herd_categories": state.get("herd_categories", {}),
		"herd_genetics": state.get("herd_genetics", {}),
		"offspring_genetics": state.get("offspring_genetics", {}),
		"pregnant_females": state.get("pregnant_females", 0),
		"gestation_days_remaining": state.get("gestation_days_remaining", 0),
		"calf_age_days": state.get("calf_age_days", -1),
		"breeding_method": state.get("breeding_method", ""),
		"pond_level_1": state.get("pond_level_1", 70.0),
		"pond_level_2": state.get("pond_level_2", 70.0),
		"pasture_quality_1": state.get("pasture_quality_1", 75.0),
		"pasture_quality_2": state.get("pasture_quality_2", 75.0),
		"pasture_degradation_1": state.get("pasture_degradation_1", 0.0),
		"pasture_degradation_2": state.get("pasture_degradation_2", 0.0),
		"soil_moisture_1": state.get("soil_moisture_1", 62.0),
		"soil_moisture_2": state.get("soil_moisture_2", 38.0),
		"soil_fertility_1": state.get("soil_fertility_1", 78.0),
		"soil_fertility_2": state.get("soil_fertility_2", 48.0),
		"soil_compaction_1": state.get("soil_compaction_1", 12.0),
		"soil_compaction_2": state.get("soil_compaction_2", 8.0),
		"soil_erosion_1": state.get("soil_erosion_1", 4.0),
		"soil_erosion_2": state.get("soil_erosion_2", 12.0),
		"mineral_stock_kg": state.get("mineral_stock_kg", 0.0),
		"supplement_stock_kg": state.get("supplement_stock_kg", 0.0),
		"river_level": state.get("river_level", 65.0),
		"rainfall_mm": state.get("rainfall_mm", 0.0),
		"max_temperature_c": state.get("max_temperature_c", 33.0),
		"consecutive_dry_days": state.get("consecutive_dry_days", 0),
		"weather_condition": state.get("weather_condition", "Seco"),
		"heat_stress": state.get("heat_stress", 0.0),
		"parasite_pressure": state.get("parasite_pressure", 0.0),
		"parasite_treatment_days_remaining": state.get("parasite_treatment_days_remaining", 0),
		"clinical_medication_days_remaining": state.get("clinical_medication_days_remaining", 0),
		"vitamin_supplement_days_remaining": state.get("vitamin_supplement_days_remaining", 0),
		"sanitary_last_event": state.get("sanitary_last_event", "Sem ocorrências sanitárias."),
		"active_service_order": state.get("active_service_order", {}),
		"last_cowboy_activity": state.get("last_cowboy_activity", ""),
		"selected_crop_index": state.get("selected_crop_index", 0),
		"field_state": state.get("field_state", "idle"),
		"crop_days_elapsed": state.get("crop_days_elapsed", 0),
		"stored_silage_kg": state.get("stored_silage_kg", 0.0),
		"stored_fresh_forage_kg": state.get("stored_fresh_forage_kg", 0.0),
		"stored_hay_kg": state.get("stored_hay_kg", 0.0),
		"feeding_plan_days_remaining": state.get("feeding_plan_days_remaining", 0),
		"vegetation_state": vegetation_state,
		"vegetation_last_event": state.get("vegetation_last_event", ""),
		"cash_balance": state.get("cash_balance", 0),
		"transaction_history": state.get("transaction_history", []),
		"built_structures": serialize_built_structures(
			built_structures, cost_breakdown_fn, labor_rate_fn
		),
		"structure_investment": state.get("structure_investment", 0),
		"construction_job": serialize_construction_job(
			construction_job_data.get("active", false),
			construction_job_data.get("data", {}),
			construction_job_data.get("name", ""),
			construction_job_data.get("target", Vector2.ZERO),
			construction_job_data.get("started_unix_utc", 0),
			construction_job_data.get("completes_unix_utc", 0),
			construction_job_data.get("duration_seconds", 0.0),
			current_server_unix_utc
		),
	}


static func save_to_file(save_data: Dictionary) -> bool:
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		return false
	save_file.store_string(JSON.stringify(save_data))
	return true


static func load_from_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if save_file == null:
		return {}
	var parsed_data = JSON.parse_string(save_file.get_as_text())
	if parsed_data is Dictionary:
		return parsed_data
	return {}


static func get_save_version(save_data: Dictionary) -> int:
	return int(save_data.get("version", 0))
