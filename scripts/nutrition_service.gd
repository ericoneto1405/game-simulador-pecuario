class_name NutritionService

const DAILY_RESERVE_KG_PER_ANIMAL := 5.0
const FEEDING_PLAN_DAYS := 7
const MINERAL_DAILY_KG_PER_ANIMAL := 0.08
const SUPPLEMENT_DAILY_KG_PER_ANIMAL := 0.5
const MINERAL_PACKAGE_KG := 25.0
const MINERAL_PACKAGE_PRICE := 180
const SUPPLEMENT_PACKAGE_KG := 100.0
const SUPPLEMENT_PACKAGE_PRICE := 320
const SOIL_PREPARATION_COST := 800
const FORAGE_CROPS := [
	{
		"name": "Milho para silagem",
		"days": 90,
		"planting_cost": 1200,
		"yield_kg": 30000.0,
		"product": "silage",
	},
	{
		"name": "Sorgo para silagem",
		"days": 80,
		"planting_cost": 900,
		"yield_kg": 26000.0,
		"product": "silage",
	},
	{
		"name": "Capiaçu",
		"days": 120,
		"planting_cost": 700,
		"yield_kg": 35000.0,
		"product": "fresh_forage",
	},
	{
		"name": "Palma forrageira",
		"days": 180,
		"planting_cost": 1000,
		"yield_kg": 20000.0,
		"product": "fresh_forage",
	},
	{
		"name": "Capim para feno",
		"days": 70,
		"planting_cost": 600,
		"yield_kg": 8000.0,
		"product": "hay",
	},
]


static func total_stored_feed(stored_feed_kg: Dictionary) -> float:
	return (
		float(stored_feed_kg.get("silage", 0.0))
		+ float(stored_feed_kg.get("fresh_forage", 0.0))
		+ float(stored_feed_kg.get("hay", 0.0))
	)


static func crop_soil_yield_factor(
	soil_fertility: float,
	soil_moisture: float,
	soil_erosion: float
) -> float:
	var fertility_penalty := maxf(60.0 - soil_fertility, 0.0) * 0.006
	var moisture_penalty := maxf(25.0 - soil_moisture, 0.0) * 0.01
	var erosion_penalty := maxf(soil_erosion - 35.0, 0.0) * 0.004
	return clampf(1.0 - fertility_penalty - moisture_penalty - erosion_penalty, 0.45, 1.0)


static func consume_stored_feed(stored_feed_kg: Dictionary, required_feed: float) -> Dictionary:
	var result := stored_feed_kg.duplicate()
	var remaining := required_feed
	for product in ["fresh_forage", "silage", "hay"]:
		var available := float(result.get(product, 0.0))
		var consumed := minf(available, remaining)
		result[product] = available - consumed
		remaining -= consumed
		if remaining <= 0.0:
			break
	return result


static func consume_daily_supplements(
	herd_size: int,
	mineral_stock_kg: float,
	supplement_stock_kg: float
) -> Dictionary:
	var mineral_required := herd_size * MINERAL_DAILY_KG_PER_ANIMAL
	var supplement_required := herd_size * SUPPLEMENT_DAILY_KG_PER_ANIMAL
	var mineral_used := mineral_stock_kg >= mineral_required and mineral_required > 0.0
	var supplement_used := supplement_stock_kg >= supplement_required and supplement_required > 0.0

	var new_mineral := mineral_stock_kg
	var new_supplement := supplement_stock_kg
	if mineral_used:
		new_mineral -= mineral_required
	if supplement_used:
		new_supplement -= supplement_required

	return {
		"mineral": mineral_used,
		"supplement": supplement_used,
		"mineral_stock_kg": new_mineral,
		"supplement_stock_kg": new_supplement,
	}
