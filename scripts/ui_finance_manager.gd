class_name FinanceUiManager

var cash_status: Label
var finance_status: Label
var buy_animals_button: Button
var sell_animals_button: Button
var market_sale_list: ItemList


func _init(
	p_cash_status: Label,
	p_finance_status: Label,
	p_buy_animals_button: Button,
	p_sell_animals_button: Button,
	p_market_sale_list: ItemList
) -> void:
	cash_status = p_cash_status
	finance_status = p_finance_status
	buy_animals_button = p_buy_animals_button
	sell_animals_button = p_sell_animals_button
	market_sale_list = p_market_sale_list


func update(state: Dictionary) -> void:
	var cash_balance: int = state.get("cash_balance", 0)
	var transaction_history: Array = state.get("transaction_history", [])

	cash_status.text = "CAIXA\nR$ %s" % EconomyService.format_money(cash_balance)
	var history_text := "Nenhuma movimentação registrada."

	if not transaction_history.is_empty():
		var history_lines: Array[String] = []
		for transaction in transaction_history.slice(0, 3):
			var amount := int(transaction.get("amount", 0))
			var signal_text := "+" if amount >= 0 else "-"
			history_lines.append("D%d | %s R$ %s | %s" % [
				int(transaction.get("day", 1)),
				signal_text,
				EconomyService.format_money(absi(amount)),
				str(transaction.get("description", "")),
			])
		history_text = "\n".join(history_lines)

	finance_status.text = "Saldo: R$ %s\nCustos separados entre insumos, materiais e mão de obra.\n%s" % [
		EconomyService.format_money(cash_balance),
		history_text,
	]
	buy_animals_button.disabled = false
	sell_animals_button.disabled = market_sale_list.get_selected_items().is_empty()
