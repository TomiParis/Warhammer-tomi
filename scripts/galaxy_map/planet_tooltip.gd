## planet_tooltip.gd - Tooltip al pasar mouse sobre un planeta
extends PanelContainer

var label: RichTextLabel = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Estilo
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.08, 0.92)
	style.border_color = Color(0.6, 0.55, 0.3, 0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	# Crear estructura
	var margin: MarginContainer = MarginContainer.new()
	margin.name = "MarginContainer"
	add_child(margin)
	var rtl: RichTextLabel = RichTextLabel.new()
	rtl.name = "Content"
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.custom_minimum_size = Vector2(200, 0)
	margin.add_child(rtl)
	label = rtl

func show_planet(planet: Dictionary, screen_pos: Vector2) -> void:
	if label == null:
		return
	var nombre: String = str(planet["nombre"])
	var tipo_key: String = str(planet["tipo"])
	var tipo_name: String = str(PlanetTypes.TYPES[tipo_key]["nombre"]) if PlanetTypes.TYPES.has(tipo_key) else tipo_key
	var pop: int = int(planet["poblacion"])
	var pop_str: String = _format_pop(pop)

	label.text = "[b][color=#d9c05a]%s[/color][/b]\n[color=#807a6b]%s[/color]  •  [color=#807a6b]%s[/color]" % [
		nombre, tipo_name, pop_str
	]

	# Posicionar cerca del mouse pero dentro de la pantalla
	var vp_size: Vector2 = get_viewport_rect().size
	var pos: Vector2 = screen_pos + Vector2(15, -10)
	pos.x = minf(pos.x, vp_size.x - 250.0)
	pos.y = maxf(pos.y, 10.0)
	global_position = pos
	visible = true

func _format_pop(pop: int) -> String:
	if pop <= 0: return "Deshabitado"
	elif pop >= 1_000_000_000: return "%.1f mil M hab." % (float(pop) / 1_000_000_000.0)
	elif pop >= 1_000_000: return "%.1f M hab." % (float(pop) / 1_000_000.0)
	elif pop >= 1_000: return "%.1f K hab." % (float(pop) / 1_000.0)
	else: return str(pop) + " hab."
