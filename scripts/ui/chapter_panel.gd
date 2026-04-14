## chapter_panel.gd - Panel de información de un Capítulo de Space Marines
extends PanelContainer

var _content: RichTextLabel = null
var _close_btn: Button = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	style.border_color = Color(0.55, 0.5, 0.3, 0.25)
	style.border_width_left = 2
	style.set_corner_radius_all(0)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", style)

	# Posición: mismo lugar que PlanetInfoPanel (lo reemplaza temporalmente)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = -430.0
	offset_top = 5.0
	offset_bottom = -220.0
	offset_right = -5.0

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.flat = true
	_close_btn.custom_minimum_size = Vector2(30, 25)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	_close_btn.pressed.connect(func() -> void: visible = false)
	vbox.add_child(_close_btn)

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = false
	_content.scroll_active = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_color_override("default_color", Color(0.75, 0.72, 0.65))
	vbox.add_child(_content)

func show_chapter(chapter: Dictionary) -> void:
	if _content == null:
		return
	visible = true
	_content.text = _build_text(chapter)
	_content.scroll_to_line(0)

func _build_text(ch: Dictionary) -> String:
	var col1: Color = ch.get("color_primario", Color.WHITE)
	var col2: Color = ch.get("color_secundario", Color.GRAY)
	var col1_hex: String = col1.to_html(false)
	var col2_hex: String = col2.to_html(false)

	var t: String = ""

	# Nombre con colores heráldicos
	t += "[font_size=18][color=#%s]█[/color][color=#%s]█[/color] " % [col1_hex, col2_hex]
	t += "[color=#d9c05a][b]%s[/b][/color][/font_size]\n" % str(ch["nombre"])

	# Info básica
	t += "[color=#807a6b]%s • %s Fundación[/color]\n" % [str(ch["progenitor"]), str(ch["fundacion"])]
	if str(ch["primarca"]) != "Desconocido" and str(ch["primarca"]) != "Ninguno":
		var estado_col: String = "6b8c5a" if str(ch["primarca_estado"]) == "vivo" else "807a6b"
		t += "[color=#807a6b]Primarca:[/color] [color=#%s]%s (%s)[/color]\n" % [
			estado_col, str(ch["primarca"]), str(ch["primarca_estado"])]
	t += "\n"

	# Chapter Master
	t += "[color=#999080]CHAPTER MASTER[/color]\n"
	t += "[color=#c8c0b0]%s[/color]\n\n" % str(ch["chapter_master"])

	# Mundo natal
	t += "[color=#999080]MUNDO NATAL[/color]\n"
	var mundo: String = str(ch["mundo_natal"])
	if bool(ch["fleet_based"]):
		mundo += " [color=#807a6b](Fleet-based)[/color]"
	t += "[color=#c8c0b0]%s[/color]\n" % mundo
	t += "[color=#807a6b]Segmentum %s[/color]\n\n" % str(ch["segmentum"]).capitalize()

	# Fuerza y gene-seed
	t += "[color=#999080]FUERZA[/color]\n"
	var fuerza: int = int(ch["fuerza_total"])
	var fuerza_col: String = "6b8c5a" if fuerza >= 800 else ("c09a40" if fuerza >= 500 else "8c5a5a")
	t += "[color=#%s]%d Battle-Brothers[/color]\n" % [fuerza_col, fuerza]
	t += "[color=#807a6b]Gene-seed: %s[/color]\n" % str(ch["gene_seed"])
	t += "[color=#807a6b]Especialidad: %s[/color]\n\n" % str(ch["especialidad"])

	# Estado actual
	var mision: String = str(ch["mision_actual"])
	if mision != "":
		t += "[color=#c09a40]⚔ %s[/color]\n\n" % mision
	else:
		t += "[color=#6b8c5a]Disponible para despliegue[/color]\n\n"

	# Compañías
	t += "[color=#999080]COMPAÑÍAS[/color]\n"
	var companias: Array = ch.get("companias", [])
	for comp_idx: int in companias.size():
		var comp: Dictionary = companias[comp_idx]
		var num: int = int(comp["numero"])
		var nombre: String = str(comp["nombre"])
		var fuerza_c: int = int(comp["fuerza"])
		var max_c: int = int(comp["fuerza_max"])
		var estado: String = str(comp["estado"])

		var estado_icon: String = "●"
		var estado_col: String = "6b8c5a"
		match estado:
			"base": estado_icon = "●"; estado_col = "6b8c5a"
			"desplegada": estado_icon = "⚔"; estado_col = "c09a40"
			"en_combate": estado_icon = "⚔"; estado_col = "8c5a5a"
			"en_transito": estado_icon = "→"; estado_col = "807a6b"
			"recuperandose": estado_icon = "✚"; estado_col = "c09a40"

		var bar_filled: int = floori(float(fuerza_c) / float(max_c) * 10.0)
		var bar_empty: int = 10 - bar_filled
		var bar: String = "█".repeat(bar_filled) + "░".repeat(bar_empty)

		t += " [color=#%s]%s[/color] %d. %-12s [color=#%s]%s[/color] %d/%d\n" % [
			estado_col, estado_icon, num, nombre, estado_col, bar, fuerza_c, max_c]

	# Flota
	t += "\n[color=#999080]FLOTA[/color]\n"
	var flota: Dictionary = ch.get("flota", {})
	t += " [color=#c8c0b0]%d Battle Barges, %d Strike Cruisers, %d Escorts[/color]\n" % [
		int(flota.get("battle_barges", 0)),
		int(flota.get("strike_cruisers", 0)),
		int(flota.get("escorts", 0)),
	]

	return t
