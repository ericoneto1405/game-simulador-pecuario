class_name EconomyService

const TRANSACTION_HISTORY_LIMIT := 8


static func format_money(value: int) -> String:
	var text := str(value)
	var formatted := ""
	while text.length() > 3:
		formatted = "." + text.right(3) + formatted
		text = text.left(text.length() - 3)
	return text + formatted


static func record_transaction(
	transaction_history: Array,
	description: String,
	amount: int,
	day: int,
	formatted_date: String
) -> int:
	var new_balance := maxi(0, 0)
	transaction_history.push_front({
		"day": day,
		"date": formatted_date,
		"description": description,
		"amount": amount,
	})
	if transaction_history.size() > TRANSACTION_HISTORY_LIMIT:
		transaction_history.resize(TRANSACTION_HISTORY_LIMIT)
	return new_balance
