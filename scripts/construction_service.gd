class_name ConstructionService

const FARM_WIDTH := 3200.0
const FARM_HEIGHT := 1800.0
const METERS_PER_MAP_UNIT := 0.670797097
const BARBED_FENCE_COST_PER_100 := 120
const SMOOTH_FENCE_COST_PER_100 := 180
const ELECTRIC_FENCE_COST_PER_100 := 250
const FREE_GATE_COST := 500
const CORRAL_COST := 8000
const SCALE_COST := 4500
const CORRAL_SIZE := Vector2(90.0, 60.0)
const FENCE_CLOSURE_TOLERANCE := 350.0
const FENCE_POST_SPACING_METERS := 25.0
const MAX_FENCE_POST_VISUALS := 240
const FREE_GATE_VISUAL_LENGTH := 24.0
const FENCE_LABOR_RATE := 0.30
const GATE_LABOR_RATE := 0.35
const CORRAL_LABOR_RATE := 0.40
const SCALE_LABOR_RATE := 0.20
const VETERINARY_LABOR_RATE := 0.30
const COWBOY_SERVICE_RATE := 0.20

const BUILD_MODE_NONE := 0
const BUILD_MODE_BARBED_FENCE := 1
const BUILD_MODE_SMOOTH_FENCE := 2
const BUILD_MODE_ELECTRIC_FENCE := 3
const BUILD_MODE_GATE := 4
const BUILD_MODE_CORRAL := 5
const BUILD_MODE_SCALE := 6


static func fence_length_meters(points: PackedVector2Array) -> float:
	var length_units := 0.0
	for point_index in range(1, points.size()):
		length_units += points[point_index - 1].distance_to(points[point_index])
	return length_units * METERS_PER_MAP_UNIT


static func fence_cost(length_meters: float, build_mode: int) -> int:
	var rate := fence_rate(build_mode)
	return maxi(ceili(length_meters / 100.0 * rate), 1)


static func fence_rate(build_mode: int) -> int:
	match build_mode:
		BUILD_MODE_SMOOTH_FENCE:
			return SMOOTH_FENCE_COST_PER_100
		BUILD_MODE_ELECTRIC_FENCE:
			return ELECTRIC_FENCE_COST_PER_100
	return BARBED_FENCE_COST_PER_100


static func single_structure_cost(build_mode: int) -> int:
	match build_mode:
		BUILD_MODE_GATE:
			return FREE_GATE_COST
		BUILD_MODE_CORRAL:
			return CORRAL_COST
		BUILD_MODE_SCALE:
			return SCALE_COST
	return 0


static func construction_labor_rate(build_mode: int) -> float:
	match build_mode:
		BUILD_MODE_GATE:
			return GATE_LABOR_RATE
		BUILD_MODE_CORRAL:
			return CORRAL_LABOR_RATE
		BUILD_MODE_SCALE:
			return SCALE_LABOR_RATE
	return FENCE_LABOR_RATE


static func construction_labor_rate_for_type(type_name: String) -> float:
	match type_name:
		"Porteira":
			return GATE_LABOR_RATE
		"Curral simples":
			return CORRAL_LABOR_RATE
		"Balança pecuária":
			return SCALE_LABOR_RATE
	return FENCE_LABOR_RATE


static func cost_breakdown(total_cost: int, labor_rate: float) -> Dictionary:
	var labor_cost := clampi(roundi(total_cost * labor_rate), 0, total_cost)
	return {
		"material": total_cost - labor_cost,
		"labor": labor_cost,
		"total": total_cost,
	}


static func format_cost_breakdown(total_cost: int, labor_rate: float, format_money_fn: Callable) -> String:
	var breakdown := cost_breakdown(total_cost, labor_rate)
	return "Material R$ %s  •  Mão de obra R$ %s  •  Total R$ %s" % [
		format_money_fn.call(int(breakdown["material"])),
		format_money_fn.call(int(breakdown["labor"])),
		format_money_fn.call(int(breakdown["total"])),
	]


static func is_fence_build_mode(build_mode: int) -> bool:
	return build_mode in [BUILD_MODE_BARBED_FENCE, BUILD_MODE_SMOOTH_FENCE, BUILD_MODE_ELECTRIC_FENCE]


static func is_single_structure_mode(build_mode: int) -> bool:
	return build_mode in [BUILD_MODE_GATE, BUILD_MODE_CORRAL, BUILD_MODE_SCALE]


static func is_closed_fence(points: PackedVector2Array) -> bool:
	return points.size() >= 4 and points[0].distance_to(points[-1]) <= 1.0


static func normalize_fence_closure(points: PackedVector2Array) -> PackedVector2Array:
	var normalized := points.duplicate()
	if (
		normalized.size() >= 3
		and not is_closed_fence(normalized)
		and normalized[0].distance_to(normalized[-1]) <= FENCE_CLOSURE_TOLERANCE
	):
		normalized.append(normalized[0])
	return normalized


static func fence_color(build_mode: int) -> Color:
	match build_mode:
		BUILD_MODE_SMOOTH_FENCE:
			return Color(0.76, 0.78, 0.73, 1)
		BUILD_MODE_ELECTRIC_FENCE:
			return Color(0.98, 0.76, 0.12, 1)
	return Color(0.34, 0.2, 0.09, 1)


static func fence_wire_width(build_mode: int) -> float:
	match build_mode:
		BUILD_MODE_SMOOTH_FENCE:
			return 2.8
		BUILD_MODE_ELECTRIC_FENCE:
			return 1.4
	return 2.2


static func fence_post_radius(build_mode: int) -> float:
	match build_mode:
		BUILD_MODE_ELECTRIC_FENCE:
			return 2.0
		BUILD_MODE_SMOOTH_FENCE:
			return 2.7
	return 2.3


static func fence_post_color(build_mode: int) -> Color:
	match build_mode:
		BUILD_MODE_SMOOTH_FENCE:
			return Color(0.62, 0.49, 0.3, 1)
		BUILD_MODE_ELECTRIC_FENCE:
			return Color(0.92, 0.9, 0.72, 1)
	return Color(0.43, 0.26, 0.11, 1)


static func build_mode_name(build_mode: int) -> String:
	match build_mode:
		BUILD_MODE_BARBED_FENCE:
			return "Cerca de arame farpado"
		BUILD_MODE_SMOOTH_FENCE:
			return "Cerca de arame liso"
		BUILD_MODE_ELECTRIC_FENCE:
			return "Cerca elétrica"
		BUILD_MODE_GATE:
			return "Porteira"
		BUILD_MODE_CORRAL:
			return "Curral simples"
		BUILD_MODE_SCALE:
			return "Balança pecuária"
	return "Estrutura"


static func rectangle_points(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	])


static func polygon_center(points: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	var point_count := points.size() - 1 if is_closed_fence(points) else points.size()
	for point_index in range(point_count):
		center += points[point_index]
	return center / maxf(point_count, 1)


static func polygon_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for point_index in range(points.size() - 1):
		area += (
			points[point_index].x * points[point_index + 1].y
			- points[point_index + 1].x * points[point_index].y
		)
	return absf(area) * 0.5


static func closest_point_on_segment(point: Vector2, start: Vector2, end: Vector2) -> Vector2:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0:
		return start
	var factor := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return start + segment * factor


static func nearest_fence_position(world_position: Vector2, built_structures: Array) -> Dictionary:
	var nearest := {}
	var shortest_distance := INF
	for structure in built_structures:
		if not str(structure.get("type", "")).begins_with("Cerca"):
			continue
		var points: PackedVector2Array = structure.get("points", PackedVector2Array())
		for point_index in range(1, points.size()):
			var segment_start := points[point_index - 1]
			var segment_end := points[point_index]
			var closest := closest_point_on_segment(
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


static func validate_gate_position(world_position: Vector2, built_structures: Array, cash_balance: int) -> Dictionary:
	var nearest := nearest_fence_position(world_position, built_structures)
	if nearest.is_empty() or float(nearest["distance"]) > 70.0:
		return {"valid": false, "message": "A porteira precisa ser instalada sobre uma cerca."}
	if cash_balance < FREE_GATE_COST:
		return {"valid": false, "message": "Caixa insuficiente para instalar a porteira."}
	return {"valid": true}


static func validate_corral_position(world_position: Vector2, cash_balance: int) -> Dictionary:
	var rect := Rect2(world_position - CORRAL_SIZE / 2.0, CORRAL_SIZE)
	if not Rect2(Vector2.ZERO, Vector2(FARM_WIDTH, FARM_HEIGHT)).encloses(rect):
		return {"valid": false, "message": "O curral precisa ficar inteiramente dentro da propriedade."}
	if cash_balance < CORRAL_COST:
		return {"valid": false, "message": "Caixa insuficiente para construir o curral."}
	return {"valid": true}


static func validate_scale_position(world_position: Vector2, corral_rects: Array, cash_balance: int) -> Dictionary:
	var inside_corral := false
	for corral_rect in corral_rects:
		if corral_rect.has_point(world_position):
			inside_corral = true
			break
	if not inside_corral:
		return {"valid": false, "message": "A balança precisa ser instalada dentro de um curral."}
	if cash_balance < SCALE_COST:
		return {"valid": false, "message": "Caixa insuficiente para instalar a balança."}
	return {"valid": true}


static func full_perimeter_cost(farm_visual_boundary: PackedVector2Array) -> int:
	var points := farm_visual_boundary.duplicate()
	if not points.is_empty() and points[0] != points[-1]:
		points.append(points[0])
	var length_meters := fence_length_meters(points)
	return maxi(ceili(length_meters / 100.0 * BARBED_FENCE_COST_PER_100), 1)


static func sanitary_labor_rate(action: String) -> float:
	return COWBOY_SERVICE_RATE if action == "vitamin" else VETERINARY_LABOR_RATE
