class_name ClimateService


static func climate_phase(month: int) -> String:
	if month in [11, 12, 1, 2, 3, 4]:
		return "Período chuvoso"
	if month in [5, 10]:
		return "Transição"
	return "Estiagem"


static func climate_phase_short(month: int) -> String:
	match climate_phase(month):
		"Período chuvoso":
			return "Chuvoso"
		"Transição":
			return "Transição"
		_:
			return "Estiagem"


static func climate_phase_color(month: int) -> Color:
	match climate_phase(month):
		"Período chuvoso":
			return Color("63bfe8")
		"Transição":
			return Color("becf78")
		_:
			return Color("f2aa40")


static func calculate_heat_stress(temperature_c: float, heat_adaptation: float) -> float:
	var thermal_load := maxf(temperature_c - 30.0, 0.0) * 8.0
	var genetic_protection := clampf(heat_adaptation / 100.0, 0.0, 1.0) * 0.65
	return clampf(thermal_load * (1.0 - genetic_protection), 0.0, 100.0)


static func generate_daily_weather(
	day_of_year: int,
	current_year: int,
	month: int
) -> Dictionary:
	var phase := climate_phase(month)
	var rain_chance := 4
	var base_temperature := 37.0
	match phase:
		"Período chuvoso":
			rain_chance = 40
			base_temperature = 32.0
		"Transição":
			rain_chance = 15
			base_temperature = 35.0

	var rainfall_mm := 0.0
	var consecutive_dry_days := 0
	var rain_score := posmod(day_of_year * 13 + current_year * 7, 100)
	if rain_score < rain_chance:
		var rain_range := 470 if phase == "Período chuvoso" else 230
		var minimum_rain := 8.0 if phase == "Período chuvoso" else 2.0
		rainfall_mm = minimum_rain + (
			float(posmod(day_of_year * 19 + current_year * 11, rain_range)) / 10.0
		)
	else:
		consecutive_dry_days = 0

	var temperature_variation := (
		float(posmod(day_of_year * 7 + current_year * 13, 60)) / 10.0
	)
	var max_temperature_c := base_temperature + temperature_variation
	if rainfall_mm >= 2.0:
		max_temperature_c -= 2.5

	var weather_condition := (
		"Chuva forte"
		if rainfall_mm >= 30.0
		else ("Chuva" if rainfall_mm >= 2.0 else "Seco")
	)

	return {
		"rainfall_mm": rainfall_mm,
		"max_temperature_c": max_temperature_c,
		"weather_condition": weather_condition,
	}


static func daily_pasture_growth(
	month: int,
	rainfall_mm: float,
	consecutive_dry_days: int,
	max_temperature_c: float
) -> float:
	var base_growth := 0.0
	match climate_phase(month):
		"Período chuvoso":
			base_growth = 0.8
		"Transição":
			base_growth = 0.15
		_:
			base_growth = -0.55
	var rain_bonus := minf(rainfall_mm * 0.08, 3.5)
	var prolonged_drought_penalty := minf(maxi(consecutive_dry_days - 10, 0) * 0.04, 1.5)
	var heat_penalty := maxf(max_temperature_c - 36.0, 0.0) * 0.15
	return clampf(
		base_growth + rain_bonus - prolonged_drought_penalty - heat_penalty,
		-2.5,
		4.0
	)
