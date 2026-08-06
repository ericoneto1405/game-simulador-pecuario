class_name HerdUiManager

var herd_status: Label
var herd_marker: Label
var select_herd_button: Button
var herd_selection_info: Label
var pasture_1_center: Vector2
var pasture_2_center: Vector2


func _init(
	p_herd_status: Label,
	p_herd_marker: Label,
	p_select_herd_button: Button,
	p_herd_selection_info: Label,
	p_pasture_1_center: Vector2,
	p_pasture_2_center: Vector2
) -> void:
	herd_status = p_herd_status
	herd_marker = p_herd_marker
	select_herd_button = p_select_herd_button
	herd_selection_info = p_herd_selection_info
	pasture_1_center = p_pasture_1_center
	pasture_2_center = p_pasture_2_center


func update_status(state: Dictionary) -> void:
	var current_day: int = state.get("current_day", 1)
	var formatted_date: String = state.get("formatted_date", "")
	var herd_size: int = state.get("herd_size", 0)
	var herd_pasture: int = state.get("herd_pasture", 1)
	var average_weight_kg: float = state.get("average_weight_kg", 385.0)
	var body_condition: float = state.get("body_condition", 3.5)
	var hunger: float = state.get("hunger", 0.0)
	var thirst: float = state.get("thirst", 0.0)
	var health: float = state.get("health", 80.0)
	var heat_stress: float = state.get("heat_stress", 0.0)
	var message: String = state.get("message", "")

	var body_condition_label := _body_condition_label(body_condition)

	herd_status.text = "Dia %d | %s | %d bovinos | %s\nPeso: %.1f kg | Condição: %.2f (%s)\nFome: %d%% | Sede: %d%% | Saúde: %d%%\nEstresse térmico: %d%%\n%s" % [
		current_day,
		formatted_date,
		herd_size,
		_pasteure_name(herd_pasture),
		average_weight_kg,
		body_condition,
		body_condition_label,
		roundi(hunger),
		roundi(thirst),
		roundi(health),
		roundi(heat_stress),
		message
	]


func update_marker(state: Dictionary) -> void:
	var herd_created: bool = state.get("herd_created", false)
	var herd_size: int = state.get("herd_size", 0)
	var herd_pasture: int = state.get("herd_pasture", 1)

	herd_marker.visible = false
	select_herd_button.disabled = herd_size <= 0

	var center := pasture_1_center if herd_pasture == 1 else pasture_2_center
	herd_marker.position = center - Vector2(115, 55)
	if herd_created and herd_size > 0:
		herd_marker.visible = true


func on_selection_changed(summary: String) -> void:
	herd_selection_info.text = summary


static func _body_condition_label(body_condition: float) -> String:
	if body_condition < 2.0:
		return "muito baixa"
	if body_condition < 3.0:
		return "baixa"
	if body_condition < 4.0:
		return "adequada"
	if body_condition < 4.5:
		return "alta"
	return "excessiva"


static func _pasteure_name(herd_pasture: int) -> String:
	if herd_pasture == 1:
		return "Pasto 1"
	return "Pasto 2"
