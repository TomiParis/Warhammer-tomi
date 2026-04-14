## command_panel.gd - Panel principal con pestañas tipo navegador
## Pestañas: Imperio | Flotas | Campañas (expandible con nuevas funciones)
## Reemplaza fleet_list_panel y campaign_list_panel separados
extends PanelContainer

var _content: RichTextLabel = null
var _tabs_container: HBoxContainer = null
var _scroll_container: ScrollContainer = null
var _toggle_btn: Button = null
var _minimized: bool = true
var _active_tab: String = "imperio"

# Referencia al panel de detalle que se abre al hacer click
# (campaign_panel, chapter_panel, etc.)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: izquierda, debajo del breadcrumb
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 5.0
	offset_top = 30.0
	custom_minimum_size = Vector2(260, 0)

	_update_style()

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# Botón minimizar
	_toggle_btn = Button.new()
	_toggle_btn.text = "► COMANDO IMPERIAL"
	_toggle_btn.flat = true
	_toggle_btn.add_theme_color_override("font_color", Color(0.75, 0.65, 0.35))
	_toggle_btn.add_theme_font_size_override("font_size", 10)
	_toggle_btn.pressed.connect(_on_toggle)
	main_vbox.add_child(_toggle_btn)

	# Pestañas
	_tabs_container = HBoxContainer.new()
	_tabs_container.visible = false
	_tabs_container.add_theme_constant_override("separation", 0)
	main_vbox.add_child(_tabs_container)

	var tabs: Array = [
		["imperio", "Imperio", Color(0.75, 0.65, 0.3)],
		["flotas", "Flotas", Color(0.4, 0.55, 0.7)],
		["campanas", "Campañas", Color(0.7, 0.35, 0.25)],
	]
	for tab: Array in tabs:
		var btn: Button = Button.new()
		btn.text = str(tab[1])
		btn.add_theme_font_size_override("font_size", 9)
		btn.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))
		var tab_style: StyleBoxFlat = StyleBoxFlat.new()
		tab_style.bg_color = Color(0.06, 0.05, 0.08, 0.6)
		tab_style.content_margin_left = 8.0
		tab_style.content_margin_right = 8.0
		tab_style.content_margin_top = 3.0
		tab_style.content_margin_bottom = 3.0
		btn.add_theme_stylebox_override("normal", tab_style)
		var captured: String = str(tab[0])
		btn.pressed.connect(func() -> void: _switch_tab(captured))
		_tabs_container.add_child(btn)

	# Contenido scrolleable
	_scroll_container = ScrollContainer.new()
	_scroll_container.visible = false
	_scroll_container.custom_minimum_size = Vector2(250, 400)
	main_vbox.add_child(_scroll_container)

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = true
	_content.scroll_active = false
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_color_override("default_color", Color(0.6, 0.58, 0.5))
	_content.add_theme_font_size_override("normal_font_size", 10)
	_content.meta_clicked.connect(_on_click)
	_scroll_container.add_child(_content)

	call_deferred("_connect_signals")

func _connect_signals() -> void:
	var ts: Node = get_node_or_null("/root/TurnSystem")
	if ts and ts.has_signal("turno_completado"):
		ts.turno_completado.connect(func(_r: Dictionary) -> void:
			_update_badge()
			if not _minimized:
				_refresh()
		)

func _on_toggle() -> void:
	_minimized = not _minimized
	_scroll_container.visible = not _minimized
	_tabs_container.visible = not _minimized
	_toggle_btn.text = "▼ COMANDO IMPERIAL" if not _minimized else "► COMANDO IMPERIAL"
	_update_style()
	if not _minimized:
		_refresh()

func _switch_tab(tab: String) -> void:
	_active_tab = tab
	_update_tab_colors()
	_refresh()

func _update_badge() -> void:
	if not _minimized:
		return
	var gd: Node = get_node_or_null("/root/GameData")
	if gd == null:
		return
	var camp_count: int = 0
	for camp: Dictionary in gd.campaigns:
		if not bool(camp.get("terminada", false)):
			camp_count += 1
	if camp_count > 0:
		_toggle_btn.text = "► COMANDO IMPERIAL [%d⚔]" % camp_count
	else:
		_toggle_btn.text = "► COMANDO IMPERIAL"

func _update_tab_colors() -> void:
	var tab_keys: Array = ["imperio", "flotas", "campanas"]
	var tab_colors: Array = [Color(0.75, 0.65, 0.3), Color(0.4, 0.55, 0.7), Color(0.7, 0.35, 0.25)]
	for i: int in _tabs_container.get_child_count():
		var btn: Button = _tabs_container.get_child(i) as Button
		if btn and i < tab_keys.size():
			var is_active: bool = tab_keys[i] == _active_tab
			var col: Color = tab_colors[i] if is_active else Color(0.45, 0.42, 0.38)
			btn.add_theme_color_override("font_color", col)
			var s: StyleBoxFlat = StyleBoxFlat.new()
			s.bg_color = Color(0.08, 0.07, 0.10, 0.8) if is_active else Color(0.06, 0.05, 0.08, 0.5)
			s.content_margin_left = 8.0
			s.content_margin_right = 8.0
			s.content_margin_top = 3.0
			s.content_margin_bottom = 3.0
			if is_active:
				s.border_color = col
				s.border_color.a = 0.4
				s.border_width_bottom = 2
			btn.add_theme_stylebox_override("normal", s)

func _update_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if _minimized:
		style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		style.set_content_margin_all(2)
	else:
		style.bg_color = Color(0.03, 0.03, 0.06, 0.92)
		style.border_color = Color(0.5, 0.45, 0.25, 0.2)
		style.border_width_right = 1
		style.set_content_margin_all(5)
	style.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", style)

# =============================================================================
# REFRESH
# =============================================================================

func _refresh() -> void:
	if _content == null:
		return
	_update_tab_colors()

	var gd: Node = get_node_or_null("/root/GameData")
	if gd == null:
		_content.text = "[color=#605a4a]Sin datos.[/color]"
		return

	match _active_tab:
		"imperio": _content.text = _build_imperio(gd)
		"flotas": _content.text = _build_flotas(gd)
		"campanas": _content.text = _build_campanas(gd)

# =============================================================================
# TAB: IMPERIO
# =============================================================================

func _build_imperio(gd: Node) -> String:
	var t: String = ""
	var planetas: Array = gd.get_all_planets()
	var total: int = planetas.size()
	var amenazas: int = 0
	var baja_lealtad: int = 0
	var nihilus: int = 0
	var pop_total: int = 0

	for p: Dictionary in planetas:
		if p.get("amenaza_actual") != null: amenazas += 1
		if int(p["lealtad_imperial"]) < 30: baja_lealtad += 1
		if str(p["lado_grieta"]) == "nihilus": nihilus += 1
		pop_total += int(p["poblacion"])

	t += "[color=#d9c05a][b]ESTADO DEL IMPERIUM[/b][/color]\n"
	t += " Planetas: [color=#c8c0b0]%d[/color]\n" % total
	t += " Población: [color=#c8c0b0]%s[/color]\n" % _fmt_pop(pop_total)
	t += " Con amenaza: [color=#8c5a5a]%d[/color]\n" % amenazas
	t += " Lealtad baja: [color=#c09a40]%d[/color]\n" % baja_lealtad
	t += " En Nihilus: [color=#807a6b]%d[/color]\n" % nihilus

	# Regimientos
	var mil: Array = gd.military_units
	var reg_total: int = mil.size()
	var reg_combat: int = 0
	var reg_garrison: int = 0
	for u: Dictionary in mil:
		if str(u["estado"]) == "combate": reg_combat += 1
		elif str(u["estado"]) == "guarnicion": reg_garrison += 1
	t += "\n[color=#999080]FUERZAS MILITARES[/color]\n"
	t += " Regimientos: [color=#c8c0b0]%d[/color]\n" % reg_total
	t += " En combate: [color=#8c5a5a]%d[/color]\n" % reg_combat
	t += " En guarnición: [color=#6b8c5a]%d[/color]\n" % reg_garrison

	# Capítulos
	t += " Capítulos Astartes: [color=#c8c0b0]%d[/color]\n" % gd.chapters.size()

	# Gobernanza
	t += "\n[color=#999080]GOBERNANZA[/color]\n"
	t += " Lord Sectors: [color=#c8c0b0]%d[/color]\n" % gd.lord_sectors.size()
	t += " Knight Houses: [color=#c8c0b0]%d[/color]\n" % gd.knight_houses.size()
	t += " Rogue Traders: [color=#c8c0b0]%d[/color]\n" % gd.rogue_traders.size()

	# Relaciones (resumen)
	var rels: Dictionary = gd.faction_relations
	if not rels.is_empty():
		t += "\n[color=#999080]RELACIONES CLAVE[/color]\n"
		for key: String in rels:
			var val: int = int(rels[key])
			var rc: String = "6b8c5a" if val >= 60 else ("c09a40" if val >= 40 else "8c5a5a")
			t += " [color=#605a4a]%s:[/color] [color=#%s]%d[/color]\n" % [key, rc, val]

	return t

# =============================================================================
# TAB: FLOTAS
# =============================================================================

func _build_flotas(gd: Node) -> String:
	var t: String = ""
	var fl: Dictionary = gd.fleet_data
	if fl.is_empty():
		return "[color=#605a4a]Sin flotas.[/color]"

	# Battlefleets
	var bfs: Array = fl.get("battlefleets", [])
	t += "[color=#5a8ab0][b]BATTLEFLEETS (%d)[/b][/color]\n" % bfs.size()
	for bf_idx: int in bfs.size():
		var bf: Dictionary = bfs[bf_idx]
		var estado: String = str(bf["estado"])
		var ec: String = "6b8c5a"
		match estado:
			"desplegada": ec = "c09a40"
			"combate": ec = "8c5a5a"
			"reparaciones": ec = "c09a40"
		var naves: int = int(bf["naves_capital"]) + int(bf["cruceros"]) + int(bf["escoltas"])
		t += " [color=#%s]●[/color] [url=bf_%d][color=#8aaccc]%s[/color][/url]\n" % [ec, bf_idx, str(bf["nombre"])]
		t += "   [color=#605a4a]%s • %d naves[/color]\n" % [str(bf["admiral"]).replace("Lord Admiral ", ""), naves]

	# Transporte
	var trs: Array = fl.get("transport_fleets", [])
	var avail: int = 0
	for tr: Dictionary in trs:
		if str(tr["estado"]) == "disponible": avail += 1
	t += "\n[color=#807a6b][b]TRANSPORTE[/b][/color]\n"
	t += " [color=#6b8c5a]%d disponibles[/color] / %d total\n" % [avail, trs.size()]

	# En tránsito
	var transit: Array = fl.get("fleets_in_transit", [])
	if not transit.is_empty():
		t += "\n[color=#c09a40][b]EN EL WARP (%d)[/b][/color]\n" % transit.size()
		for ft: Dictionary in transit:
			if bool(ft.get("perdido_warp", false)):
				t += " [color=#8c5a5a]⚠ %s PERDIDO[/color]\n" % str(ft["nombre"])
			else:
				t += " [color=#807a6b]→ %s (%dt)[/color]\n" % [str(ft["nombre"]), int(ft["turnos_restantes"])]

	# Enemigos
	var efs: Array = fl.get("enemy_fleets", [])
	var active_e: int = 0
	for ef: Dictionary in efs:
		if not bool(ef.get("derrotada", false)): active_e += 1
	if active_e > 0:
		t += "\n[color=#8c3a3a][b]⚠ ENEMIGAS (%d)[/b][/color]\n" % active_e
		for ef: Dictionary in efs:
			if bool(ef.get("derrotada", false)): continue
			t += " [color=#cc6a6a]%s[/color] [color=#605a4a]P:%d[/color]\n" % [str(ef["nombre"]), int(ef["poder"])]

	# Navegantes
	t += "\n[color=#807a6b]Navegantes: %d/%d[/color]\n" % [int(fl.get("navigators_available", 0)), int(fl.get("navigators_total", 0))]

	return t

# =============================================================================
# TAB: CAMPAÑAS
# =============================================================================

func _build_campanas(gd: Node) -> String:
	var t: String = ""
	var active: int = 0

	for camp: Dictionary in gd.campaigns:
		if bool(camp.get("terminada", false)):
			continue
		active += 1

		var frente: int = int(camp["frente"])
		var moral: int = int(camp["moral"])
		var supply: int = int(camp["suministros_semanas"])
		var fc: String = "6b8c5a" if frente >= 60 else ("c09a40" if frente >= 30 else "8c5a5a")

		var bar_f: int = floori(float(frente) / 10.0)
		var bar_e: int = 10 - bar_f

		t += "[url=camp_%d][color=#d9c05a]%s[/color][/url]\n" % [int(camp["id"]), str(camp["nombre"])]
		t += " [color=#807a6b]vs %s • T%d • %s[/color]\n" % [
			str(camp["enemigo_tipo"]).capitalize(), int(camp["duracion_turnos"]), str(camp["estrategia"]).replace("_", " ")]
		t += " [color=#8c4a4a]%s[/color][color=#4a6a8c]%s[/color] [color=#%s]%d%%[/color]\n" % [
			"█".repeat(bar_e), "█".repeat(bar_f), fc, frente]
		t += " [color=#807a6b]Moral %d • Supply %dsem[/color]\n\n" % [moral, supply]

	if active == 0:
		t += "[color=#6b8c5a][b]Pax Imperialis[/b][/color]\n"
		t += "[color=#605a4a]No hay campañas activas.[/color]\n"
	else:
		t += "[color=#999080]%d campañas activas[/color]\n" % active

	# Historial
	var resolved: int = 0
	for camp: Dictionary in gd.campaigns:
		if bool(camp.get("terminada", false)):
			resolved += 1
	if resolved > 0:
		t += "[color=#605a4a]%d resueltas[/color]\n" % resolved

	return t

# =============================================================================
# CLICKS
# =============================================================================

func _on_click(meta: Variant) -> void:
	var action: String = str(meta)
	var gd: Node = get_node_or_null("/root/GameData")
	if gd == null:
		return

	if action.begins_with("camp_"):
		var camp_id: int = int(action.substr(5))
		for camp: Dictionary in gd.campaigns:
			if int(camp["id"]) == camp_id:
				var galaxy_map = get_tree().get_first_node_in_group("galaxy_map")
				if galaxy_map:
					var pid: int = int(camp["planeta_id"])
					if gd.planets_by_id.has(pid):
						galaxy_map.navigate_to_planet(gd.planets_by_id[pid])
					if galaxy_map.has_method("_show_campaign"):
						galaxy_map._show_campaign(camp)
				break

	elif action.begins_with("bf_"):
		var bf_idx: int = int(action.substr(3))
		var bfs: Array = gd.fleet_data.get("battlefleets", [])
		if bf_idx >= 0 and bf_idx < bfs.size():
			var galaxy_map = get_tree().get_first_node_in_group("galaxy_map")
			if galaxy_map and galaxy_map.has_method("_show_fleet"):
				galaxy_map._show_fleet(bfs[bf_idx])

func _fmt_pop(pop: int) -> String:
	if pop >= 1_000_000_000_000: return "%.1f billones" % (float(pop) / 1_000_000_000_000.0)
	elif pop >= 1_000_000_000: return "%.1f mil M" % (float(pop) / 1_000_000_000.0)
	elif pop >= 1_000_000: return "%.1f M" % (float(pop) / 1_000_000.0)
	return str(pop)
