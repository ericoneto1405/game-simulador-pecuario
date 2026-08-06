class_name ServiceOrderUiManager

var service_order_status: Label


func _init(p_service_order_status: Label) -> void:
	service_order_status = p_service_order_status


func update(state: Dictionary) -> void:
	if not is_instance_valid(service_order_status):
		return

	var active_service_order: Dictionary = state.get("active_service_order", {})
	var last_cowboy_activity: String = state.get("last_cowboy_activity", "")

	if not active_service_order.is_empty():
		service_order_status.text = (
			"%s\n%s • conclusão no próximo dia\n"
			+ "Insumos R$ %s + equipe R$ %s • total R$ %s"
		) % [
			str(active_service_order.get("phase", "Executando manejo")),
			str(active_service_order.get("executor", "Equipe rural")),
			EconomyService.format_money(int(active_service_order.get("input_cost", 0))),
			EconomyService.format_money(int(active_service_order.get("labor_cost", 0))),
			EconomyService.format_money(int(active_service_order.get("total_cost", 0))),
		]
		return
	if not last_cowboy_activity.is_empty():
		service_order_status.text = last_cowboy_activity
		return
	service_order_status.text = (
		"Nenhum manejo em andamento.\n"
		+ "O vaqueiro abastece cochos e suplementos automaticamente."
	)
