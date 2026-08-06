class_name WaterUiManager

var water_status: Label


func _init(p_water_status: Label) -> void:
	water_status = p_water_status


func update(state: Dictionary) -> void:
	var pond_level: Dictionary = state.get("pond_level", {1: 70.0, 2: 70.0})
	var river_level: float = state.get("river_level", 65.0)
	var weather_condition: String = state.get("weather_condition", "Seco")
	var rainfall_mm: float = state.get("rainfall_mm", 0.0)
	var consecutive_dry_days: int = state.get("consecutive_dry_days", 0)
	var herd_created: bool = state.get("herd_created", false)
	var herd_pasture: int = state.get("herd_pasture", 1)
	var using_general_area: bool = state.get("using_general_farm_area", false)
	var has_river_access: bool = state.get("herd_has_river_access", false)

	var water_areas_text := "Açudes: P1 %s | P2 %s" % [
		_pond_level_label(pond_level[1]),
		_pond_level_label(pond_level[2]),
	]
	if using_general_area:
		water_areas_text = "Açudes da área geral: %s | %s" % [
			_pond_level_label(pond_level[1]),
			_pond_level_label(pond_level[2]),
		]
	water_status.text = (
		"Hoje: %s | Chuva %.1f mm | %d dias secos\n"
		+ "%s\n"
		+ "Rio intermitente: %s\n"
		+ "Acesso atual do lote: %s"
	) % [
		weather_condition,
		rainfall_mm,
		consecutive_dry_days,
		water_areas_text,
		_river_level_label(river_level),
		(
			"açude ou rio"
			if herd_created and (
				pond_level[herd_pasture] > 5.0
				or (has_river_access and river_level > 5.0)
			)
			else ("sem lote" if not herd_created else "sem água disponível")
		),
	]


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
