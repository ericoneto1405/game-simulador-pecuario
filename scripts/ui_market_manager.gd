class_name MarketUiManager

const MARKET_TRANSPORT_BASE_COST := 250
const MARKET_TRANSPORT_COST_PER_ANIMAL := 50
const MARKET_DOCUMENT_BASE_COST := 100
const MARKET_BUY_PRICE_PER_KG := {
	"female_calves": 12.0,
	"male_calves": 11.5,
	"heifers": 9.0,
	"cows": 7.0,
	"steers": 8.5,
	"oxen": 7.5,
	"bulls": 9.5,
}
const MARKET_SELL_PRICE_FACTOR := 0.95
const DEFAULT_CATTLE_BREED := "nelore"

var market_info: Label
var market_mode_selector: OptionButton
var market_category_selector: OptionButton
var market_quantity_selector: SpinBox
var breed_selector: OptionButton
var buy_animals_button: Button
var market_sale_filter: OptionButton
var market_sale_list: ItemList
var market_select_all_button: Button
var market_clear_selection_button: Button
var sell_animals_button: Button
var sidebar_content: Control
var sidebar_scroll: ScrollContainer

var _format_money_fn: Callable
var _has_livestock_area_fn: Callable
var _formed_paddock_count_fn: Callable
var _using_general_farm_area_fn: Callable
var _selected_market_breed_fn: Callable
var _animal_category_display_name_fn: Callable
var _breed_display_name_fn: Callable
var _normalize_breed_fn: Callable


func _init(
	p_market_info: Label,
	p_market_mode_selector: OptionButton,
	p_market_category_selector: OptionButton,
	p_market_quantity_selector: SpinBox,
	p_breed_selector: OptionButton,
	p_buy_animals_button: Button,
	p_market_sale_filter: OptionButton,
	p_market_sale_list: ItemList,
	p_market_select_all_button: Button,
	p_market_clear_selection_button: Button,
	p_sell_animals_button: Button,
	p_sidebar_content: Control,
	p_sidebar_scroll: ScrollContainer,
	p_format_money_fn: Callable,
	p_has_livestock_area_fn: Callable,
	p_formed_paddock_count_fn: Callable,
	p_using_general_farm_area_fn: Callable,
	p_selected_market_breed_fn: Callable,
	p_animal_category_display_name_fn: Callable,
	p_breed_display_name_fn: Callable,
	p_normalize_breed_fn: Callable
) -> void:
	market_info = p_market_info
	market_mode_selector = p_market_mode_selector
	market_category_selector = p_market_category_selector
	market_quantity_selector = p_market_quantity_selector
	breed_selector = p_breed_selector
	buy_animals_button = p_buy_animals_button
	market_sale_filter = p_market_sale_filter
	market_sale_list = p_market_sale_list
	market_select_all_button = p_market_select_all_button
	market_clear_selection_button = p_market_clear_selection_button
	sell_animals_button = p_sell_animals_button
	sidebar_content = p_sidebar_content
	sidebar_scroll = p_sidebar_scroll
	_format_money_fn = p_format_money_fn
	_has_livestock_area_fn = p_has_livestock_area_fn
	_formed_paddock_count_fn = p_formed_paddock_count_fn
	_using_general_farm_area_fn = p_using_general_farm_area_fn
	_selected_market_breed_fn = p_selected_market_breed_fn
	_animal_category_display_name_fn = p_animal_category_display_name_fn
	_breed_display_name_fn = p_breed_display_name_fn
	_normalize_breed_fn = p_normalize_breed_fn


func update_readiness(state: Dictionary) -> void:
	refresh_sale_list(state)
	market_info.text = rules_text(state)
	sell_animals_button.disabled = market_sale_list.get_selected_items().is_empty()


func update_mode(state: Dictionary) -> void:
	var buying := selected_mode() == "buy"
	for control in [
		sidebar_content.get_node("MarketBuyTitle"),
		sidebar_content.get_node("MarketCategorySelectorLabel"),
		market_category_selector,
		sidebar_content.get_node("BreedSelectorLabel"),
		breed_selector,
		sidebar_content.get_node("MarketQuantitySelectorLabel"),
		market_quantity_selector,
		buy_animals_button,
	]:
		control.visible = buying
	for control in [
		sidebar_content.get_node("MarketSellTitle"),
		sidebar_content.get_node("MarketSaleFilterLabel"),
		market_sale_filter,
		market_sale_list,
		market_select_all_button,
		market_clear_selection_button,
		sell_animals_button,
	]:
		control.visible = not buying
	market_info.custom_minimum_size.y = 230.0 if buying else 145.0
	market_info.text = rules_text(state)


func on_mode_selected(state: Dictionary) -> void:
	update_readiness(state)
	update_mode(state)
	sidebar_scroll.scroll_vertical = 0


func on_offer_changed(state: Dictionary) -> void:
	market_info.text = rules_text(state)


func on_quantity_changed(state: Dictionary) -> void:
	market_info.text = rules_text(state)


func on_sale_selection_changed(state: Dictionary) -> void:
	sell_animals_button.disabled = market_sale_list.get_selected_items().is_empty()
	market_info.text = rules_text(state)


func on_sale_filter_changed(state: Dictionary) -> void:
	refresh_sale_list(state)
	sell_animals_button.disabled = true
	market_info.text = rules_text(state)


func select_all() -> void:
	for item_index in range(market_sale_list.item_count):
		market_sale_list.select(item_index, false)
	sell_animals_button.disabled = market_sale_list.get_selected_items().is_empty()
	market_info.text = rules_text({})


func clear_selection() -> void:
	market_sale_list.deselect_all()
	sell_animals_button.disabled = true
	market_info.text = rules_text({})


func selected_mode() -> String:
	if market_mode_selector.item_count <= 0:
		return "buy"
	return str(market_mode_selector.get_selected_metadata())


func selected_category() -> String:
	if market_category_selector.item_count <= 0:
		return "heifers"
	return str(market_category_selector.get_selected_metadata())


func selected_quantity() -> int:
	return maxi(int(market_quantity_selector.value), 1)


func purchase_quote(state: Dictionary) -> Dictionary:
	var category := selected_category()
	var quantity := selected_quantity()
	var profile := category_profile(category, state)
	var animal_price := roundi(
		float(profile["weight_kg"]) * float(MARKET_BUY_PRICE_PER_KG.get(category, 10.0))
	)
	var costs := transaction_costs(quantity)
	var animals_total := animal_price * quantity
	return {
		"category": category,
		"quantity": quantity,
		"age_days": int(profile["age_days"]),
		"weight_kg": float(profile["weight_kg"]),
		"animal_price": animal_price,
		"animals_total": animals_total,
		"transport": int(costs["transport"]),
		"documents": int(costs["documents"]),
		"total": animals_total + int(costs["transport"]) + int(costs["documents"]),
	}


func sale_quote(state: Dictionary) -> Dictionary:
	var selected_animals := selected_sale_animals(state)
	var gross_total := 0
	var pregnant_count := 0
	var sanitary_alerts := 0
	for animal in selected_animals:
		var cat := str(animal.get("category", "heifers"))
		gross_total += roundi(
			float(animal.get("weight_kg", 0.0))
			* float(MARKET_BUY_PRICE_PER_KG.get(cat, 10.0))
			* MARKET_SELL_PRICE_FACTOR
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


func projected_capacity(state: Dictionary) -> Dictionary:
	if not _has_livestock_area_fn.call():
		return {"available": false}
	var herd_created: bool = state.get("herd_created", false)
	var herd_pasture: int = state.get("herd_pasture", 1)
	var herd_size: int = state.get("herd_size", 0)
	var average_weight_kg: float = state.get("average_weight_kg", 385.0)
	var vegetation_manager: Node = state.get("vegetation_manager")
	var area_id := herd_pasture if herd_created else 1
	var category := selected_category()
	var quantity := selected_quantity()
	var profile := category_profile(category, state)
	var projected_size := herd_size + quantity
	var projected_weight := (
		average_weight_kg * herd_size + float(profile["weight_kg"]) * quantity
	) / maxf(float(projected_size), 1.0)
	return {
		"available": true,
		"herd_size": projected_size,
		"capacity": vegetation_manager.capacity_animals(area_id, projected_weight),
	}


func refresh_sale_list(state: Dictionary) -> void:
	var herd_animals: Array = state.get("herd_animals", [])
	market_sale_list.clear()
	var category_filter := "all"
	if market_sale_filter.item_count > 0:
		category_filter = str(market_sale_filter.get_selected_metadata())
	for animal in herd_animals:
		var cat := str(animal.get("category", "heifers"))
		if category_filter != "all" and cat != category_filter:
			continue
		var price := roundi(
			float(animal.get("weight_kg", 0.0))
			* float(MARKET_BUY_PRICE_PER_KG.get(cat, 10.0))
			* MARKET_SELL_PRICE_FACTOR
		)
		var reproductive_state := " | PRENHE" if bool(animal.get("pregnant", false)) else ""
		market_sale_list.add_item("%s • %s • %.0f kg%s • R$ %s" % [
			str(animal.get("id", "")),
			_animal_category_display_name_fn.call(cat),
			float(animal.get("weight_kg", 0.0)),
			reproductive_state,
			_format_money_fn.call(price),
		])
		var item_index := market_sale_list.item_count - 1
		market_sale_list.set_item_metadata(item_index, str(animal.get("id", "")))
		market_sale_list.set_item_tooltip(item_index, "%s\nRaça: %s\nIdade: %d meses\nSanidade: %s" % [
			str(animal.get("id", "")),
			_breed_display_name_fn.call(str(animal.get("breed", DEFAULT_CATTLE_BREED))),
			int(animal.get("age_days", 0)) / 30,
			str(animal.get("sanitary_state", "Saudável")),
		])


func rules_text(state: Dictionary, event_message: String = "") -> String:
	var sale := sale_quote(state)
	if selected_mode() == "sell":
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
				int(sale["quantity"]), _format_money_fn.call(int(sale["gross"])),
				_format_money_fn.call(int(sale["costs"])), _format_money_fn.call(int(sale["net"])),
			]
			if int(sale["pregnant"]) > 0:
				sale_text += "\nATENÇÃO: inclui %d fêmea(s) prenhe(s)." % int(sale["pregnant"])
			if int(sale["sanitary_alerts"]) > 0:
				sale_text += "\nATENÇÃO: %d animal(is) com alerta sanitário." % int(sale["sanitary_alerts"])
		if event_message.is_empty():
			return sale_text
		return "%s\n\n%s" % [event_message, sale_text]

	var herd_created: bool = state.get("herd_created", false)
	var cash_balance: int = state.get("cash_balance", 0)
	var gate_installed: bool = state.get("gate_installed", false)

	var area_text := "pendente"
	if _using_general_farm_area_fn.call():
		area_text = "pronta — área geral"
	elif _formed_paddock_count_fn.call() >= 1:
		area_text = "pronta — pasto formado"
	var gate_text := "pronta" if gate_installed else "pendente"
	var purchase := purchase_quote(state)
	var cash_text := "suficiente" if cash_balance >= int(purchase["total"]) else "insuficiente"
	var proj := projected_capacity(state)
	var capacity_text := "indisponível sem área cercada"
	if bool(proj.get("available", false)):
		capacity_text = "%d animais para capacidade estimada de %d" % [
			int(proj["herd_size"]), int(proj["capacity"]),
		]
		if int(proj["herd_size"]) > int(proj["capacity"]):
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
		_animal_category_display_name_fn.call(str(purchase["category"])).to_lower(),
		_breed_display_name_fn.call(_selected_market_breed_fn.call()),
		int(purchase["age_days"]) / 30,
		float(purchase["weight_kg"]),
		_format_money_fn.call(int(purchase["animal_price"])),
		_format_money_fn.call(int(purchase["animals_total"])),
		_format_money_fn.call(int(purchase["transport"])),
		_format_money_fn.call(int(purchase["documents"])),
		_format_money_fn.call(int(purchase["total"])),
		_format_money_fn.call(maxi(cash_balance - int(purchase["total"]), 0)),
		area_text,
		gate_text,
		cash_text,
		capacity_text,
	]
	if event_message.is_empty():
		return rules
	return "%s\n\n%s" % [event_message, rules]


func selected_sale_animals(state: Dictionary) -> Array[Dictionary]:
	var herd_animals: Array = state.get("herd_animals", [])
	var selected_animals: Array[Dictionary] = []
	for item_index in market_sale_list.get_selected_items():
		var animal_id := str(market_sale_list.get_item_metadata(item_index))
		for animal in herd_animals:
			if str(animal.get("id", "")) == animal_id:
				selected_animals.append(animal)
				break
	return selected_animals


func category_profile(category: String, state: Dictionary) -> Dictionary:
	var average_weight_kg: float = state.get("average_weight_kg", 385.0)
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
		"weight_kg": float(weight_by_category.get(category, average_weight_kg)),
	}


static func transaction_costs(quantity: int) -> Dictionary:
	return {
		"transport": MARKET_TRANSPORT_BASE_COST + MARKET_TRANSPORT_COST_PER_ANIMAL * quantity,
		"documents": MARKET_DOCUMENT_BASE_COST,
	}
