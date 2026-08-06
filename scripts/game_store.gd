class_name GameStore

const STARTING_CASH := 50000

# Calendar
var current_day := 1
var day_of_year := 305
var current_year := 1

# Herd
var herd_created := false
var herd_size := 0
var herd_animals: Array[Dictionary] = []
var next_animal_id := 1
var herd_pasture := 1
var herd_categories := {
	"female_calves": 0,
	"male_calves": 0,
	"heifers": 0,
	"cows": 0,
	"steers": 0,
	"oxen": 0,
	"bulls": 0,
}
var herd_genetics := {
	"fertility": 82.0,
	"calving_ease": 85.0,
	"heat_adaptation": 78.0,
	"parasite_resistance": 72.0,
	"weight_gain": 70.0,
	"maternal_ability": 68.0,
}
var offspring_genetics: Dictionary = {}

# Animal condition
var average_weight_kg := 300.0
var body_condition := 3.0
var hunger := 0.0
var thirst := 0.0
var health := 100.0
var herd_had_water_today := true

# Reproduction
var pregnant_females := 0
var gestation_days_remaining := 0
var calf_age_days := -1
var breeding_method := ""

# Forage / Pasture
var forage := {1: 100.0, 2: 100.0}
var pasture_quality := {1: 75.0, 2: 75.0}
var pasture_degradation := {1: 0.0, 2: 0.0}
var pasture_capacity := {1: 12, 2: 12}

# Soil
var soil_moisture := {1: 62.0, 2: 38.0}
var soil_fertility := {1: 78.0, 2: 48.0}
var soil_compaction := {1: 12.0, 2: 8.0}
var soil_erosion := {1: 4.0, 2: 12.0}
var soil_daily_runoff := {1: 0.0, 2: 0.0}

# Water
var pond_level := {1: 70.0, 2: 70.0}
var river_level := 65.0

# Climate
var rainfall_mm := 0.0
var max_temperature_c := 33.0
var consecutive_dry_days := 0
var weather_condition := "Seco"
var heat_stress := 0.0

# Nutrition
var mineral_stock_kg := 0.0
var supplement_stock_kg := 0.0

# Sanitary
var parasite_pressure := 0.0
var parasite_treatment_days_remaining := 0
var clinical_medication_days_remaining := 0
var vitamin_supplement_days_remaining := 0
var sanitary_last_event := "Sem ocorrências sanitárias."
var active_service_order: Dictionary = {}
var last_cowboy_activity := ""

# Agriculture
var selected_crop_index := 0
var field_state := "idle"
var crop_days_elapsed := 0
var stored_feed_kg := {
	"silage": 0.0,
	"fresh_forage": 0.0,
	"hay": 0.0,
}
var feeding_plan_days_remaining := 0

# Economy
var cash_balance := STARTING_CASH
var transaction_history: Array = []

# Vegetation
var vegetation_last_event := "Vegetação acompanhada diariamente."
