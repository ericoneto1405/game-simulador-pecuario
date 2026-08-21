class_name VegetationShader
extends RefCounted


const SHADER_CODE := """
shader_type canvas_item;

uniform sampler2D noise_texture : filter_linear, repeat_enable;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 noise = texture(noise_texture, UV * 3.0);
	COLOR = tex_color * vec4(1.0 - noise.r * 0.18, 1.0 - noise.r * 0.12, 1.0 - noise.r * 0.08, 1.0);
}
"""

static var _noise_texture: ImageTexture
static var _pasture_material: ShaderMaterial
static var _grass_material: ShaderMaterial
static var _bush_material: ShaderMaterial


static func _generate_noise_image(size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var val := randf() * 0.5 + 0.25
			img.set_pixel(x, y, Color(val, val, val, 1.0))
	return img


static func _ensure_noise() -> ImageTexture:
	if _noise_texture == null:
		var img := _generate_noise_image(128)
		_noise_texture = ImageTexture.create_from_image(img)
	return _noise_texture


static func _make_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER_CODE
	mat.set_shader_parameter("noise_texture", _ensure_noise())
	return mat


static func pasture_material() -> ShaderMaterial:
	if _pasture_material == null:
		_pasture_material = _make_material()
	return _pasture_material


static func grass_material() -> ShaderMaterial:
	if _grass_material == null:
		_grass_material = _make_material()
	return _grass_material


static func bush_material() -> ShaderMaterial:
	if _bush_material == null:
		_bush_material = _make_material()
	return _bush_material
