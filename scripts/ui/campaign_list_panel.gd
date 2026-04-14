## campaign_list_panel.gd - Lista de todas las campañas activas
## Click en campaña → navega al planeta y abre campaign_panel
extends PanelContainer

var _content: RichTextLabel = null
var _toggle_btn: Button = null
var _scroll_container: ScrollContainer = null
var _minimized: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Posición: izquierda, debajo del fleet_list_panel
	anchor_left = 0.0
	anchor_top = 0.0
	offset_left = 5.0
	offset_top = 55.0 # Debajo del ► FLOTAS
	custom_minimum_size = Vector2(160, 0)

	_update_style()

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	add_child(main_vbox)

	_toggle_btn = Button.new()
	_toggle_btn.text = "► CAMPAÑAS"
	_toggle_btn.flat = true
	_toggle_btn.add_theme_color_override("font_color", Color(0.7, 0.35, 0.25))
	_toggle_btn.add_theme_font_size_override("font_size", 9)
	_toggle_btn.pressed.connect(_on_toggle)
	main_vbox.add_child(_toggle_btn)

	_scroll_container = ScrollContainer.new()
	_scroll_container.visible = false
	_scroll_container.custom_minimum_size = Vector2(220, 250)
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
	_toggle_btn.text = "▼ CAMPAÑAS" if not _minimized else "► CAMPAÑAS"
	_update_style()
	if not _minimized:
		_refresh()

func _update_badge() -> void:
	# Mostrar cantidad de campañas activas en el botón
	var gd: Node = get_node_or_null("/root/GameData")
	if gd == null:
		return
	var count: int = 0
	for camp: Dictionary in gd.campaigns:
		if not bool(camp.get("terminada", false)):
			count += 1
	if _minimized:
		if count > 0:
			_toggle_btn.text = "► CAMPAÑAS (%d)" % count
			_toggle_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.2))
		else:
			_toggle_btn.text = "► CAMPAÑAS"
			_toggle_btn.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))

func _update_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	if _minimized:
		style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		style.set_content_margin_all(2)
	else:
		style.bg_color = Color(0.04, 0.03, 0.06, 0.90)
		style.border_color = Color(0.6, 0.3, 0.2, 0.2)
		style.border_width_right = 1
		style.set_content_margin_all(5)
	style.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", style)

func _refresh() -> void:
	if _content == null:
		return
	var gd: Node = get_node_or_null("/root/GameData")
	if gd == null:
		_content.text = "[color=#605a4a]Sin datos.[/color]"
		return

	var t: String = ""
	var active: int = 0
	var resolved: int = 0

	for camp: Dictionary in gd.campaigns:
		if bool(camp.get("terminada", false)):
			resolved += 1
			continue
		active += 1

		var frente: int = int(camp["frente"])
		var moral: int = int(camp["moral"])
		var supply: int = int(camp["suministros_semanas"])
		var duracion: int = int(camp["duracion_turnos"])
		var fc: String = "6b8c5a" if frente >= 60 else ("c09a40" if frente >= 30 else "8c5a5a")
		var mc: String = "6b8c5a" if moral >= 60 else ("c09a40" if moral >= 30 else "8c5a5a")

		# Barra de frente compacta
		var bar_f: int = floori(float(frente) / 10.0)
		var bar_e: int = 10 - bar_f
		var frente_bar: String = "[color=#8c4a4a]%s[/color][color=#4a6a8c]%s[/color]" % [
			"█".repeat(bar_e), "█".repeat(bar_f)]

		t += "[url=camp_%d][color=#d9c05a]%s[/color][/url]\n" % [int(camp["id"]), str(camp["nombre"])]
		t += " [color=#807a6b]vs %s • T%d[/color]\n" % [str(camp["enemigo_tipo"]).capitalize(), duracion]
		t += " Frente: %s [color=#%s]%d%%[/color]\n" % [frente_bar, fc, frente]
		t += " [color=#%s]Moral %d[/color] • [color=#807a6b]Supply %dsem[/color]\n\n" % [mc, moral, supply]

	if active == 0:
		t += "[color=#6b8c5a]No hay campañas activas.[/color]\n"
		t += "[color=#605a4a]Pax Imperialis.[/color]\n"

	if resolved > 0:
		t += "\n[color=#605a4a]%d campañas resueltas en el historial.[/color]\n" % resolved

	_content.text = t

func _on_click(meta: Variant) -> void:
	var action: String = str(meta)
	if not action.begins_with("camp_"):
		return

	var camp_id: int = int(action.substr(5))
	var gd: Node = get_node_or_null("/root/GameData")
	if gd == null:
		return

	for camp: Dictionary in gd.campaigns:
		if int(camp["id"]) == camp_id:
			# Navegar al planeta de la campaña
			var planet_id: int = int(camp["planeta_id"])
			if gd.planets_by_id.has(planet_id):
				var planet: Dictionary = gd.planets_by_id[planet_id]
				var galaxy_map = get_tree().get_first_node_in_group("galaxy_map")
				if galaxy_map:
					if galaxy_map.has_method("navigate_to_planet"):
						galaxy_map.navigate_to_planet(planet)
					if galaxy_map.has_method("_show_campaign"):
						galaxy_map._show_campaign(camp)
			break
