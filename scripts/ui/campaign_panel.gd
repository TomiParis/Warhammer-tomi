## campaign_panel.gd - Panel de campaña militar con frente visual, fuerzas, log
extends PanelContainer

var _content: RichTextLabel = null
var _close_btn: Button = null
var _current_campaign: Dictionary = {}
var _current_units: Array = []

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.06, 0.92)
	style.border_color = Color(0.6, 0.3, 0.2, 0.3)
	style.border_width_left = 2
	style.set_corner_radius_all(0)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", style)

	# Posición: abajo-izquierda, al lado izquierdo del event log
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = 5.0
	offset_right = 500.0
	offset_top = -200.0
	offset_bottom = -5.0

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	_close_btn = Button.new()
	_close_btn.text = "✕"
	_close_btn.flat = true
	_close_btn.custom_minimum_size = Vector2(30, 20)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_btn.add_theme_color_override("font_color", Color(0.6, 0.55, 0.45))
	_close_btn.pressed.connect(func() -> void: visible = false)
	vbox.add_child(_close_btn)

	_content = RichTextLabel.new()
	_content.bbcode_enabled = true
	_content.fit_content = false
	_content.scroll_active = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_color_override("default_color", Color(0.72, 0.70, 0.63))
	_content.add_theme_font_size_override("normal_font_size", 10)
	_content.meta_clicked.connect(_on_action)
	vbox.add_child(_content)

	# Conectar al turno para refresh automático
	call_deferred("_connect_turn")

func _connect_turn() -> void:
	var ts: Node = get_node_or_null("/root/TurnSystem")
	if ts and ts.has_signal("turno_completado"):
		ts.turno_completado.connect(func(_r: Dictionary) -> void:
			if visible and not _current_campaign.is_empty():
				show_campaign(_current_campaign, _current_units)
		)

func show_campaign(camp: Dictionary, units: Array) -> void:
	if _content == null:
		return
	_current_campaign = camp
	_current_units = units
	visible = true
	_content.text = _build_text(camp, units)
	_content.scroll_to_line(0)

func _build_text(c: Dictionary, units: Array) -> String:
	var t: String = ""
	var frente: int = int(c["frente"])
	var moral: int = int(c["moral"])
	var supply: int = int(c["suministros_semanas"])
	var imp_total: int = int(c["fuerza_imperial_total"])
	var enem_total: int = int(c["fuerzas_enemigas"])
	var duracion: int = int(c["duracion_turnos"])

	# Encabezado compacto
	t += "[color=#d9c05a][b]%s[/b][/color] " % str(c["nombre"])
	t += "[color=#807a6b]vs %s • T%d • %s[/color]\n" % [
		str(c["enemigo_tipo"]).capitalize(), duracion,
		str(c["comandante"]).replace("General ", "").replace("Coronel ", "")]

	# Frente (barra horizontal)
	var bar_imp: int = floori(float(frente) / 100.0 * 20.0)
	var bar_enem: int = 20 - bar_imp
	var fc: String = "6b8c5a" if frente >= 60 else ("c09a40" if frente >= 30 else "8c5a5a")
	t += "[color=#8c4a4a]%s[/color][color=#%s]|[/color][color=#4a6a8c]%s[/color] [color=#%s]%d%%[/color]  " % [
		"█".repeat(bar_enem), fc, "█".repeat(bar_imp), fc, frente]
	t += "Moral: %s  Supply: %s\n" % [_bar(moral, 100), _bar(supply, 16)]

	# Fuerzas en línea
	t += "[color=#4a6a8c]Imp: %s[/color] vs [color=#8c4a4a]Enem: %s[/color] • " % [_fmt(imp_total), _fmt(enem_total)]
	t += "[color=#605a4a]Bajas: %s/%s[/color]\n" % [_fmt(int(c["bajas_imperiales"])), _fmt(int(c["bajas_enemigas"]))]

	# Estrategia + acciones en línea
	var strat: String = str(c["estrategia"])
	var strat_name: String = str(MilitaryData.STRATEGIES.get(strat, {}).get("nombre", strat))
	t += "[color=#d9c05a]%s[/color] " % strat_name
	for strat_key: String in MilitaryData.STRATEGIES:
		if strat_key != strat:
			var sn: String = str(MilitaryData.STRATEGIES[strat_key]["nombre"])
			t += "[url=strat_%s][color=#5a7a9a]%s[/color][/url] " % [strat_key, sn.substr(0, 4)]

	# Acciones
	var avail_rf: int = 0
	for u: Dictionary in units:
		if str(u["estado"]) == "guarnicion" and int(u.get("campana_id", -1)) < 0:
			avail_rf += 1
	t += "\n[url=send_reinforcements][color=#5a7a9a]⚔ Refuerzos(%d)[/color][/url] " % avail_rf
	t += "[url=assign_supply][color=#5a7a9a]📦 Supply[/color][/url] "
	t += "[url=retreat][color=#8c5a5a]← Retirada[/color][/url]\n"

	# Unidades (compacto, 1 línea cada una)
	var imp_units: Array = c.get("fuerzas_imperiales", [])
	if not imp_units.is_empty():
		t += "[color=#999080]Unidades (%d):[/color] " % imp_units.size()
		var shown_u: int = 0
		for uid: int in imp_units:
			if shown_u >= 4:
				t += "[color=#605a4a]+%d más[/color]" % (imp_units.size() - 4)
				break
			for u: Dictionary in units:
				if int(u["id"]) == uid:
					var uf: int = int(u["fuerza"])
					var um: int = int(u["fuerza_max"])
					var uc: String = "6b8c5a" if uf > um / 2 else "8c5a5a"
					t += "[color=#%s]●[/color]%s(%d) " % [uc, str(u["nombre"]).substr(0, 15), uf]
					shown_u += 1
					break
		t += "\n"

	# Log (últimos 3, compacto)
	var log: Array = c.get("log", [])
	if not log.is_empty():
		var max_log: int = mini(log.size(), 3)
		for l_idx: int in range(log.size() - 1, maxi(log.size() - max_log - 1, -1), -1):
			t += "[color=#504a3a]%s[/color]\n" % str(log[l_idx])

	return t

func _bar(value: int, max_val: int) -> String:
	var pct: float = clampf(float(value) / float(max_val), 0.0, 1.0)
	var f: int = floori(pct * 10.0)
	var e: int = 10 - f
	var c: String = "6b8c5a" if pct >= 0.6 else ("c09a40" if pct >= 0.3 else "8c5a5a")
	return "[color=#%s]%s[/color][color=#333]%s[/color] %d" % [c, "█".repeat(f), "░".repeat(e), value]

func _on_action(meta: Variant) -> void:
	var action: String = str(meta)
	var gd_node: Node = get_node_or_null("/root/GameData")
	if gd_node == null or _current_campaign.is_empty():
		return

	if action.begins_with("strat_"):
		# Cambiar estrategia
		var new_strat: String = action.substr(6)
		_current_campaign["estrategia"] = new_strat
		var strat_name: String = new_strat
		if MilitaryData.STRATEGIES.has(new_strat):
			strat_name = str(MilitaryData.STRATEGIES[new_strat]["nombre"])
		_current_campaign["log"].append("Estrategia cambiada a: %s" % strat_name)
		show_campaign(_current_campaign, _current_units)

	elif action == "send_reinforcements":
		# Enviar el primer regimiento disponible
		for u: Dictionary in gd_node.military_units:
			if str(u["estado"]) == "guarnicion" and int(u.get("campana_id", -1)) < 0:
				u["estado"] = "combate"
				u["campana_id"] = int(_current_campaign["id"])
				_current_campaign["fuerzas_imperiales"].append(int(u["id"]))
				_current_campaign["log"].append("Refuerzos: %s enviados al frente" % str(u["nombre"]))
				show_campaign(_current_campaign, _current_units)
				break

	elif action == "assign_supply":
		# Buscar planeta productor cercano y crear ruta
		var planetas: Array = gd_node.get_all_planets()
		for p: Dictionary in planetas:
			var tipo: String = str(p["tipo"])
			if tipo in ["agri_world", "forge_world", "hive_world"]:
				if int(p["capacidad_industrial"]) > 30:
					var supply_sys: SupplySystem = SupplySystem.new()
					var route: Dictionary = supply_sys.create_supply_route(
						int(_current_campaign["id"]), p, 20, 3)
					gd_node.supply_routes.append(route)
					_current_campaign["log"].append("Ruta de suministro desde %s establecida" % str(p["nombre"]))
					_current_campaign["suministros_semanas"] = mini(
						int(_current_campaign["suministros_semanas"]) + 4, 20)
					show_campaign(_current_campaign, _current_units)
					break

	elif action == "retreat":
		# Ordenar retirada
		_current_campaign["terminada"] = true
		_current_campaign["resultado"] = "retirada"
		_current_campaign["fase"] = "resolucion"
		_current_campaign["log"].append("Retirada ordenada por el Alto Mando")
		# Liberar unidades
		for uid: int in _current_campaign["fuerzas_imperiales"]:
			for u: Dictionary in gd_node.military_units:
				if int(u["id"]) == uid:
					u["estado"] = "recuperacion"
					u["campana_id"] = -1
		show_campaign(_current_campaign, _current_units)

func _fmt(n: int) -> String:
	if abs(n) >= 1_000_000: return "%.1fM" % (float(n) / 1_000_000.0)
	elif abs(n) >= 1_000: return "%.1fK" % (float(n) / 1_000.0)
	return str(n)
