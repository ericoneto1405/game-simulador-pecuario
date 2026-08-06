class_name EconomyService

const TRANSACTION_HISTORY_LIMIT := 8
const STARTING_CASH := 50000
const PURCHASE_PRICE_PER_ANIMAL := 3000
const SALE_PRICE_PER_ANIMAL := 2850
const MARKET_BUY_PRICE_PER_KG := {
	"female_calves": 12.5,
	"male_calves": 13.0,
	"heifers": 10.2,
	"cows": 8.2,
	"steers": 10.8,
	"oxen": 9.6,
	"bulls": 12.0,
}
const MARKET_SELL_PRICE_FACTOR := 0.95
const DEFAULT_CATTLE_BREED := "nelore"
const CATTLE_BREEDS := [
	{"key": "nelore", "name": "Nelore"},
	{"key": "nelore_pintado", "name": "Nelore Pintado"},
	{"key": "guzera", "name": "Guzerá"},
	{"key": "brahman", "name": "Brahman"},
	{"key": "tabapua", "name": "Tabapuã"},
	{"key": "sindi", "name": "Sindi"},
	{"key": "angus", "name": "Angus"},
	{"key": "hereford", "name": "Hereford"},
	{"key": "brangus", "name": "Brangus"},
	{"key": "braford", "name": "Braford"},
	{"key": "senepol", "name": "Senepol"},
]


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
