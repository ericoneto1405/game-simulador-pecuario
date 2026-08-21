extends Node2D

const VegetationManagerClass := preload("res://scripts/vegetation_manager.gd")

enum DivisionMode {
	NONE,
	HORIZONTAL,
	VERTICAL,
}

enum BuildMode {
	NONE,
	BARBED_FENCE,
	SMOOTH_FENCE,
	ELECTRIC_FENCE,
	GATE,
	CORRAL,
	SCALE,
}

const FARM_WIDTH := 3200.0
const FARM_HEIGHT := 1800.0
const FARM_AREA_BAHIA_TASKS := 595.0
const SQUARE_METERS_PER_BAHIA_TASK := 4356.0
const FARM_AREA_SQUARE_METERS := 2591820.0
const FARM_AREA_HECTARES := 259.182
const METERS_PER_MAP_UNIT := 0.670797097
const HORIZONTAL_MIN := 550.0
const HORIZONTAL_MAX := 1050.0
const VERTICAL_MIN := 950.0
const VERTICAL_MAX := 2150.0
const GATE_LENGTH := 24.0
var save_path: String
const SAVE_VERSION := 19
const CALENDAR_365_SAVE_VERSION := 15
const SERVER_TIME_SYNC_INTERVAL_SECONDS := 300.0
const AUTO_SAVE_INTERVAL_SECONDS := 60.0
const OFFLINE_DAYS_PER_FRAME := 30
const FARM_TIMEZONE := "America/Bahia"
const CLIMATE_ICON_DROUGHT := preload("res://assets/ui/icons/climate-drought.svg")
const CLIMATE_ICON_TRANSITION := preload("res://assets/ui/icons/climate-transition.svg")
const CLIMATE_ICON_RAINY := preload("res://assets/ui/icons/climate-rainy.svg")
const STARTING_CASH := 50000
const PURCHASE_PRICE_PER_ANIMAL := 3000
const SALE_PRICE_PER_ANIMAL := 2850
const MARKET_TRANSPORT_BASE_COST := 250
const MARKET_TRANSPORT_COST_PER_ANIMAL := 50
const MARKET_DOCUMENT_BASE_COST := 100
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
const TOTAL_FARM_CAPACITY := 24
const MINERAL_PACKAGE_KG := 25.0
const MINERAL_PACKAGE_PRICE := 180
const MINERAL_DAILY_KG_PER_ANIMAL := 0.08
const SUPPLEMENT_PACKAGE_KG := 100.0
const SUPPLEMENT_PACKAGE_PRICE := 320
const SUPPLEMENT_DAILY_KG_PER_ANIMAL := 0.5
const PERIMETER_FENCE_COST := 3000
const INTERNAL_FENCE_COST := 1500
const GATE_COST := 500
const SOIL_PREPARATION_COST := 800
const FEEDING_PLAN_DAYS := 7
const DAILY_RESERVE_KG_PER_ANIMAL := 5.0
const ARTIFICIAL_INSEMINATION_COST := 1500
const PARASITE_TREATMENT_COST_PER_ANIMAL := 25
const BRUCELLOSIS_VACCINE_COST_PER_CALF := 40
const PARASITE_TREATMENT_PROTECTION_DAYS := 30
const CLINICAL_MEDICATION_COST_PER_ANIMAL := 60
const CLINICAL_MEDICATION_COOLDOWN_DAYS := 7
const CLOSTRIDIOSIS_VACCINE_COST_PER_ANIMAL := 20
const CLOSTRIDIOSIS_PROTECTION_DAYS := 365
const VITAMIN_SUPPLEMENT_COST_PER_ANIMAL := 15
const VITAMIN_SUPPLEMENT_DAYS := 30
const GESTATION_DAYS := 285
const WEANING_AGE_DAYS := 210
const WEANING_WEIGHT_KG := 210.0
const FIRST_BREEDING_WEIGHT_KG := 300.0
const BARBED_FENCE_COST_PER_100 := 120
const SMOOTH_FENCE_COST_PER_100 := 180
const ELECTRIC_FENCE_COST_PER_100 := 250
const FREE_GATE_COST := 500
const CORRAL_COST := 8000
const SCALE_COST := 4500
const FENCE_LABOR_RATE := 0.30
const GATE_LABOR_RATE := 0.35
const CORRAL_LABOR_RATE := 0.40
const SCALE_LABOR_RATE := 0.20
const VETERINARY_LABOR_RATE := 0.30
const COWBOY_SERVICE_RATE := 0.20
const CORRAL_SIZE := Vector2(90.0, 60.0)
const FENCE_CLOSURE_TOLERANCE := 350.0
const FENCE_POST_SPACING_METERS := 25.0
const MAX_FENCE_POST_VISUALS := 240
const FREE_GATE_VISUAL_LENGTH := 24.0
const TRANSACTION_HISTORY_LIMIT := 8
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
const GENETIC_TRAITS := ["fertility", "calving_ease", "heat_adaptation", "parasite_resistance", "weight_gain", "maternal_ability"]
const VISUAL_TRAITS := ["coat_color", "horn_type"]
const ALL_TRAITS := GENETIC_TRAITS + VISUAL_TRAITS
const LOCI_PER_TRAIT := 3
const PASTURE_1_COLOR := Color(0.39, 0.49, 0.25, 0.22)
const PASTURE_2_COLOR := Color(0.35, 0.45, 0.22, 0.22)
const DRY_PASTURE_COLOR := Color(0.56, 0.43, 0.22, 0.22)
const HEALTHY_PASTURE_COLOR := Color(0.35, 0.53, 0.22, 0.22)
const FIELD_IDLE_COLOR := Color(0.42, 0.31, 0.18, 0.82)
const FIELD_GROWING_COLOR := Color(0.26, 0.5, 0.19, 0.9)
const FIELD_READY_COLOR := Color(0.78, 0.66, 0.22, 0.92)
const FORAGE_CROPS := [
	{
		"name": "Milho para silagem",
		"days": 90,
		"planting_cost": 1200,
		"yield_kg": 30000.0,
		"product": "silage",
	},
	{
		"name": "Sorgo para silagem",
		"days": 80,
		"planting_cost": 900,
		"yield_kg": 26000.0,
		"product": "silage",
	},
	{
		"name": "Capiaçu",
		"days": 120,
		"planting_cost": 700,
		"yield_kg": 35000.0,
		"product": "fresh_forage",
	},
	{
		"name": "Palma forrageira",
		"days": 180,
		"planting_cost": 1000,
		"yield_kg": 20000.0,
		"product": "fresh_forage",
	},
	{
		"name": "Capim para feno",
		"days": 70,
		"planting_cost": 600,
		"yield_kg": 8000.0,
		"product": "hay",
	},
]
const MONTH_LENGTHS := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
var farm_visual_boundary := PackedVector2Array([
	Vector2(1613, 124), Vector2(1701, 222), Vector2(1879, 182),
	Vector2(1975, 262), Vector2(2147, 201), Vector2(2132, 331),
	Vector2(2073, 360), Vector2(2069, 432), Vector2(2322, 415),
	Vector2(2444, 440), Vector2(2465, 486), Vector2(2341, 606),
	Vector2(2312, 679), Vector2(2331, 740), Vector2(2945, 916),
	Vector2(2944, 1006), Vector2(2861, 1094), Vector2(2798, 1308),
	Vector2(2861, 1387), Vector2(2649, 1389), Vector2(2484, 1649),
	Vector2(2381, 1718), Vector2(2243, 1739), Vector2(1899, 1588),
	Vector2(1717, 1551), Vector2(1652, 1486), Vector2(1462, 1465),
	Vector2(1311, 1406), Vector2(1275, 1419), Vector2(1244, 1490),
	Vector2(1208, 1490), Vector2(1055, 1329), Vector2(804, 1152),
	Vector2(758, 1146), Vector2(544, 1308), Vector2(358, 1167),
	Vector2(419, 1102), Vector2(561, 1060), Vector2(649, 953),
	Vector2(540, 817), Vector2(471, 782), Vector2(268, 522),
	Vector2(157, 448), Vector2(142, 402), Vector2(306, 421),
	Vector2(373, 390), Vector2(423, 316), Vector2(561, 249),
	Vector2(691, 226), Vector2(746, 258), Vector2(846, 254),
	Vector2(930, 214), Vector2(1007, 360), Vector2(1100, 383),
	Vector2(1152, 350), Vector2(1183, 254), Vector2(1261, 187),
	Vector2(1355, 149), Vector2(1407, 189), Vector2(1508, 186),
])

@onready var pasture_1: Polygon2D = $Pasture1
@onready var pasture_2: Polygon2D = $Pasture2
@onready var pond_1: Polygon2D = $Pond1
@onready var pond_2: Polygon2D = $Pond2
@onready var pond_1_visual: Sprite2D = $Pond1Visual
@onready var pond_2_visual: Sprite2D = $Pond2Visual
@onready var intermittent_river: Sprite2D = $IntermittentRiver
@onready var river_label: Label = $RiverLabel
@onready var perimeter_fence: Line2D = $PerimeterFence
@onready var internal_fence: Line2D = $InternalFence
@onready var internal_fence_2: Line2D = $InternalFence2
@onready var gate: Line2D = $Gate
@onready var pasture_1_label: Label = $Pasture1Label
@onready var pasture_2_label: Label = $Pasture2Label
@onready var pond_1_label: Label = $Pond1Label
@onready var pond_2_label: Label = $Pond2Label
@onready var pond_1_gauge: Node2D = $Pond1Gauge
@onready var pond_2_gauge: Node2D = $Pond2Gauge
@onready var herd_marker: Label = $HerdMarker
@onready var herd_visuals: Node2D = $HerdVisuals
@onready var cowboy_visual: Node2D = $CowboyVisual
@onready var cowboy_sprite: AnimatedSprite2D = $CowboyVisual/Sprite
@onready var construction_crew_visual: Node2D = $ConstructionCrewVisual
@onready var construction_worker_1: AnimatedSprite2D = $ConstructionCrewVisual/Worker1
@onready var construction_worker_2: AnimatedSprite2D = $ConstructionCrewVisual/Worker2
@onready var construction_worker_3: AnimatedSprite2D = $ConstructionCrewVisual/Worker3
@onready var player_structures: Node2D = $PlayerStructures
@onready var construction_preview: Line2D = $PlayerStructures/ConstructionPreview
@onready var forage_field: Polygon2D = $ForageField
@onready var forage_field_label: Label = $ForageFieldLabel
@onready var property_label: Label = $PropertyLabel
@onready var status_label: Label = %SetupStatus
@onready var message_label: Label = %SetupMessage
@onready var perimeter_button: Button = %PerimeterButton
@onready var horizontal_button: Button = %HorizontalButton
@onready var vertical_button: Button = %VerticalButton
@onready var cancel_button: Button = %CancelButton
@onready var gate_install_button: Button = %GateInstallButton
@onready var herd_status: Label = %HerdStatus
@onready var herd_selection_info: Label = %HerdSelectionInfo
@onready var rebanho_hint: Label = %RebanhoHint
@onready var rebanho_list: ItemList = %RebanhoList
@onready var rebanho_detail_label: RichTextLabel = %RebanhoDetailLabel
@onready var select_herd_button: Button = %SelectHerdButton
@onready var transfer_herd_button: Button = %TransferHerdButton
@onready var service_order_status: Label = %ServiceOrderStatus
@onready var reproduction_status: Label = %ReproductionStatus
@onready var natural_breeding_button: Button = %NaturalBreedingButton
@onready var insemination_button: Button = %InseminationButton
@onready var sanitary_status: Label = %SanitaryStatus
@onready var parasite_treatment_button: Button = %ParasiteTreatmentButton
@onready var clinical_medication_button: Button = %ClinicalMedicationButton
@onready var brucellosis_vaccine_button: Button = %BrucellosisVaccineButton
@onready var clostridiosis_vaccine_button: Button = %ClostridiosisVaccineButton
@onready var vitamin_supplement_button: Button = %VitaminSupplementButton
@onready var market_info: Label = %MarketInfo
@onready var market_mode_selector: OptionButton = %MarketModeSelector
@onready var market_category_selector: OptionButton = %MarketCategorySelector
@onready var breed_selector: OptionButton = %BreedSelector
@onready var market_quantity_selector: SpinBox = %MarketQuantitySelector
@onready var buy_animals_button: Button = %BuyAnimalsButton
@onready var market_sale_filter: OptionButton = %MarketSaleFilter
@onready var market_sale_list: ItemList = %MarketSaleList
@onready var market_select_all_button: Button = %MarketSelectAllButton
@onready var market_clear_selection_button: Button = %MarketClearSelectionButton
@onready var sell_animals_button: Button = %SellAnimalsButton
@onready var nutrition_status: Label = %NutritionStatus
@onready var vegetation_species_selector: OptionButton = %VegetationSpeciesSelector
@onready var vegetation_rest_button: Button = %VegetationRestButton
@onready var vegetation_form_button: Button = %VegetationFormButton
@onready var vegetation_fertilize_button: Button = %VegetationFertilizeButton
@onready var vegetation_recover_button: Button = %VegetationRecoverButton
@onready var buy_mineral_button: Button = %BuyMineralButton
@onready var buy_supplement_button: Button = %BuySupplementButton
@onready var water_status: Label = %WaterStatus
@onready var agriculture_status: Label = %AgricultureStatus
@onready var select_crop_button: Button = %SelectCropButton
@onready var prepare_soil_button: Button = %PrepareSoilButton
@onready var plant_crop_button: Button = %PlantCropButton
@onready var harvest_crop_button: Button = %HarvestCropButton
@onready var use_feed_reserve_button: Button = %UseFeedReserveButton
@onready var climate_icon: TextureRect = %ClimateIcon
@onready var climate_status: Label = %ClimateStatus
@onready var cash_status: Label = %CashStatus
@onready var finance_status: Label = %FinanceStatus
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var save_status: Label = %SaveStatus
@onready var server_time_request: HTTPRequest = $ServerTimeRequest
@onready var offline_report_dialog: AcceptDialog = %OfflineReportDialog
@onready var sidebar_content: VBoxContainer = $Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent
@onready var sidebar_margin: MarginContainer = $Interface/MainLayout/Body/Sidebar/SidebarMargin
@onready var sidebar_scroll: ScrollContainer = $Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll
@onready var module_title: Label = %ModuleTitle
@onready var module_description: Label = %ModuleDescription
@onready var module_actions: Panel = %ModuleActions
@onready var construction_mode_label: Label = %ConstructionModeLabel
@onready var dashboard_module_button: Button = %DashboardModuleButton
@onready var farm_module_button: Button = %FarmModuleButton
@onready var structure_module_button: Button = %StructureModuleButton
@onready var store_module_button: Button = %StoreModuleButton
@onready var herd_module_button: Button = %HerdModuleButton
@onready var production_module_button: Button = %ProductionModuleButton
@onready var market_module_button: Button = %MarketModuleButton
@onready var finance_module_button: Button = %FinanceModuleButton
@onready var dashboard_panel: Label = %DashboardPanel
@onready var farm_alert_card: PanelContainer = %FarmAlertCard
@onready var farm_panel: Label = %FarmPanel
@onready var farm_soil_relief_status: Label = %FarmSoilReliefStatus
@onready var farm_pasture_selector: OptionButton = %FarmPastureSelector
@onready var farm_pasture_layer_button: CheckButton = %FarmPastureLayerButton
@onready var farm_water_layer_button: CheckButton = %FarmWaterLayerButton
@onready var farm_terrain_info_button: CheckButton = %FarmTerrainInfoButton
@onready var farm_structures_layer_button: CheckButton = %FarmStructuresLayerButton
@onready var map_frame: Control = $Interface/MainLayout/Body/Content/MapFrame
@onready var terrain_tooltip: PanelContainer = %TerrainTooltip
@onready var terrain_tooltip_label: Label = %TerrainTooltipLabel
@onready var structures_inventory: Label = %StructuresInventory
@onready var structures_empty_card: PanelContainer = %StructuresEmptyCard
@onready var structures_stats: GridContainer = %StructuresStats
@onready var structures_investment_card: PanelContainer = %StructuresInvestmentCard
@onready var structures_paddocks_stat: Label = %StructuresPaddocksStat
@onready var structures_fences_stat: Label = %StructuresFencesStat
@onready var structures_gates_stat: Label = %StructuresGatesStat
@onready var structures_support_stat: Label = %StructuresSupportStat
@onready var structures_investment: Label = %StructuresInvestment
@onready var store_status: Label = %StoreStatus
@onready var full_perimeter_fence_button: Button = %FullPerimeterFenceButton
@onready var barbed_fence_button: Button = %BarbedFenceButton
@onready var smooth_fence_button: Button = %SmoothFenceButton
@onready var electric_fence_button: Button = %ElectricFenceButton
@onready var store_gate_button: Button = %StoreGateButton
@onready var corral_button: Button = %CorralButton
@onready var scale_button: Button = %ScaleButton
@onready var finish_construction_button: Button = %FinishConstructionButton
@onready var cancel_free_construction_button: Button = %CancelFreeConstructionButton

var division_mode := DivisionMode.NONE
var division_orientation := DivisionMode.NONE
var division_position := 0.0
var perimeter_built := false
var full_farm_perimeter_built := false
var full_perimeter_build_tween: Tween
var full_perimeter_preview_visual: Node2D
const FULL_PERIMETER_BUILD_DURATION_SECONDS := 18.0
const CREW_TRAVEL_DURATION_SECONDS := 1.8
const GATE_BUILD_DURATION_SECONDS := 3.0
const CORRAL_BUILD_DURATION_SECONDS := 8.0
const SCALE_BUILD_DURATION_SECONDS := 4.0
var construction_job_tween: Tween
var cowboy_job_tween: Tween
var construction_job_active := false
var construction_job_completion := Callable()
var construction_job_name := ""
var construction_job_data: Dictionary = {}
var construction_job_target := Vector2.ZERO
var construction_job_started_unix_utc := 0
var construction_job_completes_unix_utc := 0
var construction_job_duration_seconds := 0.0
var division_created := false
var placing_gate := false
var gate_installed := false
var gate_open := false
var gate_center_position := 0.0
var herd_created := false
var herd_size := 0
var herd_animals: Array[Dictionary] = []
var next_animal_id := 1
var herd_pasture := 1
var pasture_1_center := Vector2.ZERO
var pasture_2_center := Vector2.ZERO
var current_day := 1
var day_of_year := 305
var current_year := 1
var server_clock_synchronized := false
var server_time_request_in_flight := false
var server_unix_utc_anchor := 0
var server_utc_offset_seconds := 0
var server_sync_ticks_msec := 0
var server_sync_accumulator := 0.0
var server_display_accumulator := 0.0
var auto_save_accumulator := 0.0
var last_processed_server_unix_utc := 0
var offline_target_server_unix_utc := 0
var offline_days_pending := 0
var offline_days_total := 0
var offline_summary_before: Dictionary = {}
var startup_save_checked := false
var forage := {1: 100.0, 2: 100.0}
var average_weight_kg := 300.0
var body_condition := 3.0
var hunger := 0.0
var thirst := 0.0
var health := 100.0
var pregnant_females := 0
var gestation_days_remaining := 0
var calf_age_days := -1
var breeding_method := ""
var pond_level := {1: 70.0, 2: 70.0}
var pasture_quality := {1: 75.0, 2: 75.0}
var pasture_degradation := {1: 0.0, 2: 0.0}
var pasture_capacity := {1: 12, 2: 12}
var soil_type := {1: "Solo de baixada", 2: "Solo raso e pedregoso"}
var relief_zone := {1: "Baixada", 2: "Área alta"}
var soil_moisture := {1: 62.0, 2: 38.0}
var soil_fertility := {1: 78.0, 2: 48.0}
var soil_compaction := {1: 12.0, 2: 8.0}
var herd_genotype_average: Dictionary = {
	"fertility": 50.0,
	"calving_ease": 50.0,
	"heat_adaptation": 50.0,
	"parasite_resistance": 50.0,
	"weight_gain": 50.0,
	"maternal_ability": 50.0,
}
var soil_erosion := {1: 4.0, 2: 12.0}
var soil_daily_runoff := {1: 0.0, 2: 0.0}
var mineral_stock_kg := 0.0
var supplement_stock_kg := 0.0
var river_level := 65.0
var rainfall_mm := 0.0
var max_temperature_c := 33.0
var consecutive_dry_days := 0
var weather_condition := "Seco"
var heat_stress := 0.0
var parasite_pressure := 0.0
var parasite_treatment_days_remaining := 0
var clinical_medication_days_remaining := 0
var vitamin_supplement_days_remaining := 0
var sanitary_last_event := "Sem ocorrências sanitárias."
var active_service_order: Dictionary = {}
var last_cowboy_activity := ""
var herd_had_water_today := true
var selected_crop_index := 0
var field_state := "idle"
var crop_days_elapsed := 0
var stored_feed_kg := {
	"silage": 0.0,
	"fresh_forage": 0.0,
	"hay": 0.0,
}
var feeding_plan_days_remaining := 0
var restoring_game := false
var cash_balance := STARTING_CASH
var transaction_history: Array = []
var current_module := "farm"
var build_mode := BuildMode.NONE
var build_points := PackedVector2Array()
var pending_structure_position := Vector2.ZERO
var has_pending_structure_position := false
var built_structures: Array[Dictionary] = []
var structure_investment := 0
var free_paddock_count := 0
var corral_rects: Array[Rect2] = []
var free_gate_nodes: Array[Line2D] = []
var free_gate_base_rotations: Array[float] = []
var free_gate_open_states: Array[bool] = []
var selected_farm_pasture := 1
var terrain_info_enabled := false
var vegetation_manager := VegetationManagerClass.new()
var vegetation_last_event := "Vegetação acompanhada diariamente."
var _current_lod_level: int = -1
var _visual_season_factor: float = -1.0
var _visual_condition: Dictionary = {}
var native_vegetation_cache: Dictionary = {}
var pasture_grass_layer: Node2D = null
var pasture_grass_cache: Dictionary = {}
var caatinga_vegetation_layer: Node2D = null


func _ready() -> void:
	if UserManager.current_slot >= 1:
		save_path = UserManager.get_slot_path(UserManager.current_slot)
	else:
		save_path = "user://fazenda_save.json"
	perimeter_button.pressed.connect(_build_perimeter)
	horizontal_button.pressed.connect(_start_horizontal_division)
	vertical_button.pressed.connect(_start_vertical_division)
	cancel_button.pressed.connect(_cancel_division)
	gate_install_button.pressed.connect(_start_gate_placement)
	select_herd_button.pressed.connect(_select_herd_lot)
	transfer_herd_button.pressed.connect(_transfer_herd)
	rebanho_list.item_selected.connect(_on_rebanho_item_selected)
	natural_breeding_button.pressed.connect(_start_natural_breeding)
	insemination_button.pressed.connect(_start_artificial_insemination)
	parasite_treatment_button.pressed.connect(
		_request_sanitary_service.bind("parasite", "Controle parasitário")
	)
	clinical_medication_button.pressed.connect(
		_request_sanitary_service.bind("clinical", "Tratamento clínico")
	)
	brucellosis_vaccine_button.pressed.connect(
		_request_sanitary_service.bind("brucellosis", "Vacinação contra brucelose")
	)
	clostridiosis_vaccine_button.pressed.connect(
		_request_sanitary_service.bind("clostridiosis", "Vacinação contra clostridioses")
	)
	vitamin_supplement_button.pressed.connect(
		_request_sanitary_service.bind("vitamin", "Suplementação vitamínico-mineral")
	)
	market_mode_selector.add_item("Comprar animais")
	market_mode_selector.set_item_metadata(0, "buy")
	market_mode_selector.add_item("Vender animais")
	market_mode_selector.set_item_metadata(1, "sell")
	market_mode_selector.item_selected.connect(_on_market_mode_selected)
	market_sale_filter.add_item("Todas as categorias")
	market_sale_filter.set_item_metadata(0, "all")
	for category in [
		"female_calves", "male_calves", "heifers", "cows",
		"steers", "oxen", "bulls",
	]:
		market_category_selector.add_item(_animal_category_display_name(category))
		market_category_selector.set_item_metadata(
			market_category_selector.item_count - 1, category
		)
		market_sale_filter.add_item(_animal_category_display_name(category))
		market_sale_filter.set_item_metadata(
			market_sale_filter.item_count - 1, category
		)
	market_category_selector.select(2)
	market_category_selector.item_selected.connect(_on_market_offer_changed)
	market_sale_filter.item_selected.connect(_on_market_sale_filter_changed)
	for breed_definition in CATTLE_BREEDS:
		breed_selector.add_item(str(breed_definition["name"]))
		breed_selector.set_item_metadata(
			breed_selector.item_count - 1,
			str(breed_definition["key"])
		)
	breed_selector.item_selected.connect(_on_market_offer_changed)
	market_quantity_selector.value_changed.connect(_on_market_quantity_changed)
	buy_animals_button.pressed.connect(_buy_animals)
	market_sale_list.multi_selected.connect(_on_market_sale_selection_changed)
	market_select_all_button.pressed.connect(_select_all_market_animals)
	market_clear_selection_button.pressed.connect(_clear_market_sale_selection)
	sell_animals_button.pressed.connect(_sell_animals)
	buy_mineral_button.pressed.connect(_buy_mineral)
	buy_supplement_button.pressed.connect(_buy_supplement)
	vegetation_rest_button.pressed.connect(_toggle_selected_pasture_rest)
	vegetation_form_button.pressed.connect(_schedule_selected_pasture_formation)
	vegetation_fertilize_button.pressed.connect(
		_schedule_selected_pasture_intervention.bind("fertilize")
	)
	vegetation_recover_button.pressed.connect(
		_schedule_selected_pasture_intervention.bind("recover")
	)
	select_crop_button.pressed.connect(_select_next_crop)
	prepare_soil_button.pressed.connect(_prepare_soil)
	plant_crop_button.pressed.connect(_plant_selected_crop)
	harvest_crop_button.pressed.connect(_harvest_crop)
	use_feed_reserve_button.pressed.connect(_activate_feed_reserve)
	save_button.pressed.connect(_save_game)
	load_button.pressed.connect(_load_game)
	server_time_request.request_completed.connect(_on_server_time_received)
	dashboard_module_button.pressed.connect(_show_module.bind("dashboard"))
	farm_module_button.pressed.connect(_show_module.bind("farm"))
	structure_module_button.pressed.connect(_show_module.bind("structures"))
	store_module_button.pressed.connect(_show_module.bind("store"))
	herd_module_button.pressed.connect(_show_module.bind("herd"))
	production_module_button.pressed.connect(_show_module.bind("production"))
	market_module_button.pressed.connect(_show_module.bind("market"))
	finance_module_button.pressed.connect(_show_module.bind("finance"))
	farm_pasture_selector.add_item("Pasto 1")
	farm_pasture_selector.add_item("Pasto 2")
	farm_pasture_selector.item_selected.connect(_on_farm_pasture_selected)
	farm_pasture_layer_button.toggled.connect(_on_farm_layer_toggled)
	farm_water_layer_button.toggled.connect(_on_farm_layer_toggled)
	farm_terrain_info_button.toggled.connect(_on_terrain_info_toggled)
	farm_structures_layer_button.toggled.connect(_on_farm_layer_toggled)
	_initialize_vegetation_ui()
	_initialize_vegetation_areas()
	barbed_fence_button.pressed.connect(_start_free_fence.bind(BuildMode.BARBED_FENCE))
	full_perimeter_fence_button.pressed.connect(_build_full_farm_perimeter)
	smooth_fence_button.pressed.connect(_start_free_fence.bind(BuildMode.SMOOTH_FENCE))
	electric_fence_button.pressed.connect(_start_free_fence.bind(BuildMode.ELECTRIC_FENCE))
	store_gate_button.pressed.connect(_start_single_structure.bind(BuildMode.GATE))
	corral_button.pressed.connect(_start_single_structure.bind(BuildMode.CORRAL))
	scale_button.pressed.connect(_start_single_structure.bind(BuildMode.SCALE))
	finish_construction_button.pressed.connect(_confirm_construction)
	cancel_free_construction_button.pressed.connect(_cancel_free_construction)
	herd_visuals.connect("selection_changed", _on_herd_visual_selection_changed)
	_update_daily_weather()
	_update_climate_visuals()
	_update_finance_ui()
	_update_nutrition_ui()
	_update_agriculture_ui()
	_update_water_ui()
	_update_reproduction_ui()
	_update_sanitary_ui()
	_update_service_order_ui()
	_update_structures_ui()
	_show_module("farm")
	call_deferred("_request_server_time")


func _process(delta: float) -> void:
	_update_server_clock(delta)
	_process_offline_days()
	if server_clock_synchronized and offline_days_pending <= 0:
		auto_save_accumulator += delta
		if auto_save_accumulator >= AUTO_SAVE_INTERVAL_SECONDS:
			auto_save_accumulator = 0.0
			_save_game(false)


func _server_time_url() -> String:
	var configured_url := OS.get_environment("GAME_TIME_API_URL").strip_edges()
	if not configured_url.is_empty():
		return configured_url
	if not OS.has_feature("web"):
		return ""
	var origin = JavaScriptBridge.eval("window.location.origin")
	if origin == null or str(origin).strip_edges().is_empty():
		return ""
	return "%s/api/time" % str(origin).trim_suffix("/")


func _request_server_time() -> void:
	if server_time_request_in_flight:
		return
	var request_url := _server_time_url()
	if request_url.is_empty():
		return
	server_time_request_in_flight = true
	var error := server_time_request.request(request_url)
	if error != OK:
		server_time_request_in_flight = false


func _on_server_time_received(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	server_time_request_in_flight = false
	if response_code != 200:
		return
	var payload = JSON.parse_string(body.get_string_from_utf8())
	if payload is Dictionary and _apply_server_time_payload(payload):
		_update_climate_visuals()
		_on_official_time_synchronized()


func _apply_server_time_payload(payload: Dictionary) -> bool:
	if str(payload.get("timezone", "")) != FARM_TIMEZONE:
		return false
	var unix_utc := int(payload.get("unix_utc", 0))
	var offset_seconds := int(payload.get("offset_seconds", 0))
	var local = payload.get("local", {})
	if unix_utc <= 0 or not local is Dictionary:
		return false
	var year := int(local.get("year", 0))
	var month := int(local.get("month", 0))
	var day := int(local.get("day", 0))
	var hour := int(local.get("hour", -1))
	var minute := int(local.get("minute", -1))
	var second := int(local.get("second", -1))
	if (
		year < 1
		or month < 1 or month > 12
		or day < 1 or day > 31
		or hour < 0 or hour > 23
		or minute < 0 or minute > 59
		or second < 0 or second > 59
	):
		return false
	server_unix_utc_anchor = unix_utc
	server_utc_offset_seconds = offset_seconds
	server_sync_ticks_msec = Time.get_ticks_msec()
	server_sync_accumulator = 0.0
	server_clock_synchronized = true
	return true


func _current_server_unix_utc() -> int:
	if not server_clock_synchronized:
		return 0
	var elapsed_seconds := maxi(
		floori((Time.get_ticks_msec() - server_sync_ticks_msec) / 1000.0),
		0
	)
	return server_unix_utc_anchor + elapsed_seconds


func _formatted_server_datetime() -> String:
	if not server_clock_synchronized:
		return "HORÁRIO OFICIAL INDISPONÍVEL"
	var local_unix := _current_server_unix_utc() + server_utc_offset_seconds
	var date_time := Time.get_datetime_dict_from_unix_time(local_unix)
	return "%02d/%02d/%04d %02d:%02d" % [
		int(date_time["day"]),
		int(date_time["month"]),
		int(date_time["year"]),
		int(date_time["hour"]),
		int(date_time["minute"]),
	]


func _update_server_clock(delta: float) -> void:
	server_sync_accumulator += delta
	server_display_accumulator += delta
	if server_sync_accumulator >= SERVER_TIME_SYNC_INTERVAL_SECONDS:
		server_sync_accumulator = 0.0
		_request_server_time()
	if server_clock_synchronized and server_display_accumulator >= 1.0:
		server_display_accumulator = 0.0
		_update_climate_visuals()
		if offline_days_pending <= 0:
			_schedule_real_time_progress()


func _on_official_time_synchronized() -> void:
	if not startup_save_checked:
		startup_save_checked = true
		if FileAccess.file_exists(save_path):
			_load_game(false)
			return
		_set_calendar_from_server_unix(_current_server_unix_utc())
		last_processed_server_unix_utc = _current_server_unix_utc()
		_save_game(false)
		return
	_schedule_real_time_progress()


func _local_datetime_from_server_unix(unix_utc: int) -> Dictionary:
	return Time.get_datetime_dict_from_unix_time(unix_utc + server_utc_offset_seconds)


func _civil_day_number(year: int, month: int, day: int) -> int:
	var adjusted_year := year
	var adjusted_month := month
	if adjusted_month <= 2:
		adjusted_year -= 1
		adjusted_month += 12
	return (
		365 * adjusted_year
		+ floori(adjusted_year / 4.0)
		- floori(adjusted_year / 100.0)
		+ floori(adjusted_year / 400.0)
		+ floori((153 * (adjusted_month - 3) + 2) / 5.0)
		+ day - 1
	)


func _days_between_server_dates(from_unix_utc: int, to_unix_utc: int) -> int:
	if from_unix_utc <= 0 or to_unix_utc <= from_unix_utc:
		return 0
	var from_date := _local_datetime_from_server_unix(from_unix_utc)
	var to_date := _local_datetime_from_server_unix(to_unix_utc)
	return maxi(
		_civil_day_number(
			int(to_date["year"]), int(to_date["month"]), int(to_date["day"])
		) - _civil_day_number(
			int(from_date["year"]), int(from_date["month"]), int(from_date["day"])
		),
		0
	)


func _set_calendar_from_server_unix(unix_utc: int) -> void:
	if unix_utc <= 0:
		return
	var local_date := _local_datetime_from_server_unix(unix_utc)
	current_year = int(local_date["year"])
	day_of_year = _day_of_year_from_date(
		current_year,
		int(local_date["month"]),
		int(local_date["day"])
	)


func _schedule_real_time_progress() -> void:
	if not server_clock_synchronized or offline_days_pending > 0:
		return
	var server_now := _current_server_unix_utc()
	if last_processed_server_unix_utc <= 0:
		_set_calendar_from_server_unix(server_now)
		last_processed_server_unix_utc = server_now
		_save_game(false)
		return
	var elapsed_days := _days_between_server_dates(
		last_processed_server_unix_utc,
		server_now
	)
	if elapsed_days <= 0:
		return
	_set_calendar_from_server_unix(last_processed_server_unix_utc)
	offline_target_server_unix_utc = server_now
	offline_days_pending = elapsed_days
	offline_days_total = elapsed_days
	offline_summary_before = {
		"herd_size": herd_size,
		"weight": average_weight_kg,
		"forage_1": float(forage[1]),
		"forage_2": float(forage[2]),
		"pond_1": float(pond_level[1]),
		"pond_2": float(pond_level[2]),
	}
	save_status.text = "Atualizando a fazenda: %d dia(s) transcorrido(s)." % elapsed_days


func _process_offline_days() -> void:
	if offline_days_pending <= 0:
		return
	var batch_size := mini(offline_days_pending, OFFLINE_DAYS_PER_FRAME)
	for _day_index in range(batch_size):
		_advance_day(true)
	offline_days_pending -= batch_size
	if offline_days_pending > 0:
		save_status.text = "Atualizando a fazenda: faltam %d dia(s)." % offline_days_pending
		return
	last_processed_server_unix_utc = offline_target_server_unix_utc
	_set_calendar_from_server_unix(last_processed_server_unix_utc)
	_refresh_simulation_ui()
	_show_offline_report()
	_save_game(false)


func _show_offline_report() -> void:
	if offline_days_total <= 0 or offline_summary_before.is_empty():
		return
	var report := (
		"Período processado: %d dia(s)\n\n"
		+ "Rebanho: %d → %d bovinos\n"
		+ "Peso médio: %.1f → %.1f kg\n"
		+ "Forragem Pasto 1: %.0f%% → %.0f%%\n"
		+ "Forragem Pasto 2: %.0f%% → %.0f%%\n"
		+ "Açude 1: %.0f%% → %.0f%%\n"
		+ "Açude 2: %.0f%% → %.0f%%"
	) % [
		offline_days_total,
		int(offline_summary_before.get("herd_size", 0)), herd_size,
		float(offline_summary_before.get("weight", average_weight_kg)), average_weight_kg,
		float(offline_summary_before.get("forage_1", forage[1])), float(forage[1]),
		float(offline_summary_before.get("forage_2", forage[2])), float(forage[2]),
		float(offline_summary_before.get("pond_1", pond_level[1])), float(pond_level[1]),
		float(offline_summary_before.get("pond_2", pond_level[2])), float(pond_level[2]),
	]
	offline_report_dialog.dialog_text = report
	offline_report_dialog.popup_centered(Vector2i(520, 380))
	save_status.text = "Fazenda atualizada após %d dia(s)." % offline_days_total
	offline_days_total = 0
	offline_summary_before = {}


func _refresh_simulation_ui() -> void:
	_update_pasture_visuals()
	_update_climate_visuals()
	_update_nutrition_ui()
	_update_water_ui()
	_update_agriculture_ui()
	_update_reproduction_ui()
	_update_sanitary_ui()
	_update_farm_ui()
	if herd_created and herd_size > 0:
		_update_herd_status("Estado atualizado pelo calendário oficial.")
	else:
		_update_empty_herd_guidance()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED]:
		if server_clock_synchronized:
			_save_game(false)


func _critical_time_pause_reason() -> String:
	if not herd_created or herd_size <= 0:
		return ""
	if not herd_had_water_today:
		return "o rebanho ficou sem água"
	if health <= 20.0:
		return "a saúde do rebanho está crítica"
	if forage[herd_pasture] <= 5.0:
		return "a forragem do pasto se esgotou"
	var sanitary_event := sanitary_last_event.to_lower()
	if "morreu" in sanitary_event or "morte" in sanitary_event:
		return "ocorreu uma morte no rebanho"
	return ""


func _report_critical_event() -> void:
	var reason := _critical_time_pause_reason()
	if reason.is_empty():
		return
	save_status.text = "Alerta da fazenda: %s." % reason


func _show_module(module_name: String) -> void:
	if build_mode != BuildMode.NONE and module_name != "store":
		_cancel_free_construction()

	current_module = module_name
	if module_name == "market":
		_update_market_readiness_ui()
	elif module_name == "herd":
		_update_empty_herd_guidance()
		_update_transfer_herd_action()
		_update_rebanho_list()
		_update_sanitary_ui()
		_update_service_order_ui()
	elif module_name == "farm":
		_update_farm_ui()
	elif module_name == "store":
		farm_structures_layer_button.set_pressed_no_signal(true)
		_apply_farm_layer_visibility()
	var module_metadata := {
		"dashboard": ["DASHBOARD", "Indicadores e alertas da propriedade"],
		"farm": ["FAZENDA", "Visão geral da propriedade"],
		"structures": ["ESTRUTURAS", "Inventário e controle das instalações"],
		"store": ["LOJA RURAL", "Comprar e posicionar estruturas"],
		"herd": ["REBANHO", "Lotes, manejo e reprodução"],
		"production": ["PRODUÇÃO", "Nutrição e reserva forrageira"],
		"market": ["MERCADO", "Compra e venda de animais"],
		"finance": ["FINANCEIRO", "Caixa e movimentações da fazenda"],
	}
	var selected_metadata: Array = module_metadata.get(module_name, module_metadata["farm"])
	module_title.text = selected_metadata[0]
	module_description.text = selected_metadata[1]

	var module_buttons := {
		"dashboard": dashboard_module_button,
		"farm": farm_module_button,
		"structures": structure_module_button,
		"store": store_module_button,
		"herd": herd_module_button,
		"production": production_module_button,
		"market": market_module_button,
		"finance": finance_module_button,
	}
	for button_name: String in module_buttons:
		var module_button: Button = module_buttons[button_name]
		module_button.set_pressed_no_signal(button_name == module_name)

	_update_construction_actions_visibility()
	sidebar_scroll.scroll_vertical = 0

	var module_nodes := {
		"dashboard": ["DashboardPanel"],
		"farm": [
			"FarmAlertCard",
			"FarmSoilReliefCard",
			"FarmPastureSelectorLabel", "FarmPastureSelector",
			"FarmLayersTitle", "FarmPastureLayerButton", "FarmWaterLayerButton",
			"FarmTerrainInfoButton", "FarmStructuresLayerButton",
		],
		"structures": [
			"StructuresEmptyCard", "StructuresStats", "StructuresInvestmentCard",
		],
		"store": [
			"StoreStatusCard", "StoreFencesTitle", "FullPerimeterFenceButton",
			"BarbedFenceButton",
			"SmoothFenceButton", "ElectricFenceButton", "StoreInstallationsTitle",
			"StoreGateButton", "CorralButton", "ScaleButton",
		],
		"herd": [
			"HerdSeparator", "HerdTitle", "HerdStatus", "HerdSelectionInfo",
			"SelectHerdButton",
			"TransferHerdButton",
			"RebanhoSeparator", "RebanhoTitle", "RebanhoHint",
			"RebanhoList", "RebanhoDetailLabel",
			"ReproductionSeparator",
			"ServiceOrderSeparator", "ServiceOrderTitle", "ServiceOrderStatus",
			"ReproductionTitle", "ReproductionStatus", "NaturalBreedingButton",
			"InseminationButton",
			"SanitarySeparator", "SanitaryTitle", "SanitaryStatus",
			"SanitaryMedicinesLabel", "ParasiteTreatmentButton",
			"ClinicalMedicationButton", "SanitaryVaccinesLabel",
			"BrucellosisVaccineButton", "ClostridiosisVaccineButton",
			"SanitarySupplementsLabel", "VitaminSupplementButton",
		],
		"production": [
			"FarmPastureSelectorLabel", "FarmPastureSelector",
			"NutritionSeparator", "NutritionTitle", "NutritionStatus",
			"VegetationSpeciesSelectorLabel", "VegetationSpeciesSelector",
			"VegetationRestButton", "VegetationFormButton",
			"VegetationFertilizeButton", "VegetationRecoverButton",
			"BuyMineralButton", "BuySupplementButton", "WaterSeparator",
			"WaterTitle", "WaterStatus", "AgricultureSeparator",
			"AgricultureTitle", "AgricultureStatus", "SelectCropButton",
			"PrepareSoilButton", "PlantCropButton", "HarvestCropButton",
			"UseFeedReserveButton",
		],
		"market": [
			"MarketModeLabel", "MarketModeSelector", "MarketInfo",
			"MarketBuyTitle", "MarketCategorySelectorLabel",
			"MarketCategorySelector", "BreedSelectorLabel", "BreedSelector",
			"MarketQuantitySelectorLabel", "MarketQuantitySelector",
			"BuyAnimalsButton", "MarketSellTitle", "MarketSaleFilterLabel",
			"MarketSaleFilter", "MarketSaleList", "MarketSelectAllButton",
			"MarketClearSelectionButton", "SellAnimalsButton",
		],
		"finance": ["FinanceStatus"],
	}
	var visible_names: Array = module_nodes.get(module_name, module_nodes["farm"])

	for child in sidebar_content.get_children():
		child.visible = child.name in visible_names
	if module_name == "market":
		_update_market_mode_ui()
	if module_name != "farm":
		terrain_tooltip.visible = false
	if module_name == "structures":
		_update_structures_ui()


func _formed_paddock_count() -> int:
	if free_paddock_count > 0:
		return free_paddock_count
	return 2 if division_created else 0


func _initialize_vegetation_ui() -> void:
	vegetation_species_selector.clear()
	for species_key in ["buffel", "massai", "andropogon", "caatinga"]:
		vegetation_species_selector.add_item(vegetation_manager.species_name(species_key))
		vegetation_species_selector.set_item_metadata(
			vegetation_species_selector.item_count - 1, species_key
		)


func _initialize_vegetation_areas() -> void:
	vegetation_manager.configure_area(1, FARM_AREA_HECTARES * 0.5, 12.0, "buffel")
	vegetation_manager.configure_area(2, FARM_AREA_HECTARES * 0.5, 30.0, "caatinga")
	_sync_legacy_from_vegetation()


func _vegetation_polygon(area_id: int) -> PackedVector2Array:
	if _using_general_farm_area() and area_id == 1:
		return farm_visual_boundary
	return pasture_1.polygon if area_id == 1 else pasture_2.polygon


func _average_polygon_elevation(polygon: PackedVector2Array) -> float:
	if polygon.is_empty():
		return 20.0
	var samples := PackedVector2Array([_polygon_center(polygon)])
	var step := maxi(floori(float(polygon.size()) / 6.0), 1)
	for point_index in range(0, polygon.size(), step):
		samples.append(polygon[point_index])
	var elevation_total := 0.0
	for sample in samples:
		elevation_total += float(_relative_elevation_m(sample))
	return elevation_total / maxf(float(samples.size()), 1.0)


func _sync_vegetation_area_geometry(area_id: int) -> void:
	var polygon := _vegetation_polygon(area_id)
	if polygon.size() < 3:
		return
	var center := _polygon_center(polygon)
	var area_hectares := FARM_AREA_HECTARES
	if not (_using_general_farm_area() and area_id == 1):
		area_hectares = FARM_AREA_HECTARES * _polygon_area(polygon) / (FARM_WIDTH * FARM_HEIGHT)
	var initial_species := "buffel" if area_id == 1 else "caatinga"
	var elevation := _average_polygon_elevation(polygon)
	vegetation_manager.configure_area(
		area_id, maxf(area_hectares, 0.1), elevation, initial_species
	)
	soil_type[area_id] = _terrain_soil_label(roundi(elevation))
	relief_zone[area_id] = _terrain_relief_label(roundi(elevation))
	if not restoring_game:
		soil_moisture[area_id] = clampf(74.0 - elevation * 1.15, 22.0, 78.0)
		soil_fertility[area_id] = clampf(82.0 - elevation * 0.82, 35.0, 85.0)
		soil_erosion[area_id] = clampf(4.0 + elevation * 0.34, 3.0, 25.0)
	_sync_legacy_from_vegetation()


func _sync_all_vegetation_geometry() -> void:
	_sync_vegetation_area_geometry(1)
	if _formed_paddock_count() >= 2:
		_sync_vegetation_area_geometry(2)


func _sync_legacy_from_vegetation() -> void:
	for area_id in [1, 2]:
		if not vegetation_manager.has_area(area_id):
			continue
		var area: Dictionary = vegetation_manager.get_area(area_id)
		forage[area_id] = vegetation_manager.forage_percent(area_id)
		pasture_quality[area_id] = float(area["quality_pct"])
		pasture_degradation[area_id] = float(area["degradation_pct"])
		pasture_capacity[area_id] = vegetation_manager.capacity_animals(
			area_id, average_weight_kg
		)


func _has_livestock_area() -> bool:
	return full_farm_perimeter_built or _formed_paddock_count() > 0


func _using_general_farm_area() -> bool:
	return full_farm_perimeter_built and _formed_paddock_count() == 0


func _current_herd_area_name() -> String:
	if _using_general_farm_area():
		return "Área geral"
	return "Pasto %d" % herd_pasture


func _configure_general_farm_area() -> void:
	pasture_1_center = _polygon_center(farm_visual_boundary)
	_sync_vegetation_area_geometry(1)
	forage_field.position = pasture_1_center + Vector2(300.0, 120.0)
	forage_field_label.position = forage_field.position - Vector2(260.0, 65.0)


func _update_empty_herd_guidance() -> void:
	if herd_created:
		return
	if not _has_livestock_area():
		herd_status.text = "Cerque a propriedade ou forme um pasto antes de comprar animais."
	elif not gate_installed:
		herd_status.text = "Área cercada. Instale uma porteira para permitir a entrada dos animais."
	else:
		herd_status.text = "Área geral pronta. Compre os primeiros animais no Mercado."


func _update_transfer_herd_action() -> void:
	if _formed_paddock_count() < 2:
		transfer_herd_button.disabled = true
		transfer_herd_button.text = "Forme 2 pastos para transferir"
		return
	transfer_herd_button.disabled = not herd_created
	transfer_herd_button.text = "Transferir para Pasto %d" % (
		2 if herd_pasture == 1 else 1
	)


func _update_rebanho_list() -> void:
	rebanho_list.clear()
	rebanho_detail_label.clear()
	if not herd_created or herd_animals.is_empty():
		rebanho_hint.text = "Nenhum animal registrado."
		return
	rebanho_hint.text = "%d animais no rebanho." % herd_animals.size()
	var category_names := {
		"female_calves": "Bezerra",
		"male_calves": "Bezerro",
		"heifers": "Novilha",
		"cows": "Vaca",
		"steers": "Garrote",
		"oxen": "Boi",
		"bulls": "Touro",
	}
	for animal in herd_animals:
		var cat := str(animal.get("category", ""))
		var cat_display: String = category_names.get(cat, cat)
		var breed_name := _breed_display_name(str(animal.get("breed", DEFAULT_CATTLE_BREED)))
		var w_kg := float(animal.get("weight_kg", 0.0))
		var hp := int(animal.get("health", 100.0))
		var destiny := str(animal.get("destiny", "unassigned"))
		rebanho_list.add_item(
			"%s | %s | %s | %.0f kg | %d%% | %s" % [
				str(animal.get("id", "?")),
				cat_display,
				breed_name,
				w_kg,
				hp,
				destiny,
			]
		)


func _on_rebanho_item_selected(index: int) -> void:
	if index < 0 or index >= herd_animals.size():
		return
	var animal: Dictionary = herd_animals[index]
	var category_names := {
		"female_calves": "Bezerra",
		"male_calves": "Bezerro",
		"heifers": "Novilha",
		"cows": "Vaca",
		"steers": "Garrote",
		"oxen": "Boi",
		"bulls": "Touro",
	}
	var cat := str(animal.get("category", ""))
	var breed_name := _breed_display_name(str(animal.get("breed", DEFAULT_CATTLE_BREED)))
	var w_kg := float(animal.get("weight_kg", 0.0))
	var hp := int(animal.get("health", 100.0))
	var age := int(animal.get("age_days", 0))
	var destiny := str(animal.get("destiny", "unassigned"))
	var pregnant_text := "Sim (%d dias)" % int(animal.get("gestation_days", 0)) if bool(animal.get("pregnant", false)) else "Não"
	var g: Dictionary = animal.get("genetics", {})
	var lines := "[b]%s — %s[/b]\n" % [str(animal.get("id", "?")), category_names.get(cat, cat)]
	lines += "Raça: %s | Sexo: %s\n" % [breed_name, "Fêmea" if animal.get("sex", "") == "female" else "Macho"]
	lines += "Idade: %d dias | Peso: %.1f kg\n" % [age, w_kg]
	lines += "Saúde: %d%% | Destino: %s\n" % [hp, destiny]
	lines += "Gestante: %s\n" % pregnant_text
	lines += "\n[b]Genética:[/b]\n"
	lines += "Fertilidade: %d | Parto: %d | Materna: %d\n" % [
		roundi(float(g.get("fertility", 0))), roundi(float(g.get("calving_ease", 0))),
		roundi(float(g.get("maternal_ability", 0))),
	]
	lines += "Calor: %d | Parasitas: %d | Ganho: %d" % [
		roundi(float(g.get("heat_adaptation", 0))), roundi(float(g.get("parasite_resistance", 0))),
		roundi(float(g.get("weight_gain", 0))),
	]
	rebanho_detail_label.clear()
	rebanho_detail_label.append_text(lines)


func _update_farm_ui() -> void:
	var paddock_count := _formed_paddock_count()
	if selected_farm_pasture > maxi(paddock_count, 1):
		selected_farm_pasture = 1
	farm_pasture_selector.select(selected_farm_pasture - 1)
	farm_pasture_selector.disabled = paddock_count == 0
	farm_pasture_selector.set_item_disabled(1, paddock_count < 2)

	var soil_details := "RELEVO E SOLO\nCerque a propriedade para consultar esta área."
	if _using_general_farm_area() or selected_farm_pasture <= paddock_count:
		soil_details = (
			"RELEVO E SOLO  •  %s\n"
			+ "%s\n"
			+ "Umidade %d%%  •  Fertilidade %d%%\n"
			+ "Compactação %d%%  •  Erosão %d%%"
		) % [
			relief_zone[selected_farm_pasture],
			soil_type[selected_farm_pasture],
			roundi(soil_moisture[selected_farm_pasture]),
			roundi(soil_fertility[selected_farm_pasture]),
			roundi(soil_compaction[selected_farm_pasture]),
			roundi(soil_erosion[selected_farm_pasture]),
		]

	var alert := _farm_territorial_alert(paddock_count)
	_apply_farm_alert_style(alert)
	farm_soil_relief_status.text = soil_details


func _apply_farm_alert_style(alert: String) -> void:
	var title := "ATENÇÃO"
	var accent := Color(0.95, 0.7, 0.24, 1)
	var background := Color(0.22, 0.16, 0.08, 0.96)
	if alert == "Nenhum alerta territorial crítico.":
		title = "OPERAÇÃO NORMAL"
		accent = Color(0.48, 0.78, 0.4, 1)
		background = Color(0.09, 0.19, 0.1, 0.96)
	elif (
		"sem água" in alert.to_lower()
		or "nível crítico" in alert.to_lower()
		or "degradação elevada" in alert.to_lower()
		or "erosão elevada" in alert.to_lower()
	):
		title = "CRÍTICO"
		accent = Color(0.96, 0.39, 0.3, 1)
		background = Color(0.24, 0.08, 0.06, 0.96)
	farm_panel.text = "%s\n%s" % [title, alert]
	farm_panel.add_theme_color_override("font_color", accent)
	var alert_style := StyleBoxFlat.new()
	alert_style.bg_color = background
	alert_style.border_color = accent
	alert_style.set_border_width_all(1)
	alert_style.set_corner_radius_all(6)
	farm_alert_card.add_theme_stylebox_override("panel", alert_style)


func _farm_territorial_alert(paddock_count: int) -> String:
	if not full_farm_perimeter_built:
		return "A propriedade ainda não está cercada."
	if paddock_count == 0:
		if not gate_installed:
			return "Área geral cercada. Falta instalar uma porteira."
		if not herd_created:
			return "Área geral pronta para comprar o primeiro rebanho."
	if pond_level[selected_farm_pasture] <= 5.0 and (
		not _selected_farm_pasture_has_river_access() or river_level <= 5.0
	):
		return "O pasto selecionado está sem água disponível."
	if forage[selected_farm_pasture] < 20.0:
		return "A forragem do pasto selecionado está em nível crítico."
	if pasture_degradation[selected_farm_pasture] >= 60.0:
		return "O pasto selecionado apresenta degradação elevada."
	if soil_erosion[selected_farm_pasture] >= 60.0:
		return "O pasto selecionado apresenta erosão elevada."
	if soil_moisture[selected_farm_pasture] <= 12.0:
		return "A umidade do solo está em nível crítico."
	if gate_open:
		return "Existe uma porteira aberta."
	return "Nenhum alerta territorial crítico."


func _selected_farm_pasture_has_river_access() -> bool:
	if _using_general_farm_area():
		return true
	if division_orientation == DivisionMode.HORIZONTAL:
		return true
	if division_orientation == DivisionMode.VERTICAL:
		return selected_farm_pasture == 2
	return false


func _on_farm_pasture_selected(index: int) -> void:
	selected_farm_pasture = index + 1
	_update_farm_ui()
	_update_nutrition_ui()


func _selected_vegetation_species() -> String:
	var metadata = vegetation_species_selector.get_selected_metadata()
	return str(metadata) if metadata != null else "buffel"


func _toggle_selected_pasture_rest() -> void:
	if not vegetation_manager.has_area(selected_farm_pasture):
		return
	var area: Dictionary = vegetation_manager.get_area(selected_farm_pasture)
	var resting := str(area["management_mode"]) == "rest"
	if not resting and herd_created and herd_size > 0 and herd_pasture == selected_farm_pasture:
		vegetation_last_event = "Transfira o lote antes de colocar o pasto ocupado em descanso."
		_update_nutrition_ui()
		return
	vegetation_manager.set_management_mode(selected_farm_pasture, "grazing" if resting else "rest")
	vegetation_last_event = "Pastejo liberado." if resting else "Pasto colocado em descanso."
	_update_nutrition_ui()


func _schedule_selected_pasture_formation() -> void:
	var area: Dictionary = vegetation_manager.get_area(selected_farm_pasture)
	if area.is_empty():
		return
	var action := "reform" if int(area["degradation_stage"]) >= 2 else "formation"
	_schedule_selected_pasture_intervention(action)


func _schedule_selected_pasture_intervention(action: String) -> void:
	if not vegetation_manager.has_area(selected_farm_pasture):
		return
	if herd_created and herd_size > 0 and herd_pasture == selected_farm_pasture:
		vegetation_last_event = "Transfira o lote antes de iniciar o serviço no pasto ocupado."
		_update_nutrition_ui()
		return
	var cost := vegetation_manager.intervention_cost(selected_farm_pasture, action)
	if cost <= 0 or cash_balance < cost:
		vegetation_last_event = "Caixa insuficiente para o manejo selecionado."
		_update_nutrition_ui()
		return
	var target_species := _selected_vegetation_species()
	if not vegetation_manager.schedule_intervention(selected_farm_pasture, action, target_species):
		vegetation_last_event = "Já existe um serviço de vegetação em andamento nesta área."
		_update_nutrition_ui()
		return
	_record_transaction("Manejo da vegetação: %s" % action, -cost)
	vegetation_last_event = "Serviço programado. Custo: R$ %s." % _format_money(cost)
	_update_nutrition_ui()


func _on_farm_layer_toggled(_enabled: bool) -> void:
	_apply_farm_layer_visibility()


func _on_terrain_info_toggled(enabled: bool) -> void:
	terrain_info_enabled = enabled
	if not enabled:
		terrain_tooltip.visible = false


func _apply_farm_layer_visibility() -> void:
	var paddock_count := _formed_paddock_count()
	pasture_1.visible = farm_pasture_layer_button.button_pressed and paddock_count >= 1
	pasture_2.visible = farm_pasture_layer_button.button_pressed and paddock_count >= 2

	var show_water_indicators := farm_water_layer_button.button_pressed
	# Os polígonos permanecem apenas como geometria da simulação. A aparência
	# utiliza sprites e textura natural, independentemente dos indicadores.
	pond_1.visible = false
	pond_2.visible = false
	pond_1_gauge.visible = show_water_indicators
	pond_2_gauge.visible = show_water_indicators
	_update_water_level_visuals()

	var show_structures := farm_structures_layer_button.button_pressed
	player_structures.visible = show_structures
	var using_legacy_structures := built_structures.is_empty()
	perimeter_fence.visible = show_structures and using_legacy_structures and perimeter_built
	internal_fence.visible = show_structures and using_legacy_structures and division_created
	internal_fence_2.visible = (
		show_structures and using_legacy_structures and division_created and gate_installed
	)
	gate.visible = show_structures and using_legacy_structures and gate_installed


func _select_farm_pasture_at(world_position: Vector2) -> bool:
	var paddock_count := _formed_paddock_count()
	for pasture_number in range(paddock_count, 0, -1):
		var polygon: PackedVector2Array = (
			pasture_1.polygon if pasture_number == 1 else pasture_2.polygon
		)
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(world_position, polygon):
			selected_farm_pasture = pasture_number
			farm_pasture_selector.select(pasture_number - 1)
			_update_farm_ui()
			return true
	return false


func _start_free_fence(selected_mode: BuildMode) -> void:
	_cancel_free_construction(false)
	build_mode = selected_mode
	_set_store_selection(selected_mode)
	build_points = PackedVector2Array()
	construction_preview.visible = true
	finish_construction_button.disabled = true
	cancel_free_construction_button.disabled = false
	construction_mode_label.text = _build_mode_name(selected_mode).to_upper()
	_update_construction_actions_visibility()
	store_status.text = (
		"Clique no mapa para iniciar. Adicione quantos trechos desejar.\n"
		+ "O comprimento e o custo aparecerão antes da confirmação."
	)


func _start_single_structure(selected_mode: BuildMode) -> void:
	_cancel_free_construction(false)
	build_mode = selected_mode
	_set_store_selection(selected_mode)
	construction_preview.visible = true
	finish_construction_button.disabled = true
	cancel_free_construction_button.disabled = false
	construction_mode_label.text = _build_mode_name(selected_mode).to_upper()
	_update_construction_actions_visibility()
	var instruction := "Clique no mapa para posicionar."
	if selected_mode == BuildMode.GATE:
		instruction = "Clique sobre uma cerca construída para instalar a porteira."
	elif selected_mode == BuildMode.SCALE:
		instruction = "Clique dentro de um curral para instalar a balança."
	store_status.text = instruction + "\nDepois, confirme no rodapé. Esc cancela sem cobrança."


func _handle_free_build_click(world_position: Vector2) -> void:
	if not Rect2(Vector2.ZERO, Vector2(FARM_WIDTH, FARM_HEIGHT)).has_point(world_position):
		store_status.text = "A estrutura deve ficar dentro da propriedade."
		return

	if build_mode in [
		BuildMode.BARBED_FENCE,
		BuildMode.SMOOTH_FENCE,
		BuildMode.ELECTRIC_FENCE,
	]:
		if not build_points.is_empty() and build_points[-1].distance_to(world_position) < 35.0:
			return
		if build_points.size() >= 3 and world_position.distance_to(build_points[0]) <= 100.0:
			world_position = build_points[0]
			build_points.append(world_position)
			construction_preview.points = build_points
			finish_construction_button.disabled = false
			_update_fence_estimate_status("Área fechada. Confira os valores e confirme.")
			return
		build_points.append(world_position)
		construction_preview.points = build_points
		finish_construction_button.disabled = build_points.size() < 2
		_update_fence_estimate_status("Continue desenhando ou confirme.")
		return

	pending_structure_position = world_position
	has_pending_structure_position = true
	finish_construction_button.disabled = false
	_update_construction_preview(world_position)
	var structure_cost := _current_single_structure_cost()
	store_status.text = "%s posicionado.\n%s\nConfirme para construir." % [
		_build_mode_name(build_mode),
		_format_cost_breakdown(structure_cost, _construction_labor_rate(build_mode)),
	]


func _update_construction_preview(world_position: Vector2) -> void:
	if build_mode == BuildMode.NONE:
		return
	if has_pending_structure_position and build_mode in [
		BuildMode.GATE,
		BuildMode.CORRAL,
		BuildMode.SCALE,
	]:
		world_position = pending_structure_position

	var clamped_position := Vector2(
		clampf(world_position.x, 0.0, FARM_WIDTH),
		clampf(world_position.y, 0.0, FARM_HEIGHT)
	)
	if build_mode in [
		BuildMode.BARBED_FENCE,
		BuildMode.SMOOTH_FENCE,
		BuildMode.ELECTRIC_FENCE,
	]:
		var preview_points := build_points.duplicate()
		if not preview_points.is_empty():
			preview_points.append(clamped_position)
		construction_preview.points = preview_points
	elif build_mode == BuildMode.GATE:
		construction_preview.points = PackedVector2Array([
			clamped_position - Vector2(55, 0),
			clamped_position + Vector2(55, 0),
		])
	elif build_mode == BuildMode.CORRAL:
		construction_preview.points = _rectangle_points(
			Rect2(clamped_position - CORRAL_SIZE / 2.0, CORRAL_SIZE)
		)
	elif build_mode == BuildMode.SCALE:
		construction_preview.points = _rectangle_points(
			Rect2(clamped_position - Vector2(12, 6), Vector2(24, 12))
		)


func _confirm_construction() -> void:
	if construction_job_active:
		store_status.text = "A equipe rural já está executando uma obra."
		return
	if build_mode in [
		BuildMode.BARBED_FENCE,
		BuildMode.SMOOTH_FENCE,
		BuildMode.ELECTRIC_FENCE,
	]:
		_finish_free_construction()
		return
	if not has_pending_structure_position:
		return
	match build_mode:
		BuildMode.GATE:
			if _validate_free_gate_position(pending_structure_position):
				_start_timed_construction(
					pending_structure_position,
					GATE_BUILD_DURATION_SECONDS,
					_place_free_gate.bind(pending_structure_position),
					"porteira",
					{
						"kind": "gate",
						"position": _serialize_vector2(pending_structure_position),
					}
				)
		BuildMode.CORRAL:
			if _validate_free_corral_position(pending_structure_position):
				_start_timed_construction(
					pending_structure_position,
					CORRAL_BUILD_DURATION_SECONDS,
					_place_free_corral.bind(pending_structure_position),
					"curral",
					{
						"kind": "corral",
						"position": _serialize_vector2(pending_structure_position),
					}
				)
		BuildMode.SCALE:
			if _validate_free_scale_position(pending_structure_position):
				_start_timed_construction(
					pending_structure_position,
					SCALE_BUILD_DURATION_SECONDS,
					_place_free_scale.bind(pending_structure_position),
					"balança",
					{
						"kind": "scale",
						"position": _serialize_vector2(pending_structure_position),
					}
				)


func _finish_free_construction() -> void:
	if not build_mode in [
		BuildMode.BARBED_FENCE,
		BuildMode.SMOOTH_FENCE,
		BuildMode.ELECTRIC_FENCE,
	] or build_points.size() < 2:
		return

	build_points = _normalize_fence_closure(build_points)
	construction_preview.points = build_points
	var cost := _current_fence_cost()
	if cash_balance < cost:
		store_status.text = "Caixa insuficiente. Custo estimado: R$ %s." % _format_money(cost)
		return

	var type_name := _build_mode_name(build_mode)
	var points := build_points.duplicate()
	var selected_mode := build_mode
	var duration := clampf(3.0 + _fence_length_meters_for_points(points) / 300.0, 4.0, 15.0)
	var work_position := _polygon_center(points) if _is_closed_fence(points) else points[points.size() / 2]
	_start_timed_construction(
		work_position,
		duration,
		_complete_free_fence_construction.bind(points, selected_mode, cost, type_name),
		type_name.to_lower(),
		{
			"kind": "fence",
			"points": _serialize_vector2_array(points),
			"selected_mode": int(selected_mode),
			"cost": cost,
			"type_name": type_name,
		}
	)


func _complete_free_fence_construction(
	points: PackedVector2Array,
	selected_mode: BuildMode,
	cost: int,
	type_name: String
) -> void:
	_create_fence_visual(points, selected_mode)
	player_structures.move_child(construction_preview, player_structures.get_child_count() - 1)
	var breakdown := _cost_breakdown(cost, _construction_labor_rate(selected_mode))
	built_structures.append({
		"type": type_name,
		"cost": cost,
		"material_cost": int(breakdown["material"]),
		"labor_cost": int(breakdown["labor"]),
		"points": points.duplicate(),
	})
	structure_investment += cost
	_record_split_expense(type_name, cost, _construction_labor_rate(selected_mode))

	var formed_paddock := _is_closed_fence(points)
	if formed_paddock:
		_register_free_paddock(points)

	store_status.text = "Equipe rural concluiu %s por R$ %s." % [
		type_name,
		_format_money(cost),
	]
	if formed_paddock and not gate_installed:
		store_status.text += "\nPasto formado. Agora instale uma porteira sobre a cerca."
		market_info.text = (
			"Pasto formado.\n"
			+ "Para comprar animais, instale uma porteira sobre a cerca."
		)
	_reset_build_mode()
	_update_structures_ui()


func _start_timed_construction(
	target_position: Vector2,
	work_duration: float,
	completion: Callable,
	work_name: String,
	job_data: Dictionary = {}
) -> void:
	construction_job_active = true
	construction_job_completion = completion
	construction_job_name = work_name
	construction_job_data = job_data.duplicate(true)
	construction_job_target = target_position
	construction_job_started_unix_utc = _current_server_unix_utc()
	construction_job_completes_unix_utc = (
		construction_job_started_unix_utc
		+ ceili(CREW_TRAVEL_DURATION_SECONDS + work_duration)
		if construction_job_started_unix_utc > 0
		else 0
	)
	construction_job_duration_seconds = CREW_TRAVEL_DURATION_SECONDS + work_duration
	finish_construction_button.disabled = true
	cancel_free_construction_button.disabled = false
	construction_crew_visual.visible = true
	construction_crew_visual.position = target_position + Vector2(-70.0, 45.0)
	construction_worker_1.call("start_walk")
	construction_worker_2.call("start_walk")
	construction_worker_3.call("start_walk")
	store_status.text = "Equipe rural a caminho da obra: %s." % work_name
	construction_job_tween = create_tween()
	construction_job_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	construction_job_tween.tween_property(
		construction_crew_visual,
		"position",
		target_position,
		CREW_TRAVEL_DURATION_SECONDS
	)
	construction_job_tween.tween_callback(_start_construction_worker_actions)
	construction_job_tween.tween_interval(work_duration)
	construction_job_tween.tween_callback(_complete_active_construction_job)
	_save_game(false)


func _complete_active_construction_job() -> void:
	if not construction_job_active:
		return
	var completion := construction_job_completion
	construction_job_completion = Callable()
	construction_job_name = ""
	construction_job_data = {}
	construction_job_target = Vector2.ZERO
	construction_job_started_unix_utc = 0
	construction_job_completes_unix_utc = 0
	construction_job_duration_seconds = 0.0
	construction_job_active = false
	construction_job_tween = null
	if completion.is_valid():
		completion.call()
	construction_crew_visual.visible = false
	_reset_construction_crew_pose()
	_save_game(false)


func _complete_active_construction_immediately() -> void:
	if not construction_job_active:
		return
	if is_instance_valid(construction_job_tween):
		construction_job_tween.kill()
	construction_job_tween = null
	_complete_active_construction_job()


func _cancel_active_construction_job() -> void:
	if not construction_job_active and not is_instance_valid(construction_job_tween):
		return
	if is_instance_valid(construction_job_tween):
		construction_job_tween.kill()
	construction_job_tween = null
	construction_job_completion = Callable()
	construction_job_name = ""
	construction_job_data = {}
	construction_job_target = Vector2.ZERO
	construction_job_started_unix_utc = 0
	construction_job_completes_unix_utc = 0
	construction_job_duration_seconds = 0.0
	construction_job_active = false
	construction_crew_visual.visible = false
	_reset_construction_crew_pose()
	_save_game(false)


func _resume_saved_construction_job(serialized_job) -> void:
	if not serialized_job is Dictionary or serialized_job.is_empty():
		return
	var job_data = serialized_job.get("data", {})
	if not job_data is Dictionary:
		return
	var completion := _construction_callable_from_data(job_data)
	if not completion.is_valid():
		return
	var target := _deserialize_vector2(
		serialized_job.get("target", job_data.get("position", []))
	)
	var completes_unix := maxi(int(serialized_job.get("completes_unix_utc", 0)), 0)
	var server_now := _current_server_unix_utc()
	if completes_unix > 0 and server_now >= completes_unix:
		completion.call()
		return

	construction_job_active = true
	construction_job_completion = completion
	construction_job_name = str(serialized_job.get("name", "obra"))
	construction_job_data = job_data.duplicate(true)
	construction_job_target = target
	construction_job_started_unix_utc = maxi(
		int(serialized_job.get("started_unix_utc", 0)), 0
	)
	construction_job_completes_unix_utc = completes_unix
	var remaining_seconds := maxf(
		float(completes_unix - server_now)
		if completes_unix > 0 and server_now > 0
		else float(serialized_job.get("remaining_seconds", 1.0)),
		0.05
	)
	construction_job_duration_seconds = remaining_seconds
	finish_construction_button.disabled = true
	cancel_free_construction_button.disabled = false
	construction_crew_visual.visible = true
	construction_crew_visual.position = target
	_start_construction_worker_actions()
	store_status.text = "Equipe rural trabalhando: %s." % construction_job_name
	construction_job_tween = create_tween()
	construction_job_tween.tween_interval(remaining_seconds)
	construction_job_tween.tween_callback(_complete_active_construction_job)


func _construction_callable_from_data(job_data: Dictionary) -> Callable:
	var kind := str(job_data.get("kind", ""))
	var position := _deserialize_vector2(job_data.get("position", []))
	match kind:
		"gate":
			return _place_free_gate.bind(position)
		"corral":
			return _place_free_corral.bind(position)
		"scale":
			return _place_free_scale.bind(position)
		"fence":
			var points := _deserialize_vector2_array(job_data.get("points", []))
			var selected_mode: BuildMode = int(
				job_data.get("selected_mode", BuildMode.BARBED_FENCE)
			)
			if points.size() < 2 or not selected_mode in [
				BuildMode.BARBED_FENCE,
				BuildMode.SMOOTH_FENCE,
				BuildMode.ELECTRIC_FENCE,
			]:
				return Callable()
			return _complete_free_fence_construction.bind(
				points,
				selected_mode,
				maxi(int(job_data.get("cost", 0)), 0),
				str(job_data.get("type_name", _build_mode_name(selected_mode)))
			)
	return Callable()


func _serialize_vector2(value: Vector2) -> Array:
	return [value.x, value.y]


func _deserialize_vector2(value) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


func _serialize_vector2_array(points: PackedVector2Array) -> Array:
	var serialized: Array = []
	for point in points:
		serialized.append(_serialize_vector2(point))
	return serialized


func _deserialize_vector2_array(serialized_points) -> PackedVector2Array:
	var points := PackedVector2Array()
	if serialized_points is Array:
		for serialized_point in serialized_points:
			points.append(_deserialize_vector2(serialized_point))
	return points


func _serialize_construction_job() -> Dictionary:
	if not construction_job_active or construction_job_data.is_empty():
		return {}
	var server_now := _current_server_unix_utc()
	var remaining_seconds := construction_job_duration_seconds
	if construction_job_completes_unix_utc > 0 and server_now > 0:
		remaining_seconds = maxf(
			float(construction_job_completes_unix_utc - server_now),
			0.0
		)
	return {
		"name": construction_job_name,
		"data": construction_job_data.duplicate(true),
		"target": _serialize_vector2(construction_job_target),
		"started_unix_utc": construction_job_started_unix_utc,
		"completes_unix_utc": construction_job_completes_unix_utc,
		"remaining_seconds": remaining_seconds,
	}


func _full_farm_perimeter_points() -> PackedVector2Array:
	var points := farm_visual_boundary.duplicate()
	if not points.is_empty() and points[0] != points[-1]:
		points.append(points[0])
	return points


func _full_farm_perimeter_cost() -> int:
	var length_meters := _fence_length_meters_for_points(_full_farm_perimeter_points())
	return maxi(ceili(length_meters / 100.0 * BARBED_FENCE_COST_PER_100), 1)


func _build_full_farm_perimeter() -> void:
	if full_farm_perimeter_built:
		store_status.text = "Todo o perímetro da fazenda já está cercado."
		return
	var points := _full_farm_perimeter_points()
	var cost := _full_farm_perimeter_cost()
	if cash_balance < cost:
		store_status.text = "Caixa insuficiente. O perímetro custa R$ %s." % _format_money(cost)
		return

	_cancel_free_construction(false)
	var breakdown := _cost_breakdown(cost, FENCE_LABOR_RATE)
	built_structures.append({
		"type": "Cerca de arame farpado — perímetro",
		"cost": cost,
		"material_cost": int(breakdown["material"]),
		"labor_cost": int(breakdown["labor"]),
		"points": points,
		"full_perimeter": true,
	})
	structure_investment += cost
	perimeter_built = true
	full_farm_perimeter_built = true
	_configure_general_farm_area()
	property_label.visible = false
	_record_split_expense("cerca de todo o perímetro", cost, FENCE_LABOR_RATE)
	store_status.text = (
		"Equipe rural iniciou a cerca do perímetro.\n"
		+ "Acompanhe a construção no mapa."
	)
	market_info.text = "Perímetro em construção. Depois, instale uma porteira para liberar o Mercado."
	_start_full_perimeter_animation(points, cost)
	_update_structures_ui()
	_apply_farm_layer_visibility()
	_update_farm_ui()


func _start_full_perimeter_animation(points: PackedVector2Array, cost: int) -> void:
	if is_instance_valid(full_perimeter_build_tween):
		full_perimeter_build_tween.kill()
	full_perimeter_preview_visual = Node2D.new()
	full_perimeter_preview_visual.name = "PerimeterConstructionPreview"
	player_structures.add_child(full_perimeter_preview_visual)
	var wire := Line2D.new()
	wire.width = 2.2
	wire.default_color = Color(0.5, 0.29, 0.1, 1)
	wire.joint_mode = Line2D.LINE_JOINT_ROUND
	full_perimeter_preview_visual.add_child(wire)
	construction_crew_visual.visible = true
	construction_crew_visual.position = points[0] + Vector2(-320.0, 260.0)
	construction_worker_1.call("start_walk")
	construction_worker_2.call("start_walk")
	construction_worker_3.call("start_walk")
	store_status.text = "Equipe rural a caminho do início da obra."
	full_perimeter_build_tween = create_tween()
	full_perimeter_build_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	full_perimeter_build_tween.tween_property(
		construction_crew_visual,
		"position",
		points[0],
		3.0
	)
	full_perimeter_build_tween.tween_callback(_start_construction_worker_actions)
	full_perimeter_build_tween.set_trans(Tween.TRANS_LINEAR)
	full_perimeter_build_tween.tween_method(
		_update_full_perimeter_animation.bind(points, wire),
		0.0,
		1.0,
		FULL_PERIMETER_BUILD_DURATION_SECONDS
	)
	full_perimeter_build_tween.finished.connect(
		_finish_full_perimeter_animation.bind(points, cost)
	)


func _start_construction_worker_actions() -> void:
	construction_worker_1.call("start_work")
	construction_worker_2.call("start_work")
	construction_worker_3.call("start_work")
	store_status.text = (
		"Equipe rural construindo: %s." % construction_job_name
		if construction_job_active
		else "Equipe rural iniciou a construção do perímetro."
	)


func _update_full_perimeter_animation(
	progress: float,
	points: PackedVector2Array,
	wire: Line2D
) -> void:
	if not is_instance_valid(wire) or points.size() < 2:
		return
	var total_length := 0.0
	for point_index in range(1, points.size()):
		total_length += points[point_index - 1].distance_to(points[point_index])
	var target_distance := total_length * clampf(progress, 0.0, 1.0)
	var traversed := 0.0
	var partial_points := PackedVector2Array([points[0]])
	var crew_position := points[0]
	for point_index in range(1, points.size()):
		var segment_start := points[point_index - 1]
		var segment_end := points[point_index]
		var segment_length := segment_start.distance_to(segment_end)
		if traversed + segment_length <= target_distance:
			partial_points.append(segment_end)
			crew_position = segment_end
			traversed += segment_length
			continue
		var segment_progress := (
			clampf((target_distance - traversed) / segment_length, 0.0, 1.0)
			if segment_length > 0.0
			else 0.0
		)
		crew_position = segment_start.lerp(segment_end, segment_progress)
		partial_points.append(crew_position)
		break
	wire.points = partial_points
	construction_crew_visual.position = crew_position
	store_status.text = "Equipe rural construindo o perímetro: %d%%" % roundi(progress * 100.0)


func _finish_full_perimeter_animation(
	points: PackedVector2Array,
	cost: int
) -> void:
	if is_instance_valid(full_perimeter_preview_visual):
		full_perimeter_preview_visual.queue_free()
	full_perimeter_preview_visual = null
	construction_crew_visual.visible = false
	_reset_construction_crew_pose()
	_create_fence_visual(points, BuildMode.BARBED_FENCE)
	player_structures.move_child(construction_preview, player_structures.get_child_count() - 1)
	store_status.text = (
		"Equipe rural cercou toda a fazenda por R$ %s.\n"
		+ "A área geral está disponível. Instale uma porteira para comprar animais."
	) % _format_money(cost)
	market_info.text = "Área geral cercada. Instale uma porteira para liberar a compra de animais."
	_update_empty_herd_guidance()
	full_perimeter_build_tween = null


func _reset_construction_crew_pose() -> void:
	construction_worker_1.call("stop_work")
	construction_worker_2.call("stop_work")
	construction_worker_3.call("stop_work")
	construction_worker_1.position = Vector2(-12.0, 0.0)
	construction_worker_1.rotation = 0.0
	construction_worker_2.position = Vector2.ZERO
	construction_worker_2.rotation = 0.0
	construction_worker_3.position = Vector2(12.0, 0.0)
	construction_worker_3.rotation = 0.0


func _cancel_free_construction(show_message := true) -> void:
	var had_construction := build_mode != BuildMode.NONE or construction_job_active
	_cancel_active_construction_job()
	_reset_build_mode()
	if show_message and had_construction:
		store_status.text = "Construção cancelada. Nenhum valor foi cobrado."


func _reset_build_mode() -> void:
	build_mode = BuildMode.NONE
	build_points = PackedVector2Array()
	pending_structure_position = Vector2.ZERO
	has_pending_structure_position = false
	construction_preview.points = PackedVector2Array()
	construction_preview.visible = false
	finish_construction_button.disabled = true
	cancel_free_construction_button.disabled = true
	_set_store_selection(BuildMode.NONE)
	_update_construction_actions_visibility()


func _current_fence_cost() -> int:
	if build_points.size() < 2:
		return 0
	var length_meters := _current_fence_length_meters()
	var rate := _current_fence_rate()
	return maxi(ceili(length_meters / 100.0 * rate), 1)


func _current_fence_length_meters() -> float:
	return _fence_length_meters_for_points(build_points)


func _fence_length_meters_for_points(points: PackedVector2Array) -> float:
	var length_units := 0.0
	for point_index in range(1, points.size()):
		length_units += points[point_index - 1].distance_to(points[point_index])
	return length_units * METERS_PER_MAP_UNIT


func _current_fence_rate() -> int:
	var rate := BARBED_FENCE_COST_PER_100
	if build_mode == BuildMode.SMOOTH_FENCE:
		rate = SMOOTH_FENCE_COST_PER_100
	elif build_mode == BuildMode.ELECTRIC_FENCE:
		rate = ELECTRIC_FENCE_COST_PER_100
	return rate


func _current_single_structure_cost() -> int:
	match build_mode:
		BuildMode.GATE:
			return FREE_GATE_COST
		BuildMode.CORRAL:
			return CORRAL_COST
		BuildMode.SCALE:
			return SCALE_COST
	return 0


func _construction_labor_rate(selected_mode: BuildMode) -> float:
	match selected_mode:
		BuildMode.GATE:
			return GATE_LABOR_RATE
		BuildMode.CORRAL:
			return CORRAL_LABOR_RATE
		BuildMode.SCALE:
			return SCALE_LABOR_RATE
	return FENCE_LABOR_RATE


func _construction_labor_rate_for_type(type_name: String) -> float:
	match type_name:
		"Porteira":
			return GATE_LABOR_RATE
		"Curral simples":
			return CORRAL_LABOR_RATE
		"Balança pecuária":
			return SCALE_LABOR_RATE
	return FENCE_LABOR_RATE


func _cost_breakdown(total_cost: int, labor_rate: float) -> Dictionary:
	var labor_cost := clampi(roundi(total_cost * labor_rate), 0, total_cost)
	return {
		"material": total_cost - labor_cost,
		"labor": labor_cost,
		"total": total_cost,
	}


func _record_split_expense(description: String, total_cost: int, labor_rate: float) -> Dictionary:
	var breakdown := _cost_breakdown(total_cost, labor_rate)
	var material_cost := int(breakdown["material"])
	var labor_cost := int(breakdown["labor"])
	if material_cost > 0:
		_record_transaction("Materiais — %s" % description, -material_cost)
	if labor_cost > 0:
		_record_transaction("Mão de obra — %s" % description, -labor_cost)
	return breakdown


func _sanitary_labor_rate(action: String) -> float:
	return COWBOY_SERVICE_RATE if action == "vitamin" else VETERINARY_LABOR_RATE


func _sanitary_service_total(action: String) -> int:
	match action:
		"parasite":
			return herd_size * PARASITE_TREATMENT_COST_PER_ANIMAL
		"clinical":
			return _clinical_treatment_candidates().size() * CLINICAL_MEDICATION_COST_PER_ANIMAL
		"brucellosis":
			return _eligible_brucellosis_calves().size() * BRUCELLOSIS_VACCINE_COST_PER_CALF
		"clostridiosis":
			return _eligible_clostridiosis_animals().size() * CLOSTRIDIOSIS_VACCINE_COST_PER_ANIMAL
		"vitamin":
			return herd_size * VITAMIN_SUPPLEMENT_COST_PER_ANIMAL
	return 0


func _record_sanitary_expense(description: String, total_cost: int, action: String) -> Dictionary:
	var breakdown := _cost_breakdown(total_cost, _sanitary_labor_rate(action))
	_record_transaction("Insumos — %s" % description, -int(breakdown["material"]))
	var service_name := "Serviço do vaqueiro" if action == "vitamin" else "Serviço veterinário"
	_record_transaction("%s — %s" % [service_name, description], -int(breakdown["labor"]))
	return breakdown


func _format_sanitary_cost(label: String, total_cost: int, action: String) -> String:
	var breakdown := _cost_breakdown(total_cost, _sanitary_labor_rate(action))
	return "%s — R$ %s\nInsumos R$ %s + equipe R$ %s" % [
		label,
		_format_money(total_cost),
		_format_money(int(breakdown["material"])),
		_format_money(int(breakdown["labor"])),
	]


func _format_cost_breakdown(total_cost: int, labor_rate: float) -> String:
	var breakdown := _cost_breakdown(total_cost, labor_rate)
	return "Material R$ %s  •  Mão de obra R$ %s  •  Total R$ %s" % [
		_format_money(int(breakdown["material"])),
		_format_money(int(breakdown["labor"])),
		_format_money(int(breakdown["total"])),
	]


func _update_fence_estimate_status(instruction: String) -> void:
	store_status.text = "%d m de cerca\n%s\n%s" % [
		roundi(_current_fence_length_meters()),
		_format_cost_breakdown(_current_fence_cost(), FENCE_LABOR_RATE),
		instruction,
	]


func _set_store_selection(selected_mode: BuildMode) -> void:
	var store_buttons := {
		BuildMode.BARBED_FENCE: barbed_fence_button,
		BuildMode.SMOOTH_FENCE: smooth_fence_button,
		BuildMode.ELECTRIC_FENCE: electric_fence_button,
		BuildMode.GATE: store_gate_button,
		BuildMode.CORRAL: corral_button,
		BuildMode.SCALE: scale_button,
	}
	for mode: BuildMode in store_buttons:
		var store_button: Button = store_buttons[mode]
		store_button.set_pressed_no_signal(mode == selected_mode)


func _update_construction_actions_visibility() -> void:
	if not is_node_ready():
		return
	var show_actions := current_module == "store" and build_mode != BuildMode.NONE
	module_actions.visible = show_actions
	sidebar_margin.offset_bottom = -90.0 if show_actions else 0.0


func _fence_color(selected_mode: BuildMode) -> Color:
	if selected_mode == BuildMode.SMOOTH_FENCE:
		return Color(0.76, 0.78, 0.73, 1)
	if selected_mode == BuildMode.ELECTRIC_FENCE:
		return Color(0.98, 0.76, 0.12, 1)
	return Color(0.34, 0.2, 0.09, 1)


func _create_fence_visual(points: PackedVector2Array, selected_mode: BuildMode) -> Node2D:
	var fence_visual := Node2D.new()
	fence_visual.name = "FenceVisual"
	fence_visual.set_meta("structure_visual", "fence")
	fence_visual.set_meta("fence_type", _build_mode_name(selected_mode))
	player_structures.add_child(fence_visual)

	if selected_mode == BuildMode.ELECTRIC_FENCE:
		var electric_glow := Line2D.new()
		electric_glow.width = 5.0
		electric_glow.default_color = Color(0.98, 0.76, 0.12, 0.22)
		electric_glow.joint_mode = Line2D.LINE_JOINT_ROUND
		electric_glow.points = points
		fence_visual.add_child(electric_glow)

	var wire := Line2D.new()
	wire.name = "Wire"
	wire.width = _fence_wire_width(selected_mode)
	wire.default_color = _fence_color(selected_mode)
	wire.joint_mode = Line2D.LINE_JOINT_ROUND
	wire.points = points
	fence_visual.add_child(wire)

	var total_length_units := 0.0
	for point_index in range(1, points.size()):
		total_length_units += points[point_index - 1].distance_to(points[point_index])
	var desired_spacing_units := FENCE_POST_SPACING_METERS / METERS_PER_MAP_UNIT
	var visual_spacing_units := maxf(
		desired_spacing_units,
		total_length_units / MAX_FENCE_POST_VISUALS
	)
	for point_index in range(1, points.size()):
		var segment_start := points[point_index - 1]
		var segment_end := points[point_index]
		var segment_length := segment_start.distance_to(segment_end)
		var post_count := floori(segment_length / visual_spacing_units)
		for post_index in range(1, post_count + 1):
			var distance_on_segment := post_index * visual_spacing_units
			if distance_on_segment >= segment_length - 8.0:
				continue
			var factor := distance_on_segment / segment_length
			_create_fence_post(
				fence_visual,
				segment_start.lerp(segment_end, factor),
				_fence_post_radius(selected_mode),
				_fence_post_color(selected_mode)
			)

	var corner_count := points.size()
	if _is_closed_fence(points):
		corner_count -= 1
	for corner_index in range(corner_count):
		_create_fence_post(
			fence_visual,
			points[corner_index],
			4.5,
			Color(0.23, 0.12, 0.045, 1)
		)
	return fence_visual


func _create_fence_post(
	parent: Node2D,
	post_position: Vector2,
	radius: float,
	color: Color
) -> Polygon2D:
	var post := Polygon2D.new()
	var post_polygon := PackedVector2Array()
	for point_index in range(10):
		var angle := TAU * point_index / 10.0
		post_polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	post.polygon = post_polygon
	post.position = post_position
	post.color = color
	parent.add_child(post)
	return post


func _fence_wire_width(selected_mode: BuildMode) -> float:
	if selected_mode == BuildMode.SMOOTH_FENCE:
		return 2.8
	if selected_mode == BuildMode.ELECTRIC_FENCE:
		return 1.4
	return 2.2


func _fence_post_radius(selected_mode: BuildMode) -> float:
	if selected_mode == BuildMode.ELECTRIC_FENCE:
		return 2.0
	if selected_mode == BuildMode.SMOOTH_FENCE:
		return 2.7
	return 2.3


func _fence_post_color(selected_mode: BuildMode) -> Color:
	if selected_mode == BuildMode.SMOOTH_FENCE:
		return Color(0.62, 0.49, 0.3, 1)
	if selected_mode == BuildMode.ELECTRIC_FENCE:
		return Color(0.92, 0.9, 0.72, 1)
	return Color(0.43, 0.26, 0.11, 1)


func _build_mode_name(selected_mode: BuildMode) -> String:
	match selected_mode:
		BuildMode.BARBED_FENCE:
			return "Cerca de arame farpado"
		BuildMode.SMOOTH_FENCE:
			return "Cerca de arame liso"
		BuildMode.ELECTRIC_FENCE:
			return "Cerca elétrica"
		BuildMode.GATE:
			return "Porteira"
		BuildMode.CORRAL:
			return "Curral simples"
		BuildMode.SCALE:
			return "Balança pecuária"
	return "Estrutura"


func _validate_free_gate_position(world_position: Vector2) -> bool:
	var nearest := _nearest_fence_position(world_position)
	if nearest.is_empty() or float(nearest["distance"]) > 70.0:
		store_status.text = "A porteira precisa ser instalada sobre uma cerca."
		return false
	if cash_balance < FREE_GATE_COST:
		store_status.text = "Caixa insuficiente para instalar a porteira."
		return false
	return true


func _validate_free_corral_position(world_position: Vector2) -> bool:
	var rect := Rect2(world_position - CORRAL_SIZE / 2.0, CORRAL_SIZE)
	if not Rect2(Vector2.ZERO, Vector2(FARM_WIDTH, FARM_HEIGHT)).encloses(rect):
		store_status.text = "O curral precisa ficar inteiramente dentro da propriedade."
		return false
	if cash_balance < CORRAL_COST:
		store_status.text = "Caixa insuficiente para construir o curral."
		return false
	return true


func _validate_free_scale_position(world_position: Vector2) -> bool:
	var inside_corral := false
	for corral_rect in corral_rects:
		if corral_rect.has_point(world_position):
			inside_corral = true
			break
	if not inside_corral:
		store_status.text = "A balança precisa ser instalada dentro de um curral."
		return false
	if cash_balance < SCALE_COST:
		store_status.text = "Caixa insuficiente para instalar a balança."
		return false
	return true


func _place_free_gate(world_position: Vector2) -> void:
	var nearest := _nearest_fence_position(world_position)
	if nearest.is_empty() or float(nearest["distance"]) > 70.0:
		store_status.text = "A porteira precisa ser instalada sobre uma cerca."
		return
	if cash_balance < FREE_GATE_COST:
		store_status.text = "Caixa insuficiente para instalar a porteira."
		return

	var gate_rotation := float(nearest["rotation"])
	var gate_direction := Vector2.RIGHT.rotated(gate_rotation)
	var hinge_position: Vector2 = nearest["position"] - (
		gate_direction * FREE_GATE_VISUAL_LENGTH / 2.0
	)
	var gate_line := _create_free_gate_visual(hinge_position, gate_rotation)
	var breakdown := _cost_breakdown(FREE_GATE_COST, GATE_LABOR_RATE)
	built_structures.append({
		"type": "Porteira",
		"cost": FREE_GATE_COST,
		"material_cost": int(breakdown["material"]),
		"labor_cost": int(breakdown["labor"]),
		"position": gate_line.position,
		"rotation": gate_line.rotation,
		"open": false,
		"hinge_pivot": true,
	})
	structure_investment += FREE_GATE_COST
	gate_installed = true
	gate_open = false
	free_gate_nodes.append(gate_line)
	free_gate_base_rotations.append(gate_line.rotation)
	free_gate_open_states.append(false)
	_record_split_expense("Porteira", FREE_GATE_COST, GATE_LABOR_RATE)
	store_status.text = "Porteira instalada e fechada. Dê duplo clique nela para abrir ou fechar."
	if _has_livestock_area():
		market_info.text = "Estrutura pronta.\nVocê já pode comprar animais."
	else:
		market_info.text = "Porteira instalada.\nFeche uma área com cerca para formar um pasto."
	_update_empty_herd_guidance()
	_reset_build_mode()
	_update_structures_ui()


func _create_free_gate_visual(hinge_position: Vector2, base_rotation: float) -> Line2D:
	var gate_line := Line2D.new()
	gate_line.name = "GateVisual"
	gate_line.width = 4.0
	gate_line.default_color = Color(0.55, 0.32, 0.12, 1)
	gate_line.points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(FREE_GATE_VISUAL_LENGTH, 0),
	])
	gate_line.position = hinge_position
	gate_line.rotation = base_rotation
	gate_line.set_meta("structure_visual", "gate")
	player_structures.add_child(gate_line)
	_create_fence_post(
		gate_line,
		Vector2.ZERO,
		5.5,
		Color(0.22, 0.11, 0.04, 1)
	)
	var receiver_position := hinge_position + (
		Vector2.RIGHT.rotated(base_rotation) * FREE_GATE_VISUAL_LENGTH
	)
	_create_fence_post(
		player_structures,
		receiver_position,
		4.5,
		Color(0.26, 0.14, 0.055, 1)
	)
	return gate_line


func _place_free_corral(world_position: Vector2) -> void:
	var rect := Rect2(world_position - CORRAL_SIZE / 2.0, CORRAL_SIZE)
	if not Rect2(Vector2.ZERO, Vector2(FARM_WIDTH, FARM_HEIGHT)).encloses(rect):
		store_status.text = "O curral precisa ficar inteiramente dentro da propriedade."
		return
	if cash_balance < CORRAL_COST:
		store_status.text = "Caixa insuficiente para construir o curral."
		return

	_create_rectangle_structure(rect, Color(0.42, 0.25, 0.1, 1), 3.5)
	var breakdown := _cost_breakdown(CORRAL_COST, CORRAL_LABOR_RATE)
	corral_rects.append(rect)
	built_structures.append({
		"type": "Curral simples",
		"cost": CORRAL_COST,
		"material_cost": int(breakdown["material"]),
		"labor_cost": int(breakdown["labor"]),
		"rect": rect,
	})
	structure_investment += CORRAL_COST
	_record_split_expense("Curral simples", CORRAL_COST, CORRAL_LABOR_RATE)
	store_status.text = "Equipe rural construiu o curral por R$ %s." % _format_money(CORRAL_COST)
	_reset_build_mode()
	_update_structures_ui()


func _place_free_scale(world_position: Vector2) -> void:
	var inside_corral := false
	for corral_rect in corral_rects:
		if corral_rect.has_point(world_position):
			inside_corral = true
			break
	if not inside_corral:
		store_status.text = "A balança precisa ser instalada dentro de um curral."
		return
	if cash_balance < SCALE_COST:
		store_status.text = "Caixa insuficiente para instalar a balança."
		return

	var rect := Rect2(world_position - Vector2(12, 6), Vector2(24, 12))
	_create_rectangle_structure(rect, Color(0.24, 0.3, 0.32, 1), 3.0)
	var breakdown := _cost_breakdown(SCALE_COST, SCALE_LABOR_RATE)
	built_structures.append({
		"type": "Balança pecuária",
		"cost": SCALE_COST,
		"material_cost": int(breakdown["material"]),
		"labor_cost": int(breakdown["labor"]),
		"rect": rect,
	})
	structure_investment += SCALE_COST
	_record_split_expense("Balança pecuária", SCALE_COST, SCALE_LABOR_RATE)
	store_status.text = "Balança instalada por R$ %s." % _format_money(SCALE_COST)
	_reset_build_mode()
	_update_structures_ui()


func _create_rectangle_structure(rect: Rect2, color: Color, width: float) -> void:
	var structure_line := Line2D.new()
	structure_line.width = width
	structure_line.default_color = color
	structure_line.joint_mode = Line2D.LINE_JOINT_ROUND
	structure_line.points = _rectangle_points(rect)
	player_structures.add_child(structure_line)


func _rectangle_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	])


func _nearest_fence_position(world_position: Vector2) -> Dictionary:
	var nearest := {}
	var shortest_distance := INF
	for structure in built_structures:
		if not str(structure.get("type", "")).begins_with("Cerca"):
			continue
		var points: PackedVector2Array = structure.get("points", PackedVector2Array())
		for point_index in range(1, points.size()):
			var segment_start := points[point_index - 1]
			var segment_end := points[point_index]
			var closest := _closest_point_on_segment(
				world_position,
				segment_start,
				segment_end
			)
			var distance := world_position.distance_to(closest)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest = {
					"distance": distance,
					"position": closest,
					"rotation": segment_start.angle_to_point(segment_end),
				}
	return nearest


func _closest_point_on_segment(point: Vector2, start: Vector2, end: Vector2) -> Vector2:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0:
		return start
	var factor := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return start + segment * factor


func _is_closed_fence(points: PackedVector2Array) -> bool:
	return points.size() >= 4 and points[0].distance_to(points[-1]) <= 1.0


func _normalize_fence_closure(points: PackedVector2Array) -> PackedVector2Array:
	var normalized := points.duplicate()
	if (
		normalized.size() >= 3
		and not _is_closed_fence(normalized)
		and normalized[0].distance_to(normalized[-1]) <= FENCE_CLOSURE_TOLERANCE
	):
		normalized.append(normalized[0])
	return normalized


func _register_free_paddock(points: PackedVector2Array) -> void:
	if free_paddock_count >= 2:
		store_status.text = "Cerca concluída. O protótipo reconhece até dois pastos."
		return

	var paddock_number := free_paddock_count + 1
	var paddock_polygon := pasture_1 if paddock_number == 1 else pasture_2
	var paddock_label := pasture_1_label if paddock_number == 1 else pasture_2_label
	var center := _polygon_center(points)
	paddock_polygon.polygon = points
	paddock_polygon.color = PASTURE_1_COLOR if paddock_number == 1 else PASTURE_2_COLOR
	paddock_polygon.visible = true
	paddock_label.position = center - Vector2(170, 65)
	paddock_label.visible = paddock_number != 1
	var capacity := clampi(
		roundi(TOTAL_FARM_CAPACITY * _polygon_area(points) / (FARM_WIDTH * FARM_HEIGHT)),
		1,
		TOTAL_FARM_CAPACITY
	)
	pasture_capacity[paddock_number] = capacity
	if paddock_number == 1:
		pasture_1_center = center
	else:
		pasture_2_center = center
	free_paddock_count = paddock_number
	perimeter_built = true
	division_created = true
	_sync_vegetation_area_geometry(paddock_number)
	property_label.visible = false
	_update_transfer_herd_action()
	_update_pasture_visuals()
	_update_finance_ui()
	_apply_farm_layer_visibility()
	_update_farm_ui()


func _update_market_readiness_ui() -> void:
	_refresh_market_sale_list()
	market_info.text = _market_rules_text()
	sell_animals_button.disabled = market_sale_list.get_selected_items().is_empty()


func _selected_market_mode() -> String:
	if market_mode_selector.item_count <= 0:
		return "buy"
	return str(market_mode_selector.get_selected_metadata())


func _on_market_mode_selected(_index: int) -> void:
	_update_market_readiness_ui()
	_update_market_mode_ui()
	sidebar_scroll.scroll_vertical = 0


func _update_market_mode_ui() -> void:
	var buying := _selected_market_mode() == "buy"
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
	market_info.text = _market_rules_text()


func _on_market_offer_changed(_index: int) -> void:
	market_info.text = _market_rules_text()


func _on_market_quantity_changed(_value: float) -> void:
	market_info.text = _market_rules_text()


func _on_market_sale_selection_changed(_index: int, _selected: bool) -> void:
	sell_animals_button.disabled = market_sale_list.get_selected_items().is_empty()
	market_info.text = _market_rules_text()


func _on_market_sale_filter_changed(_index: int) -> void:
	_refresh_market_sale_list()
	sell_animals_button.disabled = true
	market_info.text = _market_rules_text()


func _select_all_market_animals() -> void:
	for item_index in range(market_sale_list.item_count):
		market_sale_list.select(item_index, false)
	sell_animals_button.disabled = market_sale_list.get_selected_items().is_empty()
	market_info.text = _market_rules_text()


func _clear_market_sale_selection() -> void:
	market_sale_list.deselect_all()
	sell_animals_button.disabled = true
	market_info.text = _market_rules_text()


func _selected_market_category() -> String:
	if market_category_selector.item_count <= 0:
		return "heifers"
	return str(market_category_selector.get_selected_metadata())


func _selected_market_quantity() -> int:
	return maxi(int(market_quantity_selector.value), 1)


func _market_category_profile(category: String) -> Dictionary:
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


func _market_transaction_costs(quantity: int) -> Dictionary:
	return {
		"transport": MARKET_TRANSPORT_BASE_COST + MARKET_TRANSPORT_COST_PER_ANIMAL * quantity,
		"documents": MARKET_DOCUMENT_BASE_COST,
	}


func _market_purchase_quote() -> Dictionary:
	var category := _selected_market_category()
	var quantity := _selected_market_quantity()
	var profile := _market_category_profile(category)
	var animal_price := roundi(
		float(profile["weight_kg"]) * float(MARKET_BUY_PRICE_PER_KG.get(category, 10.0))
	)
	var costs := _market_transaction_costs(quantity)
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


func _market_selected_sale_animals() -> Array[Dictionary]:
	var selected_animals: Array[Dictionary] = []
	for item_index in market_sale_list.get_selected_items():
		var animal_id := str(market_sale_list.get_item_metadata(item_index))
		for animal in herd_animals:
			if str(animal.get("id", "")) == animal_id:
				selected_animals.append(animal)
				break
	return selected_animals


func _market_sale_quote() -> Dictionary:
	var selected_animals := _market_selected_sale_animals()
	var gross_total := 0
	var pregnant_count := 0
	var sanitary_alerts := 0
	for animal in selected_animals:
		var category := str(animal.get("category", "heifers"))
		gross_total += roundi(
			float(animal.get("weight_kg", 0.0))
			* float(MARKET_BUY_PRICE_PER_KG.get(category, 10.0))
			* MARKET_SELL_PRICE_FACTOR
		)
		if bool(animal.get("pregnant", false)):
			pregnant_count += 1
		if str(animal.get("sanitary_state", "Saudável")) != "Saudável":
			sanitary_alerts += 1
	var costs := _market_transaction_costs(selected_animals.size())
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


func _market_projected_capacity(category: String, quantity: int) -> Dictionary:
	if not _has_livestock_area():
		return {"available": false}
	var area_id := herd_pasture if herd_created else 1
	var profile := _market_category_profile(category)
	var projected_size := herd_size + quantity
	var projected_weight := (
		average_weight_kg * herd_size + float(profile["weight_kg"]) * quantity
	) / maxf(float(projected_size), 1.0)
	return {
		"available": true,
		"herd_size": projected_size,
		"capacity": vegetation_manager.capacity_animals(area_id, projected_weight),
	}


func _refresh_market_sale_list() -> void:
	market_sale_list.clear()
	var category_filter := "all"
	if market_sale_filter.item_count > 0:
		category_filter = str(market_sale_filter.get_selected_metadata())
	for animal in herd_animals:
		var category := str(animal.get("category", "heifers"))
		if category_filter != "all" and category != category_filter:
			continue
		var price := roundi(
			float(animal.get("weight_kg", 0.0))
			* float(MARKET_BUY_PRICE_PER_KG.get(category, 10.0))
			* MARKET_SELL_PRICE_FACTOR
		)
		var reproductive_state := " | PRENHE" if bool(animal.get("pregnant", false)) else ""
		market_sale_list.add_item("%s • %s • %.0f kg%s • R$ %s" % [
			str(animal.get("id", "")),
			_animal_category_display_name(category),
			float(animal.get("weight_kg", 0.0)),
			reproductive_state,
			_format_money(price),
		])
		var item_index := market_sale_list.item_count - 1
		market_sale_list.set_item_metadata(item_index, str(animal.get("id", "")))
		market_sale_list.set_item_tooltip(item_index, "%s\nRaça: %s\nIdade: %d meses\nSanidade: %s" % [
			str(animal.get("id", "")),
			_breed_display_name(str(animal.get("breed", DEFAULT_CATTLE_BREED))),
			int(animal.get("age_days", 0)) / 30,
			str(animal.get("sanitary_state", "Saudável")),
		])


func _market_rules_text(event_message: String = "") -> String:
	var sale := _market_sale_quote()
	if _selected_market_mode() == "sell":
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
				int(sale["quantity"]), _format_money(int(sale["gross"])),
				_format_money(int(sale["costs"])), _format_money(int(sale["net"])),
			]
			if int(sale["pregnant"]) > 0:
				sale_text += "\nATENÇÃO: inclui %d fêmea(s) prenhe(s)." % int(sale["pregnant"])
			if int(sale["sanitary_alerts"]) > 0:
				sale_text += "\nATENÇÃO: %d animal(is) com alerta sanitário." % int(sale["sanitary_alerts"])
		if event_message.is_empty():
			return sale_text
		return "%s\n\n%s" % [event_message, sale_text]

	var area_text := "pendente"
	if _using_general_farm_area():
		area_text = "pronta — área geral"
	elif _formed_paddock_count() >= 1:
		area_text = "pronta — pasto formado"
	var gate_text := "pronta" if gate_installed else "pendente"
	var purchase := _market_purchase_quote()
	var cash_text := "suficiente" if cash_balance >= int(purchase["total"]) else "insuficiente"
	var projected_capacity := _market_projected_capacity(
		str(purchase["category"]), int(purchase["quantity"])
	)
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
		_animal_category_display_name(str(purchase["category"])).to_lower(),
		_breed_display_name(_selected_market_breed()),
		int(purchase["age_days"]) / 30,
		float(purchase["weight_kg"]),
		_format_money(int(purchase["animal_price"])),
		_format_money(int(purchase["animals_total"])),
		_format_money(int(purchase["transport"])),
		_format_money(int(purchase["documents"])),
		_format_money(int(purchase["total"])),
		_format_money(maxi(cash_balance - int(purchase["total"]), 0)),
		area_text,
		gate_text,
		cash_text,
		capacity_text,
	]
	if event_message.is_empty():
		return rules
	return "%s\n\n%s" % [event_message, rules]


func _polygon_center(points: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	var point_count := points.size() - 1 if _is_closed_fence(points) else points.size()
	for point_index in range(point_count):
		center += points[point_index]
	return center / maxf(point_count, 1)


func _polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for point_index in range(points.size() - 1):
		area += (
			points[point_index].x * points[point_index + 1].y
			- points[point_index + 1].x * points[point_index].y
		)
	return absf(area) * 0.5


func _update_structures_ui() -> void:
	var counts := {
		"Cercas": 0,
		"Porteiras": 0,
		"Currais": 0,
		"Balanças": 0,
	}
	for structure in built_structures:
		var type_name := str(structure.get("type", ""))
		if type_name.begins_with("Cerca"):
			counts["Cercas"] += 1
		elif type_name == "Porteira":
			counts["Porteiras"] += 1
		elif type_name == "Curral simples":
			counts["Currais"] += 1
		elif type_name == "Balança pecuária":
			counts["Balanças"] += 1

	if built_structures.is_empty():
		counts["Cercas"] = (1 if perimeter_built else 0) + (1 if division_created else 0)
		counts["Porteiras"] = 1 if gate_installed else 0

	var total_structures: int = (
		counts["Cercas"] + counts["Porteiras"] + counts["Currais"] + counts["Balanças"]
	)
	var is_empty := total_structures == 0
	structures_inventory.text = "Nenhuma estrutura construída."
	structures_paddocks_stat.text = (
		"ÁREA DE MANEJO\nGeral cercada"
		if _using_general_farm_area()
		else "PASTOS\n%d formados" % _formed_paddock_count()
	)
	structures_fences_stat.text = "CERCAS\n%d construídas" % counts["Cercas"]
	structures_gates_stat.text = "PORTEIRAS\n%d instaladas" % counts["Porteiras"]
	structures_support_stat.text = "APOIO\n%d estruturas" % (
		counts["Currais"] + counts["Balanças"]
	)
	structures_investment.text = "VALOR CONSTRUÍDO\nR$ %s" % _format_money(
		structure_investment
	)
	if current_module == "structures":
		structures_empty_card.visible = is_empty
		structures_stats.visible = not is_empty
		structures_investment_card.visible = not is_empty
	barbed_fence_button.disabled = cash_balance < BARBED_FENCE_COST_PER_100
	var full_perimeter_cost := _full_farm_perimeter_cost()
	var full_perimeter_breakdown := _cost_breakdown(full_perimeter_cost, FENCE_LABOR_RATE)
	full_perimeter_fence_button.text = (
		"Cercar toda a fazenda — R$ %s\nMaterial R$ %s + equipe R$ %s"
		% [
			_format_money(full_perimeter_cost),
			_format_money(int(full_perimeter_breakdown["material"])),
			_format_money(int(full_perimeter_breakdown["labor"])),
		]
	)
	full_perimeter_fence_button.disabled = (
		full_farm_perimeter_built or cash_balance < full_perimeter_cost
	)
	smooth_fence_button.disabled = cash_balance < SMOOTH_FENCE_COST_PER_100
	electric_fence_button.disabled = cash_balance < ELECTRIC_FENCE_COST_PER_100
	corral_button.disabled = cash_balance < CORRAL_COST
	scale_button.disabled = cash_balance < SCALE_COST or corral_rects.is_empty()
	store_gate_button.disabled = cash_balance < FREE_GATE_COST or not _has_built_fence()
	if current_module == "farm":
		_update_farm_ui()


func _has_built_fence() -> bool:
	if perimeter_built:
		return true
	for structure in built_structures:
		if str(structure.get("type", "")).begins_with("Cerca"):
			return true
	return false


func _serialize_built_structures() -> Array:
	var serialized: Array = []
	for structure in built_structures:
		var type_name := str(structure.get("type", ""))
		var total_cost := int(structure.get("cost", 0))
		var fallback_breakdown := _cost_breakdown(
			total_cost,
			_construction_labor_rate_for_type(type_name)
		)
		var entry := {
			"type": type_name,
			"cost": total_cost,
			"material_cost": int(structure.get("material_cost", fallback_breakdown["material"])),
			"labor_cost": int(structure.get("labor_cost", fallback_breakdown["labor"])),
		}
		if structure.has("points"):
			var serialized_points: Array = []
			for point in structure["points"]:
				serialized_points.append([point.x, point.y])
			entry["points"] = serialized_points
			entry["full_perimeter"] = bool(structure.get("full_perimeter", false))
		if structure.has("position"):
			var structure_position: Vector2 = structure["position"]
			entry["position"] = [structure_position.x, structure_position.y]
			entry["rotation"] = float(structure.get("rotation", 0.0))
			entry["open"] = bool(structure.get("open", false))
			entry["hinge_pivot"] = bool(structure.get("hinge_pivot", false))
		if structure.has("rect"):
			var structure_rect: Rect2 = structure["rect"]
			entry["rect"] = [
				structure_rect.position.x,
				structure_rect.position.y,
				structure_rect.size.x,
				structure_rect.size.y,
			]
		serialized.append(entry)
	return serialized


func _restore_free_structures(serialized_structures: Array) -> void:
	for serialized in serialized_structures:
		if not serialized is Dictionary:
			continue
		var type_name := str(serialized.get("type", ""))
		var cost := maxi(int(serialized.get("cost", 0)), 0)
		var fallback_breakdown := _cost_breakdown(
			cost,
			_construction_labor_rate_for_type(type_name)
		)
		var material_cost := maxi(
			int(serialized.get("material_cost", fallback_breakdown["material"])),
			0
		)
		var labor_cost := maxi(
			int(serialized.get("labor_cost", fallback_breakdown["labor"])),
			0
		)
		if type_name.begins_with("Cerca"):
			var is_full_perimeter := bool(serialized.get("full_perimeter", false))
			var points := PackedVector2Array()
			for point_data in serialized.get("points", []):
				if point_data is Array and point_data.size() >= 2:
					points.append(Vector2(float(point_data[0]), float(point_data[1])))
			if points.size() < 2:
				continue
			points = _normalize_fence_closure(points)
			var restored_mode := BuildMode.BARBED_FENCE
			if type_name.contains("liso"):
				restored_mode = BuildMode.SMOOTH_FENCE
			elif type_name.contains("elétrica"):
				restored_mode = BuildMode.ELECTRIC_FENCE
			_create_fence_visual(points, restored_mode)
			built_structures.append({
				"type": type_name,
				"cost": cost,
				"material_cost": material_cost,
				"labor_cost": labor_cost,
				"points": points,
				"full_perimeter": is_full_perimeter,
			})
			if is_full_perimeter:
				perimeter_built = true
				full_farm_perimeter_built = true
			elif _is_closed_fence(points):
				_register_free_paddock(points)
		elif type_name == "Porteira":
			var position_data = serialized.get("position", [])
			if position_data is Array and position_data.size() >= 2:
				var restored_open := bool(serialized.get("open", false))
				var restored_base_rotation := float(serialized.get("rotation", 0.0))
				var restored_position := Vector2(
					float(position_data[0]),
					float(position_data[1])
				)
				var uses_hinge_pivot := bool(serialized.get("hinge_pivot", false))
				if not uses_hinge_pivot:
					restored_position -= (
						Vector2.RIGHT.rotated(restored_base_rotation)
						* FREE_GATE_VISUAL_LENGTH / 2.0
					)
				var restored_gate := _create_free_gate_visual(
					restored_position,
					restored_base_rotation
				)
				restored_gate.rotation = restored_base_rotation + (
					PI / 2.0 if restored_open else 0.0
				)
				built_structures.append({
					"type": type_name,
					"cost": cost,
					"material_cost": material_cost,
					"labor_cost": labor_cost,
					"position": restored_gate.position,
					"rotation": restored_base_rotation,
					"open": restored_open,
					"hinge_pivot": true,
				})
				gate_installed = true
				free_gate_nodes.append(restored_gate)
				free_gate_base_rotations.append(restored_base_rotation)
				free_gate_open_states.append(restored_open)
		elif type_name in ["Curral simples", "Balança pecuária"]:
			var rect_data = serialized.get("rect", [])
			if rect_data is Array and rect_data.size() >= 4:
				var restored_rect := Rect2(
					Vector2(float(rect_data[0]), float(rect_data[1])),
					Vector2(float(rect_data[2]), float(rect_data[3]))
				)
				var color := (
					Color(0.42, 0.25, 0.1, 1)
					if type_name == "Curral simples"
					else Color(0.24, 0.3, 0.32, 1)
				)
				var width := 3.5 if type_name == "Curral simples" else 3.0
				_create_rectangle_structure(restored_rect, color, width)
				built_structures.append({
					"type": type_name,
					"cost": cost,
					"material_cost": material_cost,
					"labor_cost": labor_cost,
					"rect": restored_rect,
				})
				if type_name == "Curral simples":
					corral_rects.append(restored_rect)
		structure_investment += cost

	player_structures.move_child(construction_preview, player_structures.get_child_count() - 1)
	_update_structures_ui()


func _build_perimeter() -> void:
	if perimeter_built:
		return
	if not _pay_infrastructure_cost("Cerca do perímetro", PERIMETER_FENCE_COST):
		return

	perimeter_built = true
	full_farm_perimeter_built = true
	perimeter_fence.visible = true
	perimeter_fence.modulate.a = 0.0
	create_tween().tween_property(perimeter_fence, "modulate:a", 1.0, 0.6)
	perimeter_button.disabled = true
	horizontal_button.disabled = false
	vertical_button.disabled = false
	property_label.text = "PROPRIEDADE CERCADA\nSEM DIVISÕES INTERNAS"
	status_label.text = "Perímetro: cercado\nDivisões internas: nenhuma\nPastos formados: nenhum"
	message_label.text = "Perímetro concluído. Agora delimite os pastos."
	_update_water_ui()


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	if (
		not terrain_info_enabled
		or current_module != "farm"
		or build_mode != BuildMode.NONE
		or not map_frame.get_global_rect().has_point(event.position)
	):
		terrain_tooltip.visible = false
		return

	var world_position := get_global_mouse_position()
	if not _is_inside_visual_property(world_position):
		terrain_tooltip.visible = false
		return
	_show_terrain_tooltip(event.position, world_position)


func _is_inside_visual_property(world_position: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(world_position, farm_visual_boundary)


func _radial_terrain_influence(
	world_position: Vector2,
	center: Vector2,
	radius: float
) -> float:
	return clampf(1.0 - world_position.distance_to(center) / radius, 0.0, 1.0)


func _relative_elevation_m(world_position: Vector2) -> int:
	var normalized_x := clampf(world_position.x / FARM_WIDTH, 0.0, 1.0)
	var normalized_y := clampf(world_position.y / FARM_HEIGHT, 0.0, 1.0)
	var elevation_factor := 0.62 - normalized_y * 0.38 + normalized_x * 0.1
	elevation_factor += _radial_terrain_influence(
		world_position,
		Vector2(1650.0, 340.0),
		850.0
	) * 0.22
	elevation_factor += _radial_terrain_influence(
		world_position,
		Vector2(2650.0, 900.0),
		700.0
	) * 0.12
	elevation_factor -= _radial_terrain_influence(
		world_position,
		Vector2(950.0, 1110.0),
		650.0
	) * 0.34
	elevation_factor -= _radial_terrain_influence(
		world_position,
		Vector2(1540.0, 1290.0),
		700.0
	) * 0.38
	return roundi(clampf(elevation_factor, 0.0, 1.0) * 40.0)


func _terrain_relief_label(elevation_m: int) -> String:
	if elevation_m <= 10:
		return "Baixada"
	if elevation_m <= 25:
		return "Meia encosta"
	return "Área alta"


func _terrain_soil_label(elevation_m: int) -> String:
	if elevation_m <= 10:
		return "Solo de baixada"
	if elevation_m <= 25:
		return "Solo argilo-arenoso"
	return "Solo raso e pedregoso"


func _terrain_moisture_at(elevation_m: int) -> int:
	var average_soil_moisture := (
		float(soil_moisture[1]) + float(soil_moisture[2])
	) / 2.0
	return roundi(clampf(
		average_soil_moisture + (20.0 - float(elevation_m)) * 1.2,
		0.0,
		100.0
	))


func _terrain_summary_at(world_position: Vector2) -> String:
	var elevation_m := _relative_elevation_m(world_position)
	return (
		"ELEVAÇÃO RELATIVA: +%d m\n"
		+ "Relevo: %s\n"
		+ "Solo: %s\n"
		+ "Umidade: %d%%"
	) % [
		elevation_m,
		_terrain_relief_label(elevation_m),
		_terrain_soil_label(elevation_m),
		_terrain_moisture_at(elevation_m),
	]


func _show_terrain_tooltip(screen_position: Vector2, world_position: Vector2) -> void:
	terrain_tooltip_label.text = _terrain_summary_at(world_position)
	terrain_tooltip.visible = true
	var viewport_size := get_viewport_rect().size
	var desired_position := screen_position + Vector2(16.0, 16.0)
	terrain_tooltip.position = Vector2(
		clampf(desired_position.x, 8.0, viewport_size.x - terrain_tooltip.size.x - 8.0),
		clampf(desired_position.y, 8.0, viewport_size.y - terrain_tooltip.size.y - 8.0)
	)


func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and build_mode != BuildMode.NONE
	):
		if event.keycode == KEY_ESCAPE:
			_cancel_free_construction()
			return
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_confirm_construction()
			return

	if build_mode != BuildMode.NONE:
		if event is InputEventMouseMotion:
			_update_construction_preview(get_global_mouse_position())
			return
		if (
			event is InputEventMouseButton
			and event.pressed
			and event.button_index == MOUSE_BUTTON_RIGHT
			and build_mode in [
				BuildMode.BARBED_FENCE,
				BuildMode.SMOOTH_FENCE,
				BuildMode.ELECTRIC_FENCE,
			]
		):
			_confirm_construction()
			return
		if (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			if (
				event.double_click
				and build_mode in [
					BuildMode.BARBED_FENCE,
					BuildMode.SMOOTH_FENCE,
					BuildMode.ELECTRIC_FENCE,
				]
			):
				var finish_position := get_global_mouse_position()
				if (
					build_points.is_empty()
					or build_points[-1].distance_to(finish_position) >= 35.0
				):
					_handle_free_build_click(finish_position)
				_confirm_construction()
				return
			_handle_free_build_click(get_global_mouse_position())
			return

	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and event.double_click
		and _toggle_gate_at(get_global_mouse_position())
	):
		get_viewport().set_input_as_handled()
		return

	if placing_gate:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_place_gate(get_global_mouse_position())
		return

	if (
		current_module == "farm"
		and event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and _select_farm_pasture_at(get_global_mouse_position())
	):
		get_viewport().set_input_as_handled()
		return

	if division_mode == DivisionMode.NONE or division_created:
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	var click_position := get_global_mouse_position()

	if division_mode == DivisionMode.HORIZONTAL:
		_create_horizontal_division(click_position.y)
	elif division_mode == DivisionMode.VERTICAL:
		_create_vertical_division(click_position.x)


func _start_horizontal_division() -> void:
	if not perimeter_built:
		message_label.text = "Cerque o perímetro da fazenda primeiro."
		return

	division_mode = DivisionMode.HORIZONTAL
	message_label.text = "Clique entre os dois açudes para posicionar a cerca horizontal."
	cancel_button.disabled = false


func _start_vertical_division() -> void:
	if not perimeter_built:
		message_label.text = "Cerque o perímetro da fazenda primeiro."
		return

	division_mode = DivisionMode.VERTICAL
	message_label.text = "Clique entre os dois açudes para posicionar a cerca vertical."
	cancel_button.disabled = false


func _cancel_division() -> void:
	division_mode = DivisionMode.NONE
	placing_gate = false
	message_label.text = "Construção cancelada."
	cancel_button.disabled = true


func _create_horizontal_division(y_position: float) -> void:
	if y_position < HORIZONTAL_MIN or y_position > HORIZONTAL_MAX:
		message_label.text = "Posição inválida. Clique na faixa entre os dois açudes."
		return
	if not _pay_infrastructure_cost("Cerca interna", INTERNAL_FENCE_COST):
		return

	pasture_1.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(FARM_WIDTH, 0),
		Vector2(FARM_WIDTH, y_position),
		Vector2(0, y_position),
	])
	pasture_2.polygon = PackedVector2Array([
		Vector2(0, y_position),
		Vector2(FARM_WIDTH, y_position),
		Vector2(FARM_WIDTH, FARM_HEIGHT),
		Vector2(0, FARM_HEIGHT),
	])
	internal_fence.points = PackedVector2Array([
		Vector2(0, y_position),
		Vector2(FARM_WIDTH, y_position),
	])
	division_orientation = DivisionMode.HORIZONTAL
	division_position = y_position
	pasture_1_label.position = Vector2(1450, y_position * 0.45)
	pasture_2_label.position = Vector2(1450, y_position + ((FARM_HEIGHT - y_position) * 0.5))
	pasture_1_center = Vector2(FARM_WIDTH * 0.5, y_position * 0.5)
	pasture_2_center = Vector2(FARM_WIDTH * 0.5, y_position + ((FARM_HEIGHT - y_position) * 0.5))
	_update_pasture_capacities(y_position / FARM_HEIGHT)
	_sync_all_vegetation_geometry()
	_finish_division()


func _create_vertical_division(x_position: float) -> void:
	if x_position < VERTICAL_MIN or x_position > VERTICAL_MAX:
		message_label.text = "Posição inválida. Clique na faixa entre os dois açudes."
		return
	if not _pay_infrastructure_cost("Cerca interna", INTERNAL_FENCE_COST):
		return

	pasture_1.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(x_position, 0),
		Vector2(x_position, FARM_HEIGHT),
		Vector2(0, FARM_HEIGHT),
	])
	pasture_2.polygon = PackedVector2Array([
		Vector2(x_position, 0),
		Vector2(FARM_WIDTH, 0),
		Vector2(FARM_WIDTH, FARM_HEIGHT),
		Vector2(x_position, FARM_HEIGHT),
	])
	internal_fence.points = PackedVector2Array([
		Vector2(x_position, 0),
		Vector2(x_position, FARM_HEIGHT),
	])
	division_orientation = DivisionMode.VERTICAL
	division_position = x_position
	pasture_1_label.position = Vector2(x_position * 0.45, 850)
	pasture_2_label.position = Vector2(x_position + ((FARM_WIDTH - x_position) * 0.45), 850)
	pasture_1_center = Vector2(x_position * 0.5, FARM_HEIGHT * 0.5)
	pasture_2_center = Vector2(x_position + ((FARM_WIDTH - x_position) * 0.5), FARM_HEIGHT * 0.5)
	_update_pasture_capacities(x_position / FARM_WIDTH)
	_sync_all_vegetation_geometry()
	_finish_division()


func _update_pasture_capacities(pasture_1_fraction: float) -> void:
	var pasture_1_capacity := clampi(
		roundi(TOTAL_FARM_CAPACITY * pasture_1_fraction),
		1,
		TOTAL_FARM_CAPACITY - 1
	)
	pasture_capacity = {
		1: pasture_1_capacity,
		2: TOTAL_FARM_CAPACITY - pasture_1_capacity,
	}


func _finish_division() -> void:
	division_created = true
	division_mode = DivisionMode.NONE
	pasture_1.color = PASTURE_1_COLOR
	pasture_2.color = PASTURE_2_COLOR
	pasture_1.visible = true
	pasture_2.visible = true
	internal_fence.visible = true
	pasture_1_label.visible = false
	pasture_2_label.visible = true
	property_label.visible = false
	forage_field.position = pasture_2_center
	forage_field_label.position = pasture_2_center - Vector2(260, 65)
	forage_field.visible = true
	forage_field_label.visible = true
	horizontal_button.disabled = true
	vertical_button.disabled = true
	cancel_button.disabled = true
	gate_install_button.disabled = false
	status_label.text = "Perímetro: cercado\nDivisões internas: 1\nPastos formados: 2\nAçudes: 1 em cada pasto"
	message_label.text = "Divisão concluída. Agora instale uma porteira."
	_update_pasture_visuals()
	_update_nutrition_ui()
	_update_water_ui()
	_update_agriculture_ui()
	_update_reproduction_ui()
	_update_sanitary_ui()
	_apply_farm_layer_visibility()
	_update_farm_ui()


func _start_gate_placement() -> void:
	if not division_created or gate_installed:
		return

	placing_gate = true
	division_mode = DivisionMode.NONE
	cancel_button.disabled = false
	message_label.text = "Clique sobre a cerca interna para instalar a porteira."


func _place_gate(click_position: Vector2) -> void:
	if division_orientation == DivisionMode.HORIZONTAL:
		if absf(click_position.y - division_position) > 100.0:
			message_label.text = "Clique mais perto da cerca interna."
			return
	else:
		if absf(click_position.x - division_position) > 100.0:
			message_label.text = "Clique mais perto da cerca interna."
			return
	if not _pay_infrastructure_cost("Porteira", GATE_COST):
		return

	if division_orientation == DivisionMode.HORIZONTAL:
		var gate_center_x := clampf(click_position.x, 250.0, FARM_WIDTH - 250.0)
		gate_center_position = gate_center_x
		var gate_start_x := gate_center_x - (GATE_LENGTH / 2.0)
		var gate_end_x := gate_center_x + (GATE_LENGTH / 2.0)
		internal_fence.points = PackedVector2Array([
			Vector2(0, division_position),
			Vector2(gate_start_x, division_position),
		])
		internal_fence_2.points = PackedVector2Array([
			Vector2(gate_end_x, division_position),
			Vector2(FARM_WIDTH, division_position),
		])
		gate.position = Vector2(gate_start_x, division_position)
		gate.points = PackedVector2Array([Vector2.ZERO, Vector2(GATE_LENGTH, 0)])
	else:
		var gate_center_y := clampf(click_position.y, 250.0, FARM_HEIGHT - 250.0)
		gate_center_position = gate_center_y
		var gate_start_y := gate_center_y - (GATE_LENGTH / 2.0)
		var gate_end_y := gate_center_y + (GATE_LENGTH / 2.0)
		internal_fence.points = PackedVector2Array([
			Vector2(division_position, 0),
			Vector2(division_position, gate_start_y),
		])
		internal_fence_2.points = PackedVector2Array([
			Vector2(division_position, gate_end_y),
			Vector2(division_position, FARM_HEIGHT),
		])
		gate.position = Vector2(division_position, gate_start_y)
		gate.points = PackedVector2Array([Vector2.ZERO, Vector2(0, GATE_LENGTH)])

	internal_fence_2.visible = true
	gate.visible = true
	gate_installed = true
	placing_gate = false
	cancel_button.disabled = true
	gate_install_button.disabled = true
	buy_animals_button.disabled = false
	status_label.text = "Perímetro: cercado\nDivisões internas: 1\nPastos formados: 2\nPorteiras: 1"
	message_label.text = "Porteira instalada e fechada."
	herd_status.text = "Estrutura pronta. Adquira animais no Mercado."
	_update_finance_ui()
	_update_water_ui()


func _toggle_gate() -> void:
	if not gate_installed:
		return

	if not free_gate_nodes.is_empty():
		_set_free_gate_open(0, not free_gate_open_states[0])
		return

	gate_open = not gate_open
	var target_rotation := 0.0

	if gate_open:
		target_rotation = PI / 2.0 if division_orientation == DivisionMode.HORIZONTAL else -PI / 2.0

	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT).tween_property(
		gate,
		"rotation",
		target_rotation,
		0.3
	)
	message_label.text = "Porteira aberta." if gate_open else "Porteira fechada."
	_update_farm_ui()


func _toggle_gate_at(world_position: Vector2) -> bool:
	for gate_index in range(free_gate_nodes.size() - 1, -1, -1):
		var gate_node := free_gate_nodes[gate_index]
		if not is_instance_valid(gate_node):
			continue
		var local_position := gate_node.to_local(world_position)
		if _distance_to_line_points(local_position, gate_node.points) <= 55.0:
			_set_free_gate_open(gate_index, not free_gate_open_states[gate_index])
			return true

	if gate_installed and free_gate_nodes.is_empty():
		var legacy_local_position := gate.to_local(world_position)
		if _distance_to_line_points(legacy_local_position, gate.points) <= 55.0:
			_toggle_gate()
			return true
	return false


func _distance_to_line_points(point: Vector2, points: PackedVector2Array) -> float:
	var shortest_distance := INF
	for point_index in range(1, points.size()):
		shortest_distance = minf(
			shortest_distance,
			point.distance_to(_closest_point_on_segment(
				point,
				points[point_index - 1],
				points[point_index]
			))
		)
	return shortest_distance


func _set_free_gate_open(gate_index: int, is_open: bool) -> void:
	if gate_index < 0 or gate_index >= free_gate_nodes.size():
		return
	free_gate_open_states[gate_index] = is_open
	var target_rotation := free_gate_base_rotations[gate_index]
	if is_open:
		target_rotation += PI / 2.0
	create_tween().set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_IN_OUT
	).tween_property(
		free_gate_nodes[gate_index],
		"rotation",
		target_rotation,
		0.3
	)
	_sync_free_gate_structure_state(gate_index, is_open)
	gate_open = free_gate_open_states.any(func(open_state: bool) -> bool: return open_state)
	_update_farm_ui()


func _sync_free_gate_structure_state(gate_index: int, is_open: bool) -> void:
	var current_gate_index := 0
	for structure in built_structures:
		if str(structure.get("type", "")) != "Porteira":
			continue
		if current_gate_index == gate_index:
			structure["open"] = is_open
			return
		current_gate_index += 1


func _add_initial_herd() -> void:
	if not gate_installed or herd_created:
		return
	if not _has_livestock_area():
		herd_status.text = "Cerque a propriedade ou forme um pasto antes de adicionar animais."
		return

	herd_created = true
	herd_animals.clear()
	_add_individual_animals("heifers", 4)
	_add_individual_animals("cows", 5)
	_add_individual_animals("bulls", 1)
	herd_pasture = 1
	herd_marker.position = pasture_1_center - Vector2(115, 55)
	herd_marker.visible = true
	_update_herd_marker()
	_update_transfer_herd_action()
	sell_animals_button.disabled = true
	market_info.text = "Animais adicionados ao cenário.\nCompra: R$ %s | Venda: R$ %s por cabeça." % [
		_format_money(PURCHASE_PRICE_PER_ANIMAL),
		_format_money(SALE_PRICE_PER_ANIMAL),
	]
	_update_herd_status("Animais adicionados à área de manejo.")
	_update_finance_ui()
	_update_nutrition_ui()
	_update_agriculture_ui()
	_update_reproduction_ui()
	_update_sanitary_ui()


func _transfer_herd() -> void:
	if not herd_created:
		return
	if _formed_paddock_count() < 2:
		herd_status.text = "Construa um segundo pasto fechado antes da transferência."
		return
	if not gate_open:
		herd_status.text = "A porteira está fechada.\nAbra antes de transferir o lote."
		return

	herd_pasture = 2 if herd_pasture == 1 else 1
	_update_herd_marker()
	_update_transfer_herd_action()
	_update_herd_status("Lote transferido.")
	_update_nutrition_ui()


func _start_natural_breeding() -> void:
	if not _can_start_breeding():
		return
	if int(herd_categories["bulls"]) < 1:
		reproduction_status.text = "A monta natural exige pelo menos um touro."
		return

	_start_breeding_cycle("Monta natural", 0.0)


func _start_artificial_insemination() -> void:
	if not _can_start_breeding():
		return
	if cash_balance < ARTIFICIAL_INSEMINATION_COST:
		reproduction_status.text = "Caixa insuficiente para a inseminação."
		return

	_record_transaction("Inseminação das matrizes", -ARTIFICIAL_INSEMINATION_COST)
	_start_breeding_cycle("Inseminação artificial", 8.0)


func _can_start_breeding() -> bool:
	if not herd_created:
		reproduction_status.text = "Compre animais no Mercado antes de iniciar a reprodução."
		return false
	if pregnant_females > 0:
		reproduction_status.text = "Já existe uma gestação em andamento."
		return false
	if calf_age_days >= 0:
		reproduction_status.text = "Aguarde a desmama do lote atual de bezerros."
		return false
	var eligible := _eligible_breeding_females()
	if eligible.is_empty():
		reproduction_status.text = "Não há fêmeas aptas para reprodução."
		return false
	if body_condition < 2.5 or health < 60.0:
		reproduction_status.text = "Condição corporal ou saúde insuficiente para a reprodução."
		return false
	return true


func _eligible_breeding_females() -> Array:
	var eligible: Array = []
	for animal in herd_animals:
		var cat := str(animal.get("category", ""))
		if cat == "cows":
			eligible.append(animal)
		elif cat == "heifers":
			var w_kg := float(animal.get("weight_kg", 0.0))
			if w_kg >= FIRST_BREEDING_WEIGHT_KG:
				eligible.append(animal)
	return eligible


func _start_breeding_cycle(method: String, fertility_bonus: float) -> void:
	var eligible := _eligible_breeding_females()
	var eligible_count := eligible.size()
	if eligible_count == 0:
		return
	var condition_adjustment := (body_condition - 3.0) * 8.0
	var conception_rate := clampf(
		_herd_average_phenotype("fertility") + fertility_bonus + condition_adjustment,
		35.0,
		95.0
	)
	pregnant_females = clampi(roundi(eligible_count * conception_rate / 100.0), 1, eligible_count)
	gestation_days_remaining = GESTATION_DAYS
	breeding_method = method
	var pregnancies_to_assign := pregnant_females
	for animal in herd_animals:
		animal["pregnant"] = false
		animal["gestation_days"] = 0
	for animal in eligible:
		if pregnancies_to_assign <= 0:
			break
		animal["pregnant"] = true
		animal["gestation_days"] = GESTATION_DAYS
		pregnancies_to_assign -= 1
	_update_reproduction_ui()


func _advance_reproduction_day() -> String:
	var event_message := ""

	if calf_age_days >= 0:
		calf_age_days += 1
		var weaned_females := 0
		var weaned_males := 0
		for animal in herd_animals:
			var cat := str(animal.get("category", ""))
			if cat not in ["female_calves", "male_calves"]:
				continue
			var w_kg := float(animal.get("weight_kg", 0.0))
			var age_d := int(animal.get("age_days", 0))
			if w_kg >= WEANING_WEIGHT_KG or age_d >= WEANING_AGE_DAYS:
				animal["age_days"] = maxi(age_d, WEANING_AGE_DAYS)
				if cat == "female_calves":
					weaned_females += 1
				else:
					weaned_males += 1
		if weaned_females + weaned_males > 0:
			_sync_herd_size()
			event_message = "Desmama: %d fêmeas e %d machos." % [weaned_females, weaned_males]
		if int(herd_categories["female_calves"]) + int(herd_categories["male_calves"]) == 0:
			calf_age_days = -1

	if pregnant_females <= 0:
		return event_message

	gestation_days_remaining = maxi(gestation_days_remaining - 1, 0)
	for animal in herd_animals:
		if bool(animal.get("pregnant", false)):
			animal["gestation_days"] = gestation_days_remaining
	if gestation_days_remaining > 0:
		return event_message

	var births := pregnant_females
	var female_births := ceili(births / 2.0)
	var male_births := births - female_births
	var newborn_breeds: Array[String] = []
	for animal in herd_animals:
		if bool(animal.get("pregnant", false)):
			newborn_breeds.append(_normalize_breed(str(animal.get("breed", DEFAULT_CATTLE_BREED))))
	if newborn_breeds.is_empty():
		newborn_breeds.append(DEFAULT_CATTLE_BREED)
	for animal in herd_animals:
		if bool(animal.get("pregnant", false)):
			animal["pregnant"] = false
			animal["gestation_days"] = 0
			animal["has_calved"] = true
	var newborn_index := 0
	var pregnant_mothers: Array = []
	for animal in herd_animals:
		if bool(animal.get("pregnant", false)):
			pregnant_mothers.append(animal)
	var mother_idx := 0
	for _female_index in range(female_births):
		if mother_idx >= pregnant_mothers.size():
			mother_idx = 0
		var mother := pregnant_mothers[mother_idx]
		mother_idx += 1
			
		// Find a bull father - look for intact males
		var father := {}
		for a in herd_animals:
			if bool(a.get("intact_male", false)) and str(a.get("category", "")) == "bulls":
				father := a
				break
		if father == {}:
			father := herd_animals[0]  // fallback
				
		// Resolve calf breed: use father's breed if different from mother, else mother's
		var calf_breed := _resolve_offspring_breed(
			str(mother["breed"]),
			str(father["breed"])
		)
			
		// Create offspring genotype via Punnett square inheritance
		var calf_genotype := _create_offspring_genotype(mother, father)
			
		var female_calf := _create_individual_animal("female_calves", calf_genotype, calf_breed)
		female_calf["age_days"] = 0
		female_calf["weight_kg"] = 32.0
		herd_animals.append(female_calf)
		newborn_index += 1
	for _male_index in range(male_births):
		if mother_idx >= pregnant_mothers.size():
			mother_idx = 0
		var mother := pregnant_mothers[mother_idx]
		mother_idx += 1
			
		var father := {}
		for a in herd_animals:
			if bool(a.get("intact_male", false)) and str(a.get("category", "")) == "bulls":
				father := a
				break
		if father == {}:
			father := herd_animals[0]
				
		var calf_breed := _resolve_offspring_breed(
			str(mother["breed"]),
			str(father["breed"])
		)
			
		var calf_genotype := _create_offspring_genotype(mother, father)
			
		var male_calf := _create_individual_animal("male_calves", calf_genotype, calf_breed)
		male_calf["age_days"] = 0
		male_calf["weight_kg"] = 34.0
		herd_animals.append(male_calf)
		newborn_index += 1
	pregnant_females = 0
	gestation_days_remaining = 0
	breeding_method = ""

	if births > 0:
		calf_age_days = 0
		_sync_herd_size()
		_update_herd_marker()
		return "Nasceram %d bezerros: %d fêmeas e %d machos." % [
			births,
			female_births,
			male_births,
		]

	return "O parto foi adiado por falta de capacidade na fazenda."


func _sync_herd_size() -> void:
	if herd_created or not herd_animals.is_empty():
		_rebuild_herd_categories()
		return
	herd_size = 0
	for category in herd_categories:
		herd_size += int(herd_categories[category])


func _update_herd_genotype_averages() -> void:
	var herd_animal_list: Array = herd_animals.filter(
		func(a: Dictionary) -> bool: return str(a.get("destiny", "")) == "herd"
	)
	if herd_animal_list.is_empty():
		return
	for trait in GENETIC_TRAITS:
		herd_genotype_average[trait] = _herd_average_phenotype(trait)


func _create_individual_animal(
	category: String,
	custom_genotype: Dictionary = {},
	custom_breed: String = DEFAULT_CATTLE_BREED
) -> Dictionary:
	var sex := "female" if category in ["female_calves", "heifers", "cows"] else "male"
	var category_profile := _market_category_profile(category)
	
	// Handle legacy "genetics" field for backward compatibility
	var legacy_genetics := custom_genotype.get("genetics", {})
	var has_legacy_genetics := not legacy_genetics.is_empty() and legacy_genetics.has_key("fertility")
	
	var animal_genotype: Dictionary = (
		if has_legacy_genetics:
			// Convert legacy genetics to new genotype format
			_genetics_to_genotype(legacy_genetics, _normalize_breed(custom_breed))
		else:
			custom_genotype.duplicate(true)
			if not custom_genotype.is_empty()
			else _generate_random_genotype(_normalize_breed(custom_breed))
	)
	var animal := {
		"id": "BOV-%04d" % next_animal_id,
		"sex": sex,
		"age_days": int(category_profile["age_days"]),
		"category": category,
		"breed": _normalize_breed(custom_breed),
		"weight_kg": float(category_profile["weight_kg"]),
		"hunger": hunger,
		"thirst": thirst,
		"health": health,
		"genotype": animal_genotype,
		"destiny": "herd" if category in ["cows", "heifers", "bulls"] else "unassigned",
		"pregnant": false,
		"gestation_days": 0,
		"has_calved": category == "cows",
		"intact_male": category == "bulls",
		"parasite_load": 0.0,
		"sanitary_state": "Saudável",
		"brucellosis_vaccinated": false,
		"clostridiosis_vaccine_days_remaining": 0,
	}
	next_animal_id += 1
	return animal


func _genetics_to_genotype(legacy_genetics: Dictionary, breed: String) -> Dictionary:
	// Convert the old 6-trait genetics dictionary to the new polygenic genotype format
	var genotype := {}
	for trait in ALL_TRAITS:
		genotype[trait] := {}
		var locus_count := 3
		for locus_idx in range(locus_count):
			var locus_name := "locus_%d" % (locus_idx + 1)
			// Map the old value (0-100) to allele dominance
			// Higher values = more dominant alleles
			var old_value := float(legacy_genetics.get(trait, 50.0))
			var dominant_alleles := roundi(old_value / (100.0 / (locus_count * 2)))  // roughly how many dominant alleles
			var total_alleles := locus_count * 2
			var recessive_alleles := total_alleles - dominant_alleles
			
			// Generate dominant alleles (A) and recessive alleles (a)
			var loci := {}
			for i in range(locus_count):
				var locus_locus_name := "locus_%d" % (i + 1)
				// Distribute dominant alleles across loci
				var has_dominant := dominant_alleles > 0
				dominant_alleles = maxi(dominant_alleles - 1, 0)
				loci[locus_locus_name] := ["A", "a"]  // default heterozygous
				if not has_dominant:
					loci[locus_locus_name] := ["a", "a"]
				// If we have leftover dominant alleles, make this locus homozygous dominant
				if dominant_alleles > 0 and i == locus_count - 1:
					loci[locus_locus_name] := ["A", "A"]
			genotype[trait] := loci
	return genotype


func _add_individual_animals(
	category: String,
	quantity: int,
	custom_genotype: Dictionary = {},
	custom_breed: String = DEFAULT_CATTLE_BREED
) -> void:
	for _animal_index in range(maxi(quantity, 0)):
		herd_animals.append(
			_create_individual_animal(category, custom_genotype, custom_breed)
		)
	_sync_herd_size()


func _normalize_breed(breed_key: String) -> String:
	for breed_definition in CATTLE_BREEDS:
		if str(breed_definition["key"]) == breed_key:
			return breed_key
	return DEFAULT_CATTLE_BREED


const BREED_GENOTYPE_PROFILES := {
	"nelore": {
		"fertility": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["a","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"heat_adaptation": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"parasite_resistance": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"weight_gain": {"locus_1": ["A","a"], "locus_2": ["a","a"], "locus_3": ["a","a"]},
		"maternal_ability": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
	},
	"angus": {
		"fertility": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["a","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"heat_adaptation": {"locus_1": ["a","a"], "locus_2": ["a","a"], "locus_3": ["A","a"]},
		"parasite_resistance": {"locus_1": ["A","a"], "locus_2": ["a","a"], "locus_3": ["a","a"]},
		"weight_gain": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"maternal_ability": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
	},
	"guzera": {
		"fertility": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","A"]},
		"heat_adaptation": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"parasite_resistance": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"weight_gain": {"locus_1": ["A","a"], "locus_2": ["a","a"], "locus_3": ["a","a"]},
		"maternal_ability": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
	},
	"brahman": {
		"fertility": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"calving_ease": {"locus_1": ["A","a"], "locus_2": ["a","a"], "locus_3": ["a","a"]},
		"heat_adaptation": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","A"]},
		"parasite_resistance": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","A"]},
		"weight_gain": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"maternal_ability": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
	},
	"tabapua": {
		"fertility": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"heat_adaptation": {"locus_1": ["A","a"], "locus_2": ["a","a"], "locus_3": ["a","a"]},
		"parasite_resistance": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"weight_gain": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"maternal_ability": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
	},
	"sindi": {
		"fertility": {"locus_1": ["a","a"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"calving_ease": {"locus_1": ["a","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"heat_adaptation": {"locus_1": ["a","a"], "locus_2": ["a","a"], "locus_3": ["A","A"]},
		"parasite_resistance": {"locus_1": ["a","a"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"weight_gain": {"locus_1": ["a","a"], "locus_2": ["a","a"], "locus_3": ["a","a"]},
		"maternal_ability": {"locus_1": ["a","a"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
	},
	"angus": {
		"fertility": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["a","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"heat_adaptation": {"locus_1": ["a","a"], "locus_2": ["a","a"], "locus_3": ["A","a"]},
		"parasite_resistance": {"locus_1": ["A","a"], "locus_2": ["a","a"], "locus_3": ["a","a"]},
		"weight_gain": {"locus_1": ["A","A"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"maternal_ability": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
	},
	"hereford": {
		"fertility": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"heat_adaptation": {"locus_1": ["a","a"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"parasite_resistance": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"weight_gain": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"maternal_ability": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
	},
	"brangus": {
		"fertility": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"heat_adaptation": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"parasite_resistance": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"weight_gain": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"maternal_ability": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
	},
	"braford": {
		"fertility": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"heat_adaptation": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["a","a"]},
		"parasite_resistance": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"weight_gain": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"maternal_ability": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
	},
	"senepol": {
		"fertility": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"calving_ease": {"locus_1": ["A","A"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"heat_adaptation": {"locus_1": ["A","a"], "locus_2": ["A","A"], "locus_3": ["A","a"]},
		"parasite_resistance": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"weight_gain": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
		"maternal_ability": {"locus_1": ["A","a"], "locus_2": ["A","a"], "locus_3": ["A","a"]},
	},
}

func _generate_random_genotype(breed: String) -> Dictionary:
	var base := BREED_GENOTYPE_PROFILES.get(breed, BREED_GENOTYPE_PROFILES["nelore"])
	var genotype := {}
	for trait in ALL_TRAITS:
		genotype[trait] := {}
		var trait_base := base.get(trait, {})
		for locus_name in trait_base:
			var alleles := trait_base[locus_name].duplicate()
			// 10% chance of mutation per allele
			if randf() < 0.10:
				alleles[0] = _flip_allele(alleles[0])
			if randf() < 0.10:
				alleles[1] = _flip_allele(alleles[1])
			genotype[trait][locus_name] := alleles
	return genotype

func _flip_allele(allele: String) -> String:
	return allele.to_lower() if allele == allele.to_upper() else allele.to_upper()

func _calculate_phenotype(genotype: Dictionary, trait: String) -> float:
	var loci = genotype[trait]
	var dominant_count = 0
	var total_alleles = 0
	for locus in loci:
		for allele in locus:
			total_alleles += 1
			if allele == allele.to_upper():
				dominant_count += 1
	if total_alleles == 0:
		return 50.0
	return (dominant_count / float(total_alleles)) * 100.0

func _herd_average_phenotype(trait: String) -> float:
	var herd_animal_list: Array = herd_animals.filter(
		func(a: Dictionary) -> bool: return str(a.get("destiny", "")) == "herd"
	)
	if herd_animal_list.is_empty():
		return herd_genotype_average[trait]
	var total := 0.0
	for animal in herd_animal_list:
		total += _calculate_phenotype(animal["genotype"], trait)
	return total / float(herd_animal_list.size())

func _herd_genetics_snapshot() -> Dictionary:
	var snapshot := {}
	for trait in GENETIC_TRAITS:
		snapshot[trait] = _herd_average_phenotype(trait)
	return snapshot

func _create_offspring_genotype(mother: Dictionary, father: Dictionary) -> Dictionary:
	var offspring_genotype := {}
	for trait in ALL_TRAITS:
		offspring_genotype[trait] := {}
		for locus_idx in range(LOCI_PER_TRAIT):
			var locus_name := "locus_%d" % (locus_idx + 1)
			// Mother contributes 1 random allele
			var mother_alleles := mother["genotype"][trait][locus_name]
			var maternal_allele := mother_alleles.pick_random()
			// Father contributes 1 random allele
			var father_alleles := father["genotype"][trait][locus_name]
			var paternal_allele := father_alleles.pick_random()
			// Punnett: combine maternal and paternal alleles
			offspring_genotype[trait][locus_name] := [maternal_allele, paternal_allele]
	return offspring_genotype

func _selected_market_breed() -> String:
	return _normalize_breed(str(breed_selector.get_selected_metadata()))


func _breed_display_name(breed_key: String) -> String:
	for breed_definition in CATTLE_BREEDS:
		if str(breed_definition["key"]) == breed_key:
			return str(breed_definition["name"])
	return "Nelore"


func _animal_category_display_name(category: String) -> String:
	return {
		"female_calves": "Bezerra",
		"male_calves": "Bezerro",
		"heifers": "Novilha",
		"cows": "Vaca",
		"steers": "Garrote",
		"oxen": "Boi",
		"bulls": "Touro",
	}.get(category, "Bovino")


func _rebuild_herd_categories() -> void:
	herd_categories = {
		"female_calves": 0,
		"male_calves": 0,
		"heifers": 0,
		"cows": 0,
		"steers": 0,
		"oxen": 0,
		"bulls": 0,
	}
	var weight_total := 0.0
	for animal in herd_animals:
		var category := _category_for_animal(animal)
		animal["category"] = category
		herd_categories[category] = int(herd_categories[category]) + 1
		weight_total += float(animal.get("weight_kg", average_weight_kg))
	herd_size = herd_animals.size()
	if herd_size > 0:
		average_weight_kg = weight_total / float(herd_size)


func _category_for_animal(animal: Dictionary) -> String:
	var age_days := int(animal.get("age_days", 0))
	var sex := str(animal.get("sex", "female"))
	var w_kg := float(animal.get("weight_kg", 0.0))
	if sex == "female":
		if age_days < WEANING_AGE_DAYS and w_kg < WEANING_WEIGHT_KG:
			return "female_calves"
		if bool(animal.get("has_calved", false)) or age_days >= 900:
			return "cows"
		return "heifers"
	if bool(animal.get("intact_male", false)):
		return "bulls"
	if age_days < WEANING_AGE_DAYS:
		return "male_calves"
	if age_days < 730:
		return "steers"
	return "oxen"


func _update_reproduction_ui() -> void:
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
			cycle_text = "bezerros com %d dias | desmame aos %d kg" % [
				calf_age_days,
				WEANING_WEIGHT_KG,
			]

		reproduction_status.text = (
			"Vacas: %d | Novilhas: %d | Touro: %d\n"
			+ "Bezerros: %d F / %d M | Garrotes: %d | Bois: %d\n"
			+ "%s\n"
			+ "Fertilidade %d | Parto %d | Materna %d\n"
			+ "Calor %d | Parasitas %d | Ganho %d"
		) % [
			int(herd_categories["cows"]),
			int(herd_categories["heifers"]),
			int(herd_categories["bulls"]),
			int(herd_categories["female_calves"]),
			int(herd_categories["male_calves"]),
			int(herd_categories["steers"]),
			int(herd_categories["oxen"]),
			cycle_text,
			roundi(float(_herd_genetics_snapshot()["fertility"])),
			roundi(float(_herd_genetics_snapshot()["calving_ease"])),
			roundi(float(_herd_genetics_snapshot()["maternal_ability"])),
			roundi(float(_herd_genetics_snapshot()["heat_adaptation"])),
			roundi(float(_herd_genetics_snapshot()["parasite_resistance"])),
			roundi(float(_herd_genetics_snapshot()["weight_gain"])),
		]

	var can_breed_now := (
		herd_created
		and pregnant_females == 0
		and calf_age_days < 0
		and not _eligible_breeding_females().is_empty()
		and body_condition >= 2.5
		and health >= 60.0
	)
	natural_breeding_button.disabled = (
		not can_breed_now
		or int(herd_categories["bulls"]) < 1
	)
	insemination_button.disabled = (
		not can_breed_now
		or cash_balance < ARTIFICIAL_INSEMINATION_COST
	)


func _daily_parasite_increase(parasite_resistance: float) -> float:
	var capacity := maxi(int(pasture_capacity[herd_pasture]), 1)
	var grazing_pressure := float(herd_size) / float(capacity)
	var environmental_exposure: float = (
		0.45
		+ minf(rainfall_mm / 30.0, 1.5)
		+ float(soil_moisture[herd_pasture]) / 300.0
		+ pasture_degradation[herd_pasture] / 100.0
		+ maxf(grazing_pressure - 0.8, 0.0) * 0.7
	)
	var genetic_protection: float = (
		clampf(parasite_resistance / 100.0, 0.0, 1.0) * 0.7
	)
	var treatment_factor: float = (
		0.25 if parasite_treatment_days_remaining > 0 else 1.0
	)
	return maxf(environmental_exposure * (1.0 - genetic_protection) * treatment_factor, 0.0)


func _advance_sanitary_day() -> String:
	if herd_animals.is_empty():
		parasite_pressure = 0.0
		return ""

	var parasite_total := 0.0
	for animal in herd_animals:
		animal["clostridiosis_vaccine_days_remaining"] = maxi(
			int(animal.get("clostridiosis_vaccine_days_remaining", 0)) - 1,
			0
		)
		var parasite_resistance := _calculate_phenotype(animal["genotype"], "parasite_resistance")
		var parasite_load := clampf(
			float(animal.get("parasite_load", 0.0))
			+ _daily_parasite_increase(parasite_resistance),
			0.0,
			100.0
		)
		animal["parasite_load"] = parasite_load
		animal["sanitary_state"] = (
			"Parasitose clínica"
			if parasite_load >= 70.0
			else ("Sob atenção" if parasite_load >= 40.0 else "Saudável")
		)
		parasite_total += parasite_load

	if parasite_treatment_days_remaining > 0:
		parasite_treatment_days_remaining -= 1
	if clinical_medication_days_remaining > 0:
		clinical_medication_days_remaining -= 1
	if vitamin_supplement_days_remaining > 0:
		vitamin_supplement_days_remaining -= 1
		health = minf(health + 0.15, 100.0)
	parasite_pressure = parasite_total / float(herd_animals.size())

	var event_message := ""
	if parasite_pressure >= 80.0:
		average_weight_kg = maxf(average_weight_kg - 0.6, 0.0)
		health = maxf(health - 0.5, 0.0)
		event_message = "Alerta grave: parasitose reduzindo peso e saúde."
	elif parasite_pressure >= 60.0:
		average_weight_kg = maxf(average_weight_kg - 0.25, 0.0)
		health = maxf(health - 0.15, 0.0)
		event_message = "Pressão parasitária alta reduziu o desempenho."
	elif parasite_pressure >= 40.0:
		event_message = "Pressão parasitária em elevação."

	if parasite_pressure >= 90.0 and health <= 3.0:
		var most_affected_index := 0
		for animal_index in range(1, herd_animals.size()):
			if (
				float(herd_animals[animal_index].get("parasite_load", 0.0))
				> float(herd_animals[most_affected_index].get("parasite_load", 0.0))
			):
				most_affected_index = animal_index
		var lost_animal_id := str(herd_animals[most_affected_index].get("id", "sem identificação"))
		herd_animals.remove_at(most_affected_index)
		_sync_herd_size()
		health = maxf(health, 8.0)
		event_message = (
			"Mortalidade sanitária: %s. O quadro crítico permaneceu sem controle."
			% lost_animal_id
		)

	if not event_message.is_empty():
		sanitary_last_event = event_message
	return event_message


func _sanitary_service_is_available(action: String) -> bool:
	match action:
		"parasite":
			return parasite_treatment_days_remaining <= 0
		"clinical":
			return (
				not _clinical_treatment_candidates().is_empty()
				and clinical_medication_days_remaining <= 0
			)
		"brucellosis":
			return not _eligible_brucellosis_calves().is_empty()
		"clostridiosis":
			return not _eligible_clostridiosis_animals().is_empty()
		"vitamin":
			return vitamin_supplement_days_remaining <= 0
	return false


func _request_sanitary_service(action: String, title: String) -> void:
	if not herd_created or herd_animals.is_empty():
		sanitary_last_event = "Não há rebanho para realizar o manejo."
		_update_sanitary_ui()
		return
	if not active_service_order.is_empty():
		sanitary_last_event = "O vaqueiro já está executando outro manejo."
		_update_sanitary_ui()
		return
	if not _sanitary_service_is_available(action):
		sanitary_last_event = "Não há bovinos elegíveis para este manejo."
		_update_sanitary_ui()
		return
	if action != "vitamin" and corral_rects.is_empty():
		sanitary_last_event = "Construa um curral para o vaqueiro prender o lote."
		_update_sanitary_ui()
		return

	var executor := "Vaqueiro"
	var phase := "Abastecendo os cochos"
	var target := pasture_1_center if herd_pasture == 1 else pasture_2_center
	if action != "vitamin":
		executor = "Vaqueiro e veterinário"
		phase = "Conduzindo o lote ao curral"
		target = corral_rects[0].get_center()
		herd_visuals.call("start_managed_movement", target)
	var total_cost := _sanitary_service_total(action)
	var breakdown := _cost_breakdown(total_cost, _sanitary_labor_rate(action))

	active_service_order = {
		"action": action,
		"title": title,
		"executor": executor,
		"phase": phase,
		"days_remaining": 1,
		"total_cost": total_cost,
		"input_cost": int(breakdown["material"]),
		"labor_cost": int(breakdown["labor"]),
	}
	sanitary_last_event = "%s solicitado por R$ %s. A equipe iniciou o trabalho." % [
		title,
		_format_money(total_cost),
	]
	_start_cowboy_visual(target)
	_update_service_order_ui()
	_update_sanitary_ui()


func _start_cowboy_visual(target: Vector2) -> void:
	var start := pasture_1_center if herd_pasture == 1 else pasture_2_center
	cowboy_visual.position = start
	cowboy_visual.modulate.a = 1.0
	cowboy_visual.visible = true
	cowboy_sprite.call("start_walk")
	cowboy_job_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	cowboy_job_tween.tween_property(
		cowboy_visual,
		"position",
		target,
		1.2
	)
	cowboy_job_tween.tween_callback(func() -> void: cowboy_sprite.call("start_work"))


func _advance_service_order() -> String:
	if active_service_order.is_empty():
		return ""
	active_service_order["days_remaining"] = maxi(
		int(active_service_order.get("days_remaining", 1)) - 1,
		0
	)
	if int(active_service_order["days_remaining"]) > 0:
		_update_service_order_ui()
		return ""

	var completed_order := active_service_order.duplicate(true)
	active_service_order = {}
	match str(completed_order.get("action", "")):
		"parasite":
			_apply_parasite_treatment()
		"clinical":
			_apply_clinical_medication()
		"brucellosis":
			_vaccinate_brucellosis()
		"clostridiosis":
			_vaccinate_clostridiosis()
		"vitamin":
			_start_vitamin_supplement()

	herd_visuals.call("end_managed_movement")
	_update_herd_marker()
	last_cowboy_activity = "%s concluído automaticamente." % str(
		completed_order.get("title", "Manejo")
	)
	_return_cowboy_visual()
	_update_service_order_ui()
	_update_sanitary_ui()
	return last_cowboy_activity


func _return_cowboy_visual() -> void:
	var pasture_center := pasture_1_center if herd_pasture == 1 else pasture_2_center
	cowboy_sprite.call("start_walk")
	cowboy_job_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	cowboy_job_tween.tween_property(cowboy_visual, "position", pasture_center, 0.8)
	cowboy_job_tween.tween_property(cowboy_visual, "modulate:a", 0.0, 0.25)
	cowboy_job_tween.tween_callback(func() -> void:
		cowboy_visual.visible = false
		cowboy_sprite.call("stop_work")
	)


func _update_service_order_ui() -> void:
	if not is_instance_valid(service_order_status):
		return
	if not active_service_order.is_empty():
		service_order_status.text = (
			"%s\n%s • conclusão no próximo dia\n"
			+ "Insumos R$ %s + equipe R$ %s • total R$ %s"
		) % [
			str(active_service_order.get("phase", "Executando manejo")),
			str(active_service_order.get("executor", "Equipe rural")),
			_format_money(int(active_service_order.get("input_cost", 0))),
			_format_money(int(active_service_order.get("labor_cost", 0))),
			_format_money(int(active_service_order.get("total_cost", 0))),
		]
		return
	if not last_cowboy_activity.is_empty():
		service_order_status.text = last_cowboy_activity
		return
	service_order_status.text = (
		"Nenhum manejo em andamento.\n"
		+ "O vaqueiro abastece cochos e suplementos automaticamente."
	)


func _resume_service_order_visuals() -> void:
	if active_service_order.is_empty() or not herd_created:
		herd_visuals.call("end_managed_movement")
		cowboy_visual.visible = false
		return
	var action := str(active_service_order.get("action", ""))
	var target := pasture_1_center if herd_pasture == 1 else pasture_2_center
	if action != "vitamin" and not corral_rects.is_empty():
		target = corral_rects[0].get_center()
		herd_visuals.call("start_managed_movement", target)
	_start_cowboy_visual(target)


func _apply_parasite_treatment() -> void:
	if not herd_created or herd_animals.is_empty() or parasite_treatment_days_remaining > 0:
		return
	var treatment_cost := herd_size * PARASITE_TREATMENT_COST_PER_ANIMAL
	if cash_balance < treatment_cost:
		sanitary_last_event = "Caixa insuficiente para o controle parasitário."
		_update_sanitary_ui()
		return

	for animal in herd_animals:
		animal["parasite_load"] = minf(float(animal.get("parasite_load", 0.0)), 8.0)
		animal["sanitary_state"] = "Saudável"
	parasite_pressure = minf(parasite_pressure, 8.0)
	parasite_treatment_days_remaining = PARASITE_TREATMENT_PROTECTION_DAYS
	sanitary_last_event = "Controle parasitário aplicado em %d bovinos." % herd_size
	_record_sanitary_expense("controle parasitário do rebanho", treatment_cost, "parasite")
	_update_sanitary_ui()
	_update_finance_ui()


func _eligible_brucellosis_calves() -> Array[Dictionary]:
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


func _clinical_treatment_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for animal in herd_animals:
		if (
			float(animal.get("health", health)) < 80.0
			or float(animal.get("parasite_load", 0.0)) >= 40.0
		):
			candidates.append(animal)
	return candidates


func _apply_clinical_medication() -> void:
	var candidates := _clinical_treatment_candidates()
	if candidates.is_empty() or clinical_medication_days_remaining > 0:
		return
	var medication_cost := candidates.size() * CLINICAL_MEDICATION_COST_PER_ANIMAL
	if cash_balance < medication_cost:
		sanitary_last_event = "Caixa insuficiente para o tratamento clínico."
		_update_sanitary_ui()
		return

	for animal in candidates:
		animal["health"] = minf(float(animal.get("health", health)) + 12.0, 100.0)
		animal["parasite_load"] = maxf(float(animal.get("parasite_load", 0.0)) - 20.0, 0.0)
		animal["sanitary_state"] = "Em recuperação"
	health = minf(health + 8.0, 100.0)
	clinical_medication_days_remaining = CLINICAL_MEDICATION_COOLDOWN_DAYS
	sanitary_last_event = "Tratamento clínico aplicado em %d bovinos." % candidates.size()
	_record_sanitary_expense("tratamento clínico", medication_cost, "clinical")
	_update_sanitary_ui()
	_update_finance_ui()


func _vaccinate_brucellosis() -> void:
	var eligible_calves := _eligible_brucellosis_calves()
	if eligible_calves.is_empty():
		return
	var vaccination_cost := eligible_calves.size() * BRUCELLOSIS_VACCINE_COST_PER_CALF
	if cash_balance < vaccination_cost:
		sanitary_last_event = "Caixa insuficiente para vacinar as bezerras elegíveis."
		_update_sanitary_ui()
		return

	for animal in eligible_calves:
		animal["brucellosis_vaccinated"] = true
	sanitary_last_event = "%d bezerras vacinadas contra brucelose." % eligible_calves.size()
	_record_sanitary_expense("vacinação contra brucelose", vaccination_cost, "brucellosis")
	_update_sanitary_ui()
	_update_finance_ui()


func _eligible_clostridiosis_animals() -> Array[Dictionary]:
	var eligible: Array[Dictionary] = []
	for animal in herd_animals:
		if (
			int(animal.get("age_days", 0)) >= 60
			and int(animal.get("clostridiosis_vaccine_days_remaining", 0)) <= 0
		):
			eligible.append(animal)
	return eligible


func _vaccinate_clostridiosis() -> void:
	var eligible_animals := _eligible_clostridiosis_animals()
	if eligible_animals.is_empty():
		return
	var vaccination_cost := eligible_animals.size() * CLOSTRIDIOSIS_VACCINE_COST_PER_ANIMAL
	if cash_balance < vaccination_cost:
		sanitary_last_event = "Caixa insuficiente para a vacina contra clostridioses."
		_update_sanitary_ui()
		return

	for animal in eligible_animals:
		animal["clostridiosis_vaccine_days_remaining"] = CLOSTRIDIOSIS_PROTECTION_DAYS
	sanitary_last_event = "%d bovinos vacinados contra clostridioses." % eligible_animals.size()
	_record_sanitary_expense("vacinação contra clostridioses", vaccination_cost, "clostridiosis")
	_update_sanitary_ui()
	_update_finance_ui()


func _start_vitamin_supplement() -> void:
	if not herd_created or herd_animals.is_empty() or vitamin_supplement_days_remaining > 0:
		return
	var supplement_cost := herd_size * VITAMIN_SUPPLEMENT_COST_PER_ANIMAL
	if cash_balance < supplement_cost:
		sanitary_last_event = "Caixa insuficiente para o protocolo vitamínico-mineral."
		_update_sanitary_ui()
		return

	vitamin_supplement_days_remaining = VITAMIN_SUPPLEMENT_DAYS
	sanitary_last_event = "Protocolo vitamínico-mineral iniciado por 30 dias."
	_record_sanitary_expense(
		"suplemento vitamínico-mineral do rebanho",
		supplement_cost,
		"vitamin"
	)
	_update_sanitary_ui()
	_update_finance_ui()


func _update_sanitary_ui() -> void:
	if not herd_created or herd_animals.is_empty():
		sanitary_status.text = "Compre animais no Mercado para iniciar o manejo sanitário."
		parasite_treatment_button.disabled = true
		clinical_medication_button.disabled = true
		brucellosis_vaccine_button.disabled = true
		clostridiosis_vaccine_button.disabled = true
		vitamin_supplement_button.disabled = true
		return

	var eligible_count := _eligible_brucellosis_calves().size()
	var clinical_count := _clinical_treatment_candidates().size()
	var clostridiosis_count := _eligible_clostridiosis_animals().size()
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


func _advance_day(silent: bool = false) -> void:
	current_day += 1
	day_of_year += 1
	if day_of_year > _days_in_year(current_year):
		day_of_year = 1
		current_year += 1
	_update_daily_weather()
	var has_herd := herd_created and herd_size > 0
	var service_order_message := _advance_service_order() if has_herd else ""
	_advance_soil_day()
	_advance_crop_day()
	var reproduction_message := _advance_reproduction_day() if has_herd else ""
	var previous_average_weight := average_weight_kg
	var reserve_active := has_herd and feeding_plan_days_remaining > 0
	if reserve_active:
		feeding_plan_days_remaining -= 1

	var grazing_pressure := 0.0
	var vegetation_service_message := ""
	for pasture_number in [1, 2]:
		if not vegetation_manager.has_area(pasture_number):
			continue
		var vegetation_result: Dictionary = vegetation_manager.advance_day(
			pasture_number,
			{
				"rainfall_mm": rainfall_mm,
				"temperature_c": max_temperature_c,
				"dry_days": consecutive_dry_days,
				"soil_moisture": soil_moisture[pasture_number],
				"soil_fertility": soil_fertility[pasture_number],
				"soil_compaction": soil_compaction[pasture_number],
				"soil_erosion": soil_erosion[pasture_number],
			},
			{
				"present": has_herd and pasture_number == herd_pasture,
				"live_weight_kg": average_weight_kg * herd_size,
				"grazing_fraction": 0.5 if reserve_active else 1.0,
			}
		)
		soil_compaction[pasture_number] = float(
			vegetation_result.get("soil_compaction", soil_compaction[pasture_number])
		)
		if pasture_number == herd_pasture:
			grazing_pressure = float(vegetation_result.get("grazing_pressure", 0.0))
		var completed_service := str(vegetation_result.get("intervention_message", ""))
		if not completed_service.is_empty():
			vegetation_service_message = completed_service
			match str(vegetation_result.get("completed_action", "")):
				"fertilize":
					soil_fertility[pasture_number] = minf(
						float(soil_fertility[pasture_number]) + 18.0, 100.0
					)
					soil_compaction[pasture_number] = maxf(
						float(soil_compaction[pasture_number]) - 12.0, 0.0
					)
				"recover":
					soil_erosion[pasture_number] = maxf(
						float(soil_erosion[pasture_number]) - 10.0, 0.0
					)
					soil_fertility[pasture_number] = minf(
						float(soil_fertility[pasture_number]) + 8.0, 100.0
					)
	_sync_legacy_from_vegetation()

	if not has_herd:
		_update_pond_levels()
		_update_river_level()
		herd_had_water_today = true
		if not silent:
			_refresh_simulation_ui()
		return

	var supplement_use := _consume_daily_supplements()
	if (
		service_order_message.is_empty()
		and (bool(supplement_use["mineral"]) or bool(supplement_use["supplement"]))
	):
		last_cowboy_activity = "Vaqueiro abasteceu os cochos automaticamente."
		_update_service_order_ui()
	_update_water_system()
	var available_forage: float = forage[herd_pasture]
	var daily_message := "Alimentação adequada."
	var quality_factor: float = clampf(
		(pasture_quality[herd_pasture] / 75.0)
		* (1.0 - pasture_degradation[herd_pasture] / 120.0),
		0.25,
		1.15
	)
	var protein_bonus := 0.25 if supplement_use["supplement"] else 0.0
	if reserve_active:
		protein_bonus += 0.35

	if available_forage > 60.0:
		average_weight_kg += 0.7 * quality_factor + protein_bonus
		body_condition = minf(body_condition + 0.01, 5.0)
	elif available_forage > 30.0:
		average_weight_kg += 0.2 * quality_factor + protein_bonus
		daily_message = "Ganho de peso reduzido."
	elif available_forage > 15.0:
		average_weight_kg = maxf(average_weight_kg - 0.3 + protein_bonus, 0.0)
		body_condition = maxf(body_condition - 0.01, 1.0)
		daily_message = "Pouca forragem: o lote começou a perder peso."
	else:
		average_weight_kg = maxf(average_weight_kg - 0.8, 0.0)
		body_condition = maxf(body_condition - 0.03, 1.0)
		daily_message = "Alerta: pasto crítico e perda de condição corporal."

	var heat_message := _apply_daily_heat_stress()
	if not heat_message.is_empty():
		daily_message = "%s %s" % [daily_message, heat_message]
	var needs_warning := _update_animal_needs(available_forage)
	if not needs_warning.is_empty():
		daily_message = needs_warning
	if reserve_active:
		hunger = maxf(hunger - 20.0, 0.0)
		daily_message = "%s Reserva forrageira fornecida." % daily_message
	if supplement_use["mineral"]:
		health = minf(health + 0.2, 100.0)
	if grazing_pressure > 1.0:
		daily_message = "%s Superlotação: %d bovinos para capacidade de %d." % [
			daily_message,
			herd_size,
			pasture_capacity[herd_pasture],
		]
	if not reproduction_message.is_empty():
		daily_message = "%s %s" % [daily_message, reproduction_message]
	var sanitary_message := _advance_sanitary_day()
	if not sanitary_message.is_empty():
		daily_message = "%s %s" % [daily_message, sanitary_message]
	if not service_order_message.is_empty():
		daily_message = "%s %s" % [daily_message, service_order_message]
	if not vegetation_service_message.is_empty():
		vegetation_last_event = vegetation_service_message
		daily_message = "%s %s" % [daily_message, vegetation_service_message]

	_update_individual_animals_day(average_weight_kg - previous_average_weight)
	if herd_created and herd_size > 0:
		_update_herd_genotype_averages()
	if not silent:
		_refresh_simulation_ui()
		_update_herd_status(daily_message)
		_report_critical_event()


func _update_individual_animals_day(weight_change: float) -> void:
	for animal in herd_animals:
		var category := str(animal.get("category", ""))
		if category in ["female_calves", "male_calves"] and calf_age_days >= 0:
			animal["age_days"] = calf_age_days
		else:
			animal["age_days"] = int(animal.get("age_days", 0)) + 1
		animal["weight_kg"] = maxf(
			float(animal.get("weight_kg", average_weight_kg)) + weight_change,
			0.0
		)
		animal["hunger"] = hunger
		animal["thirst"] = thirst
		animal["health"] = health
	_sync_herd_size()
	_update_herd_marker()


func _get_camera_zoom() -> float:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return 1.0
	return cam.zoom.x


func _lod_level() -> float:
	var z := _get_camera_zoom()
	if z > 0.8:
		return 1.0
	if z > 0.3:
		return 0.5
	return 0.25


func _lod_multiplier(lod: float) -> float:
	return lod


func _check_lod_change() -> void:
	var new_lod := _lod_level()
	if not is_equal_approx(new_lod, _current_lod_level):
		_current_lod_level = new_lod
		pasture_grass_cache.clear()
		native_vegetation_cache.clear()
		_rebuild_pasture_grass_visual()
		_rebuild_native_vegetation_visual()


func _season_factor() -> float:
	var month := _current_month()
	if month in [11, 12, 1, 2, 3, 4]:
		return 1.0
	if month in [5, 10]:
		return 0.6
	return 0.3


func _ensure_pasture_grass_layer() -> Node2D:
	if pasture_grass_layer == null:
		pasture_grass_layer = Node2D.new()
		pasture_grass_layer.name = "PastureGrass"
		pasture_grass_layer.z_index = pasture_1.z_index + 1
		pasture_1.get_parent().add_child(pasture_grass_layer)
	return pasture_grass_layer


func _ensure_caatinga_vegetation_layer() -> Node2D:
	if caatinga_vegetation_layer == null:
		caatinga_vegetation_layer = Node2D.new()
		caatinga_vegetation_layer.name = "CaatingaVegetation"
		caatinga_vegetation_layer.z_index = pasture_1.z_index + 1
		pasture_1.get_parent().add_child(caatinga_vegetation_layer)
	return caatinga_vegetation_layer


func _rebuild_native_vegetation_visual() -> void:
	var current_cache: Dictionary = {}
	var any_caatinga := false
	for area_id in vegetation_manager.areas.keys():
		var area: Dictionary = vegetation_manager.get_area(area_id)
		var species := str(area.get("species", "buffel"))
		var polygon := _vegetation_polygon(area_id)
		if species != "caatinga" or polygon.size() < 3:
			continue
		any_caatinga = true
		var definition: Dictionary = vegetation_manager.species_definitions()[species]
		var condition := clampf(
			float(area.get("biomass_kg_ha", 0.0)) / float(definition["max_biomass"]),
			0.0,
			1.0
		)
		_visual_condition[area_id] = clampf(
			_visual_condition.get(area_id, condition), 0.0, 1.0
		)
		var base_count := int(clampf(_polygon_area(polygon) / 16000.0, 4.0, 70.0))
		current_cache[area_id] = {
			"density": maxi(roundi(base_count * (0.5 + 0.5 * condition) * _lod_multiplier(_current_lod_level)), 2),
			"species": species,
		}
	if current_cache == native_vegetation_cache:
		return
	native_vegetation_cache = current_cache
	if not any_caatinga and caatinga_vegetation_layer == null:
		return
	var layer := _ensure_caatinga_vegetation_layer()
	for child in layer.get_children():
		child.queue_free()
	if not any_caatinga:
		return
	var rng := RandomNumberGenerator.new()
	for area_id in current_cache:
		var density: int = current_cache[area_id]["density"]
		var polygon := _vegetation_polygon(area_id)
		var definition: Dictionary = vegetation_manager.species_definitions()["caatinga"]
		var growth := clampf(_visual_condition.get(area_id, 0.5), 0.15, 1.0)
		var species_color: Color = Color(definition["dry_color"]).lerp(
			Color(definition["healthy_color"]), 0.65
		)
		var bounding_min := Vector2(INF, INF)
		var bounding_max := Vector2(-INF, -INF)
		for vertex in polygon:
			bounding_min = bounding_min.min(vertex)
			bounding_max = bounding_max.max(vertex)
		rng.seed = int(area_id) * 7919 + 17
		var placed := 0
		var attempts := 0
		while placed < density and attempts < density * 30:
			attempts += 1
			var candidate := Vector2(
				rng.randf_range(bounding_min.x, bounding_max.x),
				rng.randf_range(bounding_min.y, bounding_max.y)
			)
			if not Geometry2D.is_point_in_polygon(candidate, polygon):
				continue
			var too_close := false
			for sibling in layer.get_children():
				if sibling.position.distance_to(candidate) < 84.0:
					too_close = true
					break
			if too_close:
				continue
			placed += 1
			var radius := rng.randf_range(14.0, 28.0)
			var shadow := Sprite2D.new()
			shadow.name = "BushShadow%d_%d" % [area_id, placed]
			shadow.position = candidate + Vector2(6.0, 8.0)
			shadow.texture = VegetationSpriteGenerator.shadow_texture()
			shadow.scale = Vector2.ONE * (radius * 1.4 / 34.0) * growth
			layer.add_child(shadow)
			var bush := Sprite2D.new()
			bush.name = "Bush%d_%d" % [area_id, placed]
			bush.position = candidate
			bush.texture = VegetationSpriteGenerator.bush_texture(placed)
			bush.scale = Vector2.ONE * (radius / 26.0) * growth
			var shade := rng.randf_range(0.15, 0.55)
			bush.modulate = species_color.darkened(shade)
			bush.modulate.a = clampf(0.85 + growth * 0.15, 0.75, 0.98)
			bush.material = VegetationShader.bush_material()
			layer.add_child(bush)


func _rebuild_pasture_grass_visual() -> void:
	var current_cache: Dictionary = {}
	var any_area := false
	for area_id in vegetation_manager.areas.keys():
		var area: Dictionary = vegetation_manager.get_area(area_id)
		var polygon := _vegetation_polygon(area_id)
		if polygon.size() < 3:
			continue
		any_area = true
		var definition: Dictionary = vegetation_manager.species_definitions()[
			str(area.get("species", "buffel"))
		]
		var condition := clampf(
			float(area.get("biomass_kg_ha", 0.0)) / float(definition["max_biomass"]),
			0.0,
			1.0
		)
		_visual_condition[area_id] = clampf(
			_visual_condition.get(area_id, condition), 0.0, 1.0
		)
		var base_count := int(clampf(_polygon_area(polygon) / 9000.0, 6.0, 90.0))
		current_cache[area_id] = {
			"density": maxi(roundi(base_count * (0.4 + 0.6 * condition) * _lod_multiplier(_current_lod_level)), 2),
			"species": str(area.get("species", "buffel")),
		}
	if current_cache == pasture_grass_cache:
		return
	pasture_grass_cache = current_cache
	if not any_area and pasture_grass_layer == null:
		return
	var layer := _ensure_pasture_grass_layer()
	for child in layer.get_children():
		child.queue_free()
	if not any_area:
		return
	var rng := RandomNumberGenerator.new()
	for area_id in current_cache:
		var density: int = current_cache[area_id]["density"]
		var polygon := _vegetation_polygon(area_id)
		var base_color := vegetation_manager.visual_color(area_id, _visual_season_factor)
		var growth := clampf(_visual_condition.get(area_id, 0.5), 0.15, 1.0)
		var bounding_min := Vector2(INF, INF)
		var bounding_max := Vector2(-INF, -INF)
		for vertex in polygon:
			bounding_min = bounding_min.min(vertex)
			bounding_max = bounding_max.max(vertex)
		rng.seed = int(area_id) * 5197 + 31
		var placed := 0
		var attempts := 0
		while placed < density and attempts < density * 24:
			attempts += 1
			var candidate := Vector2(
				rng.randf_range(bounding_min.x, bounding_max.x),
				rng.randf_range(bounding_min.y, bounding_max.y)
			)
			if not Geometry2D.is_point_in_polygon(candidate, polygon):
				continue
			var too_close := false
			for sibling in layer.get_children():
				if sibling.position.distance_to(candidate) < 46.0:
					too_close = true
					break
			if too_close:
				continue
			placed += 1
			var radius := rng.randf_range(8.0, 18.0)
			var shadow := Sprite2D.new()
			shadow.name = "GrassShadow%d_%d" % [area_id, placed]
			shadow.position = candidate + Vector2(4.0, 5.0)
			shadow.texture = VegetationSpriteGenerator.shadow_texture()
			shadow.scale = Vector2.ONE * (radius * 1.2 / 34.0) * growth
			layer.add_child(shadow)
			var tuft := Sprite2D.new()
			tuft.name = "Grass%d_%d" % [area_id, placed]
			tuft.position = candidate
			tuft.texture = VegetationSpriteGenerator.grass_texture(placed)
			tuft.scale = Vector2.ONE * (radius / 28.0) * growth
			var shade := rng.randf_range(-0.12, 0.18)
			tuft.modulate = base_color.lightened(maxf(shade, 0.0)).darkened(maxf(-shade, 0.0))
			tuft.modulate.a = clampf(0.6 + growth * 0.35, 0.5, 0.95)
			tuft.material = VegetationShader.grass_material()
			layer.add_child(tuft)


func _update_pasture_visuals() -> void:
	_sync_legacy_from_vegetation()
	_check_lod_change()
	pasture_1_label.text = "PASTO 1\nForragem: %d%% | Qualidade: %d%%\nDegradação: %d%% | Capacidade: %d" % [
		roundi(forage[1]),
		roundi(pasture_quality[1]),
		roundi(pasture_degradation[1]),
		pasture_capacity[1],
	]
	pasture_2_label.text = "PASTO 2\nForragem: %d%% | Qualidade: %d%%\nDegradação: %d%% | Capacidade: %d" % [
		roundi(forage[2]),
		roundi(pasture_quality[2]),
		roundi(pasture_degradation[2]),
		pasture_capacity[2],
	]
	var target_season := _season_factor()
	if _visual_season_factor < 0.0:
		_visual_season_factor = target_season
	else:
		_visual_season_factor = lerpf(_visual_season_factor, target_season, 0.15)
	pasture_1.color = vegetation_manager.visual_color(1, _visual_season_factor)
	pasture_2.color = vegetation_manager.visual_color(2, _visual_season_factor)
	for area_id in vegetation_manager.areas.keys():
		var area: Dictionary = vegetation_manager.get_area(area_id)
		var def: Dictionary = vegetation_manager.species_definitions().get(
			str(area.get("species", "buffel")), {}
		)
		if def.is_empty():
			continue
		var raw := clampf(
			float(area.get("biomass_kg_ha", 0.0)) / float(def.get("max_biomass", 1.0)),
			0.0, 1.0
		)
		var prev: float = _visual_condition.get(area_id, raw)
		_visual_condition[area_id] = lerpf(prev, raw, 0.15)
	_rebuild_native_vegetation_visual()
	_rebuild_pasture_grass_visual()


func _update_pasture_condition() -> float:
	var capacity: int = maxi(int(pasture_capacity[herd_pasture]), 1)
	var grazing_pressure := float(herd_size) / capacity

	if grazing_pressure > 1.0:
		pasture_degradation[herd_pasture] = minf(
			pasture_degradation[herd_pasture] + (grazing_pressure - 1.0) * 1.5,
			100.0
		)
		pasture_quality[herd_pasture] = maxf(
			pasture_quality[herd_pasture] - (grazing_pressure - 1.0) * 0.8,
			10.0
		)
	elif grazing_pressure <= 0.8 and forage[herd_pasture] > 40.0:
		pasture_degradation[herd_pasture] = maxf(
			pasture_degradation[herd_pasture] - 0.1,
			0.0
		)

	if forage[herd_pasture] < 20.0:
		pasture_degradation[herd_pasture] = minf(
			pasture_degradation[herd_pasture] + 0.4,
			100.0
		)
		pasture_quality[herd_pasture] = maxf(
			pasture_quality[herd_pasture] - 0.2,
			10.0
		)

	return grazing_pressure


func _update_herd_status(message: String) -> void:
	herd_status.text = "Dia %d | %s | %d bovinos | %s\nPeso: %.1f kg | Condição: %.2f (%s)\nFome: %d%% | Sede: %d%% | Saúde: %d%%\nEstresse térmico: %d%%\n%s" % [
		current_day,
		_formatted_date(),
		herd_size,
		_current_herd_area_name(),
		average_weight_kg,
		body_condition,
		_body_condition_label(),
		roundi(hunger),
		roundi(thirst),
		roundi(health),
		roundi(heat_stress),
		message
	]


func _body_condition_label() -> String:
	if body_condition < 2.0:
		return "muito baixa"
	if body_condition < 3.0:
		return "baixa"
	if body_condition < 4.0:
		return "adequada"
	if body_condition < 4.5:
		return "alta"
	return "excessiva"


func _current_month() -> int:
	return _calendar_month_and_day().x


func _current_month_day() -> int:
	return _calendar_month_and_day().y


func _formatted_date() -> String:
	return "%02d/%02d/%04d" % [
		_current_month_day(),
		_current_month(),
		current_year,
	]


func _is_leap_year(year: int) -> bool:
	return year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)


func _days_in_year(year: int) -> int:
	return 366 if _is_leap_year(year) else 365


func _month_length(year: int, month: int) -> int:
	if month == 2 and _is_leap_year(year):
		return 29
	return int(MONTH_LENGTHS[clampi(month, 1, 12) - 1])


func _day_of_year_from_date(year: int, month: int, day: int) -> int:
	var result := clampi(day, 1, _month_length(year, month))
	for previous_month in range(1, clampi(month, 1, 12)):
		result += _month_length(year, previous_month)
	return result


func _calendar_month_and_day() -> Vector2i:
	var remaining_days := clampi(day_of_year, 1, _days_in_year(current_year))
	for month_index in range(MONTH_LENGTHS.size()):
		var month_length := _month_length(current_year, month_index + 1)
		if remaining_days <= month_length:
			return Vector2i(month_index + 1, remaining_days)
		remaining_days -= month_length
	return Vector2i(12, 31)


func _migrate_legacy_day_of_year(legacy_day_of_year: int) -> int:
	var old_day := clampi(legacy_day_of_year, 1, 360)
	var old_month_index := (old_day - 1) / 30
	var old_month_day := ((old_day - 1) % 30) + 1
	old_month_day = mini(old_month_day, int(MONTH_LENGTHS[old_month_index]))
	var migrated_day := old_month_day
	for month_index in range(old_month_index):
		migrated_day += int(MONTH_LENGTHS[month_index])
	return migrated_day


func _climate_phase() -> String:
	var month := _current_month()

	if month in [11, 12, 1, 2, 3, 4]:
		return "Período chuvoso"
	if month in [5, 10]:
		return "Transição"
	return "Estiagem"


func _climate_phase_short() -> String:
	match _climate_phase():
		"Período chuvoso":
			return "Chuvoso"
		"Transição":
			return "Transição"
		_:
			return "Estiagem"


func _climate_phase_color() -> Color:
	match _climate_phase():
		"Período chuvoso":
			return Color("63bfe8")
		"Transição":
			return Color("becf78")
		_:
			return Color("f2aa40")


func _climate_phase_icon() -> Texture2D:
	match _climate_phase():
		"Período chuvoso":
			return CLIMATE_ICON_RAINY
		"Transição":
			return CLIMATE_ICON_TRANSITION
		_:
			return CLIMATE_ICON_DROUGHT


func _update_daily_weather() -> void:
	var rain_chance := 4
	var base_temperature := 37.0
	match _climate_phase():
		"Período chuvoso":
			rain_chance = 40
			base_temperature = 32.0
		"Transição":
			rain_chance = 15
			base_temperature = 35.0

	var rain_score := posmod(day_of_year * 13 + current_year * 7, 100)
	if rain_score < rain_chance:
		var rain_range := 470 if _climate_phase() == "Período chuvoso" else 230
		var minimum_rain := 8.0 if _climate_phase() == "Período chuvoso" else 2.0
		rainfall_mm = minimum_rain + (
			float(posmod(day_of_year * 19 + current_year * 11, rain_range)) / 10.0
		)
		consecutive_dry_days = 0
	else:
		rainfall_mm = 0.0
		consecutive_dry_days += 1

	var temperature_variation := (
		float(posmod(day_of_year * 7 + current_year * 13, 60)) / 10.0
	)
	max_temperature_c = base_temperature + temperature_variation
	if rainfall_mm >= 2.0:
		max_temperature_c -= 2.5
	weather_condition = (
		"Chuva forte"
		if rainfall_mm >= 30.0
		else ("Chuva" if rainfall_mm >= 2.0 else "Seco")
	)
	heat_stress = _calculate_heat_stress(
		max_temperature_c,
		_herd_average_phenotype("heat_adaptation")
	)


func _calculate_heat_stress(temperature_c: float, heat_adaptation: float) -> float:
	var thermal_load := maxf(temperature_c - 30.0, 0.0) * 8.0
	var genetic_protection := clampf(heat_adaptation / 100.0, 0.0, 1.0) * 0.65
	return clampf(thermal_load * (1.0 - genetic_protection), 0.0, 100.0)


func _apply_daily_heat_stress() -> String:
	if not herd_created or heat_stress <= 15.0:
		return ""

	var weight_penalty := minf((heat_stress - 15.0) * 0.008, 0.6)
	average_weight_kg = maxf(average_weight_kg - weight_penalty, 0.0)
	if heat_stress >= 45.0:
		health = maxf(health - 0.35, 0.0)
		body_condition = maxf(body_condition - 0.01, 1.0)
		return "Calor intenso reduziu o desempenho do lote."
	return "Calor moderado reduziu o ganho de peso."


func _daily_pasture_growth() -> float:
	var base_growth := 0.0
	match _climate_phase():
		"Período chuvoso":
			base_growth = 0.8
		"Transição":
			base_growth = 0.15
		_:
			base_growth = -0.55
	var rain_bonus := minf(rainfall_mm * 0.08, 3.5)
	var prolonged_drought_penalty := minf(maxi(consecutive_dry_days - 10, 0) * 0.04, 1.5)
	var heat_penalty := maxf(max_temperature_c - 36.0, 0.0) * 0.15
	return clampf(
		base_growth + rain_bonus - prolonged_drought_penalty - heat_penalty,
		-2.5,
		4.0
	)


func _soil_profile_value(pasture_number: int, lowland_value: float, highland_value: float) -> float:
	return lowland_value if pasture_number == 1 else highland_value


func _advance_soil_day() -> void:
	for pasture_number in [1, 2]:
		var infiltration: float = _soil_profile_value(pasture_number, 0.78, 0.42)
		var drainage: float = _soil_profile_value(pasture_number, 0.3, 0.85)
		var slope_erosion: float = _soil_profile_value(pasture_number, 0.7, 1.45)
		var compaction_factor: float = clampf(
			1.0 - float(soil_compaction[pasture_number]) / 150.0,
			0.35,
			1.0
		)
		var effective_infiltration: float = infiltration * compaction_factor
		var runoff: float = rainfall_mm * (1.0 - effective_infiltration)
		soil_daily_runoff[pasture_number] = runoff

		var evaporation: float = (
			0.45
			+ maxf(max_temperature_c - 30.0, 0.0) * 0.07
			+ drainage
		)
		soil_moisture[pasture_number] = clampf(
			float(soil_moisture[pasture_number])
			+ rainfall_mm * effective_infiltration * 0.55
			- evaporation,
			0.0,
			100.0
		)

		var vegetation_area: Dictionary = vegetation_manager.get_area(pasture_number)
		var vegetation_cover: float = clampf(
			float(vegetation_area.get("cover_pct", forage[pasture_number])) / 100.0,
			0.0,
			1.0
		)
		var erosion_gain: float = runoff * (1.0 - vegetation_cover) * 0.035 * slope_erosion
		soil_erosion[pasture_number] = clampf(
			float(soil_erosion[pasture_number]) + erosion_gain,
			0.0,
			100.0
		)
		soil_fertility[pasture_number] = clampf(
			float(soil_fertility[pasture_number]) - erosion_gain * 0.015,
			10.0,
			100.0
		)


func _soil_growth_factor(pasture_number: int) -> float:
	var moisture_response: float = clampf(
		float(soil_moisture[pasture_number]) / 60.0,
		0.25,
		1.15
	)
	var fertility_response: float = 0.55 + float(soil_fertility[pasture_number]) / 200.0
	var relief_response: float = _soil_profile_value(pasture_number, 1.05, 0.88)
	return clampf(moisture_response * fertility_response * relief_response, 0.25, 1.2)


func _soil_drought_factor(pasture_number: int) -> float:
	var moisture_penalty: float = maxf(45.0 - float(soil_moisture[pasture_number]), 0.0) / 90.0
	var relief_penalty: float = _soil_profile_value(pasture_number, 0.0, 0.15)
	return clampf(1.0 + moisture_penalty + relief_penalty, 1.0, 1.65)


func _update_pond_levels() -> void:
	var evaporation := 0.25 + maxf(max_temperature_c - 28.0, 0.0) * 0.055
	for pond_number in [1, 2]:
		var direct_capture: float = rainfall_mm * _soil_profile_value(
			pond_number,
			0.13,
			0.09
		)
		var runoff_recharge: float = float(soil_daily_runoff[pond_number]) * 0.12
		var daily_change: float = direct_capture + runoff_recharge - evaporation
		pond_level[pond_number] = clampf(pond_level[pond_number] + daily_change, 0.0, 100.0)


func _update_water_system() -> void:
	_update_pond_levels()
	_update_river_level()
	herd_had_water_today = false

	if pond_level[herd_pasture] > 5.0:
		herd_had_water_today = true
		pond_level[herd_pasture] = maxf(
			pond_level[herd_pasture] - 0.025 * herd_size,
			0.0
		)
	elif _herd_has_river_access() and river_level > 5.0:
		herd_had_water_today = true
		river_level = maxf(river_level - 0.02 * herd_size, 0.0)


func _herd_has_river_access() -> bool:
	if _using_general_farm_area():
		return true
	if division_orientation == DivisionMode.HORIZONTAL:
		return true
	if division_orientation == DivisionMode.VERTICAL:
		return herd_pasture == 2
	return false


func _update_river_level() -> void:
	var phase_loss := 0.35
	if _climate_phase() == "Transição":
		phase_loss = 0.8
	elif _climate_phase() == "Estiagem":
		phase_loss = 1.4
	var heat_loss := maxf(max_temperature_c - 35.0, 0.0) * 0.08
	river_level = clampf(
		river_level + rainfall_mm * 0.22 - phase_loss - heat_loss,
		0.0,
		100.0
	)


func _update_climate_visuals() -> void:
	climate_icon.texture = _climate_phase_icon()
	climate_status.add_theme_color_override("font_color", _climate_phase_color())
	climate_status.text = "%s | %s • %s | %.0f°C" % [
		_formatted_server_datetime(),
		_climate_phase_short(),
		weather_condition,
		max_temperature_c,
	]
	pond_1_label.text = "AÇUDE\nNível: %s" % _pond_level_label(pond_level[1])
	pond_2_label.text = "AÇUDE\nNível: %s" % _pond_level_label(pond_level[2])
	pond_1_gauge.call("set_level", pond_level[1])
	pond_2_gauge.call("set_level", pond_level[2])
	_update_water_level_visuals()
	river_label.text = "RIO INTERMITENTE\n%s" % _river_level_label()


func _update_water_level_visuals() -> void:
	_update_pond_level_visual(pond_1_visual, pond_level[1], Vector2(0.32, 0.42))
	_update_pond_level_visual(pond_2_visual, pond_level[2], Vector2(0.32, 0.42))
	var normalized_river := clampf(river_level / 100.0, 0.0, 1.0)
	intermittent_river.visible = river_level > 5.0
	intermittent_river.material.set_shader_parameter("water_level", normalized_river)


func _update_pond_level_visual(
	water_visual: Sprite2D,
	level: float,
	full_scale: Vector2
) -> void:
	var normalized_level := clampf(level / 100.0, 0.0, 1.0)
	water_visual.visible = level > 5.0
	water_visual.scale = full_scale * sqrt(normalized_level)
	water_visual.modulate = Color(0.82, 0.94, 1.0, lerpf(0.5, 0.92, normalized_level))


func _river_level_label() -> String:
	if river_level <= 5.0:
		return "leito seco"
	if river_level < 35.0:
		return "vazão baixa"
	if river_level < 70.0:
		return "vazão média"
	return "vazão alta"


func _pond_level_label(level: float) -> String:
	if level <= 5.0:
		return "seco"
	if level < 35.0:
		return "baixo"
	if level < 70.0:
		return "médio"
	return "alto"


func _update_animal_needs(available_forage: float) -> String:
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

	if health <= 30.0:
		return "Alerta grave: saúde do lote comprometida."
	if thirst >= 50.0:
		return "Alerta: o açude do pasto não está atendendo o lote."
	if hunger >= 50.0:
		return "Alerta: fome elevada por falta de forragem."
	return ""


func _update_water_ui() -> void:
	var water_areas_text := "Açudes: P1 %s | P2 %s" % [
		_pond_level_label(pond_level[1]),
		_pond_level_label(pond_level[2]),
	]
	if _using_general_farm_area():
		water_areas_text = "Açudes da área geral: %s | %s" % [
			_pond_level_label(pond_level[1]),
			_pond_level_label(pond_level[2]),
		]
	water_status.text = (
		"Hoje: %s | Chuva %.1f mm | %d dias secos\n"
		+ "%s\n"
		+ "Rio intermitente: %s\n"
		+ "Acesso atual do lote: %s"
	) % [
		weather_condition,
		rainfall_mm,
		consecutive_dry_days,
		water_areas_text,
		_river_level_label(),
		(
			"açude ou rio"
			if herd_created and (
				pond_level[herd_pasture] > 5.0
				or (_herd_has_river_access() and river_level > 5.0)
			)
			else ("sem lote" if not herd_created else "sem água disponível")
		),
	]


func _select_next_crop() -> void:
	if field_state in ["growing", "ready"]:
		agriculture_status.text = "Conclua a cultura atual antes de trocar."
		return

	selected_crop_index = (selected_crop_index + 1) % FORAGE_CROPS.size()
	_update_agriculture_ui()


func _prepare_soil() -> void:
	if not _has_livestock_area():
		agriculture_status.text = "Cerque a propriedade antes de preparar o talhão."
		return
	if field_state != "idle":
		agriculture_status.text = "O talhão não está disponível para novo preparo."
		return
	if not _pay_infrastructure_cost("Preparo do solo", SOIL_PREPARATION_COST):
		return

	field_state = "prepared"
	forage_field.color = FIELD_IDLE_COLOR.lightened(0.12)
	_update_agriculture_ui()


func _plant_selected_crop() -> void:
	if field_state != "prepared":
		agriculture_status.text = "Prepare o solo antes do plantio."
		return

	var crop: Dictionary = FORAGE_CROPS[selected_crop_index]
	var planting_cost := int(crop["planting_cost"])
	if not _pay_infrastructure_cost("Plantio de %s" % crop["name"], planting_cost):
		return

	field_state = "growing"
	crop_days_elapsed = 0
	forage_field.color = FIELD_GROWING_COLOR
	_update_agriculture_ui()


func _advance_crop_day() -> void:
	if field_state != "growing":
		return
	if float(soil_moisture[1]) <= 8.0:
		return

	crop_days_elapsed += 1
	var crop: Dictionary = FORAGE_CROPS[selected_crop_index]
	if crop_days_elapsed >= int(crop["days"]):
		field_state = "ready"
		forage_field.color = FIELD_READY_COLOR


func _harvest_crop() -> void:
	if field_state != "ready":
		agriculture_status.text = "A cultura ainda não está pronta para colheita."
		return

	var crop: Dictionary = FORAGE_CROPS[selected_crop_index]
	var product := str(crop["product"])
	var yield_factor := _crop_soil_yield_factor()
	stored_feed_kg[product] = (
		float(stored_feed_kg[product]) + float(crop["yield_kg"]) * yield_factor
	)
	field_state = "idle"
	crop_days_elapsed = 0
	forage_field.color = FIELD_IDLE_COLOR
	_update_agriculture_ui()


func _crop_soil_yield_factor() -> float:
	var fertility_penalty := maxf(60.0 - float(soil_fertility[1]), 0.0) * 0.006
	var moisture_penalty := maxf(25.0 - float(soil_moisture[1]), 0.0) * 0.01
	var erosion_penalty := maxf(float(soil_erosion[1]) - 35.0, 0.0) * 0.004
	return clampf(1.0 - fertility_penalty - moisture_penalty - erosion_penalty, 0.45, 1.0)


func _activate_feed_reserve() -> void:
	if not herd_created:
		agriculture_status.text = "É necessário ter um lote para fornecer a reserva."
		return
	if feeding_plan_days_remaining > 0:
		agriculture_status.text = "Já existe um fornecimento programado."
		return

	var required_feed := herd_size * DAILY_RESERVE_KG_PER_ANIMAL * FEEDING_PLAN_DAYS
	if _total_stored_feed() < required_feed:
		agriculture_status.text = "Estoque insuficiente. Necessário: %.0f kg." % required_feed
		return

	_consume_stored_feed(required_feed)
	feeding_plan_days_remaining = FEEDING_PLAN_DAYS
	_update_agriculture_ui()


func _consume_stored_feed(required_feed: float) -> void:
	var remaining := required_feed
	for product in ["fresh_forage", "silage", "hay"]:
		var available := float(stored_feed_kg[product])
		var consumed := minf(available, remaining)
		stored_feed_kg[product] = available - consumed
		remaining -= consumed
		if remaining <= 0.0:
			return


func _total_stored_feed() -> float:
	return (
		float(stored_feed_kg["silage"])
		+ float(stored_feed_kg["fresh_forage"])
		+ float(stored_feed_kg["hay"])
	)


func _update_agriculture_ui() -> void:
	var crop: Dictionary = FORAGE_CROPS[selected_crop_index]
	var state_text := "sem preparo"
	if field_state == "prepared":
		state_text = "solo preparado"
	elif field_state == "growing":
		state_text = "crescendo: %d/%d dias" % [crop_days_elapsed, int(crop["days"])]
	elif field_state == "ready":
		state_text = "pronta para colheita"

	agriculture_status.text = (
		"Talhão: %s | Cultura: %s\n"
		+ "Solo: umidade %d%% | fertilidade %d%%\n"
		+ "Estoque: %.0f kg silagem | %.0f kg feno\n"
		+ "Forragem fresca: %.0f kg | Trato: %d dias"
	) % [
		state_text,
		crop["name"],
		roundi(soil_moisture[1]),
		roundi(soil_fertility[1]),
		float(stored_feed_kg["silage"]),
		float(stored_feed_kg["hay"]),
		float(stored_feed_kg["fresh_forage"]),
		feeding_plan_days_remaining,
	]
	forage_field_label.text = "TALHÃO FORRAGEIRO\n%s" % state_text.to_upper()
	select_crop_button.text = "Cultura: %s" % crop["name"]
	plant_crop_button.text = "Plantar — R$ %s" % _format_money(int(crop["planting_cost"]))
	prepare_soil_button.disabled = (
		not _has_livestock_area()
		or field_state != "idle"
		or cash_balance < SOIL_PREPARATION_COST
	)
	plant_crop_button.disabled = (
		field_state != "prepared"
		or cash_balance < int(crop["planting_cost"])
	)
	harvest_crop_button.disabled = field_state != "ready"
	use_feed_reserve_button.disabled = (
		not herd_created
		or feeding_plan_days_remaining > 0
		or _total_stored_feed() < (
			herd_size * DAILY_RESERVE_KG_PER_ANIMAL * FEEDING_PLAN_DAYS
		)
	)


func _buy_mineral() -> void:
	if cash_balance < MINERAL_PACKAGE_PRICE:
		nutrition_status.text = "Caixa insuficiente para comprar sal mineral."
		return

	mineral_stock_kg += MINERAL_PACKAGE_KG
	_record_transaction("Compra de 25 kg de sal mineral", -MINERAL_PACKAGE_PRICE)
	_update_nutrition_ui()


func _buy_supplement() -> void:
	if cash_balance < SUPPLEMENT_PACKAGE_PRICE:
		nutrition_status.text = "Caixa insuficiente para comprar suplemento."
		return

	supplement_stock_kg += SUPPLEMENT_PACKAGE_KG
	_record_transaction("Compra de 100 kg de suplemento", -SUPPLEMENT_PACKAGE_PRICE)
	_update_nutrition_ui()


func _consume_daily_supplements() -> Dictionary:
	var mineral_required := herd_size * MINERAL_DAILY_KG_PER_ANIMAL
	var supplement_required := herd_size * SUPPLEMENT_DAILY_KG_PER_ANIMAL
	var mineral_used := mineral_stock_kg >= mineral_required and mineral_required > 0.0
	var supplement_used := (
		supplement_stock_kg >= supplement_required and supplement_required > 0.0
	)

	if mineral_used:
		mineral_stock_kg -= mineral_required
	if supplement_used:
		supplement_stock_kg -= supplement_required

	return {
		"mineral": mineral_used,
		"supplement": supplement_used,
	}


func _update_nutrition_ui() -> void:
	_sync_legacy_from_vegetation()
	var selected_area := selected_farm_pasture
	var area_herd_size := (
		herd_size if herd_created and herd_pasture == selected_area else 0
	)
	var stock_text := "Estoque: %.1f kg mineral | %.1f kg suplemento" % [
		mineral_stock_kg, supplement_stock_kg
	]
	nutrition_status.text = "%s\n%s\n%s" % [
		vegetation_manager.status_text(selected_area, area_herd_size, average_weight_kg),
		stock_text,
		vegetation_last_event,
	]
	var area: Dictionary = vegetation_manager.get_area(selected_area)
	var resting := not area.is_empty() and str(area["management_mode"]) == "rest"
	vegetation_rest_button.text = "Liberar pastejo" if resting else "Colocar em descanso"
	var occupied := herd_created and herd_size > 0 and herd_pasture == selected_area
	var has_intervention := (
		not area.is_empty() and not Dictionary(area["intervention"]).is_empty()
	)
	vegetation_rest_button.disabled = area.is_empty() or (occupied and not resting) or has_intervention
	vegetation_form_button.disabled = area.is_empty() or occupied or has_intervention
	vegetation_fertilize_button.disabled = area.is_empty() or occupied or has_intervention
	vegetation_recover_button.disabled = area.is_empty() or occupied or has_intervention
	if not area.is_empty():
		vegetation_form_button.text = (
			"Reformar pastagem"
			if int(area["degradation_stage"]) >= 2
			else "Formar pastagem selecionada"
		)
	buy_mineral_button.disabled = cash_balance < MINERAL_PACKAGE_PRICE
	buy_supplement_button.disabled = cash_balance < SUPPLEMENT_PACKAGE_PRICE


func _buy_animals() -> void:
	var purchase := _market_purchase_quote()
	if not _has_livestock_area():
		market_info.text = _market_rules_text(
			"Falta uma área cercada.\n"
			+ "Cerque toda a propriedade ou forme um pasto na Loja Rural."
		)
		return
	if not gate_installed:
		market_info.text = _market_rules_text(
			"Falta uma porteira.\n"
			+ "Compre na Loja Rural e clique sobre a cerca construída."
		)
		return
	var purchase_total := int(purchase["total"])
	if cash_balance < purchase_total:
		market_info.text = _market_rules_text("Caixa insuficiente.\nCompra: R$ %s | Saldo: R$ %s" % [
			_format_money(purchase_total),
			_format_money(cash_balance),
		])
		return

	if not herd_created:
		herd_created = true
		herd_pasture = 1
		herd_marker.position = pasture_1_center - Vector2(115, 55)
		herd_marker.visible = true
		_update_transfer_herd_action()

	var selected_breed := _selected_market_breed()
	var selected_category := str(purchase["category"])
	var selected_quantity := int(purchase["quantity"])
	_add_individual_animals(selected_category, selected_quantity, {}, selected_breed)
	_record_transaction(
		"Compra de %d %s" % [
			selected_quantity,
			_animal_category_display_name(selected_category).to_lower(),
		],
		-purchase_total
	)
	_update_herd_marker()
	_update_herd_status("Compra de %d bovinos registrada." % selected_quantity)
	_update_nutrition_ui()
	_update_reproduction_ui()
	_update_sanitary_ui()
	_refresh_market_sale_list()
	market_info.text = _market_rules_text("Compra concluída: %d %s %s\nSaída: R$ %s | Saldo: R$ %s" % [
		selected_quantity,
		_animal_category_display_name(selected_category).to_lower(),
		_breed_display_name(selected_breed),
		_format_money(purchase_total),
		_format_money(cash_balance),
	])


func _sell_animals() -> void:
	var selected_animals := _market_selected_sale_animals()
	if selected_animals.is_empty():
		market_info.text = _market_rules_text("Selecione ao menos um animal para vender.")
		return

	var sale := _market_sale_quote()
	var selected_ids := {}
	for animal in selected_animals:
		selected_ids[str(animal.get("id", ""))] = true
	if selected_ids.size() != selected_animals.size():
		market_info.text = _market_rules_text("A seleção mudou. Revise os animais antes de vender.")
		return
	for animal_index in range(herd_animals.size() - 1, -1, -1):
		if selected_ids.has(str(herd_animals[animal_index].get("id", ""))):
			herd_animals.remove_at(animal_index)
	_sync_herd_size()
	_sync_reproduction_after_market_sale()
	var sale_total := int(sale["net"])
	_record_transaction("Venda de %d bovinos" % int(sale["quantity"]), sale_total)
	_refresh_market_sale_list()
	market_info.text = _market_rules_text("Venda concluída: %d bovinos\nValor líquido: R$ %s | Saldo: R$ %s" % [
		int(sale["quantity"]),
		_format_money(sale_total),
		_format_money(cash_balance),
	])

	if herd_size == 0:
		herd_created = false
		herd_marker.visible = false
		_update_herd_marker()
		transfer_herd_button.disabled = true
		pregnant_females = 0
		gestation_days_remaining = 0
		calf_age_days = -1
		breeding_method = ""
		herd_status.text = "A fazenda está sem bovinos."
		_update_finance_ui()
		_update_nutrition_ui()
		_update_agriculture_ui()
		_update_reproduction_ui()
		_update_sanitary_ui()
		return

	_update_herd_marker()
	_update_herd_status("Venda de 5 bovinos registrada.")
	_update_finance_ui()
	_update_nutrition_ui()
	_update_agriculture_ui()
	_update_reproduction_ui()
	_update_sanitary_ui()
	sell_animals_button.disabled = true


func _sync_reproduction_after_market_sale() -> void:
	pregnant_females = herd_animals.filter(
		func(animal: Dictionary) -> bool: return bool(animal.get("pregnant", false))
	).size()
	if pregnant_females == 0:
		gestation_days_remaining = 0
		breeding_method = ""
	if int(herd_categories["female_calves"]) + int(herd_categories["male_calves"]) == 0:
		calf_age_days = -1


func _remove_animals_for_sale(quantity: int) -> void:
	var remaining := quantity
	for category in ["oxen", "steers", "heifers", "cows", "male_calves", "female_calves", "bulls"]:
		for animal_index in range(herd_animals.size() - 1, -1, -1):
			if remaining <= 0:
				break
			if str(herd_animals[animal_index].get("category", "")) != category:
				continue
			herd_animals.remove_at(animal_index)
			remaining -= 1
		if remaining <= 0:
			break

	_sync_herd_size()
	pregnant_females = mini(pregnant_females, int(herd_categories["cows"]))
	if pregnant_females == 0:
		gestation_days_remaining = 0
		breeding_method = ""


func _pay_infrastructure_cost(description: String, cost: int) -> bool:
	if restoring_game:
		return true
	if cash_balance < cost:
		message_label.text = "Caixa insuficiente para %s. Custo: R$ %s." % [
			description.to_lower(),
			_format_money(cost),
		]
		return false

	_record_transaction(description, -cost)
	return true


func _record_transaction(description: String, amount: int) -> void:
	cash_balance = maxi(cash_balance + amount, 0)
	transaction_history.push_front({
		"day": current_day,
		"date": _formatted_date(),
		"description": description,
		"amount": amount,
	})
	if transaction_history.size() > TRANSACTION_HISTORY_LIMIT:
		transaction_history.resize(TRANSACTION_HISTORY_LIMIT)
	_update_finance_ui()
	_update_nutrition_ui()
	_update_water_ui()
	_update_agriculture_ui()


func _update_finance_ui() -> void:
	cash_status.text = "CAIXA\nR$ %s" % _format_money(cash_balance)
	var history_text := "Nenhuma movimentação registrada."

	if not transaction_history.is_empty():
		var history_lines: Array[String] = []
		for transaction in transaction_history.slice(0, 3):
			var amount := int(transaction.get("amount", 0))
			var signal_text := "+" if amount >= 0 else "-"
			history_lines.append("D%d | %s R$ %s | %s" % [
				int(transaction.get("day", 1)),
				signal_text,
				_format_money(absi(amount)),
				str(transaction.get("description", "")),
			])
		history_text = "\n".join(history_lines)

	finance_status.text = "Saldo: R$ %s\nCustos separados entre insumos, materiais e mão de obra.\n%s" % [
		_format_money(cash_balance),
		history_text,
	]
	buy_animals_button.disabled = false
	sell_animals_button.disabled = market_sale_list.get_selected_items().is_empty()


func _update_herd_marker() -> void:
	herd_marker.visible = false
	select_herd_button.disabled = herd_size <= 0

	var center := pasture_1_center if herd_pasture == 1 else pasture_2_center
	var polygon := pasture_1.polygon if herd_pasture == 1 else pasture_2.polygon
	if _using_general_farm_area():
		center = pasture_1_center
		polygon = farm_visual_boundary
	var preferred_pond := _pond_center_for_polygon(polygon, center)
	herd_visuals.call(
		"sync_herd",
		herd_size,
		herd_categories,
		center,
		polygon,
		preferred_pond,
		herd_animals
	)
	if herd_size > 0 and herd_selection_info.text == "Nenhum lote selecionado.":
		herd_selection_info.text = "%d bovinos no lote | clique em um animal para selecionar" % herd_size


func _pond_center_for_polygon(polygon: PackedVector2Array, fallback: Vector2) -> Vector2:
	var pond_1_center := _polygon_center(pond_1.polygon)
	var pond_2_center := _polygon_center(pond_2.polygon)
	if polygon.size() >= 3:
		if Geometry2D.is_point_in_polygon(pond_1_center, polygon):
			return pond_1_center
		if Geometry2D.is_point_in_polygon(pond_2_center, polygon):
			return pond_2_center
	return fallback


func _select_herd_lot() -> void:
	herd_visuals.call("select_lot")


func _on_herd_visual_selection_changed(summary: String) -> void:
	herd_selection_info.text = summary


func _format_money(value: int) -> String:
	var text := str(value)
	var formatted := ""

	while text.length() > 3:
		formatted = "." + text.right(3) + formatted
		text = text.left(text.length() - 3)

	return text + formatted


func _save_game(show_message: bool = true) -> void:
	var save_data := _build_save_data()
	var save_dir := save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(save_dir):
		DirAccess.make_dir_recursive_absolute(save_dir)
	var save_file := FileAccess.open(save_path, FileAccess.WRITE)

	if save_file == null:
		if show_message:
			save_status.text = "Não foi possível salvar."
		return

	save_file.store_string(JSON.stringify(save_data))
	if show_message:
		save_status.text = "Partida salva."


func _build_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"perimeter_built": perimeter_built,
		"full_farm_perimeter_built": full_farm_perimeter_built,
		"division_created": division_created,
		"division_orientation": int(division_orientation),
		"division_position": division_position,
		"gate_installed": gate_installed,
		"gate_open": gate_open,
		"gate_center_position": gate_center_position,
		"herd_created": herd_created,
		"herd_size": herd_size,
		"herd_animals": herd_animals.duplicate(true),
		"next_animal_id": next_animal_id,
		"herd_pasture": herd_pasture,
		"current_day": current_day,
		"day_of_year": day_of_year,
		"current_year": current_year,
		"server_unix_utc_at_save": _current_server_unix_utc(),
		"last_processed_server_unix_utc": last_processed_server_unix_utc,
		"server_timezone": FARM_TIMEZONE,
		"forage_1": forage[1],
		"forage_2": forage[2],
		"average_weight_kg": average_weight_kg,
		"body_condition": body_condition,
		"hunger": hunger,
		"thirst": thirst,
		"health": health,
		"herd_categories": herd_categories.duplicate(true),
		"pregnant_females": pregnant_females,
		"gestation_days_remaining": gestation_days_remaining,
		"calf_age_days": calf_age_days,
		"breeding_method": breeding_method,
		"pond_level_1": pond_level[1],
		"pond_level_2": pond_level[2],
		"pasture_quality_1": pasture_quality[1],
		"pasture_quality_2": pasture_quality[2],
		"pasture_degradation_1": pasture_degradation[1],
		"pasture_degradation_2": pasture_degradation[2],
		"soil_moisture_1": soil_moisture[1],
		"soil_moisture_2": soil_moisture[2],
		"soil_fertility_1": soil_fertility[1],
		"soil_fertility_2": soil_fertility[2],
		"soil_compaction_1": soil_compaction[1],
		"soil_compaction_2": soil_compaction[2],
		"soil_erosion_1": soil_erosion[1],
		"soil_erosion_2": soil_erosion[2],
		"mineral_stock_kg": mineral_stock_kg,
		"supplement_stock_kg": supplement_stock_kg,
		"river_level": river_level,
		"rainfall_mm": rainfall_mm,
		"max_temperature_c": max_temperature_c,
		"consecutive_dry_days": consecutive_dry_days,
		"weather_condition": weather_condition,
		"heat_stress": heat_stress,
		"parasite_pressure": parasite_pressure,
		"parasite_treatment_days_remaining": parasite_treatment_days_remaining,
		"clinical_medication_days_remaining": clinical_medication_days_remaining,
		"vitamin_supplement_days_remaining": vitamin_supplement_days_remaining,
		"sanitary_last_event": sanitary_last_event,
		"active_service_order": active_service_order.duplicate(true),
		"last_cowboy_activity": last_cowboy_activity,
		"selected_crop_index": selected_crop_index,
		"field_state": field_state,
		"crop_days_elapsed": crop_days_elapsed,
		"stored_silage_kg": stored_feed_kg["silage"],
		"stored_fresh_forage_kg": stored_feed_kg["fresh_forage"],
		"stored_hay_kg": stored_feed_kg["hay"],
		"feeding_plan_days_remaining": feeding_plan_days_remaining,
		"vegetation_state": vegetation_manager.export_state(),
		"vegetation_last_event": vegetation_last_event,
		"cash_balance": cash_balance,
		"transaction_history": transaction_history,
		"built_structures": _serialize_built_structures(),
		"structure_investment": structure_investment,
		"construction_job": _serialize_construction_job(),
	}


func _load_game(show_message: bool = true) -> void:
	startup_save_checked = true
	if not FileAccess.file_exists(save_path):
		if show_message:
			save_status.text = "Nenhuma partida salva."
		return

	var save_file := FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		if show_message:
			save_status.text = "Não foi possível carregar."
		return

	var parsed_data = JSON.parse_string(save_file.get_as_text())
	if not parsed_data is Dictionary:
		if show_message:
			save_status.text = "Arquivo de salvamento inválido."
		return

	var save_data: Dictionary = parsed_data
	_restore_saved_game(save_data)
	if server_clock_synchronized:
		_schedule_real_time_progress()
	elif show_message:
		save_status.text = "Partida carregada. Aguardando o horário oficial."
	if show_message and offline_days_pending <= 0:
		save_status.text = "Partida carregada."


func _restore_saved_game(save_data: Dictionary) -> void:
	var save_version := int(save_data.get("version", 1))
	var saved_perimeter := bool(save_data.get("perimeter_built", false))
	var saved_division := bool(save_data.get("division_created", false))
	var saved_orientation := int(save_data.get("division_orientation", DivisionMode.NONE))
	var saved_division_position := float(save_data.get("division_position", 0.0))
	var saved_gate := bool(save_data.get("gate_installed", false))
	var saved_gate_open := bool(save_data.get("gate_open", false))
	var saved_gate_center := float(save_data.get("gate_center_position", 0.0))
	var saved_herd := bool(save_data.get("herd_created", false))
	var saved_herd_size := int(save_data.get("herd_size", 10 if saved_herd else 0))
	var saved_animals = save_data.get("herd_animals", [])
	var saved_next_animal_id := int(save_data.get("next_animal_id", 1))
	var saved_herd_pasture := int(save_data.get("herd_pasture", 1))
	var saved_categories = save_data.get("herd_categories", {})
	var saved_genetics := {}  // Genetics now stored per-animal in herd_animals
	var saved_pregnant := int(save_data.get("pregnant_females", 0))
	var saved_gestation_days := int(save_data.get("gestation_days_remaining", 0))
	var saved_calf_age := int(save_data.get("calf_age_days", -1))
	var saved_breeding_method := str(save_data.get("breeding_method", ""))
	var saved_structures = save_data.get("built_structures", [])
	var saved_construction_job = save_data.get("construction_job", {})
	var legacy_full_perimeter: bool = (
		saved_perimeter
		and (not saved_structures is Array or saved_structures.is_empty())
	)
	var saved_full_perimeter := bool(save_data.get(
		"full_farm_perimeter_built",
		legacy_full_perimeter
	))
	var saved_river_level := float(save_data.get("river_level", 65.0))
	var saved_rainfall := float(save_data.get("rainfall_mm", 0.0))
	var saved_temperature := float(save_data.get("max_temperature_c", 33.0))
	var saved_dry_days := int(save_data.get("consecutive_dry_days", 0))
	var saved_weather_condition := str(save_data.get("weather_condition", "Seco"))
	var saved_heat_stress := float(save_data.get("heat_stress", 0.0))
	var saved_parasite_pressure := float(save_data.get("parasite_pressure", 0.0))
	var saved_treatment_days := int(save_data.get("parasite_treatment_days_remaining", 0))
	var saved_clinical_medication_days := int(
		save_data.get("clinical_medication_days_remaining", 0)
	)
	var saved_vitamin_supplement_days := int(
		save_data.get("vitamin_supplement_days_remaining", 0)
	)
	var saved_sanitary_event := str(
		save_data.get("sanitary_last_event", "Sem ocorrências sanitárias.")
	)
	var saved_service_order = save_data.get("active_service_order", {})
	var saved_cowboy_activity := str(save_data.get("last_cowboy_activity", ""))
	var saved_crop_index := int(save_data.get("selected_crop_index", 0))
	var saved_field_state := str(save_data.get("field_state", "idle"))
	var saved_crop_days := int(save_data.get("crop_days_elapsed", 0))
	var saved_feeding_days := int(save_data.get("feeding_plan_days_remaining", 0))
	var saved_vegetation_state = save_data.get("vegetation_state", {})
	var saved_vegetation_event := str(
		save_data.get("vegetation_last_event", "Vegetação acompanhada diariamente.")
	)
	last_processed_server_unix_utc = maxi(
		int(save_data.get(
			"last_processed_server_unix_utc",
			save_data.get("server_unix_utc_at_save", 0)
		)),
		0
	)
	var saved_feed := {
		"silage": float(save_data.get("stored_silage_kg", 0.0)),
		"fresh_forage": float(save_data.get("stored_fresh_forage_kg", 0.0)),
		"hay": float(save_data.get("stored_hay_kg", 0.0)),
	}

	current_day = maxi(int(save_data.get("current_day", 1)), 1)
	current_year = maxi(int(save_data.get("current_year", 1)), 1)
	var saved_day_of_year := int(save_data.get("day_of_year", 301))
	day_of_year = (
		_migrate_legacy_day_of_year(saved_day_of_year)
		if save_version < CALENDAR_365_SAVE_VERSION
		else clampi(saved_day_of_year, 1, _days_in_year(current_year))
	)
	forage = {
		1: float(save_data.get("forage_1", 100.0)),
		2: float(save_data.get("forage_2", 100.0)),
	}
	average_weight_kg = float(save_data.get("average_weight_kg", 300.0))
	body_condition = float(save_data.get("body_condition", 3.0))
	hunger = float(save_data.get("hunger", 0.0))
	thirst = float(save_data.get("thirst", 0.0))
	health = float(save_data.get("health", 100.0))
	pond_level = {
		1: float(save_data.get("pond_level_1", 70.0)),
		2: float(save_data.get("pond_level_2", 70.0)),
	}
	pasture_quality = {
		1: float(save_data.get("pasture_quality_1", 75.0)),
		2: float(save_data.get("pasture_quality_2", 75.0)),
	}
	pasture_degradation = {
		1: float(save_data.get("pasture_degradation_1", 0.0)),
		2: float(save_data.get("pasture_degradation_2", 0.0)),
	}
	soil_moisture = {
		1: clampf(float(save_data.get("soil_moisture_1", 62.0)), 0.0, 100.0),
		2: clampf(float(save_data.get("soil_moisture_2", 38.0)), 0.0, 100.0),
	}
	soil_fertility = {
		1: clampf(float(save_data.get("soil_fertility_1", 78.0)), 10.0, 100.0),
		2: clampf(float(save_data.get("soil_fertility_2", 48.0)), 10.0, 100.0),
	}
	soil_compaction = {
		1: clampf(float(save_data.get("soil_compaction_1", 12.0)), 0.0, 100.0),
		2: clampf(float(save_data.get("soil_compaction_2", 8.0)), 0.0, 100.0),
	}
	soil_erosion = {
		1: clampf(float(save_data.get("soil_erosion_1", 4.0)), 0.0, 100.0),
		2: clampf(float(save_data.get("soil_erosion_2", 12.0)), 0.0, 100.0),
	}
	soil_daily_runoff = {1: 0.0, 2: 0.0}
	mineral_stock_kg = maxf(float(save_data.get("mineral_stock_kg", 0.0)), 0.0)
	supplement_stock_kg = maxf(float(save_data.get("supplement_stock_kg", 0.0)), 0.0)
	rainfall_mm = maxf(saved_rainfall, 0.0)
	max_temperature_c = clampf(saved_temperature, 20.0, 50.0)
	consecutive_dry_days = maxi(saved_dry_days, 0)
	weather_condition = saved_weather_condition
	heat_stress = clampf(saved_heat_stress, 0.0, 100.0)
	parasite_pressure = clampf(saved_parasite_pressure, 0.0, 100.0)
	parasite_treatment_days_remaining = clampi(
		saved_treatment_days,
		0,
		PARASITE_TREATMENT_PROTECTION_DAYS
	)
	clinical_medication_days_remaining = clampi(
		saved_clinical_medication_days,
		0,
		CLINICAL_MEDICATION_COOLDOWN_DAYS
	)
	vitamin_supplement_days_remaining = clampi(
		saved_vitamin_supplement_days,
		0,
		VITAMIN_SUPPLEMENT_DAYS
	)
	sanitary_last_event = saved_sanitary_event
	active_service_order = (
		saved_service_order.duplicate(true)
		if saved_service_order is Dictionary
		else {}
	)
	last_cowboy_activity = saved_cowboy_activity
	cash_balance = maxi(int(save_data.get("cash_balance", STARTING_CASH)), 0)
	var saved_history = save_data.get("transaction_history", [])
	transaction_history = saved_history if saved_history is Array else []

	restoring_game = true
	_reset_construction_visuals()

	if saved_structures is Array and not saved_structures.is_empty():
		_restore_free_structures(saved_structures)
		var has_individual_gate_state := false
		for saved_structure in saved_structures:
			if (
				saved_structure is Dictionary
				and str(saved_structure.get("type", "")) == "Porteira"
				and saved_structure.has("open")
			):
				has_individual_gate_state = true
				break
		for gate_index in range(free_gate_nodes.size()):
			if not has_individual_gate_state:
				free_gate_open_states[gate_index] = saved_gate_open
				_sync_free_gate_structure_state(gate_index, saved_gate_open)
			free_gate_nodes[gate_index].rotation = (
				free_gate_base_rotations[gate_index]
				+ (PI / 2.0 if free_gate_open_states[gate_index] else 0.0)
			)
		gate_open = free_gate_open_states.any(
			func(open_state: bool) -> bool: return open_state
		)
	else:
		if saved_perimeter:
			_build_perimeter()

		if saved_division:
			if saved_orientation == DivisionMode.HORIZONTAL:
				_create_horizontal_division(saved_division_position)
			elif saved_orientation == DivisionMode.VERTICAL:
				_create_vertical_division(saved_division_position)

		if saved_gate:
			var gate_click := Vector2(saved_gate_center, division_position)
			if division_orientation == DivisionMode.VERTICAL:
				gate_click = Vector2(division_position, saved_gate_center)
			_place_gate(gate_click)
			gate_open = saved_gate_open
			gate.rotation = (
				(PI / 2.0 if division_orientation == DivisionMode.HORIZONTAL else -PI / 2.0)
				if gate_open
				else 0.0
			)
	full_farm_perimeter_built = full_farm_perimeter_built or saved_full_perimeter
	if _using_general_farm_area():
		_configure_general_farm_area()
	if not vegetation_manager.import_state(saved_vegetation_state):
		for pasture_number in [1, 2]:
			vegetation_manager.set_legacy_condition(
				pasture_number,
				float(forage[pasture_number]),
				float(pasture_quality[pasture_number]),
				float(pasture_degradation[pasture_number])
			)
	vegetation_last_event = saved_vegetation_event
	_sync_legacy_from_vegetation()

	river_level = clampf(saved_river_level, 0.0, 100.0)
	selected_crop_index = clampi(saved_crop_index, 0, FORAGE_CROPS.size() - 1)
	field_state = (
		saved_field_state
		if saved_field_state in ["idle", "prepared", "growing", "ready"]
		else "idle"
	)
	crop_days_elapsed = maxi(saved_crop_days, 0)
	stored_feed_kg = saved_feed
	feeding_plan_days_remaining = clampi(saved_feeding_days, 0, FEEDING_PLAN_DAYS)
	if field_state == "growing":
		forage_field.color = FIELD_GROWING_COLOR
	elif field_state == "ready":
		forage_field.color = FIELD_READY_COLOR
	elif field_state == "prepared":
		forage_field.color = FIELD_IDLE_COLOR.lightened(0.12)
	else:
		forage_field.color = FIELD_IDLE_COLOR

	if saved_herd:
		if saved_categories is Dictionary and not saved_categories.is_empty():
			for category in herd_categories:
				herd_categories[category] = maxi(int(saved_categories.get(category, 0)), 0)
		else:
			var fallback_bulls := 1 if saved_herd_size > 0 else 0
			var fallback_cows := mini(5, maxi(saved_herd_size - fallback_bulls, 0))
			herd_categories = {
				"female_calves": 0,
				"male_calves": 0,
				"heifers": maxi(saved_herd_size - fallback_bulls - fallback_cows, 0),
				"cows": fallback_cows,
				"steers": 0,
				"oxen": 0,
				"bulls": fallback_bulls,
			}
if saved_genetics is Dictionary and saved_genetics.has_key("herd_genetics"):
			// Legacy format - ignore, genotype is now per-animal
			pass
		herd_animals.clear()
		next_animal_id = 1
		if saved_animals is Array and not saved_animals.is_empty():
			for saved_animal in saved_animals:
				if not saved_animal is Dictionary:
					continue
				var saved_category := str(saved_animal.get("category", "heifers"))
				var restored_animal := _create_individual_animal(
					saved_category,
					saved_animal.get("genotype", {})
				)
				for animal_key in saved_animal:
					restored_animal[animal_key] = saved_animal[animal_key]
				if not restored_animal.has("destiny") or str(restored_animal.get("destiny", "")).is_empty():
					restored_animal["destiny"] = "herd" if saved_category in ["cows", "heifers", "bulls"] else "unassigned"
				herd_animals.append(restored_animal)
			next_animal_id = maxi(saved_next_animal_id, next_animal_id)
		else:
			var legacy_categories: Dictionary = herd_categories.duplicate(true)
			for category in legacy_categories:
				_add_individual_animals(category, int(legacy_categories[category]))
		pregnant_females = clampi(saved_pregnant, 0, int(herd_categories["cows"]))
		gestation_days_remaining = (
			clampi(saved_gestation_days, 0, GESTATION_DAYS)
			if pregnant_females > 0
			else 0
		)
		calf_age_days = clampi(saved_calf_age, -1, WEANING_AGE_DAYS - 1)
		breeding_method = saved_breeding_method if pregnant_females > 0 else ""
		herd_created = true
		_sync_herd_size()
		if herd_size <= 0:
			herd_categories["heifers"] = maxi(saved_herd_size, 1)
			_sync_herd_size()
		herd_pasture = clampi(saved_herd_pasture, 1, 2)
		var herd_center := pasture_1_center if herd_pasture == 1 else pasture_2_center
		herd_marker.position = herd_center - Vector2(115, 55)
		herd_marker.visible = true
		_update_herd_marker()
		_update_transfer_herd_action()
		buy_animals_button.disabled = false
		sell_animals_button.disabled = true
		_update_herd_status("Partida restaurada.")
	else:
		_update_empty_herd_guidance()

	restoring_game = false
	_resume_saved_construction_job(saved_construction_job)
	_resume_service_order_visuals()
	_update_pasture_visuals()
	_update_climate_visuals()
	_update_finance_ui()
	_update_nutrition_ui()
	_update_water_ui()
	_update_agriculture_ui()
	_update_reproduction_ui()
	_update_sanitary_ui()
	_update_service_order_ui()
	_update_structures_ui()
	_apply_farm_layer_visibility()
	_update_farm_ui()


func _reset_construction_visuals() -> void:
	if is_instance_valid(construction_job_tween):
		construction_job_tween.kill()
	construction_job_tween = null
	construction_job_completion = Callable()
	construction_job_name = ""
	construction_job_data = {}
	construction_job_target = Vector2.ZERO
	construction_job_started_unix_utc = 0
	construction_job_completes_unix_utc = 0
	construction_job_duration_seconds = 0.0
	construction_job_active = false
	if is_instance_valid(full_perimeter_build_tween):
		full_perimeter_build_tween.kill()
	full_perimeter_build_tween = null
	if is_instance_valid(full_perimeter_preview_visual):
		full_perimeter_preview_visual.free()
	full_perimeter_preview_visual = null
	construction_crew_visual.visible = false
	_reset_construction_crew_pose()
	perimeter_built = false
	full_farm_perimeter_built = false
	division_created = false
	division_mode = DivisionMode.NONE
	division_orientation = DivisionMode.NONE
	division_position = 0.0
	placing_gate = false
	gate_installed = false
	gate_open = false
	gate_center_position = 0.0
	herd_created = false
	herd_size = 0
	herd_animals.clear()
	next_animal_id = 1
	herd_categories = {
		"female_calves": 0,
		"male_calves": 0,
		"heifers": 0,
		"cows": 0,
		"steers": 0,
		"oxen": 0,
		"bulls": 0,
	}
	pregnant_females = 0
	gestation_days_remaining = 0
	calf_age_days = -1
	breeding_method = ""
	_reset_build_mode()
	built_structures = []
	structure_investment = 0
	free_paddock_count = 0
	corral_rects = []
	free_gate_nodes = []
	free_gate_base_rotations = []
	free_gate_open_states = []
	for structure_node in player_structures.get_children():
		if structure_node != construction_preview:
			structure_node.free()
	herd_pasture = 1
	field_state = "idle"
	crop_days_elapsed = 0
	feeding_plan_days_remaining = 0
	stored_feed_kg = {
		"silage": 0.0,
		"fresh_forage": 0.0,
		"hay": 0.0,
	}

	perimeter_fence.visible = false
	perimeter_fence.modulate.a = 1.0
	pasture_1.visible = false
	pasture_2.visible = false
	internal_fence.visible = false
	internal_fence_2.visible = false
	gate.visible = false
	gate.rotation = 0.0
	pasture_1_label.visible = false
	pasture_2_label.visible = false
	herd_marker.visible = false
	herd_visuals.call("clear_herd")
	herd_selection_info.text = "Nenhum lote selecionado."
	select_herd_button.disabled = true
	forage_field.visible = false
	forage_field_label.visible = false
	property_label.visible = false
	property_label.text = "PROPRIEDADE SEM CERCAS"

	perimeter_button.disabled = false
	horizontal_button.disabled = true
	vertical_button.disabled = true
	cancel_button.disabled = true
	gate_install_button.disabled = true
	transfer_herd_button.disabled = true
	transfer_herd_button.text = "Transferir para Pasto 2"
	buy_animals_button.disabled = true
	sell_animals_button.disabled = true
	market_info.text = "Cerque a propriedade e instale uma porteira para comprar animais."
	status_label.text = "Perímetro: não cercado\nDivisões internas: nenhuma\nPastos formados: nenhum"
	message_label.text = "Primeiro, cerque todo o perímetro da fazenda."
	herd_status.text = "Cerque a propriedade, instale uma porteira e adquira animais no Mercado."
	_update_finance_ui()
	_update_nutrition_ui()
	_update_water_ui()
	_update_agriculture_ui()
	_update_reproduction_ui()
	_update_sanitary_ui()
	_update_structures_ui()
