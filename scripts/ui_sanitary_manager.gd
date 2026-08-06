class_name SanitaryUiManager

var sanitary_status: Label
var parasite_treatment_button: Button
var clinical_medication_button: Button
var brucellosis_vaccine_button: Button
var clostridiosis_vaccine_button: Button
var vitamin_supplement_button: Button

const PARASITE_TREATMENT_COST_PER_ANIMAL := 35
const BRUCELLOSIS_VACCINE_COST_PER_CALF := 80
const CLINICAL_MEDICATION_COST_PER_ANIMAL := 65
const CLOSTRIDIOSIS_VACCINE_COST_PER_ANIMAL := 55
const VITAMIN_SUPPLEMENT_COST_PER_ANIMAL := 12


func _init(
	p_sanitary_status: Label,
	p_parasite_treatment_button: Button,
	p_clinical_medication_button: Button,
	p_brucellosis_vaccine_button: Button,
	p_clostridiosis_vaccine_button: Button,
	p_vitamin_supplement_button: Button
) -> void:
	sanitary_status = p_sanitary_status
	parasite_treatment_button = p_parasite_treatment_button
	clinical_medication_button = p_clinical_medication_button
	brucellosis_vaccine_button = p_brucellosis_vaccine_button
	clostridiosis_vaccine_button = p_clostridiosis_vaccine_button
	vitamin_supplement_button = p_vitamin_supplement_button


func update(state: Dictionary) -> void:
	var herd_created: bool = state.get("herd_created", false)
	var herd_animals: Array = state.get("herd_animals", [])
	var herd_size: int = state.get("herd_size", 0)
	var parasite_pressure: float = state.get("parasite_pressure", 0.0)
	var parasite_treatment_days_remaining: int = state.get("parasite_treatment_days_remaining", 0)
	var clinical_medication_days_remaining: int = state.get("clinical_medication_days_remaining", 0)
	var vitamin_supplement_days_remaining: int = state.get("vitamin_supplement_days_remaining", 0)
	var sanitary_last_event: String = state.get("sanitary_last_event", "")
	var active_service_order: Dictionary = state.get("active_service_order", {})
	var cash_balance: int = state.get("cash_balance", 0)

	if not herd_created or herd_animals.is_empty():
		sanitary_status.text = "Compre animais no Mercado para iniciar o manejo sanitário."
		parasite_treatment_button.disabled = true
		clinical_medication_button.disabled = true
		brucellosis_vaccine_button.disabled = true
		clostridiosis_vaccine_button.disabled = true
		vitamin_supplement_button.disabled = true
		return

	var eligible_count := _eligible_brucellosis_calves(herd_animals).size()
	var clinical_count := _clinical_treatment_candidates(herd_animals).size()
	var clostridiosis_count := _eligible_clostridiosis_animals(herd_animals).size()
	var vaccinated_count := 0
	var clostridiosis_protected_count := 0
	for animal in herd_animals:
		if bool(animal.get("brucellosis_vaccinated", false)):
			vaccinated_count += 1
		if int(animal.get("clostridiosis_vaccine_days_remaining", 0)) > 0:
			clostridiosis_protected_count += 1
	var protection_text := (
		"%d dias" % parasite_treatment_days_remaining
		if parasite_treatment_days_remaining > 0
		else "sem proteção ativa"
	)
	sanitary_status.text = (
		"Pressão parasitária: %d%% | Proteção: %s\n"
		+ "Brucelose: %d vacinadas | %d elegíveis\n"
		+ "Clostridioses: %d protegidos | %d elegíveis\n"
		+ "Suporte vitamínico: %s\n"
		+ "%s"
	) % [
		roundi(parasite_pressure),
		protection_text,
		vaccinated_count,
		eligible_count,
		clostridiosis_protected_count,
		clostridiosis_count,
		(
			"%d dias" % vitamin_supplement_days_remaining
			if vitamin_supplement_days_remaining > 0
			else "inativo"
		),
		sanitary_last_event,
	]
	var treatment_cost := herd_size * PARASITE_TREATMENT_COST_PER_ANIMAL
	var vaccination_cost := eligible_count * BRUCELLOSIS_VACCINE_COST_PER_CALF
	var medication_cost := clinical_count * CLINICAL_MEDICATION_COST_PER_ANIMAL
	var clostridiosis_cost := clostridiosis_count * CLOSTRIDIOSIS_VACCINE_COST_PER_ANIMAL
	var vitamin_cost := herd_size * VITAMIN_SUPPLEMENT_COST_PER_ANIMAL
	parasite_treatment_button.text = _format_sanitary_cost(
		"Controle parasitário", treatment_cost, "parasite"
	)
	brucellosis_vaccine_button.text = _format_sanitary_cost("Vacinar %d bezerras" % eligible_count,
		vaccination_cost, "brucellosis")
	clinical_medication_button.text = _format_sanitary_cost("Tratar %d bovinos" % clinical_count,
		medication_cost, "clinical")
	clostridiosis_vaccine_button.text = _format_sanitary_cost("Vacinar %d bovinos" % clostridiosis_count,
		clostridiosis_cost, "clostridiosis")
	vitamin_supplement_button.text = _format_sanitary_cost(
		"Suporte por 30 dias", vitamin_cost, "vitamin"
	)
	parasite_treatment_button.disabled = (
		parasite_treatment_days_remaining > 0
		or cash_balance < treatment_cost
		or not active_service_order.is_empty()
	)
	brucellosis_vaccine_button.disabled = (
		eligible_count <= 0
		or cash_balance < vaccination_cost
		or not active_service_order.is_empty()
	)
	clinical_medication_button.disabled = (
		clinical_count <= 0
		or clinical_medication_days_remaining > 0
		or cash_balance < medication_cost
		or not active_service_order.is_empty()
	)
	clostridiosis_vaccine_button.disabled = (
		clostridiosis_count <= 0
		or cash_balance < clostridiosis_cost
		or not active_service_order.is_empty()
	)
	vitamin_supplement_button.disabled = (
		vitamin_supplement_days_remaining > 0
		or cash_balance < vitamin_cost
		or not active_service_order.is_empty()
	)


func _format_sanitary_cost(label: String, cost: int, action: String) -> String:
	return "%s — R$ %s" % [label, EconomyService.format_money(cost)]


static func _eligible_brucellosis_calves(herd_animals: Array) -> Array:
	var result: Array = []
	for animal in herd_animals:
		if (
			str(animal.get("category", "")) == "female_calves"
			and not bool(animal.get("brucellosis_vaccinated", false))
		):
			result.append(animal)
	return result


static func _clinical_treatment_candidates(herd_animals: Array) -> Array:
	var result: Array = []
	for animal in herd_animals:
		var state_text := str(animal.get("sanitary_state", "Saudável"))
		if state_text != "Saudável" and int(animal.get("clinical_treated", 0)) == 0:
			result.append(animal)
	return result


static func _eligible_clostridiosis_animals(herd_animals: Array) -> Array:
	var result: Array = []
	for animal in herd_animals:
		if int(animal.get("clostridiosis_vaccine_days_remaining", 0)) == 0:
			result.append(animal)
	return result
