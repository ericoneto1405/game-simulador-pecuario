class_name VegetationManager
extends RefCounted

const DAILY_INTAKE_LIVE_WEIGHT := 0.025
const CAPACITY_HORIZON_DAYS := 30.0

const SPECIES := {
	"caatinga": {
		"name": "Caatinga nativa",
		"max_biomass": 2400.0,
		"residual_biomass": 900.0,
		"growth_per_day": 18.0,
		"quality": 58.0,
		"drought_tolerance": 0.92,
		"fertility_demand": 0.45,
		"utilization": 0.28,
		"capacity_ua_ha": 0.125,
		"healthy_color": Color("718b46"),
		"dry_color": Color("7a6740"),
	},
	"buffel": {
		"name": "Capim-buffel",
		"max_biomass": 4500.0,
		"residual_biomass": 1200.0,
		"growth_per_day": 38.0,
		"quality": 70.0,
		"drought_tolerance": 0.82,
		"fertility_demand": 0.62,
		"utilization": 0.42,
		"capacity_ua_ha": 0.30,
		"healthy_color": Color("648b3d"),
		"dry_color": Color("8a713b"),
	},
	"massai": {
		"name": "Capim-massai",
		"max_biomass": 6000.0,
		"residual_biomass": 1500.0,
		"growth_per_day": 55.0,
		"quality": 78.0,
		"drought_tolerance": 0.66,
		"fertility_demand": 0.78,
		"utilization": 0.48,
		"capacity_ua_ha": 0.45,
		"healthy_color": Color("52913b"),
		"dry_color": Color("88713a"),
	},
	"andropogon": {
		"name": "Capim-andropogon",
		"max_biomass": 5200.0,
		"residual_biomass": 1400.0,
		"growth_per_day": 44.0,
		"quality": 68.0,
		"drought_tolerance": 0.76,
		"fertility_demand": 0.55,
		"utilization": 0.42,
		"capacity_ua_ha": 0.36,
		"healthy_color": Color("668b42"),
		"dry_color": Color("88703e"),
	},
}

var areas: Dictionary = {}


func configure_area(
	area_id: int,
	area_hectares: float,
	elevation_m: float,
	initial_species: String = "buffel"
) -> void:
	var species_key := initial_species if SPECIES.has(initial_species) else "buffel"
	if areas.has(area_id):
		areas[area_id]["area_hectares"] = maxf(area_hectares, 0.1)
		areas[area_id]["elevation_m"] = clampf(elevation_m, 0.0, 40.0)
		return
	var definition: Dictionary = SPECIES[species_key]
	areas[area_id] = {
		"id": area_id,
		"area_hectares": maxf(area_hectares, 0.1),
		"elevation_m": clampf(elevation_m, 0.0, 40.0),
		"species": species_key,
		"biomass_kg_ha": float(definition["max_biomass"]) * 0.78,
		"cover_pct": 82.0,
		"vigor_pct": 78.0,
		"quality_pct": float(definition["quality"]),
		"degradation_pct": 8.0,
		"degradation_stage": 0,
		"rest_days": 0,
		"management_mode": "grazing",
		"trend": "estável",
		"intervention": {},
		"protected_kind": "",
	}


func has_area(area_id: int) -> bool:
	return areas.has(area_id)


func get_area(area_id: int) -> Dictionary:
	return areas.get(area_id, {})


func species_definitions() -> Dictionary:
	return SPECIES


func species_name(species_key: String) -> String:
	return str(SPECIES.get(species_key, SPECIES["buffel"])["name"])


func set_legacy_condition(
	area_id: int,
	forage_pct: float,
	quality_pct: float,
	degradation_pct: float
) -> void:
	if not areas.has(area_id):
		return
	var area: Dictionary = areas[area_id]
	var definition: Dictionary = SPECIES[area["species"]]
	area["biomass_kg_ha"] = float(definition["max_biomass"]) * clampf(
		forage_pct / 100.0, 0.0, 1.0
	)
	area["quality_pct"] = clampf(quality_pct, 10.0, 100.0)
	area["degradation_pct"] = clampf(degradation_pct, 0.0, 100.0)
	area["cover_pct"] = clampf(
		forage_pct * (1.0 - float(area["degradation_pct"]) / 140.0), 0.0, 100.0
	)
	_update_degradation_stage(area)


func set_management_mode(area_id: int, mode: String) -> bool:
	if not areas.has(area_id) or mode not in ["grazing", "rest", "recovery"]:
		return false
	areas[area_id]["management_mode"] = mode
	if mode == "grazing":
		areas[area_id]["rest_days"] = 0
	return true


func schedule_intervention(area_id: int, action: String, target_species: String = "") -> bool:
	if not areas.has(area_id):
		return false
	var area: Dictionary = areas[area_id]
	if not Dictionary(area["intervention"]).is_empty():
		return false
	var duration := 0
	match action:
		"formation":
			if not SPECIES.has(target_species):
				return false
			duration = 14
		"reform":
			if not SPECIES.has(target_species):
				return false
			duration = 21
		"fertilize":
			duration = 3
		"recover":
			duration = 30
		_:
			return false
	area["intervention"] = {
		"action": action,
		"target_species": target_species,
		"days_remaining": duration,
		"total_days": duration,
	}
	area["management_mode"] = "recovery"
	return true


func intervention_cost(area_id: int, action: String) -> int:
	if not areas.has(area_id):
		return 0
	var rate: float = float({
		"formation": 250.0,
		"reform": 320.0,
		"fertilize": 60.0,
		"recover": 120.0,
	}.get(action, 0.0))
	return maxi(roundi(float(areas[area_id]["area_hectares"]) * float(rate)), 0)


func advance_day(area_id: int, environment: Dictionary, herd: Dictionary) -> Dictionary:
	if not areas.has(area_id):
		return {}
	var area: Dictionary = areas[area_id]
	var definition: Dictionary = SPECIES[area["species"]]
	var biomass_before := float(area["biomass_kg_ha"])
	var intervention_result := _advance_intervention(area)
	definition = SPECIES[area["species"]]

	var rainfall := maxf(float(environment.get("rainfall_mm", 0.0)), 0.0)
	var temperature := float(environment.get("temperature_c", 34.0))
	var dry_days := maxi(int(environment.get("dry_days", 0)), 0)
	var moisture := clampf(float(environment.get("soil_moisture", 45.0)), 0.0, 100.0)
	var fertility := clampf(float(environment.get("soil_fertility", 60.0)), 10.0, 100.0)
	var compaction := clampf(float(environment.get("soil_compaction", 10.0)), 0.0, 100.0)
	var erosion := clampf(float(environment.get("soil_erosion", 5.0)), 0.0, 100.0)

	var moisture_factor := clampf(moisture / 55.0, 0.08, 1.2)
	var fertility_need := float(definition["fertility_demand"])
	var fertility_factor := lerpf(1.0, fertility / 75.0, fertility_need)
	var heat_factor := clampf(1.0 - maxf(temperature - 36.0, 0.0) * 0.055, 0.25, 1.0)
	var drought_tolerance := float(definition["drought_tolerance"])
	var drought_factor := clampf(
		1.0 - maxf(float(dry_days - 10), 0.0) * 0.018 * (1.1 - drought_tolerance),
		0.18,
		1.0
	)
	var rain_factor := clampf(0.45 + rainfall * 0.045, 0.35, 1.35)
	var soil_damage_factor := clampf(
		1.0 - compaction / 180.0 - erosion / 160.0, 0.18, 1.0
	)
	var vigor_factor := clampf(float(area["vigor_pct"]) / 100.0, 0.12, 1.0)
	var room_factor := clampf(
		1.0 - biomass_before / float(definition["max_biomass"]), 0.0, 1.0
	)
	var growth := (
		float(definition["growth_per_day"])
		* moisture_factor
		* fertility_factor
		* heat_factor
		* drought_factor
		* rain_factor
		* soil_damage_factor
		* vigor_factor
		* maxf(room_factor, 0.08)
	)
	if moisture < 15.0 or (dry_days > 18 and rainfall <= 0.0):
		var drought_loss := (15.0 - minf(moisture, 15.0)) * 1.2
		drought_loss += maxf(float(dry_days - 18), 0.0) * (1.0 - drought_tolerance) * 1.8
		growth -= drought_loss

	var herd_present: bool = bool(herd.get("present", false)) and str(area["management_mode"]) == "grazing"
	var live_weight := maxf(float(herd.get("live_weight_kg", 0.0)), 0.0)
	var reserve_factor := clampf(float(herd.get("grazing_fraction", 1.0)), 0.0, 1.0)
	var demand_kg := live_weight * DAILY_INTAKE_LIVE_WEIGHT * reserve_factor if herd_present else 0.0
	var residual := float(definition["residual_biomass"])
	var harvestable_total := maxf(biomass_before + growth - residual, 0.0) * float(area["area_hectares"])
	var consumed_kg := minf(demand_kg, harvestable_total)
	var consumed_per_ha := consumed_kg / maxf(float(area["area_hectares"]), 0.1)
	area["biomass_kg_ha"] = clampf(
		biomass_before + growth - consumed_per_ha,
		0.0,
		float(definition["max_biomass"])
	)

	var stocking_pressure := 0.0
	if herd_present:
		var carrying_ua := maxf(_base_capacity_ua(area), 0.05)
		stocking_pressure = (live_weight / 450.0) / carrying_ua
		compaction = clampf(compaction + maxf(stocking_pressure - 0.45, 0.0) * 0.045, 0.0, 100.0)
		area["rest_days"] = 0
	else:
		area["rest_days"] = int(area["rest_days"]) + 1
		compaction = maxf(compaction - 0.018, 0.0)

	var cover_target := 100.0 * float(area["biomass_kg_ha"]) / float(definition["max_biomass"])
	area["cover_pct"] = clampf(
		lerpf(float(area["cover_pct"]), cover_target, 0.12) - maxf(stocking_pressure - 1.0, 0.0) * 0.2,
		0.0,
		100.0
	)
	var damage_gain := 0.0
	damage_gain += maxf(stocking_pressure - 1.0, 0.0) * 0.45
	damage_gain += maxf(25.0 - float(area["cover_pct"]), 0.0) * 0.018
	damage_gain += erosion * 0.0015 + compaction * 0.001
	var natural_recovery := 0.0
	if not herd_present and growth > 0.0 and float(area["cover_pct"]) > 35.0:
		natural_recovery = 0.08 + moisture * 0.0015
		if area["management_mode"] == "recovery":
			natural_recovery *= 1.8
	area["degradation_pct"] = clampf(
		float(area["degradation_pct"]) + damage_gain - natural_recovery, 0.0, 100.0
	)
	area["vigor_pct"] = clampf(
		100.0 - float(area["degradation_pct"]) * 0.72 - erosion * 0.16,
		8.0,
		100.0
	)
	area["quality_pct"] = clampf(
		float(definition["quality"])
		* (0.72 + moisture / 360.0)
		* (1.0 - float(area["degradation_pct"]) / 180.0),
		10.0,
		100.0
	)
	_update_degradation_stage(area)
	area["trend"] = _trend_label(float(area["biomass_kg_ha"]) - biomass_before)
	return {
		"consumed_kg": consumed_kg,
		"demand_kg": demand_kg,
		"grazing_pressure": stocking_pressure,
		"soil_compaction": compaction,
		"intervention_message": str(intervention_result.get("message", "")),
		"completed_action": str(intervention_result.get("action", "")),
	}


func forage_percent(area_id: int) -> float:
	if not areas.has(area_id):
		return 0.0
	var area: Dictionary = areas[area_id]
	return clampf(
		float(area["biomass_kg_ha"]) / float(SPECIES[area["species"]]["max_biomass"]) * 100.0,
		0.0,
		100.0
	)


func capacity_animals(area_id: int, average_weight_kg: float = 300.0) -> int:
	if not areas.has(area_id):
		return 0
	var area: Dictionary = areas[area_id]
	var definition: Dictionary = SPECIES[area["species"]]
	var harvestable := maxf(
		float(area["biomass_kg_ha"]) - float(definition["residual_biomass"]), 0.0
	)
	var usable_kg := harvestable * float(area["area_hectares"]) * float(definition["utilization"])
	var demand_per_animal := maxf(average_weight_kg, 100.0) * DAILY_INTAKE_LIVE_WEIGHT * CAPACITY_HORIZON_DAYS
	var forage_capacity := usable_kg / demand_per_animal
	var ecological_capacity := _base_capacity_ua(area) * 450.0 / maxf(average_weight_kg, 100.0)
	return maxi(floori(minf(forage_capacity, ecological_capacity)), 1)


func visual_color(area_id: int, season: float = 0.5) -> Color:
	if not areas.has(area_id):
		return Color("75633d")
	var area: Dictionary = areas[area_id]
	var definition: Dictionary = SPECIES[area["species"]]
	var condition := clampf(
		float(area["cover_pct"]) / 100.0
		* (1.0 - float(area["degradation_pct"]) / 120.0),
		0.0,
		1.0
	)
	# Aplicar estação: temporada seca mantém cores mais apagadas,
	# temporada de chuva realça cores saudáveis
	var season_mod: float = clampf(season, 0.0, 1.0)
	var color: Color = Color(definition["dry_color"]).lerp(Color(definition["healthy_color"]), condition * season_mod)
	color.a = 0.10 + condition * 0.12
	return color


func status_text(area_id: int, herd_size: int, average_weight_kg: float) -> String:
	if not areas.has(area_id):
		return "Área sem vegetação configurada."
	var area: Dictionary = areas[area_id]
	var capacity := capacity_animals(area_id, average_weight_kg)
	var pressure := "sem lote" if herd_size <= 0 else "%d/%d bovinos" % [herd_size, capacity]
	var intervention: Dictionary = area["intervention"]
	var operation := "Pastejo liberado"
	if area["management_mode"] == "rest":
		operation = "Em descanso há %d dias" % int(area["rest_days"])
	elif area["management_mode"] == "recovery":
		operation = "Em recuperação"
	if not intervention.is_empty():
		operation = "Serviço: %s (%d dias)" % [
			_intervention_name(str(intervention["action"])), int(intervention["days_remaining"])
		]
	return (
		"%s • %.1f ha\n"
		+ "Biomassa: %.0f kg MS/ha • Cobertura: %d%%\n"
		+ "Qualidade: %d%% • %s • tendência %s\n"
		+ "Degradação: %s (%d%%) • Lotação: %s"
	) % [
		species_name(str(area["species"])), float(area["area_hectares"]),
		float(area["biomass_kg_ha"]), roundi(float(area["cover_pct"])),
		roundi(float(area["quality_pct"])), operation, str(area["trend"]),
		degradation_stage_name(int(area["degradation_stage"])),
		roundi(float(area["degradation_pct"])), pressure,
	]


func degradation_stage_name(stage: int) -> String:
	return ["Saudável", "Atenção", "Degradada", "Severamente degradada", "Solo exposto"][
		clampi(stage, 0, 4)
	]


func export_state() -> Dictionary:
	return {"areas": areas.duplicate(true)}


func import_state(state: Variant) -> bool:
	if not state is Dictionary or not state.has("areas") or not state["areas"] is Dictionary:
		return false
	var restored: Dictionary = {}
	for raw_key in state["areas"]:
		var area_id := int(raw_key)
		var raw_area = state["areas"][raw_key]
		if not raw_area is Dictionary:
			continue
		var species_key := str(raw_area.get("species", "buffel"))
		if not SPECIES.has(species_key):
			species_key = "buffel"
		configure_area(
			area_id,
			float(raw_area.get("area_hectares", 1.0)),
			float(raw_area.get("elevation_m", 20.0)),
			species_key
		)
		var area: Dictionary = areas[area_id]
		for key in raw_area:
			area[key] = raw_area[key]
		area["species"] = species_key
		area["biomass_kg_ha"] = clampf(
			float(area["biomass_kg_ha"]), 0.0, float(SPECIES[species_key]["max_biomass"])
		)
		_update_degradation_stage(area)
		restored[area_id] = area
	areas = restored
	return not areas.is_empty()


func _base_capacity_ua(area: Dictionary) -> float:
	var definition: Dictionary = SPECIES[area["species"]]
	var condition := clampf(
		float(area["cover_pct"]) / 100.0
		* (1.0 - float(area["degradation_pct"]) / 110.0), 0.08, 1.0
	)
	return float(area["area_hectares"]) * float(definition["capacity_ua_ha"]) * condition


func _advance_intervention(area: Dictionary) -> Dictionary:
	var intervention: Dictionary = area["intervention"]
	if intervention.is_empty():
		return {}
	intervention["days_remaining"] = maxi(int(intervention["days_remaining"]) - 1, 0)
	if int(intervention["days_remaining"]) > 0:
		return {}
	var action := str(intervention["action"])
	match action:
		"formation", "reform":
			var target := str(intervention["target_species"])
			area["species"] = target
			var definition: Dictionary = SPECIES[target]
			area["biomass_kg_ha"] = float(definition["residual_biomass"]) * 1.15
			area["cover_pct"] = 42.0
			area["vigor_pct"] = 72.0
			area["quality_pct"] = float(definition["quality"])
			area["degradation_pct"] = maxf(float(area["degradation_pct"]) - 28.0, 12.0)
		"fertilize":
			area["vigor_pct"] = minf(float(area["vigor_pct"]) + 18.0, 100.0)
			area["quality_pct"] = minf(float(area["quality_pct"]) + 8.0, 100.0)
		"recover":
			area["degradation_pct"] = maxf(float(area["degradation_pct"]) - 18.0, 0.0)
			area["vigor_pct"] = minf(float(area["vigor_pct"]) + 20.0, 100.0)
	area["intervention"] = {}
	area["management_mode"] = "rest"
	_update_degradation_stage(area)
	return {
		"action": action,
		"message": "%s concluída." % _intervention_name(action),
	}


func _intervention_name(action: String) -> String:
	return {
		"formation": "formação da pastagem",
		"reform": "reforma da pastagem",
		"fertilize": "correção e adubação",
		"recover": "recuperação assistida",
	}.get(action, action)


func _update_degradation_stage(area: Dictionary) -> void:
	var degradation := float(area["degradation_pct"])
	var cover := float(area["cover_pct"])
	var stage := 0
	if degradation >= 80.0 or cover <= 8.0:
		stage = 4
	elif degradation >= 60.0 or cover <= 20.0:
		stage = 3
	elif degradation >= 35.0 or cover <= 40.0:
		stage = 2
	elif degradation >= 15.0 or cover <= 65.0:
		stage = 1
	area["degradation_stage"] = stage


func _trend_label(delta_biomass: float) -> String:
	if delta_biomass > 2.0:
		return "crescendo"
	if delta_biomass < -2.0:
		return "caindo"
	return "estável"
