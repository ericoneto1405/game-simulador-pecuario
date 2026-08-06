class_name MarketService

const MARKET_TRANSPORT_BASE_COST := 250
const MARKET_TRANSPORT_COST_PER_ANIMAL := 50
const MARKET_DOCUMENT_BASE_COST := 100


static func category_profile(category: String) -> Dictionary:
	var age_by_category := {
		"female_calves": 90,
		"male_calves": 90,
		"heifers": 520,
		"cows": 1100,
		"steers": 520,
		"oxen": 900,
		"bulls": 1100,
	}
	var weight_by_category := {
		"female_calves": 105.0,
		"male_calves": 115.0,
		"heifers": 285.0,
		"cows": 410.0,
		"steers": 320.0,
		"oxen": 480.0,
		"bulls": 620.0,
	}
	return {
		"age_days": int(age_by_category.get(category, 520)),
		"weight_kg": float(weight_by_category.get(category, 300.0)),
	}


static func transaction_costs(quantity: int) -> Dictionary:
	return {
		"transport": MARKET_TRANSPORT_BASE_COST + MARKET_TRANSPORT_COST_PER_ANIMAL * quantity,
		"documents": MARKET_DOCUMENT_BASE_COST,
	}


static func purchase_quote(
	category: String,
	quantity: int,
	market_breed: String,
	cash_balance: int
) -> Dictionary:
	var profile := category_profile(category)
	var animal_price := roundi(
		float(profile["weight_kg"]) * float(EconomyService.MARKET_BUY_PRICE_PER_KG.get(category, 10.0))
	)
	var costs := transaction_costs(quantity)
	var animals_total := animal_price * quantity
	return {
		"category": category,
		"quantity": quantity,
		"breed": market_breed,
		"age_days": int(profile["age_days"]),
		"weight_kg": float(profile["weight_kg"]),
		"animal_price": animal_price,
		"animals_total": animals_total,
		"transport": int(costs["transport"]),
		"documents": int(costs["documents"]),
		"total": animals_total + int(costs["transport"]) + int(costs["documents"]),
	}


static func sale_quote(selected_animals: Array) -> Dictionary:
	var gross_total := 0
	var pregnant_count := 0
	var sanitary_alerts := 0
	for animal in selected_animals:
		var cat := str(animal.get("category", "heifers"))
		gross_total += roundi(
			float(animal.get("weight_kg", 0.0))
			* float(EconomyService.MARKET_BUY_PRICE_PER_KG.get(cat, 10.0))
			* EconomyService.MARKET_SELL_PRICE_FACTOR
		)
		if bool(animal.get("pregnant", false)):
			pregnant_count += 1
		if str(animal.get("sanitary_state", "Saudável")) != "Saudável":
			sanitary_alerts += 1
	var costs := transaction_costs(selected_animals.size())
	var transaction_cost := 0
	if not selected_animals.is_empty():
		transaction_cost = int(costs["transport"]) + int(costs["documents"])
	return {
		"quantity": selected_animals.size(),
		"gross": gross_total,
		"costs": transaction_cost,
		"net": maxi(gross_total - transaction_cost, 0),
		"pregnant": pregnant_count,
		"sanitary_alerts": sanitary_alerts,
	}


static func validate_purchase(
	has_livestock_area: bool,
	gate_installed: bool,
	cash_balance: int,
	purchase_total: int
) -> Dictionary:
	if not has_livestock_area:
		return {
			"valid": false,
			"message": "Falta uma área cercada.\n"
				+ "Cerque toda a propriedade ou forme um pasto na Loja Rural."
		}
	if not gate_installed:
		return {
			"valid": false,
			"message": "Falta uma porteira.\n"
				+ "Compre na Loja Rural e clique sobre a cerca construída."
		}
	if cash_balance < purchase_total:
		return {
			"valid": false,
			"message": "Caixa insuficiente.\nCompra: R$ %s | Saldo: R$ %s" % [
				EconomyService.format_money(purchase_total),
				EconomyService.format_money(cash_balance),
			]
		}
	return {"valid": true}


static func validate_sale(selected_animals: Array) -> Dictionary:
	if selected_animals.is_empty():
		return {
			"valid": false,
			"message": "Selecione ao menos um animal para vender."
		}
	return {"valid": true}


static func remove_animals_from_herd(
	herd_animals: Array,
	selected_animals: Array
) -> Array[Dictionary]:
	var selected_ids := {}
	for animal in selected_animals:
		selected_ids[str(animal.get("id", ""))] = true
	var remaining: Array[Dictionary] = []
	for animal in herd_animals:
		if not selected_ids.has(str(animal.get("id", ""))):
			remaining.append(animal)
	return remaining


static func reset_reproduction_after_sale(
	herd_categories: Dictionary,
	herd_animals: Array
) -> Dictionary:
	var pregnant_females := 0
	for animal in herd_animals:
		if bool(animal.get("pregnant", false)):
			pregnant_females += 1
	var calf_count := int(herd_categories.get("female_calves", 0)) + int(herd_categories.get("male_calves", 0))
	return {
		"pregnant_females": pregnant_females,
		"gestation_days_remaining": 0 if pregnant_females == 0 else -1,
		"breeding_method": "" if pregnant_females == 0 else -1,
		"calf_age_days": -1 if calf_count == 0 else 0,
	}


static func sale_list_entry(animal: Dictionary, format_money_fn: Callable) -> Dictionary:
	var category := str(animal.get("category", "heifers"))
	var price := roundi(
		float(animal.get("weight_kg", 0.0))
		* float(EconomyService.MARKET_BUY_PRICE_PER_KG.get(category, 10.0))
		* EconomyService.MARKET_SELL_PRICE_FACTOR
	)
	var reproductive_state := " | PRENHE" if bool(animal.get("pregnant", false)) else ""
	return {
		"text": "%s • %s • %.0f kg%s • R$ %s" % [
			str(animal.get("id", "")),
			category,
			float(animal.get("weight_kg", 0.0)),
			reproductive_state,
			format_money_fn.call(price),
		],
		"metadata": str(animal.get("id", "")),
		"tooltip": "%s\nRaça: %s\nIdade: %d meses\nSanidade: %s" % [
			str(animal.get("id", "")),
			str(animal.get("breed", EconomyService.DEFAULT_CATTLE_BREED)),
			int(animal.get("age_days", 0)) / 30,
			str(animal.get("sanitary_state", "Saudável")),
		],
	}


static func rules_text(
	event_message: String,
	sale_mode: bool,
	sale: Dictionary,
	purchase: Dictionary,
	cash_balance: int,
	has_livestock_area: bool,
	using_general_area: bool,
	paddock_count: int,
	gate_installed: bool,
	format_money_fn: Callable,
	projected_capacity: Dictionary = {}
) -> String:
	if sale_mode:
		var sale_text := (
			"Selecione os animais na lista abaixo.\n"
			+ "O valor líquido já desconta transporte e documentação."
		)
		if int(sale["quantity"]) > 0:
			sale_text = (
				"%d animal(is) selecionado(s)\n"
				+ "Bruto: R$ %s | Custos: R$ %s\n"
				+ "VALOR LÍQUIDO: R$ %s"
			) % [
				int(sale["quantity"]),
				format_money_fn.call(int(sale["gross"])),
				format_money_fn.call(int(sale["costs"])),
				format_money_fn.call(int(sale["net"])),
			]
			if int(sale["pregnant"]) > 0:
				sale_text += "\nATENÇÃO: inclui %d fêmea(s) prenhe(s)." % int(sale["pregnant"])
			if int(sale["sanitary_alerts"]) > 0:
				sale_text += "\nATENÇÃO: %d animal(is) com alerta sanitário." % int(sale["sanitary_alerts"])
		if event_message.is_empty():
			return sale_text
		return "%s\n\n%s" % [event_message, sale_text]

	var area_text := "pendente"
	if using_general_area:
		area_text = "pronta — área geral"
	elif paddock_count >= 1:
		area_text = "pronta — pasto formado"
	var gate_text := "pronta" if gate_installed else "pendente"
	var cash_text := "suficiente" if cash_balance >= int(purchase["total"]) else "insuficiente"
	var capacity_text := "indisponível sem área cercada"
	if bool(projected_capacity.get("available", false)):
		capacity_text = "%d animais para capacidade estimada de %d" % [
			int(projected_capacity["herd_size"]), int(projected_capacity["capacity"]),
		]
		if int(projected_capacity["herd_size"]) > int(projected_capacity["capacity"]):
			capacity_text += " — SUPERLOTAÇÃO"
	var rules := (
		"%d %s • %s\n"
		+ "%d meses • %.0f kg por animal • R$ %s/cabeça\n\n"
		+ "Animais: R$ %s\n"
		+ "+ Transporte: R$ %s | + Documentos: R$ %s\n"
		+ "TOTAL: R$ %s\n"
		+ "Saldo depois da compra: R$ %s\n\n"
		+ "ESTRUTURA\n"
		+ "Área: %s | Porteira: %s | Caixa: %s\n"
		+ "Lotação: %s"
	) % [
		int(purchase["quantity"]),
		str(purchase["category"]).capitalize(),
		str(purchase.get("breed", "")),
		int(purchase["age_days"]) / 30,
		float(purchase["weight_kg"]),
		format_money_fn.call(int(purchase["animal_price"])),
		format_money_fn.call(int(purchase["animals_total"])),
		format_money_fn.call(int(purchase["transport"])),
		format_money_fn.call(int(purchase["documents"])),
		format_money_fn.call(int(purchase["total"])),
		format_money_fn.call(maxi(cash_balance - int(purchase["total"]), 0)),
		area_text,
		gate_text,
		cash_text,
		capacity_text,
	]
	if event_message.is_empty():
		return rules
	return "%s\n\n%s" % [event_message, rules]
