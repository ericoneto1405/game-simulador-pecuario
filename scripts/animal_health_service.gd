class_name AnimalHealthService

const WEANING_AGE_DAYS := 210
const GESTATION_DAYS := 285
const PARASITE_TREATMENT_COST_PER_ANIMAL := 25
const BRUCELLOSIS_VACCINE_COST_PER_CALF := 40
const PARASITE_TREATMENT_PROTECTION_DAYS := 30
const CLINICAL_MEDICATION_COST_PER_ANIMAL := 60
const CLINICAL_MEDICATION_COOLDOWN_DAYS := 7
const CLOSTRIDIOSIS_VACCINE_COST_PER_ANIMAL := 20
const CLOSTRIDIOSIS_PROTECTION_DAYS := 365
const VITAMIN_SUPPLEMENT_COST_PER_ANIMAL := 15
const VITAMIN_SUPPLEMENT_DAYS := 30


static func daily_parasite_increase(
	parasite_resistance: float,
	rainfall_mm: float,
	soil_moisture: float,
	pasture_degradation: float,
	herd_size: int,
	pasture_capacity: int,
	parasite_treatment_days_remaining: int
) -> float:
	var capacity := maxi(pasture_capacity, 1)
	var grazing_pressure := float(herd_size) / float(capacity)
	var environmental_exposure: float = (
		0.45
		+ minf(rainfall_mm / 30.0, 1.5)
		+ soil_moisture / 300.0
		+ pasture_degradation / 100.0
		+ maxf(grazing_pressure - 0.8, 0.0) * 0.7
	)
	var genetic_protection: float = (
		clampf(parasite_resistance / 100.0, 0.0, 1.0) * 0.7
	)
	var treatment_factor: float = (
		0.25 if parasite_treatment_days_remaining > 0 else 1.0
	)
	return maxf(environmental_exposure * (1.0 - genetic_protection) * treatment_factor, 0.0)


static func update_animal_needs(
	available_forage: float,
	hunger: float,
	thirst: float,
	health: float,
	herd_had_water_today: bool
) -> Dictionary:
	if available_forage > 60.0:
		hunger = maxf(hunger - 20.0, 0.0)
	elif available_forage > 30.0:
		hunger = minf(hunger + 5.0, 100.0)
	elif available_forage > 15.0:
		hunger = minf(hunger + 15.0, 100.0)
	else:
		hunger = minf(hunger + 30.0, 100.0)

	if herd_had_water_today:
		thirst = maxf(thirst - 40.0, 0.0)
	else:
		thirst = minf(thirst + 35.0, 100.0)

	var daily_health_change := 0.0
	if hunger >= 80.0:
		daily_health_change -= 4.0
	elif hunger >= 50.0:
		daily_health_change -= 2.0

	if thirst >= 80.0:
		daily_health_change -= 8.0
	elif thirst >= 50.0:
		daily_health_change -= 4.0

	if hunger < 30.0 and thirst < 30.0:
		daily_health_change += 1.0

	health = clampf(health + daily_health_change, 0.0, 100.0)

	var message := ""
	if health <= 30.0:
		message = "Alerta grave: saúde do lote comprometida."
	elif thirst >= 50.0:
		message = "Alerta: o açude do pasto não está atendendo o lote."
	elif hunger >= 50.0:
		message = "Alerta: fome elevada por falta de forragem."

	return {
		"hunger": hunger,
		"thirst": thirst,
		"health": health,
		"message": message,
	}


static func category_for_animal(animal: Dictionary, weaning_age_days: int) -> String:
	var age_days := int(animal.get("age_days", 0))
	var sex := str(animal.get("sex", "female"))
	if sex == "female":
		if age_days < weaning_age_days:
			return "female_calves"
		if bool(animal.get("has_calved", false)) or age_days >= 900:
			return "cows"
		return "heifers"
	if bool(animal.get("intact_male", false)):
		return "bulls"
	if age_days < weaning_age_days:
		return "male_calves"
	if age_days < 730:
		return "steers"
	return "oxen"


static func eligible_brucellosis_calves(herd_animals: Array) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for animal in herd_animals:
		var age_days := int(animal.get("age_days", 0))
		if (
			str(animal.get("sex", "")) == "female"
			and age_days >= 90
			and age_days <= 240
			and not bool(animal.get("brucellosis_vaccinated", false))
		):
			eligible.append(animal)
	return eligible


static func clinical_treatment_candidates(herd_animals: Array) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for animal in herd_animals:
		if (
			float(animal.get("health", 80.0)) < 80.0
			or float(animal.get("parasite_load", 0.0)) >= 40.0
		):
			candidates.append(animal)
	return candidates


static func eligible_clostridiosis_animals(herd_animals: Array) -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for animal in herd_animals:
		var age_days := int(animal.get("age_days", 0))
		if (
			age_days >= 60
			and int(animal.get("clostridiosis_vaccine_days_remaining", 0)) <= 0
		):
			eligible.append(animal)
	return eligible


static func sanitary_service_is_available(
	action: String,
	herd_animals: Array,
	parasite_treatment_days_remaining: int,
	clinical_medication_days_remaining: int,
	vitamin_supplement_days_remaining: int
) -> bool:
	match action:
		"parasite":
			return parasite_treatment_days_remaining <= 0
		"clinical":
			return (
				not clinical_treatment_candidates(herd_animals).is_empty()
				and clinical_medication_days_remaining <= 0
			)
		"brucellosis":
			return not eligible_brucellosis_calves(herd_animals).is_empty()
		"clostridiosis":
			return not eligible_clostridiosis_animals(herd_animals).is_empty()
		"vitamin":
			return vitamin_supplement_days_remaining <= 0
	return false


static func body_condition_label(body_condition: float) -> String:
	if body_condition < 2.0:
		return "muito baixa"
	if body_condition < 3.0:
		return "baixa"
	if body_condition < 4.0:
		return "adequada"
	if body_condition < 4.5:
		return "alta"
	return "excessiva"
