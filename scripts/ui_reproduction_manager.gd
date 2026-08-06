class_name ReproductionUiManager

var reproduction_status: Label
var natural_breeding_button: Button
var insemination_button: Button
var select_genetics_button: Button


func _init(
	p_reproduction_status: Label,
	p_natural_breeding_button: Button,
	p_insemination_button: Button,
	p_select_genetics_button: Button
) -> void:
	reproduction_status = p_reproduction_status
	natural_breeding_button = p_natural_breeding_button
	insemination_button = p_insemination_button
	select_genetics_button = p_select_genetics_button


func update(state: Dictionary) -> void:
	var herd_created: bool = state.get("herd_created", false)
	var herd_categories: Dictionary = state.get("herd_categories", {})
	var pregnant_females: int = state.get("pregnant_females", 0)
	var gestation_days_remaining: int = state.get("gestation_days_remaining", 0)
	var calf_age_days: int = state.get("calf_age_days", -1)
	var offspring_genetics: Dictionary = state.get("offspring_genetics", {})
	var herd_genetics: Dictionary = state.get("herd_genetics", {})
	var body_condition: float = state.get("body_condition", 3.5)
	var health: float = state.get("health", 80.0)
	var cash_balance: int = state.get("cash_balance", 0)
	var weaning_age_days: int = state.get("weaning_age_days", 210)
	var artificial_insemination_cost: int = state.get("artificial_insemination_cost", 1200)
	var is_breeding_season: bool = state.get("is_breeding_season", false)

	if not herd_created:
		reproduction_status.text = "Compre animais no Mercado para iniciar o manejo reprodutivo."
	else:
		var cycle_text := "sem ciclo ativo"
		if pregnant_females > 0:
			cycle_text = "%d gestantes | parto em %d dias" % [
				pregnant_females,
				gestation_days_remaining,
			]
		elif calf_age_days >= 0:
			cycle_text = "bezerros com %d/%d dias para desmama" % [
				calf_age_days,
				weaning_age_days,
			]

		var genetics_to_show: Dictionary = (
			offspring_genetics if not offspring_genetics.is_empty() else herd_genetics
		)
		reproduction_status.text = (
			"Vacas: %d | Novilhas: %d | Touro: %d\n"
			+ "Bezerros: %d F / %d M | Garrotes: %d | Bois: %d\n"
			+ "%s\n"
			+ "Fertilidade %d | Parto %d | Materna %d\n"
			+ "Calor %d | Parasitas %d | Ganho %d"
		) % [
			int(herd_categories.get("cows", 0)),
			int(herd_categories.get("heifers", 0)),
			int(herd_categories.get("bulls", 0)),
			int(herd_categories.get("female_calves", 0)),
			int(herd_categories.get("male_calves", 0)),
			int(herd_categories.get("steers", 0)),
			int(herd_categories.get("oxen", 0)),
			cycle_text,
			roundi(float(genetics_to_show.get("fertility", 50.0))),
			roundi(float(genetics_to_show.get("calving_ease", 50.0))),
			roundi(float(genetics_to_show.get("maternal_ability", 50.0))),
			roundi(float(genetics_to_show.get("heat_adaptation", 50.0))),
			roundi(float(genetics_to_show.get("parasite_resistance", 50.0))),
			roundi(float(genetics_to_show.get("weight_gain", 50.0))),
		]

	var can_breed_now := (
		herd_created
		and pregnant_females == 0
		and calf_age_days < 0
		and int(herd_categories.get("cows", 0)) > 0
		and is_breeding_season
		and body_condition >= 2.5
		and health >= 60.0
	)
	natural_breeding_button.disabled = (
		not can_breed_now
		or int(herd_categories.get("bulls", 0)) < 1
	)
	insemination_button.disabled = (
		not can_breed_now
		or cash_balance < artificial_insemination_cost
	)
	select_genetics_button.disabled = offspring_genetics.is_empty() or calf_age_days >= 0
