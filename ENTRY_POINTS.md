# Mapa de Pontos de Entrada — farm_setup_controller.gd

Referência para a Fase 0 do refactoring. Cada ponto de entrada é um local que o Godot
chama automaticamente ou que connecta signals a funções internas.

---

## 1. Callbacks de Ciclo de Vida do Godot

| Callback | Linha | Responsabilidade |
|---|---|---|
| `_ready()` | 455 | Conecta todos os signals, inicializa UI, solicita hora do servidor |
| `_process(delta)` | 575 | Atualiza relógio, processa dias offline, auto-save |
| `_input(event)` | 3055 | Tooltip de terreno (mouse motion no módulo Farm) |
| `_unhandled_input(event)` | 3166 | Construção (cliques/teclas), gate toggle, seleção de pasto, divisão legada |
| `_notification(what)` | 841 | Auto-save no fechamento/pausa da janela |

---

## 2. Signal Connections (em `_ready()`, linhas 456-560)

### 2.1 Construção / Loja Rural
| Signal | Handler | Linha |
|---|---|---|
| `perimeter_button.pressed` | `_build_perimeter` | 456 |
| `horizontal_button.pressed` | `_start_horizontal_division` | 457 |
| `vertical_button.pressed` | `_start_vertical_division` | 458 |
| `cancel_button.pressed` | `_cancel_division` | 459 |
| `gate_install_button.pressed` | `_start_gate_placement` | 460 |
| `barbed_fence_button.pressed` | `_start_free_fence.bind(BARBED_FENCE)` | 551 |
| `smooth_fence_button.pressed` | `_start_free_fence.bind(SMOOTH_FENCE)` | 553 |
| `electric_fence_button.pressed` | `_start_free_fence.bind(ELECTRIC_FENCE)` | 554 |
| `full_perimeter_fence_button.pressed` | `_build_full_farm_perimeter` | 552 |
| `store_gate_button.pressed` | `_start_single_structure.bind(GATE)` | 555 |
| `corral_button.pressed` | `_start_single_structure.bind(CORRAL)` | 556 |
| `scale_button.pressed` | `_start_single_structure.bind(SCALE)` | 557 |
| `finish_construction_button.pressed` | `_confirm_construction` | 558 |
| `cancel_free_construction_button.pressed` | `_cancel_free_construction` | 559 |

### 2.2 Rebanho
| Signal | Handler | Linha |
|---|---|---|
| `select_herd_button.pressed` | `_select_herd_lot` | 461 |
| `transfer_herd_button.pressed` | `_transfer_herd` | 462 |
| `herd_visuals.selection_changed` | `_on_herd_visual_selection_changed` | 560 |

### 2.3 Reprodução
| Signal | Handler | Linha |
|---|---|---|
| `natural_breeding_button.pressed` | `_start_natural_breeding` | 463 |
| `insemination_button.pressed` | `_start_artificial_insemination` | 464 |
| `select_genetics_button.pressed` | `_select_offspring_genetics` | 465 |

### 2.4 Sanidade
| Signal | Handler | Linha |
|---|---|---|
| `parasite_treatment_button.pressed` | `_request_sanitary_service.bind("parasite", ...)` | 466-468 |
| `clinical_medication_button.pressed` | `_request_sanitary_service.bind("clinical", ...)` | 469-471 |
| `brucellosis_vaccine_button.pressed` | `_request_sanitary_service.bind("brucellosis", ...)` | 472-474 |
| `clostridiosis_vaccine_button.pressed` | `_request_sanitary_service.bind("clostridiosis", ...)` | 475-477 |
| `vitamin_supplement_button.pressed` | `_request_sanitary_service.bind("vitamin", ...)` | 478-480 |

### 2.5 Mercado
| Signal | Handler | Linha |
|---|---|---|
| `market_mode_selector.item_selected` | `_on_market_mode_selected` | 485 |
| `market_category_selector.item_selected` | `_on_market_offer_changed` | 501 |
| `market_sale_filter.item_selected` | `_on_market_sale_filter_changed` | 502 |
| `breed_selector.item_selected` | `_on_market_offer_changed` | 509 |
| `market_quantity_selector.value_changed` | `_on_market_quantity_changed` | 510 |
| `buy_animals_button.pressed` | `_buy_animals` | 511 |
| `market_sale_list.multi_selected` | `_on_market_sale_selection_changed` | 512 |
| `market_select_all_button.pressed` | `_select_all_market_animals` | 513 |
| `market_clear_selection_button.pressed` | `_clear_market_sale_selection` | 514 |
| `sell_animals_button.pressed` | `_sell_animals` | 515 |

### 2.6 Nutrição / Produção
| Signal | Handler | Linha |
|---|---|---|
| `buy_mineral_button.pressed` | `_buy_mineral` | 516 |
| `buy_supplement_button.pressed` | `_buy_supplement` | 517 |
| `vegetation_rest_button.pressed` | `_toggle_selected_pasture_rest` | 518 |
| `vegetation_form_button.pressed` | `_schedule_selected_pasture_formation` | 519 |
| `vegetation_fertilize_button.pressed` | `_schedule_selected_pasture_intervention.bind("fertilize")` | 520-522 |
| `vegetation_recover_button.pressed` | `_schedule_selected_pasture_intervention.bind("recover")` | 523-525 |

### 2.7 Agricultura
| Signal | Handler | Linha |
|---|---|---|
| `select_crop_button.pressed` | `_select_next_crop` | 526 |
| `prepare_soil_button.pressed` | `_prepare_soil` | 527 |
| `plant_crop_button.pressed` | `_plant_selected_crop` | 528 |
| `harvest_crop_button.pressed` | `_harvest_crop` | 529 |
| `use_feed_reserve_button.pressed` | `_activate_feed_reserve` | 530 |

### 2.8 Persistência
| Signal | Handler | Linha |
|---|---|---|
| `save_button.pressed` | `_save_game` | 531 |
| `load_button.pressed` | `_load_game` | 532 |
| `server_time_request.request_completed` | `_on_server_time_received` | 533 |

### 2.9 Navegação (Módulos)
| Signal | Handler | Linha |
|---|---|---|
| `dashboard_module_button.pressed` | `_show_module.bind("dashboard")` | 534 |
| `farm_module_button.pressed` | `_show_module.bind("farm")` | 535 |
| `structure_module_button.pressed` | `_show_module.bind("structures")` | 536 |
| `store_module_button.pressed` | `_show_module.bind("store")` | 537 |
| `herd_module_button.pressed` | `_show_module.bind("herd")` | 538 |
| `production_module_button.pressed` | `_show_module.bind("production")` | 539 |
| `market_module_button.pressed` | `_show_module.bind("market")` | 540 |
| `finance_module_button.pressed` | `_show_module.bind("finance")` | 541 |

### 2.10 Farm (Camadas / Seleção)
| Signal | Handler | Linha |
|---|---|---|
| `farm_pasture_selector.item_selected` | `_on_farm_pasture_selected` | 544 |
| `farm_pasture_layer_button.toggled` | `_on_farm_layer_toggled` | 545 |
| `farm_water_layer_button.toggled` | `_on_farm_layer_toggled` | 546 |
| `farm_terrain_info_button.toggled` | `_on_terrain_info_toggled` | 547 |
| `farm_structures_layer_button.toggled` | `_on_farm_layer_toggled` | 548 |

---

## 3. Chamadas Iniciais em `_ready()` (linhas 549-572)

```
_initialize_vegetation_ui()
_initialize_vegetation_areas()
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
```

---

## 4. Ordem de Execução do `_advance_day()` (linha 4468)

Chamado durante processamento de dias offline. Ordem exata:

1. Calendar advancement
2. `_update_daily_weather()`
3. `_advance_service_order()`
4. `_advance_soil_day()`
5. `_advance_crop_day()`
5. `_advance_reproduction_day()`
7. `_consume_daily_supplements()`
8. `_update_water_system()`
9. `vegetation_manager.advance_day()` (×2 pastures)
10. `_sync_legacy_from_vegetation()`
11. Forage/weight/condition calculations
12. `_apply_daily_heat_stress()`
13. `_update_animal_needs()`
14. Grazing pressure alerts
15. `_advance_sanitary_day()`
16. `_update_individual_animals_day()`
17. UI refresh (se não silencioso)
