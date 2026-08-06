class_name ClimateUiManager

const CLIMATE_ICON_DROUGHT := preload("res://assets/ui/icons/climate-drought.svg")
const CLIMATE_ICON_TRANSITION := preload("res://assets/ui/icons/climate-transition.svg")
const CLIMATE_ICON_RAINY := preload("res://assets/ui/icons/climate-rainy.svg")

var climate_icon: TextureRect
var climate_status: Label
var pond_1_label: Label
var pond_2_label: Label
var pond_1_gauge: Node2D
var pond_2_gauge: Node2D
var river_label: Label
var pond_1_visual: Sprite2D
var pond_2_visual: Sprite2D
var intermittent_river: Sprite2D


func _init(
	p_climate_icon: TextureRect,
	p_climate_status: Label,
	p_pond_1_label: Label,
	p_pond_2_label: Label,
	p_pond_1_gauge: Node2D,
	p_pond_2_gauge: Node2D,
	p_river_label: Label,
	p_pond_1_visual: Sprite2D,
	p_pond_2_visual: Sprite2D,
	p_intermittent_river: Sprite2D
) -> void:
	climate_icon = p_climate_icon
	climate_status = p_climate_status
	pond_1_label = p_pond_1_label
	pond_2_label = p_pond_2_label
	pond_1_gauge = p_pond_1_gauge
	pond_2_gauge = p_pond_2_gauge
	river_label = p_river_label
	pond_1_visual = p_pond_1_visual
	pond_2_visual = p_pond_2_visual
	intermittent_river = p_intermittent_river


func update(state: Dictionary) -> void:
	var weather_condition: String = state.get("weather_condition", "Seco")
	var max_temperature_c: float = state.get("max_temperature_c", 33.0)
	var pond_level: Dictionary = state.get("pond_level", {1: 70.0, 2: 70.0})
	var river_level: float = state.get("river_level", 65.0)
	var formatted_datetime: String = state.get("formatted_datetime", "")
	var climate_phase_short: String = state.get("climate_phase_short", "Estiagem")
	var climate_phase_color: Color = state.get("climate_phase_color", Color("f2aa40"))
	var climate_phase_icon: Texture2D = state.get("climate_phase_icon", CLIMATE_ICON_DROUGHT)

	climate_icon.texture = climate_phase_icon
	climate_status.add_theme_color_override("font_color", climate_phase_color)
	climate_status.text = "%s | %s • %s | %.0f°C" % [
		formatted_datetime,
		climate_phase_short,
		weather_condition,
		max_temperature_c,
	]
	pond_1_label.text = "AÇUDE\nNível: %s" % _pond_level_label(pond_level[1])
	pond_2_label.text = "AÇUDE\nNível: %s" % _pond_level_label(pond_level[2])
	pond_1_gauge.call("set_level", pond_level[1])
	pond_2_gauge.call("set_level", pond_level[2])
	_update_water_level_visuals(pond_level, river_level)
	river_label.text = "RIO INTERMITENTE\n%s" % _river_level_label(river_level)


func _update_water_level_visuals(pond_level: Dictionary, river_level: float) -> void:
	_update_pond_level_visual(pond_1_visual, pond_level[1], Vector2(0.32, 0.42))
	_update_pond_level_visual(pond_2_visual, pond_level[2], Vector2(0.32, 0.42))
	var normalized_river := clampf(river_level / 100.0, 0.0, 1.0)
	intermittent_river.visible = river_level > 5.0
	intermittent_river.material.set_shader_parameter("water_level", normalized_river)


func _update_pond_level_visual(
	water_visual: Sprite2D,
	level: float,
	full_scale: Vector2
) -> void:
	var normalized_level := clampf(level / 100.0, 0.0, 1.0)
	water_visual.visible = level > 5.0
	water_visual.scale = full_scale * sqrt(normalized_level)
	water_visual.modulate = Color(0.82, 0.94, 1.0, lerpf(0.5, 0.92, normalized_level))


static func _pond_level_label(level: float) -> String:
	if level <= 5.0:
		return "seco"
	if level < 35.0:
		return "baixo"
	if level < 70.0:
		return "médio"
	return "alto"


static func _river_level_label(river_level: float) -> String:
	if river_level <= 5.0:
		return "leito seco"
	if river_level < 35.0:
		return "vazão baixa"
	if river_level < 70.0:
		return "vazão média"
	return "vazão alta"
