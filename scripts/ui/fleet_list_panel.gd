## fleet_list_panel.gd - Panel unificado de flotas con pestañas y detalle inline
## Pestañas: Imperial | Transporte | Astartes | Enemigos
## Click en flota → detalle se muestra abajo en el mismo panel
extends PanelContainer

var _content: RichTextLabel = null
var _toggle_btn: Button = null
var _scroll_container: ScrollContainer = null
var _tabs_container: HBoxContainer = null
var _minimized: bool = true
var _active_tab: String = "imperial"
var _selected_fleet_idx: int = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: izquierda
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 5.0
	offset_top = 30.0
	custom_minimum_size = Vector2(160, 0)

	_update_style()

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	# Botón minimizar
	_toggle_btn = Button.new()
	_toggle_btn.text = "► FLOTAS"
	_toggle_btn.flat = true
	_toggle_btn.add_theme_color_override("font_color", Color(0.4, 0.55, 0.7))
	_toggle_btn.add_theme_font_size_override("font_size", 9)
	_toggle_btn.pressed.connect(_on_toggle)
	main_vbox.add_child(_toggle_btn)

	# Pestañas
	_tabs_container = HBoxContainer.new()
	_tabs_container.visible = false
	_tabs_container.add_theme_constant_override("separation", 2)
	main_vbox.add_child(_tabs_container)

	for tab_info: Array in [["imperial", "Navy"], ["transport", "Transp"], ["astartes", "SM"], ["mech", "Mech"], ["enemy", "Enem"]]:
		var tab_key: String = str(tab_info[0])
		var tab_label: String = str(tab_info[1])
		var btn: Button = Button.new()
		btn.text = tab_label
		btn.flat = true
		btn.add_theme_font_size_override("font_size", 8)
		btn.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38))
		var captured: String = tab_key
		btn.pressed.connect(func() -> void: _switch_tab(captured))
		_tabs_container.add_child(btn)

	# Contenido scrolleable
	_scroll_container = ScrollContainer.new()
	_scroll_container.visible = false
	_scroll_container.custom_minimum_size = Vector2(250, 350)
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
		ts.turno_completado.connect(func(_r: Dictionary) -> void: _refresh())

func _on_toggle() -> void:
	_minimized = not _minimized
	_scroll_container.visible = not _minimized
	_tabs_container.visible = not _minimized
	_toggle_btn.text = "▼ FLOTAS" if not _minimized else "► FLOTAS"
	_update_style()
	if not _minimized:
		_refresh()

func _switch_tab(tab: String) -> void:
	_active_tab = tab
	_selected_fleet_idx = -1
	_update_tab_colors()
	_refresh()

func _update_tab_colors() -> void:
	var idx: int = 0
	var tab_keys: Array = ["imperial", "transport", "astartes", "mech", "enemy"]
	for child_idx: int in _tabs_container.get_child_count():
		var btn: Button = _tabs_container.get_child(child_idx) as Button
		if btn:
			var is_active: bool = (idx < tab_keys.size() and tab_keys[idx] == _active_tab)
			btn.add_theme_color_override("font_color",
				Color(0.85, 0.75, 0.35) if is_active else Color(0.45, 0.42, 0.38))
			idx += 1

func _update_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if _minimized:
		style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		style.set_content_margin_all(2)
	else:
		style.bg_color = Color(0.03, 0.03, 0.06, 0.90)
		style.border_color = Color(0.3, 0.45, 0.6, 0.2)
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

	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node == null:
		_content.text = "[color=#605a4a]Sin datos.[/color]"
		return

	var fl_data: Dictionary = gd_node.fleet_data
	if fl_data.is_empty():
		_content.text = "[color=#605a4a]Sin flotas.[/color]"
		return

	match _active_tab:
		"imperial": _content.text = _build_imperial(fl_data)
		"transport": _content.text = _build_transport(fl_data)
		"astartes": _content.text = _build_astartes(gd_node)
		"mech": _content.text = _build_mechanicus(fl_data)
		"enemy": _content.text = _build_enemy(fl_data)

# =============================================================================
# TAB: NAVY IMPERIAL (Battlefleets)
# =============================================================================

func _build_imperial(fl_data: Dictionary) -> String:
	var t: String = ""
	var bfs: Array = fl_data.get("battlefleets", [])
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
		var selected: bool = (_selected_fleet_idx == bf_idx)
		var name_col: String = "d9c05a" if selected else "8aaccc"

		t += "[color=#%s]●[/color] [url=bf_%d][color=#%s]%s[/color][/url]\n" % [ec, bf_idx, name_col, str(bf["nombre"])]
		t += "  [color=#605a4a]%s • %d naves[/color]\n" % [str(bf["admiral"]).replace("Lord Admiral ", ""), naves]

		# Detalle inline si está seleccionado
		if selected:
			t += _build_bf_detail(bf)

	# Navegantes
	var nav_a: int = int(fl_data.get("navigators_available", 0))
	var nav_t: int = int(fl_data.get("navigators_total", 0))
	t += "\n[color=#807a6b]Navegantes: %d/%d[/color]\n" % [nav_a, nav_t]

	return t

func _build_bf_detail(bf: Dictionary) -> String:
	var t: String = ""
	var cap: int = int(bf["naves_capital"])
	var cru: int = int(bf["cruceros"])
	var esc: int = int(bf["escoltas"])
	var total: int = cap + cru + esc
	var poder: int = cap * 10 + cru * 4 + esc

	t += "  [color=#999080]───────────────[/color]\n"
	t += "  [color=#c8c0b0]%s[/color]\n" % str(bf["admiral"])
	t += "  [color=#807a6b]Sector: %s[/color]\n" % str(bf["sector"])
	t += "  [color=#807a6b]Capital: %d • Cruceros: %d[/color]\n" % [cap, cru]
	t += "  [color=#807a6b]Escoltas: %d • Total: [/color][color=#d9c05a]%d[/color]\n" % [esc, total]
	t += "  [color=#807a6b]Poder:[/color] %s\n" % _bar_inline(poder, 500)
	t += "  [color=#807a6b]Moral:[/color] %s\n" % _bar_inline(int(bf["moral"]), 100)
	t += "  [color=#807a6b]Exp:[/color] %s\n" % _bar_inline(int(bf["experiencia"]), 100)
	t += "  [color=#807a6b]Bombardeo:[/color] [color=#c8c0b0]%s[/color]\n" % ("Sí" if cap >= 5 else "Limitado")
	t += "  [color=#807a6b]Bloqueo:[/color] [color=#c8c0b0]%s[/color]\n" % ("Capaz" if cru >= 10 else "Insuf.")

	# Planeta base
	var base_id: int = int(bf.get("base_planeta_id", -1))
	if base_id >= 0:
		var gd: Node = get_node_or_null("/root/GameData")
		if gd and gd.planets_by_id.has(base_id):
			t += "  [color=#807a6b]Base:[/color] [url=%d][color=#c9a84c]%s[/color][/url]\n" % [base_id, str(gd.planets_by_id[base_id]["nombre"])]

	t += "  [color=#999080]───────────────[/color]\n"
	return t

# =============================================================================
# TAB: TRANSPORTE
# =============================================================================

func _build_transport(fl_data: Dictionary) -> String:
	var t: String = ""
	var trs: Array = fl_data.get("transport_fleets", [])
	var avail: int = 0
	var en_ruta: int = 0
	for tr: Dictionary in trs:
		if str(tr["estado"]) == "disponible": avail += 1
		else: en_ruta += 1

	t += "[color=#807a6b][b]TRANSPORTE (%d)[/b][/color]\n" % trs.size()
	t += "[color=#6b8c5a]%d disponibles[/color] • [color=#c09a40]%d en ruta[/color]\n\n" % [avail, en_ruta]

	# Disponibles (primeros 8)
	var shown: int = 0
	for tr: Dictionary in trs:
		if str(tr["estado"]) != "disponible": continue
		if shown >= 8: break
		t += "[color=#6b8c5a]●[/color] %s\n" % str(tr["nombre"])
		t += "  [color=#605a4a]%s • %d reg • %sT[/color]\n" % [
			str(tr["tipo"]).capitalize(), int(tr["capacidad_tropas"]),
			_fmt(int(tr["capacidad_carga"]))]
		shown += 1
	if avail > 8:
		t += "[color=#605a4a]...+%d más[/color]\n" % (avail - 8)

	# En tránsito
	var in_transit: Array = fl_data.get("fleets_in_transit", [])
	if not in_transit.is_empty():
		t += "\n[color=#c09a40][b]EN EL WARP (%d)[/b][/color]\n" % in_transit.size()
		for ft: Dictionary in in_transit:
			var turnos: int = int(ft["turnos_restantes"])
			if bool(ft.get("perdido_warp", false)):
				t += "[color=#8c5a5a]⚠ %s — PERDIDO[/color]\n" % str(ft["nombre"])
			else:
				t += "[color=#807a6b]→ %s (%d t.)[/color]\n" % [str(ft["nombre"]), turnos]

	return t

# =============================================================================
# TAB: ASTARTES
# =============================================================================

func _build_astartes(gd_node: Node) -> String:
	var t: String = ""
	var chapters: Array = gd_node.chapters

	t += "[color=#5a7a9a][b]FLOTAS ASTARTES[/b][/color]\n"
	for ch: Dictionary in chapters:
		var flota: Dictionary = ch.get("flota", {})
		var bb: int = int(flota.get("battle_barges", 0))
		var sc: int = int(flota.get("strike_cruisers", 0))
		var esc_ch: int = int(flota.get("escorts", 0))
		if bb <= 0: continue

		var col: Color = ch.get("color_primario", Color.WHITE)
		var hex: String = col.to_html(false)
		var mision: String = str(ch.get("mision_actual", ""))
		var estado_txt: String = "Disponible" if mision == "" else mision

		t += "[color=#%s]●[/color] [color=#c8c0b0]%s[/color]\n" % [hex, str(ch["nombre"])]
		t += "  [color=#605a4a]%d BB • %d SC • %d Esc[/color]\n" % [bb, sc, esc_ch]
		t += "  [color=#605a4a]%s[/color]\n" % estado_txt

	return t

# =============================================================================
# TAB: MECHANICUS
# =============================================================================

func _build_mechanicus(fl_data: Dictionary) -> String:
	var t: String = ""
	var mfs: Array = fl_data.get("mechanicus_fleets", [])

	t += "[color=#7a3a2a][b]EXPLORATOR FLEETS (%d)[/b][/color]\n" % mfs.size()
	for mf: Dictionary in mfs:
		var estado_mf: String = str(mf.get("estado", "estacionada"))
		var ec_mf: String = "6b8c5a" if estado_mf == "estacionada" else "c09a40"
		t += "[color=#%s]●[/color] [color=#c8c0b0]%s[/color]\n" % [ec_mf, str(mf["forge_world"])]
		t += "  [color=#605a4a]%d Ark • %d Cru • %d Esc • %s[/color]\n" % [
			int(mf["ark_mechanicus"]), int(mf["cruisers"]), int(mf["escorts"]), estado_mf]

	# Rogue Traders
	var rts: Array = fl_data.get("rogue_trader_fleets", [])
	if not rts.is_empty():
		t += "\n[color=#6a4a7a][b]ROGUE TRADERS (%d)[/b][/color]\n" % rts.size()
		for rt: Dictionary in rts:
			t += "[color=#7a5a8a]☸[/color] [color=#c8c0b0]%s[/color]\n" % str(rt["dinastia"])
			t += "  [color=#605a4a]%d naves • %s[/color]\n" % [int(rt["naves"]), str(rt["estado"])]

	return t

# =============================================================================
# TAB: ENEMIGOS
# =============================================================================

func _build_enemy(fl_data: Dictionary) -> String:
	var t: String = ""
	var efs: Array = fl_data.get("enemy_fleets", [])
	var active: int = 0
	for ef: Dictionary in efs:
		if not bool(ef.get("derrotada", false)): active += 1

	if active == 0:
		t += "[color=#6b8c5a]No hay flotas enemigas activas.[/color]\n"
		t += "[color=#605a4a]El Emperador Protege.[/color]\n"
		return t

	t += "[color=#8c3a3a][b]⚠ FLOTAS ENEMIGAS (%d)[/b][/color]\n" % active
	for ef: Dictionary in efs:
		if bool(ef.get("derrotada", false)): continue
		var tipo: String = str(ef.get("tipo", ""))
		var icon: String = "✦"
		match tipo:
			"chaos_warband": icon = "☠"
			"ork_waaagh": icon = "⚔"
			"tyranid_tendril": icon = "🦷"
			"dark_eldar_raid": icon = "⚡"
			"necron_harvest": icon = "◆"

		t += "[color=#8c4a4a]%s[/color] [color=#cc6a6a][b]%s[/b][/color]\n" % [icon, str(ef["nombre"])]
		t += "  [color=#807a6b]Poder: %d • Sector: %s[/color]\n" % [int(ef["poder"]), str(ef["sector"])]
		t += "  [color=#807a6b]Activo: %d turnos[/color]\n" % int(ef["turnos_activo"])

	return t

# =============================================================================
# UTILIDADES
# =============================================================================

func _bar_inline(value: int, max_val: int) -> String:
	var pct: float = clampf(float(value) / float(max_val), 0.0, 1.0)
	var filled: int = floori(pct * 8.0)
	var empty: int = 8 - filled
	var c: String = "6b8c5a" if pct >= 0.6 else ("c09a40" if pct >= 0.3 else "8c5a5a")
	return "[color=#%s]%s[/color][color=#333]%s[/color] [color=#c8c0b0]%d[/color]" % [c, "█".repeat(filled), "░".repeat(empty), value]

func _fmt(n: int) -> String:
	if n >= 1000: return "%.1fK" % (float(n) / 1000.0)
	return str(n)

func _on_click(meta: Variant) -> void:
	var meta_str: String = str(meta)

	if meta_str.begins_with("bf_"):
		# Toggle selección de Battlefleet
		var idx: int = int(meta_str.substr(3))
		if _selected_fleet_idx == idx:
			_selected_fleet_idx = -1 # Deseleccionar
		else:
			_selected_fleet_idx = idx
		_refresh()
		return

	# Si es un número, es un planet_id → navegar
	var pid: int = int(meta_str)
	if pid > 0:
		var gd_node: Node = get_node_or_null("/root/GameData")
		if gd_node and gd_node.planets_by_id.has(pid):
			var planet: Dictionary = gd_node.planets_by_id[pid]
			var galaxy_map = get_tree().get_first_node_in_group("galaxy_map")
			if galaxy_map and galaxy_map.has_method("navigate_to_planet"):
				galaxy_map.navigate_to_planet(planet)
