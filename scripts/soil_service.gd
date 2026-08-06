class_name SoilService


static func profile_value(pasture_number: int, lowland_value: float, highland_value: float) -> float:
	return lowland_value if pasture_number == 1 else highland_value


static func advance_day(
	pasture_number: int,
	rainfall_mm: float,
	max_temperature_c: float,
	soil_compaction: float,
	soil_moisture: float,
	soil_erosion: float,
	soil_fertility: float,
	vegetation_cover: float
) -> Dictionary:
	var infiltration: float = profile_value(pasture_number, 0.78, 0.42)
	var drainage: float = profile_value(pasture_number, 0.3, 0.85)
	var slope_erosion: float = profile_value(pasture_number, 0.7, 1.45)
	var compaction_factor: float = clampf(
		1.0 - soil_compaction / 150.0,
		0.35,
		1.0
	)
	var effective_infiltration: float = infiltration * compaction_factor
	var runoff: float = rainfall_mm * (1.0 - effective_infiltration)

	var evaporation: float = (
		0.45
		+ maxf(max_temperature_c - 30.0, 0.0) * 0.07
		+ drainage
	)
	var new_moisture := clampf(
		soil_moisture
		+ rainfall_mm * effective_infiltration * 0.55
		- evaporation,
		0.0,
		100.0
	)

	var erosion_gain: float = runoff * (1.0 - vegetation_cover) * 0.035 * slope_erosion
	var new_erosion := clampf(soil_erosion + erosion_gain, 0.0, 100.0)
	var new_fertility := clampf(soil_fertility - erosion_gain * 0.015, 10.0, 100.0)

	return {
		"runoff": runoff,
		"soil_moisture": new_moisture,
		"soil_erosion": new_erosion,
		"soil_fertility": new_fertility,
	}


static func growth_factor(
	pasture_number: int,
	soil_moisture: float,
	soil_fertility: float
) -> float:
	var moisture_response: float = clampf(soil_moisture / 60.0, 0.25, 1.15)
	var fertility_response: float = 0.55 + soil_fertility / 200.0
	var relief_response: float = profile_value(pasture_number, 1.05, 0.88)
	return clampf(moisture_response * fertility_response * relief_response, 0.25, 1.2)


static func drought_factor(pasture_number: int, soil_moisture: float) -> float:
	var moisture_penalty: float = maxf(45.0 - soil_moisture, 0.0) / 90.0
	var relief_penalty: float = profile_value(pasture_number, 0.0, 0.15)
	return clampf(1.0 + moisture_penalty + relief_penalty, 1.0, 1.65)
