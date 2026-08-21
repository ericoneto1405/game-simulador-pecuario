class_name VegetationSpriteGenerator
extends RefCounted


const GRASS_VARIANTS := 16
const BUSH_VARIANTS := 16
const GRASS_SIZE := 64
const BUSH_SIZE := 80
const SHADOW_SIZE := 80

static var _grass_cache: Array[ImageTexture] = []
static var _bush_cache: Array[ImageTexture] = []
static var _shadow_texture: ImageTexture


static func grass_texture(variant: int) -> ImageTexture:
	if _grass_cache.is_empty():
		_generate_grass_variants()
	return _grass_cache[variant % GRASS_VARIANTS]


static func bush_texture(variant: int) -> ImageTexture:
	if _bush_cache.is_empty():
		_generate_bush_variants()
	return _bush_cache[variant % BUSH_VARIANTS]


static func shadow_texture() -> ImageTexture:
	if _shadow_texture == null:
		_generate_shadow()
	return _shadow_texture


static func _draw_organic_circle(
	img: Image, cx: float, cy: float, base_radius: float,
	base_color: Color, edge_color: Color, seed_val: int
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var w := img.get_width()
	var h := img.get_height()
	for y in range(maxi(0, int(cy - base_radius - 2)), mini(h, int(cy + base_radius + 3))):
		for x in range(maxi(0, int(cx - base_radius - 2)), mini(w, int(cx + base_radius + 3))):
			var dx := float(x) - cx
			var dy := float(y) - cy
			var dist := sqrt(dx * dx + dy * dy)
			var angle := atan2(dy, dx)
			var variation := sin(angle * 5.0 + float(seed_val)) * base_radius * 0.15
			var variation2 := cos(angle * 3.0 + float(seed_val) * 0.7) * base_radius * 0.08
			var r := base_radius + variation + variation2
			if dist < r - 1.5:
				var t := clampf(dist / r, 0.0, 1.0)
				img.set_pixel(x, y, base_color.lerp(edge_color, t * 0.4))
			elif dist < r:
				var edge_t := clampf((dist - (r - 1.5)) / 1.5, 0.0, 1.0)
				img.set_pixel(x, y, base_color.lerp(edge_color, 0.4).lerp(Color.TRANSPARENT, edge_t * 0.5))
			else:
				var t2 := clampf((dist - r) / 2.0, 0.0, 1.0)
				var existing := img.get_pixel(x, y)
				img.set_pixel(x, y, existing.lerp(Color.TRANSPARENT, t2))


static func _draw_blade(
	img: Image, tip_x: float, tip_y: float, base_x: float, base_y: float,
	width: float, color: Color, seed_val: int
) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var w := img.get_width()
	var h := img.get_height()
	var steps := int(abs(base_y - tip_y))
	if steps < 1:
		steps = 1
	for i in steps:
		var t := float(i) / float(steps)
		var cx: float = lerpf(tip_x, base_x, t)
		var cy: float = lerpf(tip_y, base_y, t)
		var current_w: float = width * (1.0 - t * 0.15) * (0.3 + t * 0.7)
		var sway := sin(t * PI * 0.7 + float(seed_val) * 0.3) * 1.5
		cx += sway
		var px_min := maxi(0, int(cx - current_w - 1))
		var px_max := mini(w - 1, int(cx + current_w + 1))
		var py := int(cy)
		if py < 0 or py >= h:
			continue
		for px in range(px_min, px_max + 1):
			var dx: float = abs(float(px) - cx)
			if dx < current_w:
				var alpha: float = (1.0 - dx / current_w) * (0.7 + t * 0.3)
				var shade := rng.randf_range(-0.08, 0.08)
				var blade_c := Color(
					clampf(color.r + shade, 0.0, 1.0),
					clampf(color.g + shade, 0.0, 1.0),
					clampf(color.b + shade * 0.5, 0.0, 1.0),
					alpha
				)
				var existing := img.get_pixel(px, py)
				img.set_pixel(px, py, Color(
					lerpf(existing.r, blade_c.r, alpha * 0.8),
					lerpf(existing.g, blade_c.g, alpha * 0.8),
					lerpf(existing.b, blade_c.b, alpha * 0.8),
					maxf(existing.a, blade_c.a * 0.9)
				))


static func _generate_grass_variants() -> void:
	_grass_cache.resize(GRASS_VARIANTS)
	for v in GRASS_VARIANTS:
		var img := Image.create(GRASS_SIZE, GRASS_SIZE, false, Image.FORMAT_RGBA8)
		var cx := float(GRASS_SIZE) / 2.0
		var cy := float(GRASS_SIZE) * 0.65
		var rng := RandomNumberGenerator.new()
		rng.seed = v * 137 + 31
		for blade in 9:
			var bx := cx + rng.randf_range(-10.0, 10.0)
			var by := cy + rng.randf_range(-3.0, 4.0)
			var bw := rng.randf_range(1.5, 3.5)
			var bh := rng.randf_range(10.0, 24.0)
			var tip_x := bx + rng.randf_range(-4.0, 4.0)
			var tip_y := by - bh
			var green_shade := rng.randf_range(0.6, 1.0)
			var blade_color := Color(0.88, green_shade, 0.78, 1.0)
			_draw_blade(img, tip_x, tip_y, bx, by, bw, blade_color, v * 137 + blade * 17)
		for clump in 3:
			var ox := cx + rng.randf_range(-8.0, 8.0)
			var oy := cy + rng.randf_range(-4.0, 4.0)
			var r := rng.randf_range(6.0, 12.0)
			_draw_organic_circle(img, ox, oy, r,
				Color(0.85, 0.90, 0.78, 0.55),
				Color(0.75, 0.82, 0.68, 0.25),
				v * 97 + clump * 23
			)
		for dot in 4:
			var dx := cx + rng.randf_range(-12.0, 12.0)
			var dy := cy + rng.randf_range(-10.0, 6.0)
			var dr := rng.randf_range(1.0, 3.0)
			_draw_organic_circle(img, dx, dy, dr,
				Color(0.92, 0.85, 0.65, 0.4),
				Color(0.85, 0.78, 0.55, 0.15),
				v * 53 + dot * 41
			)
		_grass_cache[v] = ImageTexture.create_from_image(img)


static func _generate_bush_variants() -> void:
	_bush_cache.resize(BUSH_VARIANTS)
	for v in BUSH_VARIANTS:
		var img := Image.create(BUSH_SIZE, BUSH_SIZE, false, Image.FORMAT_RGBA8)
		var cx := float(BUSH_SIZE) / 2.0
		var cy := float(BUSH_SIZE) / 2.0
		var rng := RandomNumberGenerator.new()
		rng.seed = v * 251 + 47
		for clump in 7:
			var ox := cx + rng.randf_range(-14.0, 14.0)
			var oy := cy + rng.randf_range(-12.0, 12.0)
			var r := rng.randf_range(8.0, 18.0)
			var green := rng.randf_range(0.7, 1.0)
			_draw_organic_circle(img, ox, oy, r,
				Color(0.82 * green, 0.88 * green + 0.1, 0.72 * green, 0.7),
				Color(0.70 * green, 0.78 * green + 0.05, 0.60 * green, 0.3),
				v * 311 + clump * 53
			)
		for leaf in 5:
			var lx := cx + rng.randf_range(-16.0, 16.0)
			var ly := cy + rng.randf_range(-14.0, 10.0)
			var lw := rng.randf_range(3.0, 7.0)
			var lh := rng.randf_range(4.0, 10.0)
			var tip_x := lx + rng.randf_range(-3.0, 3.0)
			var tip_y := ly - lh
			var green_l := rng.randf_range(0.65, 0.95)
			_draw_blade(img, tip_x, tip_y, lx, ly, lw,
				Color(0.75, 0.85 * green_l + 0.15, 0.65, 1.0),
				v * 251 + leaf * 37
			)
		for branch in 3:
			var bx_start := cx + rng.randf_range(-6.0, 6.0)
			var by_start := cy + rng.randf_range(2.0, 10.0)
			var bx_end := bx_start + rng.randf_range(-12.0, 12.0)
			var by_end := by_start + rng.randf_range(-18.0, -6.0)
			var steps_b := int(abs(by_start - by_end))
			if steps_b < 1:
				steps_b = 1
			for i in steps_b:
				var t_b := float(i) / float(steps_b)
				var px := int(lerpf(bx_start, bx_end, t_b))
				var py := int(lerpf(by_start, by_end, t_b))
				if px >= 0 and px < BUSH_SIZE and py >= 0 and py < BUSH_SIZE:
					var existing := img.get_pixel(px, py)
					img.set_pixel(px, py, Color(
						lerpf(existing.r, 0.35, 0.4),
						lerpf(existing.g, 0.28, 0.4),
						lerpf(existing.b, 0.18, 0.4),
						maxf(existing.a, 0.5)
					))
		_bush_cache[v] = ImageTexture.create_from_image(img)


static func _generate_shadow() -> void:
	var img := Image.create(SHADOW_SIZE, SHADOW_SIZE, false, Image.FORMAT_RGBA8)
	var cx := float(SHADOW_SIZE) / 2.0
	var cy := float(SHADOW_SIZE) / 2.0 + 4.0
	var base_radius := 30.0
	for y in SHADOW_SIZE:
		for x in SHADOW_SIZE:
			var dx := float(x) - cx
			var dy := float(y) - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist < base_radius:
				var alpha := (1.0 - dist / base_radius) * 0.35
				var edge := smoothstep(base_radius * 0.5, base_radius, dist)
				alpha *= (1.0 - edge * 0.4)
				img.set_pixel(x, y, Color(0.08, 0.10, 0.06, alpha))
	_shadow_texture = ImageTexture.create_from_image(img)
