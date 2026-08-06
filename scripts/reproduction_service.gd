class_name ReproductionService

const GESTATION_DAYS := 285
const WEANING_AGE_DAYS := 210


static func is_breeding_season(current_month: int) -> bool:
	return current_month in [11, 12, 1, 2, 3, 4]


static func can_start_breeding(
	herd_created: bool,
	pregnant_females: int,
	calf_age_days: int,
	cows_count: int,
	is_season: bool,
	body_condition: float,
	health: float
) -> Dictionary:
	if not herd_created:
		return {"allowed": false, "message": "Compre animais no Mercado antes de iniciar a reprodução."}
	if pregnant_females > 0:
		return {"allowed": false, "message": "Já existe uma gestação em andamento."}
	if calf_age_days >= 0:
		return {"allowed": false, "message": "Aguarde a desmama do lote atual de bezerros."}
	if cows_count < 1:
		return {"allowed": false, "message": "Não há vacas aptas para reprodução."}
	if not is_season:
		return {"allowed": false, "message": "A estação de monta ocorre de novembro a abril."}
	if body_condition < 2.5 or health < 60.0:
		return {"allowed": false, "message": "Condição corporal ou saúde insuficiente para a reprodução."}
	return {"allowed": true}


static func calculate_offspring_genetics(
	herd_genetics: Dictionary,
	breeding_method: String,
	current_year: int
) -> Dictionary:
	var sire_genetics := {
		"fertility": 84.0,
		"calving_ease": 88.0,
		"heat_adaptation": 84.0,
		"parasite_resistance": 78.0,
		"weight_gain": 76.0,
		"maternal_ability": 70.0,
	}
	if breeding_method == "Inseminação artificial":
		sire_genetics = {
			"fertility": 88.0,
			"calving_ease": 90.0,
			"heat_adaptation": 76.0,
			"parasite_resistance": 70.0,
			"weight_gain": 88.0,
			"maternal_ability": 78.0,
		}

	var inherited := {}
	var natural_variation := float((current_year % 5) - 2)
	for genetic_key in herd_genetics:
		inherited[genetic_key] = clampf(
			(
				float(herd_genetics[genetic_key])
				+ float(sire_genetics[genetic_key])
			) / 2.0
			+ natural_variation,
			0.0,
			100.0
		)
	return inherited


static func calculate_conception_rate(
	herd_genetics: Dictionary,
	fertility_bonus: float,
	body_condition: float,
	cows_count: int
) -> int:
	var condition_adjustment := (body_condition - 3.0) * 8.0
	var conception_rate := clampf(
		float(herd_genetics["fertility"]) + fertility_bonus + condition_adjustment,
		35.0,
		95.0
	)
	return clampi(roundi(cows_count * conception_rate / 100.0), 1, cows_count)


static func blend_offspring_genetics(
	herd_genetics: Dictionary,
	offspring_genetics: Dictionary
) -> Dictionary:
	var blended := {}
	for key in herd_genetics:
		blended[key] = clampf(
			float(herd_genetics[key]) * 0.75 + float(offspring_genetics.get(key, herd_genetics[key])) * 0.25,
			0.0,
			100.0
		)
	return blended
