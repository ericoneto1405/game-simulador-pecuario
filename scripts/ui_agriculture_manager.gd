class_name AgricultureUiManager

const SOIL_PREPARATION_COST := 800
const DAILY_RESERVE_KG_PER_ANIMAL := 5.0
const FEEDING_PLAN_DAYS := 7

var agriculture_status: Label
var forage_field_label: Label
var select_crop_button: Button
var plant_crop_button: Button
var prepare_soil_button: Button
var harvest_crop_button: Button
var use_feed_reserve_button: Button


func _init(
	p_agriculture_status: Label,
	p_forage_field_label: Label,
	p_select_crop_button: Button,
	p_plant_crop_button: Button,
	p_prepare_soil_button: Button,
	p_harvest_crop_button: Button,
	p_use_feed_reserve_button: Button
) -> void:
	agriculture_status = p_agriculture_status
	forage_field_label = p_forage_field_label
	select_crop_button = p_select_crop_button
	plant_crop_button = p_plant_crop_button
	prepare_soil_button = p_prepare_soil_button
	harvest_crop_button = p_harvest_crop_button
	use_feed_reserve_button = p_use_feed_reserve_button


func update(state: Dictionary, forage_crops: Array) -> void:
	var selected_crop_index: int = state.get("selected_crop_index", 0)
	var field_state: String = state.get("field_state", "idle")
	var crop_days_elapsed: int = state.get("crop_days_elapsed", 0)
	var soil_moisture: Dictionary = state.get("soil_moisture", {1: 62.0, 2: 38.0})
	var soil_fertility: Dictionary = state.get("soil_fertility", {1: 78.0, 2: 48.0})
	var stored_feed_kg: Dictionary = state.get("stored_feed_kg", {})
	var feeding_plan_days_remaining: int = state.get("feeding_plan_days_remaining", 0)
	var herd_created: bool = state.get("herd_created", false)
	var herd_size: int = state.get("herd_size", 0)
	var cash_balance: int = state.get("cash_balance", 0)
	var has_livestock_area: bool = state.get("has_livestock_area", false)
	var total_stored_feed: float = state.get("total_stored_feed", 0.0)

	var crop: Dictionary = forage_crops[selected_crop_index]
	var state_text := "sem preparo"
	if field_state == "prepared":
		state_text = "solo preparado"
	elif field_state == "growing":
		state_text = "crescendo: %d/%d dias" % [crop_days_elapsed, int(crop["days"])]
	elif field_state == "ready":
		state_text = "pronta para colheita"

	agriculture_status.text = (
		"Talhão: %s | Cultura: %s\n"
		+ "Solo: umidade %d%% | fertilidade %d%%\n"
		+ "Estoque: %.0f kg silagem | %.0f kg feno\n"
		+ "Forragem fresca: %.0f kg | Trato: %d dias"
	) % [
		state_text,
		crop["name"],
		roundi(soil_moisture[1]),
		roundi(soil_fertility[1]),
		float(stored_feed_kg.get("silage", 0.0)),
		float(stored_feed_kg.get("hay", 0.0)),
		float(stored_feed_kg.get("fresh_forage", 0.0)),
		feeding_plan_days_remaining,
	]
	forage_field_label.text = "TALHÃO FORRAGEIRO\n%s" % state_text.to_upper()
	select_crop_button.text = "Cultura: %s" % crop["name"]
	plant_crop_button.text = "Plantar — R$ %s" % EconomyService.format_money(int(crop["planting_cost"]))
	prepare_soil_button.disabled = (
		not has_livestock_area
		or field_state != "idle"
		or cash_balance < SOIL_PREPARATION_COST
	)
	plant_crop_button.disabled = (
		field_state != "prepared"
		or cash_balance < int(crop["planting_cost"])
	)
	harvest_crop_button.disabled = field_state != "ready"
	use_feed_reserve_button.disabled = (
		not herd_created
		or feeding_plan_days_remaining > 0
		or total_stored_feed < (
			herd_size * DAILY_RESERVE_KG_PER_ANIMAL * FEEDING_PLAN_DAYS
		)
	)
