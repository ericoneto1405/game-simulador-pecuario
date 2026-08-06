class_name WaterService


static func update_pond_levels(
	pond_level: Dictionary,
	rainfall_mm: float,
	max_temperature_c: float,
	soil_daily_runoff: Dictionary
) -> void:
	var evaporation := 0.25 + maxf(max_temperature_c - 28.0, 0.0) * 0.055
	for pond_number in [1, 2]:
		var direct_capture: float = rainfall_mm * SoilService.profile_value(
			pond_number,
			0.13,
			0.09
		)
		var runoff_recharge: float = soil_daily_runoff[pond_number] * 0.12
		var daily_change: float = direct_capture + runoff_recharge - evaporation
		pond_level[pond_number] = clampf(pond_level[pond_number] + daily_change, 0.0, 100.0)


static func update_river_level(
	river_level: float,
	rainfall_mm: float,
	max_temperature_c: float,
	month: int
) -> float:
	var phase := ClimateService.climate_phase(month)
	var phase_loss := 0.35
	if phase == "Transição":
		phase_loss = 0.8
	elif phase == "Estiagem":
		phase_loss = 1.4
	var heat_loss := maxf(max_temperature_c - 35.0, 0.0) * 0.08
	return clampf(
		river_level + rainfall_mm * 0.22 - phase_loss - heat_loss,
		0.0,
		100.0
	)


static func herd_has_river_access(
	using_general_farm_area: bool,
	division_orientation: int,
	herd_pasture: int,
	division_mode_none: int,
	division_mode_horizontal: int,
	division_mode_vertical: int
) -> bool:
	if using_general_farm_area:
		return true
	if division_orientation == division_mode_horizontal:
		return true
	if division_orientation == division_mode_vertical:
		return herd_pasture == 2
	return false


static func pond_level_label(level: float) -> String:
	if level <= 5.0:
		return "seco"
	if level < 35.0:
		return "baixo"
	if level < 70.0:
		return "médio"
	return "alto"


static func river_level_label(river_level: float) -> String:
	if river_level <= 5.0:
		return "leito seco"
	if river_level < 35.0:
		return "vazão baixa"
	if river_level < 70.0:
		return "vazão média"
	return "vazão alta"


static func consume_herd_water(
	pond_level: Dictionary,
	river_level: float,
	herd_pasture: int,
	herd_size: int,
	using_general_farm_area: bool,
	division_orientation: int,
	division_mode_none: int,
	division_mode_horizontal: int,
	division_mode_vertical: int
) -> Dictionary:
	var herd_had_water_today := false
	var new_pond_level: float = pond_level[herd_pasture]
	var new_river_level: float = river_level

	if pond_level[herd_pasture] > 5.0:
		herd_had_water_today = true
		new_pond_level = maxf(pond_level[herd_pasture] - 0.025 * herd_size, 0.0)
	elif herd_has_river_access(
		using_general_farm_area,
		division_orientation,
		herd_pasture,
		division_mode_none,
		division_mode_horizontal,
		division_mode_vertical
	) and river_level > 5.0:
		herd_had_water_today = true
		new_river_level = maxf(river_level - 0.02 * herd_size, 0.0)

	return {
		"herd_had_water_today": herd_had_water_today,
		"pond_level": new_pond_level,
		"river_level": new_river_level,
	}
