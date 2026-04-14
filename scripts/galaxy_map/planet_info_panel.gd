## planet_info_panel.gd - Panel lateral con información detallada del planeta
extends PanelContainer

var _content: RichTextLabel = null
var _close_btn: Button = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Estilo del panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	style.border_color = Color(0.55, 0.5, 0.3, 0.25)
	style.border_width_left = 2
	style.set_corner_radius_all(0)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	add_theme_stylebox_override("panel", style)

	# Layout
	custom_minimum_size = Vector2(320, 0)
	anchor_right = 1.0
	anchor_bottom = 1.0
	anchor_left = 1.0
	offset_left = -330.0
	offset_top = 50.0
	offset_bottom = -10.0
	offset_right = -10.0

	# Contenido
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "VBox"
	add_child(vbox)

	# Botón cerrar
	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.flat = true
	_close_btn.custom_minimum_size = Vector2(30, 30)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	_close_btn.pressed.connect(func() -> void: visible = false)
	vbox.add_child(_close_btn)

	# Rich text para datos
	_content = RichTextLabel.new()
	_content.name = "Content"
	_content.bbcode_enabled = true
	_content.fit_content = true
	_content.scroll_active = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_color_override("default_color", Color(0.75, 0.72, 0.65))
	vbox.add_child(_content)

func show_planet(planet: Dictionary) -> void:
	if _content == null:
		return
	visible = true
	_content.text = _build_planet_text(planet)

func _build_planet_text(p: Dictionary) -> String:
	var nombre: String = str(p["nombre"])
	var tipo_key: String = str(p["tipo"])
	var tipo_name: String = str(GameData.PLANET_TYPES[tipo_key]["nombre"]) if GameData.PLANET_TYPES.has(tipo_key) else tipo_key
	var pop: int = int(p["poblacion"])
	var lado: String = str(p["lado_grieta"])
	var tithe: String = str(p["tithe_grade"])
	var tithe_name: String = str(GameData.TITHE_GRADES[tithe]["nombre"]) if GameData.TITHE_GRADES.has(tithe) else tithe

	var controlador: Dictionary = p.get("controlador", {})
	var ctrl_nombre: String = str(controlador.get("nombre", "Desconocido"))

	var guarnicion: Dictionary = p.get("guarnicion", {})
	var pdf: int = int(guarnicion.get("pdf_size", 0))
	var astartes: Variant = guarnicion.get("astartes_presencia")

	var lealtad: int = int(p["lealtad_imperial"])
	var fe_val: int = int(p["fe_imperial"])
	var industrial: int = int(p["capacidad_industrial"])
	var militar: int = int(p["capacidad_militar"])
	var warp: int = int(p["estabilidad_warp"])
	var astropata: bool = bool(p["tiene_astropata"])
	var ingresos: int = int(p["ingresos_mensuales"])

	var seg_name: String = _get_seg_name(str(p["segmentum"]))
	var sec_name: String = _get_sec_name(str(p["segmentum"]), str(p["sector"]))

	# Badge de lado de la grieta
	var lado_badge: String = ""
	if lado == "sanctus":
		lado_badge = "[color=#6b8c5a]SANCTUS[/color]"
	else:
		lado_badge = "[color=#8c5a5a]NIHILUS[/color]"

	# Badge de tipo con color
	var tipo_color: String = GalaxyDataProvider.PLANET_COLORS.get(tipo_key, Color.WHITE).to_html(false)
	var tipo_badge: String = "[color=#%s]%s[/color]" % [tipo_color, tipo_name]

	var text: String = ""
	text += "[font_size=20][color=#d9c05a][b]%s[/b][/color][/font_size]\n" % nombre
	text += "%s  •  %s\n" % [tipo_badge, lado_badge]
	text += "[color=#807a6b]%s > %s[/color]\n" % [seg_name, sec_name]
	text += "\n"

	# Población
	text += "[color=#999080]POBLACIÓN[/color]\n"
	text += "[color=#c8c0b0]%s habitantes[/color]\n\n" % _format_pop(pop)

	# Diezmo
	text += "[color=#999080]GRADO DE DIEZMO[/color]\n"
	text += "[color=#c8c0b0]%s[/color]\n\n" % tithe_name

	# Controlador
	text += "[color=#999080]CONTROLADOR[/color]\n"
	text += "[color=#c8c0b0]%s[/color]\n\n" % ctrl_nombre

	# Stats con barras de texto
	text += "[color=#999080]ESTADÍSTICAS[/color]\n"
	text += _stat_bar("Lealtad", lealtad)
	text += _stat_bar("Fe Imperial", fe_val)
	text += _stat_bar("Industria", industrial)
	text += _stat_bar("Militar", militar)
	text += _stat_bar("Est. Warp", warp)
	text += "\n"

	# Guarnición
	text += "[color=#999080]GUARNICIÓN[/color]\n"
	text += "[color=#c8c0b0]PDF: %s efectivos[/color]\n" % _format_pop(pdf)
	if astartes != null and str(astartes) != "":
		text += "[color=#d9c05a]Astartes: %s[/color]\n" % str(astartes)
	text += "\n"

	# Info adicional
	text += "[color=#999080]COMUNICACIONES[/color]\n"
	text += "[color=#c8c0b0]Astropata: %s[/color]\n" % ("Sí" if astropata else "No")
	text += "[color=#c8c0b0]Ingresos: %d Throne Gelt/mes[/color]\n" % ingresos

	# Flags
	var flags: Array = p.get("flags", [])
	if not flags.is_empty():
		text += "\n[color=#999080]ESTADO[/color]\n"
		for f_idx: int in flags.size():
			text += "[color=#8c5a5a]• %s[/color]\n" % str(flags[f_idx]).to_upper()

	return text

func _stat_bar(label: String, value: int) -> String:
	var filled: int = value / 5 # 20 chars max
	var empty: int = 20 - filled
	var bar_color: String = "6b8c5a" if value >= 60 else ("c09a40" if value >= 30 else "8c5a5a")
	return "[color=#807a6b]%-12s[/color] [color=#%s]%s[/color][color=#333]%s[/color] [color=#807a6b]%d[/color]\n" % [
		label, bar_color, "█".repeat(filled), "░".repeat(empty), value
	]

func _format_pop(pop: int) -> String:
	if pop <= 0: return "0"
	elif pop >= 1_000_000_000: return "%.1f mil millones" % (float(pop) / 1_000_000_000.0)
	elif pop >= 1_000_000: return "%.1f millones" % (float(pop) / 1_000_000.0)
	elif pop >= 1_000: return "%d mil" % (pop / 1000)
	else: return str(pop)

func _get_seg_name(seg_key: String) -> String:
	var hierarchy: Dictionary = GameData.GALAXY_HIERARCHY
	if hierarchy.has(seg_key):
		return str(hierarchy[seg_key]["nombre"])
	return seg_key

func _get_sec_name(seg_key: String, sec_key: String) -> String:
	var hierarchy: Dictionary = GameData.GALAXY_HIERARCHY
	if hierarchy.has(seg_key):
		var sectores: Dictionary = hierarchy[seg_key]["sectores"]
		if sectores.has(sec_key):
			return str(sectores[sec_key]["nombre"])
	return sec_key
