extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var empty_farm_scene: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(empty_farm_scene)
	await process_frame
	var official_unix := 1785943800
	empty_farm_scene.call("_apply_server_time_payload", {
		"unix_utc": official_unix,
		"timezone": "America/Bahia",
		"offset_seconds": -10800,
		"local": {"year": 2026, "month": 8, "day": 5, "hour": 12, "minute": 30, "second": 0},
	})
	_check(
		empty_farm_scene.call(
			"_days_between_server_dates", official_unix - 2 * 86400, official_unix
		) == 2,
		"O relógio oficial deve calcular os dias transcorridos sem usar aceleração."
	)
	var empty_farm_day := int(empty_farm_scene.get("current_day"))
	empty_farm_scene.set("offline_days_pending", 31)
	empty_farm_scene.set("offline_days_total", 31)
	empty_farm_scene.set("offline_target_server_unix_utc", official_unix)
	empty_farm_scene.set("offline_summary_before", {})
	empty_farm_scene.call("_process_offline_days")
	_check(
		empty_farm_scene.get("current_day") == empty_farm_day + 30
		and empty_farm_scene.get("offline_days_pending") == 1,
		"A evolução offline deve ser processada em blocos sem travar o jogo."
	)
	empty_farm_scene.queue_free()
	await process_frame

	var main_scene: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main_scene)
	await process_frame

	var camera: Camera2D = main_scene.get_node("Camera")
	var main_layout: Control = main_scene.get_node("Interface/MainLayout")
	var map_frame: Control = main_scene.get_node("Interface/MainLayout/Body/Content/MapFrame")
	var header: Control = main_scene.get_node("Interface/MainLayout/Header")
	var sidebar: Control = main_scene.get_node("Interface/MainLayout/Body/Sidebar")
	var map_background: Sprite2D = main_scene.get_node("MapBackground")
	for viewport_size in [
		Vector2i(1280, 720),
		Vector2i(1440, 900),
		Vector2i(1920, 1080),
	]:
		root.size = viewport_size
		await process_frame
		camera.call("_fit_farm_to_available_area")
		var responsive_map_rect := map_frame.get_global_rect()
		var responsive_layout_rect := main_layout.get_global_rect()
		var responsive_header_rect := header.get_global_rect()
		var responsive_sidebar_rect := sidebar.get_global_rect()
		_check(
			is_equal_approx(header.size.y, 76.0)
			and is_equal_approx(sidebar.size.x, 360.0),
			"A estrutura-base deve manter header de 76 px e menu de 360 px em %dx%d."
			% [viewport_size.x, viewport_size.y]
		)
		_check(
			responsive_map_rect.position.is_equal_approx(Vector2(
				responsive_sidebar_rect.end.x,
				responsive_header_rect.end.y
			))
			and responsive_map_rect.end.is_equal_approx(responsive_layout_rect.end),
			"A fazenda deve ocupar todo o espaço restante em %dx%d."
			% [viewport_size.x, viewport_size.y]
		)
	root.size = Vector2i(1280, 720)
	await process_frame
	var farm_constants: Dictionary = main_scene.get_script().get_script_constant_map()
	_check(
		is_equal_approx(float(farm_constants["FARM_AREA_BAHIA_TASKS"]), 595.0)
		and is_equal_approx(float(farm_constants["FARM_AREA_HECTARES"]), 259.182)
		and is_equal_approx(float(farm_constants["METERS_PER_MAP_UNIT"]), 0.670797097),
		"O mapa deve representar corretamente as 595 tarefas baianas da propriedade."
	)
	_check(map_background.texture != null, "O mapa ilustrado da fazenda deve ser carregado.")
	_check(
		map_background.texture.resource_path.ends_with("fazenda-santo-antonio-relevo-seco.png"),
		"O mapa-base deve preservar os leitos secos para receber a água simulada."
	)
	_check(
		main_scene.call("_is_inside_visual_property", Vector2(1600, 900))
		and not main_scene.call("_is_inside_visual_property", Vector2(20, 20)),
		"A consulta do terreno deve funcionar somente dentro da propriedade."
	)
	_check(
		main_scene.call("_relative_elevation_m", Vector2(1650, 340))
		> main_scene.call("_relative_elevation_m", Vector2(1540, 1290)),
		"A área alta deve possuir elevação relativa maior que a baixada."
	)
	_check(
		not main_scene.get_node("PropertyLabel").visible
		and not main_scene.get_node("CaatingaLabel").visible
		and not main_scene.get_node("RiverLabel").visible
		and not main_scene.get_node("Pond1Label").visible
		and not main_scene.get_node("Pond2Label").visible,
		"O mapa não deve exibir textos cartográficos."
	)
	_check(
		not main_scene.get_node("Pasture1Label").visible,
		"O mapa não deve exibir o texto e os indicadores do Pasto 1."
	)
	_check(
		is_equal_approx(float(main_scene.get_node("Pond1Gauge").get("level")), 70.0)
		and is_equal_approx(float(main_scene.get_node("Pond2Gauge").get("level")), 70.0),
		"Os açudes devem exibir a régua de nível."
	)
	camera.call("_fit_farm_to_available_area")
	var map_rect := map_frame.get_global_rect()
	var expected_zoom := maxf(map_rect.size.x / 3200.0, map_rect.size.y / 1800.0)
	var viewport_center := camera.get_viewport().get_visible_rect().size / 2.0
	var farm_center_on_screen := viewport_center + (Vector2(1600.0, 900.0) - camera.position) * camera.zoom.x
	_check(is_equal_approx(camera.zoom.x, expected_zoom), "A fazenda deve preencher toda a área central.")
	_check(
		farm_center_on_screen.distance_to(map_rect.position + map_rect.size / 2.0) < 1.0,
		"A fazenda deve ficar centralizada no painel do mapa."
	)
	var fitted_zoom := camera.zoom.x
	camera.call("_apply_zoom", 0.01, map_rect.get_center())
	_check(
		is_equal_approx(camera.zoom.x, fitted_zoom),
		"O zoom não deve afastar a fazenda além da área central."
	)

	var sidebar_scroll: ScrollContainer = main_scene.get_node(
		"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll"
	)
	var sidebar_wheel := InputEventMouseButton.new()
	sidebar_wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	sidebar_wheel.pressed = true
	sidebar_wheel.position = sidebar_scroll.get_global_rect().get_center()
	camera.call("_unhandled_input", sidebar_wheel)
	_check(
		is_equal_approx(camera.zoom.x, fitted_zoom),
		"A roda do mouse no menu lateral não deve alterar o mapa."
	)
	_check(
		not sidebar_scroll.mouse_force_pass_scroll_events,
		"O menu lateral deve reter seus eventos de rolagem."
	)

	var map_wheel := InputEventMouseButton.new()
	map_wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	map_wheel.pressed = true
	map_wheel.position = map_rect.get_center()
	camera.call("_unhandled_input", map_wheel)
	_check(
		is_equal_approx(camera.zoom.x, fitted_zoom * 1.06),
		"A roda do mouse sobre o mapa deve aplicar zoom suave."
	)

	camera.call("_fit_farm_to_available_area")
	var magnify_gesture := InputEventMagnifyGesture.new()
	magnify_gesture.factor = 1.2
	magnify_gesture.position = map_rect.get_center()
	camera.call("_unhandled_input", magnify_gesture)
	_check(
		is_equal_approx(camera.zoom.x, fitted_zoom * 1.1),
		"A pinça do trackpad deve aplicar metade do fator recebido."
	)

	camera.position = Vector2(-10000.0, -10000.0)
	camera.call("_clamp_position_to_map")
	var farm_top_left := viewport_center - camera.position * camera.zoom.x
	var farm_bottom_right := farm_top_left + Vector2(3200.0, 1800.0) * camera.zoom.x
	_check(
		farm_top_left.x <= map_rect.position.x + 1.0
		and farm_top_left.y <= map_rect.position.y + 1.0
		and farm_bottom_right.x >= map_rect.end.x - 1.0
		and farm_bottom_right.y >= map_rect.end.y - 1.0,
		"A câmera não deve revelar espaço fora da fazenda."
	)

	var farm_panel: Label = main_scene.get_node(
		"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/FarmAlertCard/Margin/FarmPanel"
	)
	var farm_selector: OptionButton = main_scene.get_node(
		"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/FarmPastureSelector"
	)
	var water_layer_button: CheckButton = main_scene.get_node(
		"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/FarmWaterLayerButton"
	)
	var structures_layer_button: CheckButton = main_scene.get_node(
		"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/FarmStructuresLayerButton"
	)
	var terrain_info_button: CheckButton = main_scene.get_node("%FarmTerrainInfoButton")
	var terrain_tooltip: PanelContainer = main_scene.get_node("%TerrainTooltip")
	var terrain_tooltip_label: Label = main_scene.get_node("%TerrainTooltipLabel")
	_check(
		"ATENÇÃO" in farm_panel.text
		and "ainda não está cercada" in farm_panel.text
		and farm_selector.disabled,
		"O módulo Fazenda deve destacar somente o próximo problema real."
	)
	_check(
		not main_scene.has_node(
			"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/FarmIdentityCard"
		)
		and not main_scene.has_node(
			"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/FarmStats"
		)
		and not main_scene.has_node(
			"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/FarmPastureCard"
		),
		"O módulo Fazenda não deve exibir os três quadros redundantes."
	)
	terrain_info_button.button_pressed = true
	main_scene.call("_show_terrain_tooltip", map_rect.get_center(), Vector2(1540, 1290))
	_check(
		terrain_tooltip.visible
		and "ELEVAÇÃO RELATIVA" in terrain_tooltip_label.text
		and "Relevo:" in terrain_tooltip_label.text
		and "Solo:" in terrain_tooltip_label.text
		and "Umidade:" in terrain_tooltip_label.text,
		"A opção deve mostrar os dados do terreno ao apontar para a fazenda."
	)
	terrain_info_button.button_pressed = false
	_check(not terrain_tooltip.visible, "Desativar a opção deve esconder o tooltip do terreno.")
	var pond_level_before_layer_toggle: Dictionary = main_scene.get("pond_level").duplicate()
	water_layer_button.button_pressed = false
	_check(
		not main_scene.get_node("Pond1").visible
		and not main_scene.get_node("Pond1Gauge").visible
		and main_scene.get_node("Pond1Visual").visible
		and main_scene.get_node("IntermittentRiver").visible
		and main_scene.get("pond_level") == pond_level_before_layer_toggle,
		"As camadas devem alterar somente a visualização do mapa."
	)
	water_layer_button.button_pressed = true
	_check(
		not main_scene.get_node("Pond1").visible
		and main_scene.get_node("Pond1Gauge").visible
		and main_scene.get_node("Pond1Visual").visible
		and main_scene.get_node("IntermittentRiver").visible
		and water_layer_button.text == "Indicadores de água",
		"Os indicadores devem ser independentes das ilustrações naturais de água."
	)
	main_scene.set("pond_level", {1: 20.0, 2: 70.0})
	main_scene.set("river_level", 20.0)
	main_scene.call("_update_water_level_visuals")
	var low_pond_scale: Vector2 = main_scene.get_node("Pond1Visual").scale
	var low_river_level: float = main_scene.get_node("IntermittentRiver").material.get_shader_parameter("water_level")
	main_scene.set("pond_level", {1: 90.0, 2: 70.0})
	main_scene.set("river_level", 90.0)
	main_scene.call("_update_water_level_visuals")
	_check(
		main_scene.get_node("Pond1Visual").scale.x > low_pond_scale.x
		and main_scene.get_node("IntermittentRiver").material.get_shader_parameter("water_level") > low_river_level,
		"Açudes e rio devem crescer visualmente conforme seus níveis."
	)
	main_scene.set("pond_level", pond_level_before_layer_toggle)
	main_scene.set("river_level", 65.0)
	main_scene.call("_update_water_level_visuals")
	structures_layer_button.button_pressed = false
	_check(
		not main_scene.get_node("PlayerStructures").visible,
		"A camada de estruturas deve poder ser ocultada."
	)
	main_scene.call("_show_module", "store")
	_check(
		main_scene.get_node("PlayerStructures").visible
		and structures_layer_button.button_pressed,
		"A Loja Rural deve reativar as estruturas para permitir construções."
	)
	main_scene.call("_show_module", "farm")

	_check(not main_scene.get("perimeter_built"), "A propriedade deve iniciar sem cerca.")

	main_scene.call("_build_perimeter")
	_check(main_scene.get("perimeter_built"), "A cerca do perímetro deve ser construída.")
	_check(main_scene.get("cash_balance") == 47000, "A cerca externa deve custar R$ 3.000.")

	main_scene.call("_create_horizontal_division", 800.0)
	_check(main_scene.get("division_created"), "A divisão deve formar dois pastos.")
	_check(main_scene.get("cash_balance") == 45500, "A cerca interna deve custar R$ 1.500.")
	_check(
		not farm_selector.disabled
		and not farm_selector.is_item_disabled(1),
		"O módulo Fazenda deve reconhecer os pastos formados."
	)
	_check(
		main_scene.call("_select_farm_pasture_at", Vector2(1600, 1300))
		and main_scene.get("selected_farm_pasture") == 2
		and farm_selector.selected == 1,
		"O jogador deve conseguir selecionar um pasto diretamente no mapa."
	)

	main_scene.call("_place_gate", Vector2(1600, 800))
	_check(main_scene.get("gate_installed"), "A porteira deve ser instalada.")
	_check(main_scene.get("cash_balance") == 45000, "A porteira deve custar R$ 500.")

	main_scene.call("_add_initial_herd")
	_check(main_scene.get("herd_size") == 10, "O cenário-base deve conter 10 bovinos.")
	_check(main_scene.get("cash_balance") == 45000, "A preparação do cenário-base não deve gerar custo adicional.")
	_check(main_scene.get("herd_categories")["cows"] == 5, "O cenário-base deve conter cinco vacas.")
	_check(main_scene.get("herd_categories")["bulls"] == 1, "O cenário-base deve conter um touro.")
	var individual_herd: Array = main_scene.get("herd_animals")
	var animal_ids: Dictionary = {}
	for individual_animal in individual_herd:
		animal_ids[individual_animal["id"]] = true
	_check(
		individual_herd.size() == 10 and animal_ids.size() == 10,
		"Cada bovino deve possuir um registro e uma identificação únicos."
	)
	var sanitary_fields_complete := true
	for sanitary_animal_record in individual_herd:
		sanitary_fields_complete = sanitary_fields_complete and (
			sanitary_animal_record.has("parasite_load")
			and sanitary_animal_record.has("sanitary_state")
			and sanitary_animal_record.has("brucellosis_vaccinated")
			and sanitary_animal_record.has("clostridiosis_vaccine_days_remaining")
		)
	_check(sanitary_fields_complete, "Cada bovino deve possuir um registro sanitário individual.")
	_check(
		individual_herd.all(func(animal: Dictionary) -> bool: return animal["breed"] == "nelore"),
		"O cenário-base deve registrar a raça de cada bovino."
	)
	var breed_selector: OptionButton = main_scene.get_node(
		"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/BreedSelector"
	)
	_check(
		breed_selector.item_count == 11,
		"O Mercado deve disponibilizar as onze raças com identidade visual."
	)
	var market_category_selector: OptionButton = main_scene.get("market_category_selector")
	_check(
		market_category_selector.item_count == 7,
		"O Mercado deve permitir comprar todas as categorias do rebanho."
	)
	main_scene.call("_update_market_readiness_ui")
	var market_rules_text: String = main_scene.get("market_info").text.to_lower()
	_check(
		"saldo depois da compra" in market_rules_text
		and "transporte" in market_rules_text
		and "documentos" in market_rules_text
		and "lotação" in market_rules_text,
		"O Mercado deve calcular compra, custos e impacto na lotação."
	)
	var market_mode_selector: OptionButton = main_scene.get("market_mode_selector")
	market_mode_selector.select(1)
	main_scene.call("_on_market_mode_selected", 1)
	_check(
		main_scene.get("market_sale_list").visible
		and not main_scene.get("market_category_selector").visible,
		"O Mercado deve mostrar apenas o fluxo de venda quando ele for escolhido."
	)
	market_mode_selector.select(0)
	main_scene.call("_on_market_mode_selected", 0)
	_check(
		main_scene.get("market_category_selector").visible
		and not main_scene.get("market_sale_list").visible,
		"O Mercado deve mostrar apenas o fluxo de compra quando ele for escolhido."
	)
	var herd_visual_manager: Node = main_scene.get("herd_visuals")
	var cattle_visuals: Array = herd_visual_manager.call("animals")
	_check(
		herd_visual_manager.call("visual_count") == 10
		and not main_scene.get("herd_marker").visible,
		"Os bovinos 2D devem substituir o marcador provisório."
	)
	_check(
		cattle_visuals[0].category != cattle_visuals[4].category,
		"As categorias do rebanho devem possuir representação visual própria."
	)
	var first_cattle: Area2D = cattle_visuals[0]
	var cattle_start_position := first_cattle.position
	first_cattle.call(
		"set_activity",
		"caminhando",
		cattle_start_position + Vector2(100.0, 0.0),
		10.0
	)
	first_cattle.call("advance", 1.0)
	_check(
		first_cattle.position.x > cattle_start_position.x
		and first_cattle.activity == "caminhando",
		"Os bovinos devem caminhar automaticamente."
	)
	herd_visual_manager.call("select_animal", 0)
	_check(
		"BOV-0001" in main_scene.get("herd_selection_info").text,
		"O jogador deve conseguir selecionar um bovino."
	)
	herd_visual_manager.call("select_lot")
	_check(
		"Lote selecionado" in main_scene.get("herd_selection_info").text,
		"O jogador deve conseguir selecionar o lote."
	)
	var original_day_of_year := int(main_scene.get("day_of_year"))
	var original_year := int(main_scene.get("current_year"))
	main_scene.set("day_of_year", 305)
	main_scene.set("current_year", 1)
	_check(
		main_scene.call("_formatted_date") == "01/11/0001",
		"O calendário deve exibir a data no formato DD/MM/AAAA."
	)
	main_scene.set("day_of_year", 59)
	var february_date: String = main_scene.call("_formatted_date")
	main_scene.set("day_of_year", 60)
	var march_date: String = main_scene.call("_formatted_date")
	main_scene.set("day_of_year", 365)
	var december_date: String = main_scene.call("_formatted_date")
	_check(
		february_date == "28/02/0001"
		and march_date == "01/03/0001"
		and december_date == "31/12/0001",
		"O ano deve possuir 365 dias e respeitar a duração real dos meses."
	)
	main_scene.set("current_year", 2024)
	main_scene.set("day_of_year", 60)
	var leap_date: String = main_scene.call("_formatted_date")
	main_scene.set("day_of_year", 61)
	var post_leap_date: String = main_scene.call("_formatted_date")
	_check(
		leap_date == "29/02/2024" and post_leap_date == "01/03/2024",
		"O calendário oficial deve respeitar anos bissextos."
	)
	_check(
		main_scene.call("_migrate_legacy_day_of_year", 301) == 305,
		"Partidas do calendário antigo devem preservar a data aproximada."
	)
	var official_time_payload := {
		"unix_utc": 1785943800,
		"timezone": "America/Bahia",
		"offset_seconds": -10800,
		"local": {
			"year": 2026,
			"month": 8,
			"day": 5,
			"hour": 12,
			"minute": 30,
			"second": 0,
		},
	}
	_check(
		main_scene.call("_apply_server_time_payload", official_time_payload)
		and main_scene.call("_formatted_server_datetime") == "05/08/2026 12:30"
		and main_scene.get("server_clock_synchronized"),
		"O jogo deve validar e exibir o horário oficial no fuso America/Bahia."
	)
	main_scene.call(
		"_set_calendar_from_server_unix",
		main_scene.call("_current_server_unix_utc")
	)
	main_scene.set("weather_condition", "Seco")
	main_scene.call("_update_climate_visuals")
	_check(
		"Estiagem • Seco" in main_scene.get_node("%ClimateStatus").text
		and main_scene.get_node("%ClimateIcon").texture != null,
		"O header deve diferenciar a fase climática da condição diária."
	)
	main_scene.set("day_of_year", original_day_of_year)
	main_scene.set("current_year", original_year)

	# 04/11 é um dia chuvoso determinístico no calendário semiárido do teste.
	main_scene.set("day_of_year", 307)
	var river_before: float = main_scene.get("river_level")
	var soil_moisture_before: Dictionary = main_scene.get("soil_moisture").duplicate()
	main_scene.call("_advance_day")
	var forage: Dictionary = main_scene.get("forage")
	_check(main_scene.get("current_day") == 2, "O calendário deve avançar um dia.")
	_check(
		main_scene.get("rainfall_mm") > 0.0
		and main_scene.get("max_temperature_c") > 20.0,
		"O clima diário deve gerar chuva irregular e temperatura."
	)
	_check(forage[1] < 100.0, "O lote deve consumir a forragem do pasto ocupado.")
	_check(main_scene.get("cash_balance") == 45000, "A passagem do dia não deve gerar custo genérico.")
	_check(main_scene.get("river_level") > river_before, "O rio deve reagir ao período chuvoso.")
	_check(
		main_scene.get("soil_moisture")[1] > soil_moisture_before[1]
		and main_scene.get("soil_daily_runoff")[2] > main_scene.get("soil_daily_runoff")[1],
		"Chuva, infiltração e relevo devem alterar a umidade e o escoamento."
	)
	_check(
		main_scene.call("_soil_growth_factor", 1)
		> main_scene.call("_soil_growth_factor", 2),
		"O solo de baixada deve favorecer mais o crescimento que a área alta pedregosa."
	)
	_check(
		is_equal_approx(
			float(main_scene.get_node("Pond1Gauge").get("level")),
			float(main_scene.get("pond_level")[1])
		),
		"A régua deve acompanhar o nível atual da água."
	)

	_check(
		not main_scene.has_node("%PauseTimeButton")
		and not main_scene.has_node("%NormalTimeButton")
		and not main_scene.has_node("%FastTimeButton"),
		"Pausa, 1x e 8x não devem permanecer na interface."
	)
	main_scene.set("health", 19.0)
	main_scene.call("_report_critical_event")
	_check(
		"Alerta da fazenda" in main_scene.get("save_status").text,
		"Um evento crítico deve gerar alerta sem interromper o calendário."
	)
	main_scene.set("health", 100.0)

	breed_selector.select(5)
	main_scene.call("_buy_animals")
	_check(
		main_scene.get("herd_size") == 15
		and main_scene.get("herd_animals").size() == 15,
		"A compra deve adicionar 5 bovinos individuais."
	)
	_check(
		main_scene.get("herd_animals").filter(
			func(animal: Dictionary) -> bool: return animal["breed"] == "sindi"
		).size() == 5,
		"A compra deve respeitar a raça selecionada no Mercado."
	)
	_check(main_scene.get("cash_balance") == 29865, "A compra deve descontar animais, transporte e documentação.")

	var market_sale_list: ItemList = main_scene.get("market_sale_list")
	for market_item_index in range(10, 15):
		market_sale_list.select(market_item_index, false)
	main_scene.call("_sell_animals")
	_check(
		main_scene.get("herd_size") == 10
		and main_scene.get("herd_animals").size() == 10,
		"A venda deve retirar 5 bovinos individuais."
	)
	_check(main_scene.get("cash_balance") == 43075, "A venda deve registrar o valor líquido dos animais selecionados.")

	main_scene.call("_buy_mineral")
	_check(main_scene.get("cash_balance") == 42895, "A compra de sal mineral deve descontar R$ 180.")
	_check(main_scene.get("mineral_stock_kg") == 25.0, "A compra deve adicionar 25 kg de sal mineral.")

	main_scene.call("_buy_supplement")
	_check(main_scene.get("cash_balance") == 42575, "A compra de suplemento deve descontar R$ 320.")
	_check(main_scene.get("supplement_stock_kg") == 100.0, "A compra deve adicionar 100 kg de suplemento.")

	main_scene.call("_prepare_soil")
	_check(main_scene.get("field_state") == "prepared", "O talhão deve ficar preparado.")
	_check(main_scene.get("cash_balance") == 41775, "O preparo do solo deve descontar R$ 800.")

	main_scene.call("_plant_selected_crop")
	_check(main_scene.get("field_state") == "growing", "O milho deve iniciar o crescimento.")
	_check(main_scene.get("cash_balance") == 40575, "O plantio do milho deve descontar R$ 1.200.")

	main_scene.set("crop_days_elapsed", 89)
	main_scene.call("_advance_crop_day")
	_check(main_scene.get("field_state") == "ready", "A cultura deve ficar pronta ao completar o ciclo.")
	main_scene.call("_harvest_crop")
	var stored_feed: Dictionary = main_scene.get("stored_feed_kg")
	_check(stored_feed["silage"] == 30000.0, "A colheita do milho deve produzir silagem.")

	main_scene.call("_activate_feed_reserve")
	_check(main_scene.get("feeding_plan_days_remaining") == 7, "A reserva deve programar sete dias de alimentação.")
	stored_feed = main_scene.get("stored_feed_kg")
	_check(stored_feed["silage"] == 29650.0, "O fornecimento deve retirar 350 kg do estoque.")

	var weight_before_supplement: float = main_scene.get("average_weight_kg")
	main_scene.call("_advance_day")
	_check(main_scene.get("mineral_stock_kg") < 25.0, "O lote deve consumir sal mineral diariamente.")
	_check(main_scene.get("supplement_stock_kg") < 100.0, "O lote deve consumir suplemento diariamente.")
	_check(main_scene.get("average_weight_kg") > weight_before_supplement, "A nutrição adequada deve aumentar o peso.")
	_check(main_scene.get("feeding_plan_days_remaining") == 6, "O trato programado deve diminuir a cada dia.")

	var save_data: Dictionary = main_scene.call("_build_save_data")
	_check(save_data.get("version") == 18, "O salvamento deve incluir o sistema de vegetação.")
	_check(
		save_data.has("vegetation_state")
		and save_data["vegetation_state"].get("areas", {}).size() == 2,
		"O salvamento deve guardar biomassa, espécie, cobertura e manejo de cada área."
	)
	var vegetation_engine = load("res://scripts/vegetation_manager.gd").new()
	vegetation_engine.configure_area(1, 20.0, 10.0, "buffel")
	vegetation_engine.configure_area(2, 20.0, 10.0, "massai")
	vegetation_engine.set_legacy_condition(1, 45.0, 70.0, 8.0)
	vegetation_engine.set_legacy_condition(2, 45.0, 78.0, 8.0)
	var favorable_environment := {
		"rainfall_mm": 18.0,
		"temperature_c": 32.0,
		"dry_days": 0,
		"soil_moisture": 62.0,
		"soil_fertility": 78.0,
		"soil_compaction": 8.0,
		"soil_erosion": 4.0,
	}
	vegetation_engine.advance_day(1, favorable_environment, {"present": false})
	vegetation_engine.advance_day(2, favorable_environment, {"present": false})
	_check(
		float(vegetation_engine.get_area(2)["biomass_kg_ha"])
		> float(vegetation_engine.get_area(1)["biomass_kg_ha"]),
		"Espécies reais devem possuir respostas produtivas diferentes."
	)
	vegetation_engine.set_legacy_condition(1, 10.0, 30.0, 72.0)
	vegetation_engine.set_management_mode(1, "rest")
	for recovery_day in range(10):
		vegetation_engine.advance_day(1, favorable_environment, {"present": false})
	_check(
		int(vegetation_engine.get_area(1)["degradation_stage"]) >= 3,
		"Uma área severamente degradada não deve se recuperar apenas com poucos dias de descanso."
	)
	_check(
		save_data.get("server_unix_utc_at_save") >= 1785943800
		and save_data.has("last_processed_server_unix_utc")
		and save_data.get("server_timezone") == "America/Bahia",
		"O salvamento deve registrar o horário oficial e o último dia processado em UTC."
	)
	_check(save_data.get("cash_balance") == 40575, "O salvamento deve incluir o saldo financeiro.")
	_check(save_data.get("transaction_history", []).size() == 8, "O histórico financeiro deve ser salvo.")
	_check(save_data.get("mineral_stock_kg") < 25.0, "O salvamento deve incluir o estoque nutricional.")
	_check(save_data.has("river_level"), "O salvamento deve incluir o nível do rio.")
	_check(
		save_data.has("rainfall_mm")
		and save_data.has("max_temperature_c")
		and save_data.has("consecutive_dry_days"),
		"O salvamento deve incluir o clima diário."
	)
	_check(
		save_data.has("parasite_pressure")
		and save_data.has("parasite_treatment_days_remaining")
		and save_data.has("clinical_medication_days_remaining")
		and save_data.has("vitamin_supplement_days_remaining"),
		"O salvamento deve incluir o manejo sanitário."
	)
	_check(
		save_data.has("soil_moisture_1")
		and save_data.has("soil_fertility_2")
		and save_data.has("soil_compaction_1")
		and save_data.has("soil_erosion_2"),
		"O salvamento deve incluir relevo e condições do solo."
	)
	_check(save_data.get("stored_silage_kg") == 29650.0, "O salvamento deve incluir a reserva forrageira.")
	_check(save_data.has("herd_categories"), "O salvamento deve incluir as categorias do rebanho.")
	_check(
		save_data.has("herd_animals") and save_data["herd_animals"].size() == 10,
		"O salvamento deve incluir todos os bovinos individuais."
	)
	_check(save_data.has("herd_genetics"), "O salvamento deve incluir a genética do rebanho.")

	main_scene.set("herd_size", 30)
	var degradation_before: Dictionary = main_scene.get("pasture_degradation").duplicate()
	main_scene.call("_advance_day")
	var degradation_after: Dictionary = main_scene.get("pasture_degradation")
	_check(degradation_after[1] > degradation_before[1], "A superlotação deve degradar o pasto ocupado.")

	main_scene.call("_restore_saved_game", save_data)
	_check(main_scene.get("herd_size") == 10, "O carregamento deve restaurar o tamanho do lote.")
	_check(main_scene.get("cash_balance") == 40575, "O carregamento deve restaurar o saldo financeiro.")
	_check(main_scene.get("transaction_history").size() == 8, "O carregamento deve restaurar o histórico financeiro.")
	_check(main_scene.get("river_level") == save_data.get("river_level"), "O carregamento deve restaurar o nível do rio.")
	_check(
		main_scene.get("rainfall_mm") == save_data.get("rainfall_mm")
		and main_scene.get("max_temperature_c") == save_data.get("max_temperature_c"),
		"O carregamento deve restaurar o clima diário."
	)
	_check(
		main_scene.get("parasite_pressure") == save_data.get("parasite_pressure")
		and main_scene.get("parasite_treatment_days_remaining")
			== save_data.get("parasite_treatment_days_remaining"),
		"O carregamento deve restaurar o manejo sanitário."
	)
	var clinical_animal: Dictionary = main_scene.get("herd_animals")[0]
	clinical_animal["health"] = 60.0
	clinical_animal["parasite_load"] = 55.0
	main_scene.set("health", 70.0)
	main_scene.set("clinical_medication_days_remaining", 0)
	var cash_before_clinical: int = main_scene.get("cash_balance")
	main_scene.call("_apply_clinical_medication")
	_check(
		float(clinical_animal["health"]) == 72.0
		and main_scene.get("clinical_medication_days_remaining") == 7
		and main_scene.get("cash_balance") == cash_before_clinical - 60,
		"O medicamento deve tratar apenas os bovinos em estado clínico e registrar o custo."
	)
	var clinical_cost_separated := false
	for transaction in main_scene.get("transaction_history"):
		if "Serviço veterinário" in str(transaction.get("description", "")):
			clinical_cost_separated = true
			break
	_check(
		clinical_cost_separated,
		"O tratamento clínico deve separar o serviço veterinário dos insumos."
	)
	var clostridiosis_eligible: int = main_scene.call(
		"_eligible_clostridiosis_animals"
	).size()
	var cash_before_clostridiosis: int = main_scene.get("cash_balance")
	main_scene.call("_vaccinate_clostridiosis")
	var all_animals_protected := true
	for vaccinated_animal in main_scene.get("herd_animals"):
		all_animals_protected = (
			all_animals_protected
			and int(vaccinated_animal["clostridiosis_vaccine_days_remaining"]) == 365
		)
	_check(
		clostridiosis_eligible > 0
		and all_animals_protected
		and main_scene.get("cash_balance")
			== cash_before_clostridiosis - clostridiosis_eligible * 20,
		"A vacina contra clostridioses deve proteger individualmente e registrar o custo."
	)
	var cash_before_vitamin: int = main_scene.get("cash_balance")
	main_scene.call("_start_vitamin_supplement")
	_check(
		main_scene.get("vitamin_supplement_days_remaining") == 30
		and main_scene.get("cash_balance")
			== cash_before_vitamin - main_scene.get("herd_size") * 15,
		"O protocolo vitamínico-mineral deve durar 30 dias e registrar o custo."
	)
	main_scene.call("_advance_sanitary_day")
	_check(
		main_scene.get("clinical_medication_days_remaining") == 6
		and main_scene.get("vitamin_supplement_days_remaining") == 29
		and int(main_scene.get("herd_animals")[0]["clostridiosis_vaccine_days_remaining"]) == 364,
		"Medicamentos, vacinas e suplementos devem avançar com o calendário."
	)
	var expanded_sanitary_save: Dictionary = main_scene.call("_build_save_data")
	main_scene.call("_restore_saved_game", expanded_sanitary_save)
	_check(
		main_scene.get("clinical_medication_days_remaining") == 6
		and main_scene.get("vitamin_supplement_days_remaining") == 29,
		"O carregamento deve restaurar os novos protocolos sanitários."
	)
	_check(
		main_scene.get("soil_moisture")[1] == save_data.get("soil_moisture_1")
		and main_scene.get("soil_erosion")[2] == save_data.get("soil_erosion_2"),
		"O carregamento deve restaurar as condições do solo."
	)
	_check(main_scene.get("feeding_plan_days_remaining") == 6, "O carregamento deve restaurar o trato programado.")
	var version_15_save: Dictionary = save_data.duplicate(true)
	version_15_save["version"] = 15
	version_15_save["day_of_year"] = 60
	main_scene.call("_restore_saved_game", version_15_save)
	_check(
		main_scene.get("day_of_year") == 60,
		"Partidas da versão 15 não devem repetir a migração do calendário."
	)
	main_scene.call("_restore_saved_game", save_data)
	var legacy_save: Dictionary = save_data.duplicate(true)
	legacy_save.erase("herd_animals")
	legacy_save.erase("next_animal_id")
	main_scene.call("_restore_saved_game", legacy_save)
	_check(
		main_scene.get("herd_animals").size() == main_scene.get("herd_size"),
		"Partidas antigas devem ser migradas para bovinos individuais."
	)

	main_scene.set("cash_balance", 1000)
	main_scene.call("_update_finance_ui")
	_check(
		not main_scene.get("buy_animals_button").disabled,
		"O Mercado deve manter a compra clicável para explicar impedimentos."
	)
	main_scene.call("_buy_animals")
	_check(main_scene.get("herd_size") == 10, "A compra sem saldo deve ser impedida.")
	_check(main_scene.get("cash_balance") == 1000, "O caixa nunca deve ficar negativo após uma compra.")

	main_scene.call("_restore_saved_game", save_data)
	_check(main_scene.get("pasture_degradation")[1] == save_data.get("pasture_degradation_1"), "O carregamento deve restaurar a degradação do pasto.")
	main_scene.call(
		"_request_sanitary_service",
		"clostridiosis",
		"Vacinação contra clostridioses"
	)
	_check(
		main_scene.get("active_service_order").is_empty()
		and "curral" in main_scene.get("sanitary_last_event").to_lower(),
		"O vaqueiro deve exigir um curral para prender o lote antes da vacinação."
	)
	var service_corral := Rect2(Vector2(1200, 700), Vector2(360, 260))
	main_scene.get("corral_rects").append(service_corral)
	main_scene.get("built_structures").append({
		"type": "Curral simples",
		"cost": 8000,
		"rect": service_corral,
	})
	main_scene.call(
		"_request_sanitary_service",
		"clostridiosis",
		"Vacinação contra clostridioses"
	)
	_check(
		main_scene.get("active_service_order").get("action") == "clostridiosis"
		and main_scene.get("cowboy_visual").visible
		and herd_visual_manager.get("managed_movement_active"),
		"A ordem deve enviar o vaqueiro e o lote ao curral automaticamente."
	)
	var active_service_order: Dictionary = main_scene.get("active_service_order")
	_check(
		int(active_service_order.get("input_cost", 0)) > 0
		and int(active_service_order.get("labor_cost", 0)) > 0
		and int(active_service_order.get("input_cost", 0))
			+ int(active_service_order.get("labor_cost", 0))
			== int(active_service_order.get("total_cost", 0)),
		"A ordem sanitária deve informar insumos, mão de obra e total antes da execução."
	)
	var service_order_save: Dictionary = main_scene.call("_build_save_data")
	main_scene.call("_restore_saved_game", service_order_save)
	_check(
		main_scene.get("active_service_order").get("action") == "clostridiosis"
		and main_scene.get("cowboy_visual").visible,
		"Uma ordem em andamento deve ser restaurada com a partida."
	)
	main_scene.call("_advance_service_order")
	_check(
		main_scene.get("active_service_order").is_empty()
		and not herd_visual_manager.get("managed_movement_active")
		and int(main_scene.get("herd_animals")[0]["clostridiosis_vaccine_days_remaining"]) == 365,
		"O manejo automático deve concluir a vacinação no próximo dia."
	)
	main_scene.call("_restore_saved_game", save_data)

	main_scene.call("_toggle_gate")
	main_scene.call("_transfer_herd")
	_check(main_scene.get("herd_pasture") == 2, "O lote deve atravessar a porteira aberta.")
	main_scene.set("pond_level", {1: 0.0, 2: 0.0})
	main_scene.set("river_level", 50.0)
	main_scene.call("_update_water_system")
	_check(main_scene.get("herd_had_water_today"), "O rio deve atender o lote quando o açude estiver seco e houver acesso.")

	main_scene.call("_start_natural_breeding")
	_check(main_scene.get("pregnant_females") > 0, "A monta natural deve gerar matrizes gestantes.")
	_check(main_scene.get("gestation_days_remaining") == 285, "A gestação deve começar com 285 dias.")
	var herd_before_birth: int = main_scene.get("herd_size")
	main_scene.set("gestation_days_remaining", 1)
	main_scene.call("_advance_reproduction_day")
	_check(main_scene.get("herd_size") > herd_before_birth, "O parto deve acrescentar bezerros ao rebanho.")
	_check(
		main_scene.get("herd_animals").size() == main_scene.get("herd_size"),
		"Cada nascimento deve criar um bovino individual."
	)
	_check(
		main_scene.get("herd_animals").all(
			func(animal: Dictionary) -> bool: return animal.has("breed")
		),
		"Os nascimentos devem preservar o registro da raça."
	)
	_check(not main_scene.get("offspring_genetics").is_empty(), "Os bezerros devem herdar características genéticas.")
	main_scene.set("calf_age_days", 209)
	main_scene.call("_advance_reproduction_day")
	var categories_after_weaning: Dictionary = main_scene.get("herd_categories")
	_check(
		categories_after_weaning["female_calves"] == 0
		and categories_after_weaning["male_calves"] == 0,
		"A desmama deve transferir os bezerros para categorias jovens."
	)
	var heat_adaptation_before: float = main_scene.get("herd_genetics")["heat_adaptation"]
	main_scene.call("_select_offspring_genetics")
	_check(
		main_scene.get("herd_genetics")["heat_adaptation"] != heat_adaptation_before,
		"A seleção deve incorporar a genética dos descendentes ao rebanho."
	)
	var cash_before_insemination: int = main_scene.get("cash_balance")
	main_scene.call("_start_artificial_insemination")
	_check(
		main_scene.get("cash_balance") == cash_before_insemination - 1500,
		"A inseminação deve registrar seu custo no caixa."
	)
	_check(
		main_scene.get("breeding_method") == "Inseminação artificial",
		"A inseminação deve iniciar um novo ciclo reprodutivo."
	)
	var aging_steer: Dictionary = main_scene.call("_create_individual_animal", "steers")
	aging_steer["age_days"] = 730
	_check(
		main_scene.call("_category_for_animal", aging_steer) == "oxen",
		"O garrote deve passar para a categoria Boi conforme a idade."
	)
	_check(
		main_scene.call("_calculate_heat_stress", 40.0, 90.0)
		< main_scene.call("_calculate_heat_stress", 40.0, 30.0),
		"A adaptação genética ao calor deve reduzir o estresse térmico."
	)
	_check(
		main_scene.call("_daily_parasite_increase", 90.0)
		< main_scene.call("_daily_parasite_increase", 30.0),
		"A resistência genética deve reduzir o avanço dos parasitas."
	)
	var breed_keys := [
		"nelore", "nelore_pintado", "guzera", "brahman", "tabapua", "sindi",
		"angus", "hereford", "brangus", "braford", "senepol",
	]
	var breed_samples: Array = []
	for breed_key in breed_keys:
		breed_samples.append(
			main_scene.call("_create_individual_animal", "cows", {}, breed_key)
		)
	herd_visual_manager.call(
		"sync_herd",
		breed_samples.size(),
		main_scene.get("herd_categories"),
		Vector2(1000.0, 800.0),
		PackedVector2Array(),
		Vector2(1000.0, 800.0),
		breed_samples
	)
	var breed_texture_paths: Dictionary = {}
	for breed_visual in herd_visual_manager.call("animals"):
		breed_texture_paths[breed_visual.call("breed_texture_path")] = true
	_check(
		breed_texture_paths.size() == breed_keys.size(),
		"Cada raça deve utilizar um sprite próprio."
	)
	main_scene.call("_update_herd_marker")
	var sanitary_calf: Dictionary = main_scene.call(
		"_create_individual_animal",
		"female_calves"
	)
	sanitary_calf["age_days"] = 120
	main_scene.get("herd_animals").append(sanitary_calf)
	main_scene.call("_sync_herd_size")
	main_scene.set("cash_balance", 100000)
	var eligible_vaccine_count: int = main_scene.call("_eligible_brucellosis_calves").size()
	var cash_before_vaccine: int = main_scene.get("cash_balance")
	main_scene.call("_vaccinate_brucellosis")
	_check(
		sanitary_calf["brucellosis_vaccinated"]
		and main_scene.get("cash_balance")
			== cash_before_vaccine - eligible_vaccine_count * 40,
		"A vacinação deve atender bezerras de três a oito meses e registrar o custo."
	)
	for sanitary_animal in main_scene.get("herd_animals"):
		sanitary_animal["parasite_load"] = 80.0
	main_scene.set("parasite_pressure", 80.0)
	main_scene.set("parasite_treatment_days_remaining", 0)
	var treatment_herd_size: int = main_scene.get("herd_size")
	var cash_before_treatment: int = main_scene.get("cash_balance")
	main_scene.call("_apply_parasite_treatment")
	var herd_was_treated := true
	for treated_animal in main_scene.get("herd_animals"):
		herd_was_treated = (
			herd_was_treated
			and float(treated_animal["parasite_load"]) <= 8.0
		)
	_check(
		herd_was_treated
		and main_scene.get("parasite_treatment_days_remaining") == 30
		and main_scene.get("cash_balance") == (
			cash_before_treatment
			- treatment_herd_size * 25
		),
		"O controle parasitário deve tratar o lote, proteger por 30 dias e registrar o custo."
	)
	main_scene.call("_add_individual_animals", "steers", 35)
	main_scene.call("_update_herd_marker")
	var unlimited_herd: Array = main_scene.get("herd_animals")
	_check(
		unlimited_herd.size() > 30
		and herd_visual_manager.call("visual_count") == unlimited_herd.size(),
		"O rebanho não deve possuir limite artificial e cada bovino deve continuar visível."
	)
	_check(
		herd_visual_manager.call("update_batch_size") < unlimited_herd.size(),
		"O movimento dos bovinos deve ser atualizado em lotes para preservar desempenho."
	)
	var created_visual_count: int = herd_visual_manager.get_child_count()
	var small_herd: Array = unlimited_herd.slice(0, 5)
	herd_visual_manager.call(
		"sync_herd",
		small_herd.size(),
		main_scene.get("herd_categories"),
		Vector2(1000.0, 800.0),
		PackedVector2Array(),
		Vector2(1000.0, 800.0),
		small_herd
	)
	_check(
		herd_visual_manager.call("pooled_visual_count") == unlimited_herd.size() - small_herd.size()
		and herd_visual_manager.get_child_count() == created_visual_count,
		"Os bovinos temporariamente removidos do mapa devem ser reutilizados."
	)
	herd_visual_manager.call(
		"sync_herd",
		unlimited_herd.size(),
		main_scene.get("herd_categories"),
		Vector2(1000.0, 800.0),
		PackedVector2Array(),
		Vector2(1000.0, 800.0),
		unlimited_herd
	)
	_check(
		herd_visual_manager.call("pooled_visual_count") == 0
		and herd_visual_manager.get_child_count() == created_visual_count,
		"Os bovinos do pool devem voltar ao mapa sem criar novos nós."
	)

	main_scene.queue_free()
	await process_frame

	var free_build_scene: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(free_build_scene)
	await process_frame
	var module_names := [
		"dashboard", "farm", "structures", "store",
		"herd", "production", "market", "finance",
	]
	var module_buttons: Array[Button] = [
		free_build_scene.get("dashboard_module_button"),
		free_build_scene.get("farm_module_button"),
		free_build_scene.get("structure_module_button"),
		free_build_scene.get("store_module_button"),
		free_build_scene.get("herd_module_button"),
		free_build_scene.get("production_module_button"),
		free_build_scene.get("market_module_button"),
		free_build_scene.get("finance_module_button"),
	]
	var icons_loaded := 0
	for module_button in module_buttons:
		if module_button.icon != null:
			icons_loaded += 1
	_check(icons_loaded == module_buttons.size(), "Todos os módulos devem possuir ícones.")
	for module_index in module_names.size():
		free_build_scene.call("_show_module", module_names[module_index])
		var selected_count := 0
		for module_button in module_buttons:
			if module_button.button_pressed:
				selected_count += 1
		_check(
			free_build_scene.get("current_module") == module_names[module_index]
			and selected_count == 1
			and module_buttons[module_index].button_pressed,
			"O menu deve selecionar somente o módulo %s." % module_names[module_index]
		)
	_check(
		not free_build_scene.has_node(
			"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/OpenStoreButton"
		),
		"O módulo Estruturas não deve duplicar o acesso à Loja Rural."
	)
	_check(
		not free_build_scene.has_node(
			"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/GateToggleButton"
		),
		"O módulo Estruturas não deve controlar porteiras por botão."
	)
	free_build_scene.call("_show_module", "structures")
	_check(
		free_build_scene.get("structures_empty_card").visible
		and not free_build_scene.get("structures_stats").visible,
		"O módulo Estruturas vazio deve permanecer limpo."
	)
	_check(
		not free_build_scene.has_node(
			"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/AddHerdButton"
		),
		"O módulo Rebanho não deve oferecer inclusão gratuita de animais."
	)
	free_build_scene.call("_show_module", "production")
	await process_frame
	var production_scroll: ScrollContainer = free_build_scene.get_node(
		"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll"
	)
	var production_content: VBoxContainer = free_build_scene.get_node(
		"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent"
	)
	_check(
		production_content.size.x <= production_scroll.size.x + 1.0,
		"O módulo Produção deve permanecer dentro do painel contextual."
	)
	free_build_scene.call("_show_module", "dashboard")
	_check(
		free_build_scene.get_node(
			"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/DashboardPanel"
		).visible,
		"O módulo Dashboard deve exibir a indicação Em breve."
	)
	free_build_scene.call("_show_module", "store")
	_check(
		free_build_scene.get_node(
			"Interface/MainLayout/Body/Sidebar/SidebarMargin/SidebarScroll/SidebarContent/StoreStatusCard/StoreStatus"
		).visible,
		"A Loja Rural deve possuir um painel próprio."
	)
	_check(
		not free_build_scene.get("module_actions").visible
		and free_build_scene.get("sidebar_margin").offset_bottom == 0.0,
		"A Loja Rural deve esconder o rodapé enquanto nenhuma construção estiver ativa."
	)
	free_build_scene.call("_start_free_fence", 1)
	_check(
		free_build_scene.get("module_actions").visible
		and not free_build_scene.get("cancel_free_construction_button").disabled
		and free_build_scene.get("barbed_fence_button").button_pressed,
		"As ações de construção devem permanecer acessíveis durante a obra."
	)
	free_build_scene.call("_show_module", "herd")
	_check(
		free_build_scene.get("build_mode") == 0
		and not free_build_scene.get("module_actions").visible
		and free_build_scene.get("sidebar_margin").offset_bottom == 0.0,
		"Trocar de módulo deve cancelar a obra e liberar o painel contextual."
	)
	free_build_scene.call("_show_module", "store")
	var almost_closed := PackedVector2Array([
		Vector2(100, 100),
		Vector2(800, 100),
		Vector2(800, 700),
		Vector2(250, 180),
	])
	var normalized_fence: PackedVector2Array = free_build_scene.call(
		"_normalize_fence_closure",
		almost_closed
	)
	_check(
		free_build_scene.call("_is_closed_fence", normalized_fence),
		"Uma cerca visualmente fechada deve ser reconhecida como pasto."
	)

	var cash_before_free_fence: int = free_build_scene.get("cash_balance")
	free_build_scene.call("_start_free_fence", 1)
	for fence_point in [
		Vector2(400, 300),
		Vector2(1200, 300),
		Vector2(1200, 800),
		Vector2(400, 800),
		Vector2(400, 300),
	]:
		free_build_scene.call("_handle_free_build_click", fence_point)
	_check(
		free_build_scene.get("free_paddock_count") == 0
		and free_build_scene.get("cash_balance") == cash_before_free_fence,
		"Desenhar uma cerca não deve cobrar antes da confirmação."
	)
	_check(
		roundi(free_build_scene.call("_current_fence_length_meters")) == 1744
		and "m de cerca" in free_build_scene.get("store_status").text,
		"A Loja Rural deve calcular o comprimento da cerca em metros reais."
	)
	free_build_scene.call("_confirm_construction")
	_check(
		free_build_scene.get("construction_job_active")
		and free_build_scene.get("construction_crew_visual").visible,
		"A equipe rural deve executar a cerca manual após a confirmação."
	)
	free_build_scene.call("_complete_active_construction_immediately")
	_check(
		free_build_scene.get("free_paddock_count") == 1,
		"Uma cerca fechada livre deve formar um pasto."
	)
	var first_structure: Dictionary = free_build_scene.get("built_structures")[0]
	_check(
		int(first_structure.get("material_cost", 0)) > 0
		and int(first_structure.get("labor_cost", 0)) > 0
		and int(first_structure.get("material_cost", 0))
			+ int(first_structure.get("labor_cost", 0))
			== int(first_structure.get("cost", 0)),
		"A obra deve separar materiais e mão de obra sem alterar seu custo total."
	)
	_check(
		free_build_scene.get("pasture_1").color.a <= 0.22
		and not free_build_scene.get("pasture_1_label").visible,
		"O pasto deve manter o mapa visível e não exibir informações sobrepostas."
	)
	var barbed_visual: Node2D
	for structure_visual in free_build_scene.get("player_structures").get_children():
		if structure_visual.get_meta("structure_visual", "") == "fence":
			barbed_visual = structure_visual
			break
	var fence_post_count := 0
	for fence_child in barbed_visual.get_children():
		if fence_child is Polygon2D:
			fence_post_count += 1
	_check(
		barbed_visual != null and fence_post_count > 4,
		"As cercas devem possuir estacas e mourões visíveis."
	)
	var visual_test_points := PackedVector2Array([
		Vector2(1500, 300),
		Vector2(2100, 300),
	])
	var smooth_visual: Node2D = free_build_scene.call(
		"_create_fence_visual",
		visual_test_points,
		2
	)
	var electric_visual: Node2D = free_build_scene.call(
		"_create_fence_visual",
		visual_test_points,
		3
	)
	var barbed_wire: Line2D = barbed_visual.get_node("Wire")
	var smooth_wire: Line2D = smooth_visual.get_node("Wire")
	var electric_wire: Line2D = electric_visual.get_node("Wire")
	_check(
		not barbed_wire.default_color.is_equal_approx(smooth_wire.default_color)
		and not smooth_wire.default_color.is_equal_approx(electric_wire.default_color)
		and barbed_wire.width != smooth_wire.width
		and smooth_wire.width != electric_wire.width,
		"Cada tipo de cerca deve possuir identidade visual própria."
	)
	smooth_visual.queue_free()
	electric_visual.queue_free()
	_check(
		free_build_scene.get("cash_balance") < cash_before_free_fence,
		"A cerca livre deve cobrar conforme o comprimento."
	)
	_check(
		not free_build_scene.get("buy_animals_button").disabled,
		"O botão de compra deve permitir consultar o que falta para comprar animais."
	)
	free_build_scene.call("_buy_animals")
	_check(
		free_build_scene.get("herd_size") == 0
		and "porteira" in free_build_scene.get("market_info").text.to_lower(),
		"O mercado deve informar que falta uma porteira."
	)

	free_build_scene.call("_start_single_structure", 4)
	var cash_before_gate: int = free_build_scene.get("cash_balance")
	free_build_scene.call("_handle_free_build_click", Vector2(800, 300))
	_check(
		not free_build_scene.get("gate_installed")
		and free_build_scene.get("cash_balance") == cash_before_gate,
		"Posicionar a porteira não deve cobrar antes da confirmação."
	)
	free_build_scene.call("_confirm_construction")
	free_build_scene.call("_complete_active_construction_immediately")
	_check(free_build_scene.get("gate_installed"), "A Loja Rural deve instalar porteira sobre a cerca.")
	var first_gate_visual: Line2D = free_build_scene.get("free_gate_nodes")[0]
	var first_gate_hinge_position := first_gate_visual.position
	_check(
		first_gate_visual.points[0].is_equal_approx(Vector2.ZERO)
		and first_gate_visual.points[1].x > 0.0,
		"A porteira deve usar o mourão lateral como eixo."
	)
	_check(not free_build_scene.get("gate_open"), "A nova porteira deve iniciar fechada.")
	_check(
		not free_build_scene.get("buy_animals_button").disabled,
		"A compra deve ficar disponível depois da instalação da porteira."
	)
	_check(
		free_build_scene.call("_toggle_gate_at", Vector2(800, 300))
		and free_build_scene.get("free_gate_open_states")[0]
		and first_gate_visual.position.is_equal_approx(first_gate_hinge_position),
		"O duplo clique no mapa deve abrir a porteira escolhida."
	)
	free_build_scene.call("_start_single_structure", 4)
	free_build_scene.call("_handle_free_build_click", Vector2(400, 800))
	free_build_scene.call("_confirm_construction")
	free_build_scene.call("_complete_active_construction_immediately")
	_check(
		free_build_scene.get("free_gate_open_states") == [true, false],
		"Uma nova porteira deve manter estado independente."
	)
	free_build_scene.call("_toggle_gate_at", Vector2(400, 800))
	free_build_scene.call("_toggle_gate_at", Vector2(800, 300))
	_check(
		free_build_scene.get("free_gate_open_states") == [false, true],
		"Abrir uma porteira não deve alterar as demais."
	)

	free_build_scene.call("_start_single_structure", 5)
	free_build_scene.call("_handle_free_build_click", Vector2(1900, 900))
	free_build_scene.call("_confirm_construction")
	free_build_scene.call("_complete_active_construction_immediately")
	_check(
		free_build_scene.get("corral_rects").size() == 1,
		"O curral deve ser posicionado livremente na propriedade."
	)
	free_build_scene.call("_start_single_structure", 6)
	free_build_scene.call("_handle_free_build_click", Vector2(1900, 900))
	free_build_scene.call("_confirm_construction")
	free_build_scene.call("_complete_active_construction_immediately")
	_check(
		free_build_scene.get("built_structures").size() == 5,
		"A balança deve ser instalada dentro do curral."
	)
	free_build_scene.call("_show_module", "structures")
	_check(
		free_build_scene.get("structures_stats").visible
		and "2 instaladas" in free_build_scene.get("structures_gates_stat").text,
		"O módulo Estruturas deve resumir as instalações sem ações redundantes."
	)

	var cash_before_cancel: int = free_build_scene.get("cash_balance")
	var structures_before_cancel: int = free_build_scene.get("built_structures").size()
	free_build_scene.call("_start_free_fence", 2)
	free_build_scene.call("_handle_free_build_click", Vector2(1500, 300))
	free_build_scene.call("_handle_free_build_click", Vector2(1700, 300))
	free_build_scene.call("_confirm_construction")
	_check(
		free_build_scene.get("construction_job_active"),
		"A obra confirmada deve permanecer em execução até a equipe concluir."
	)
	var pending_job_save: Dictionary = free_build_scene.call("_build_save_data")
	_check(
		pending_job_save.get("construction_job", {}).get("data", {}).get("kind") == "fence"
		and pending_job_save.get("construction_job", {}).get("remaining_seconds", 0.0) > 0.0,
		"Uma obra em andamento deve guardar sua tarefa e o tempo restante."
	)
	free_build_scene.call("_reset_construction_visuals")
	free_build_scene.call("_restore_saved_game", pending_job_save)
	_check(
		free_build_scene.get("construction_job_active")
		and free_build_scene.get("construction_job_name") == "cerca de arame liso",
		"O carregamento deve retomar uma obra que ainda não terminou."
	)
	free_build_scene.call("_cancel_free_construction")
	_check(
		free_build_scene.get("cash_balance") == cash_before_cancel
		and free_build_scene.get("built_structures").size() == structures_before_cancel,
		"Cancelar uma obra em execução não deve gerar cobrança."
	)

	var free_save: Dictionary = free_build_scene.call("_build_save_data")
	free_build_scene.call("_reset_construction_visuals")
	free_build_scene.call("_restore_saved_game", free_save)
	_check(
		free_build_scene.get("built_structures").size() == 5,
		"O carregamento deve restaurar as estruturas livres."
	)
	_check(
		free_build_scene.get("free_gate_open_states") == [false, true],
		"O carregamento deve restaurar cada porteira aberta ou fechada."
	)
	_check(
		free_build_scene.get("free_paddock_count") == 1,
		"O carregamento deve restaurar os pastos desenhados."
	)
	var restored_structure: Dictionary = free_build_scene.get("built_structures")[0]
	_check(
		int(restored_structure.get("material_cost", 0))
			+ int(restored_structure.get("labor_cost", 0))
			== int(restored_structure.get("cost", 0)),
		"O carregamento deve restaurar a composição do custo das estruturas."
	)
	free_build_scene.call("_start_free_fence", 2)
	free_build_scene.call("_handle_free_build_click", Vector2(1500, 300))
	free_build_scene.call("_handle_free_build_click", Vector2(1800, 300))
	var enter_event := InputEventKey.new()
	enter_event.pressed = true
	enter_event.keycode = KEY_ENTER
	free_build_scene.call("_unhandled_input", enter_event)
	free_build_scene.call("_complete_active_construction_immediately")
	_check(
		free_build_scene.get("build_mode") == 0
		and free_build_scene.get("built_structures").size() == 6,
		"A tecla Enter deve concluir a cerca sem exigir novos pontos."
	)
	free_build_scene.queue_free()
	await process_frame

	var full_perimeter_scene: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(full_perimeter_scene)
	await process_frame
	var full_perimeter_cost: int = full_perimeter_scene.call("_full_farm_perimeter_cost")
	var cash_before_full_perimeter: int = full_perimeter_scene.get("cash_balance")
	full_perimeter_scene.call("_build_full_farm_perimeter")
	var full_perimeter_structures: Array = full_perimeter_scene.get("built_structures")
	var animated_worker: AnimatedSprite2D = full_perimeter_scene.get(
		"construction_crew_visual"
	).get_node("Worker1")
	var cowboy_sprite: AnimatedSprite2D = full_perimeter_scene.get("cowboy_sprite")
	_check(
		full_perimeter_scene.get("full_farm_perimeter_built")
		and full_perimeter_scene.get("perimeter_built")
		and full_perimeter_structures.size() == 1
		and bool(full_perimeter_structures[0].get("full_perimeter", false))
		and full_perimeter_scene.get("construction_crew_visual").visible
		and is_instance_valid(full_perimeter_scene.get("full_perimeter_preview_visual"))
		and animated_worker.is_playing()
		and animated_worker.animation == "walk"
		and animated_worker.sprite_frames.get_frame_count("walk") == 4
		and animated_worker.sprite_frames.get_frame_count("work") == 4,
		"A Loja Rural deve cercar automaticamente todo o limite da fazenda."
	)
	_check(
		cowboy_sprite.sprite_frames.get_frame_count("walk") == 4
		and cowboy_sprite.sprite_frames.get_frame_count("work") == 4
		and cowboy_sprite.get_node("CharacterShadow") is Polygon2D,
		"O vaqueiro deve utilizar sprite animado com sombra e identidade visual própria."
	)
	_check(
		full_perimeter_scene.get("construction_worker_1").get("action_row") == 1
		and full_perimeter_scene.get("construction_worker_2").get("action_row") == 2
		and full_perimeter_scene.get("construction_worker_3").get("action_row") == 3,
		"Os três trabalhadores devem possuir aparências e funções visuais distintas."
	)
	_check(
		is_equal_approx(animated_worker.scale.x, 0.09)
		and is_equal_approx(animated_worker.scale.y, 0.09),
		"A equipe rural deve usar a escala ampliada de leitura."
	)
	_check(
		full_perimeter_scene.get("free_paddock_count") == 0
		and full_perimeter_scene.get("cash_balance")
			== cash_before_full_perimeter - full_perimeter_cost,
		"A cerca externa deve cobrar pelo comprimento sem criar um pasto interno."
	)
	var full_perimeter_save: Dictionary = full_perimeter_scene.call("_build_save_data")
	full_perimeter_scene.call("_restore_saved_game", full_perimeter_save)
	_check(
		full_perimeter_scene.get("full_farm_perimeter_built")
		and full_perimeter_scene.get("free_paddock_count") == 0
		and full_perimeter_scene.get("full_perimeter_fence_button").disabled,
		"O carregamento deve restaurar o perímetro completo sem duplicar a compra."
	)
	full_perimeter_scene.call("_place_free_gate", Vector2(1613, 124))
	full_perimeter_scene.call("_show_module", "market")
	_check(
		full_perimeter_scene.get("gate_installed")
		and "área geral" in full_perimeter_scene.get("market_info").text.to_lower(),
		"O Mercado deve reconhecer a propriedade cercada como área geral disponível."
	)
	full_perimeter_scene.call("_buy_animals")
	_check(
		full_perimeter_scene.get("herd_size") == 5
		and full_perimeter_scene.get("free_paddock_count") == 0
		and full_perimeter_scene.call("_current_herd_area_name") == "Área geral"
		and full_perimeter_scene.get("transfer_herd_button").disabled
		and "2 pastos" in full_perimeter_scene.get("transfer_herd_button").text,
		"A cerca externa e uma porteira devem permitir comprar o primeiro rebanho."
	)
	full_perimeter_scene.queue_free()

	if failures == 0:
		print("SMOKE TEST: ciclo principal validado.")
	else:
		push_error("SMOKE TEST: %d falha(s)." % failures)

	quit(failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK: %s" % message)
		return

	failures += 1
	push_error("FALHA: %s" % message)
