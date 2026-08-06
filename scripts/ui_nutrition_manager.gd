class_name NutritionUiManager

var nutrition_status: Label
var vegetation_rest_button: Button
var vegetation_form_button: Button
var vegetation_fertilize_button: Button
var vegetation_recover_button: Button
var buy_mineral_button: Button
var buy_supplement_button: Button


func _init(
	p_nutrition_status: Label,
	p_vegetation_rest_button: Button,
	p_vegetation_form_button: Button,
	p_vegetation_fertilize_button: Button,
	p_vegetation_recover_button: Button,
	p_buy_mineral_button: Button,
	p_buy_supplement_button: Button
) -> void:
	nutrition_status = p_nutrition_status
	vegetation_rest_button = p_vegetation_rest_button
	vegetation_form_button = p_vegetation_form_button
	vegetation_fertilize_button = p_vegetation_fertilize_button
	vegetation_recover_button = p_vegetation_recover_button
	buy_mineral_button = p_buy_mineral_button
	buy_supplement_button = p_buy_supplement_button


func update(state: Dictionary, vegetation_manager) -> void:
	var selected_farm_pasture: int = state.get("selected_farm_pasture", 1)
	var herd_created: bool = state.get("herd_created", false)
	var herd_pasture: int = state.get("herd_pasture", 1)
	var herd_size: int = state.get("herd_size", 0)
	var average_weight_kg: float = state.get("average_weight_kg", 385.0)
	var mineral_stock_kg: float = state.get("mineral_stock_kg", 0.0)
	var supplement_stock_kg: float = state.get("supplement_stock_kg", 0.0)
	var vegetation_last_event: String = state.get("vegetation_last_event", "")
	var cash_balance: int = state.get("cash_balance", 0)
	var mineral_package_price: int = state.get("mineral_package_price", 300)
	var supplement_package_price: int = state.get("supplement_package_price", 450)

	var selected_area := selected_farm_pasture
	var area_herd_size := (
		herd_size if herd_created and herd_pasture == selected_area else 0
	)
	var stock_text := "Estoque: %.1f kg mineral | %.1f kg suplemento" % [
		mineral_stock_kg, supplement_stock_kg
	]
	nutrition_status.text = "%s\n%s\n%s" % [
		vegetation_manager.status_text(selected_area, area_herd_size, average_weight_kg),
		stock_text,
		vegetation_last_event,
	]
	var area: Dictionary = vegetation_manager.get_area(selected_area)
	var resting := not area.is_empty() and str(area.get("management_mode", "")) == "rest"
	vegetation_rest_button.text = "Liberar pastejo" if resting else "Colocar em descanso"
	var occupied := herd_created and herd_size > 0 and herd_pasture == selected_area
	var has_intervention := (
		not area.is_empty() and not Dictionary(area.get("intervention", {})).is_empty()
	)
	vegetation_rest_button.disabled = area.is_empty() or (occupied and not resting) or has_intervention
	vegetation_form_button.disabled = area.is_empty() or occupied or has_intervention
	vegetation_fertilize_button.disabled = area.is_empty() or occupied or has_intervention
	vegetation_recover_button.disabled = area.is_empty() or occupied or has_intervention
	if not area.is_empty():
		vegetation_form_button.text = (
			"Reformar pastagem"
			if int(area.get("degradation_stage", 0)) >= 2
			else "Formar pastagem selecionada"
		)
	buy_mineral_button.disabled = cash_balance < mineral_package_price
	buy_supplement_button.disabled = cash_balance < supplement_package_price
