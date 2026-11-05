extends CanvasLayer
class_name PRHud

signal speed_changed(mult: float)
signal confirm_build
signal cancel_build
signal buy_train_pressed
signal line_selected(line_id: String)
signal tooltip_request(key: String)

@onready var money_label: Label = $Root/TopBar/MoneyLabel
@onready var day_label: Label = $Root/TopBar/DayLabel
@onready var goal_label: Label = $Root/TopBar/GoalLabel
@onready var lines_box: VBoxContainer = $Root/SidePanel/Margin/VBox/LinesScroll/LinesBox
@onready var lines_scroll: ScrollContainer = $Root/SidePanel/Margin/VBox/LinesScroll
@onready var preview_panel: PanelContainer = $Root/PreviewPanel
@onready var preview_label: Label = $Root/PreviewPanel/VBox/PreviewLabel
@onready var btn_confirm: Button = $Root/PreviewPanel/VBox/Buttons/Confirm
@onready var btn_cancel: Button = $Root/PreviewPanel/VBox/Buttons/Cancel
@onready var btn_buy: Button = $Root/SidePanel/Margin/VBox/BuyTrain
@onready var tooltip: Label = $Root/Tooltip
@onready var status_label: Label = $Root/StatusLabel
@onready var selected_line_label: Label = $Root/SidePanel/Margin/VBox/SelectedLine

var selected_line_id: String = ""
var _line_buttons: Dictionary = {}
var _buy_ui_state := -1

## Buy target is only the line the player selected. One existing line is not a selection.
static func resolve_buy_line_id(selected_line_id: String, _line_count: int = 0) -> String:
	return selected_line_id

func _ready() -> void:
	_style_side_panel()
	preview_panel.visible = false
	tooltip.visible = false
	_sync_buy_button()
	$Root/TopBar/SpeedPause.pressed.connect(func(): speed_changed.emit(0.0))
	$Root/TopBar/Speed1.pressed.connect(func(): speed_changed.emit(1.0))
	$Root/TopBar/Speed2.pressed.connect(func(): speed_changed.emit(2.0))
	$Root/TopBar/Speed4.pressed.connect(func(): speed_changed.emit(4.0))
	btn_confirm.pressed.connect(func(): confirm_build.emit())
	btn_cancel.pressed.connect(func(): cancel_build.emit())
	btn_buy.pressed.connect(func(): buy_train_pressed.emit())
	$Root/TopBar/HelpTrack.pressed.connect(func(): show_tooltip("Tap two stations to lay track. Cost shows first."))
	$Root/TopBar/HelpTrain.pressed.connect(func(): show_tooltip("Tap a line in the list or on the map, then Buy Train. The train stays on that line."))
	$Root/TopBar/HelpGrow.pressed.connect(func(): show_tooltip("Served cities grow. Skipped towns stagnate."))

func update_money(amount: float) -> void:
	money_label.text = "$%s" % _fmt(amount)

func update_day(day: float) -> void:
	day_label.text = "Day %d" % int(day)

func update_goal(text: String, connected: bool, profit: float) -> void:
	var mark := "✓" if connected else "…"
	goal_label.text = "%s  [%s]  profit $%s" % [text, mark, _fmt(profit)]

func show_preview(from_name: String, to_name: String, cost: int, can_afford: bool) -> void:
	preview_panel.visible = true
	preview_label.text = "Build %s → %s\nCost: $%d%s" % [from_name, to_name, cost, "" if can_afford else " (can't afford)"]
	btn_confirm.disabled = not can_afford

func hide_preview() -> void:
	preview_panel.visible = false

func show_tooltip(text: String) -> void:
	tooltip.text = text
	tooltip.visible = true
	get_tree().create_timer(3.5).timeout.connect(func(): tooltip.visible = false)

func set_status(text: String) -> void:
	status_label.text = text

func select_line(line_id: String, line_name: String) -> void:
	if line_id == "":
		clear_line_selection()
		return
	selected_line_id = line_id
	selected_line_label.text = "Selected: %s\nBuy Train assigns to this line only." % line_name
	_restyle_line_buttons()
	_sync_buy_button()
	line_selected.emit(line_id)

func clear_line_selection() -> void:
	var had := selected_line_id != ""
	selected_line_id = ""
	selected_line_label.text = "No line selected.\nTap a line or its track."
	_restyle_line_buttons()
	_sync_buy_button()
	if had:
		line_selected.emit("")

func refresh_lines(summary: Array) -> void:
	var seen := {}
	var added := false
	for item in summary:
		var lid := str(item.id)
		seen[lid] = true
		var b: Button = _line_buttons.get(lid)
		if b == null:
			b = _make_line_button(lid)
			lines_box.add_child(b)
			_line_buttons[lid] = b
			added = true
		var trains := int(item.trains)
		var train_word := "train" if trains == 1 else "trains"
		var selected := lid == selected_line_id
		var mark := "●" if selected else "○"
		var text := "%s %s\n$%s · %d %s" % [mark, str(item.name), _fmt(item.profit), trains, train_word]
		# Leave the button alone when nothing changed. Rebuilding it every frame
		# ate the touch release, so a tap could never select a line.
		if b.text != text:
			b.text = text
		b.set_meta("line_name", str(item.name))
		var idx := int(item.index)
		var styled := int(b.get_meta("styled_selected", -1))
		if styled != (1 if selected else 0) or int(b.get_meta("line_index", -2)) != idx:
			b.set_meta("line_index", idx)
			_style_line_button(b, selected)
	var stale: Array = []
	for lid in _line_buttons.keys():
		if not seen.has(lid):
			stale.append(lid)
	for lid in stale:
		var old: Button = _line_buttons[lid]
		_line_buttons.erase(lid)
		old.queue_free()
	_ensure_empty_state(summary.is_empty())
	if selected_line_id != "" and not seen.has(selected_line_id):
		clear_line_selection()
	else:
		_sync_buy_button()
	if added:
		call_deferred("_scroll_lines_to_end")

func _make_line_button(line_id: String) -> Button:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 48)
	b.clip_text = true
	b.focus_mode = Control.FOCUS_NONE
	b.set_meta("line_id", line_id)
	# Default args bind this button now. A loop variable would capture the last row.
	b.pressed.connect(func(id := line_id, btn := b):
		select_line(id, str(btn.get_meta("line_name", "")))
	)
	return b

func _restyle_line_buttons() -> void:
	for lid in _line_buttons.keys():
		_style_line_button(_line_buttons[lid], str(lid) == selected_line_id)

func _style_line_button(b: Button, selected: bool) -> void:
	b.set_meta("styled_selected", 1 if selected else 0)
	var col := PRPalette.line_color(int(b.get_meta("line_index", 0)))
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 8
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	if selected:
		sb.bg_color = Color("f0c14a")
		sb.border_color = PRPalette.SELECT_EDGE
		sb.set_border_width_all(3)
	else:
		sb.bg_color = Color("f7f1e0")
		sb.border_color = col
		sb.set_border_width_all(4)
	for state in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", PRPalette.UI_TEXT)
	b.add_theme_color_override("font_hover_color", PRPalette.UI_TEXT)
	b.add_theme_color_override("font_pressed_color", PRPalette.UI_TEXT)
	b.add_theme_font_size_override("font_size", 12)

func _sync_buy_button() -> void:
	if btn_buy == null:
		return
	var state := 1 if selected_line_id != "" else 0
	if state == _buy_ui_state:
		return
	_buy_ui_state = state
	var ready := state == 1
	btn_buy.disabled = not ready
	_style_buy_button(ready)
	if ready:
		btn_buy.text = "Buy Train ($%s)" % _fmt(float(PRConstants.TRAIN_COST))
		btn_buy.tooltip_text = "Buy a train for the selected line only"
	else:
		btn_buy.text = "Pick a line first"
		btn_buy.tooltip_text = "Tap a line in the list, or tap its track on the map"

func _style_buy_button(enabled: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	if enabled:
		sb.bg_color = PRPalette.UI_ACCENT
		sb.border_color = Color("8a3a18")
	else:
		sb.bg_color = Color("e4d8bc")
		sb.border_color = Color("b4a078")
	sb.set_border_width_all(2)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn_buy.add_theme_stylebox_override(state, sb)
	btn_buy.add_theme_color_override("font_color", PRPalette.UI_TEXT)
	btn_buy.add_theme_color_override("font_hover_color", PRPalette.UI_TEXT)
	btn_buy.add_theme_color_override("font_pressed_color", PRPalette.UI_TEXT)
	btn_buy.add_theme_color_override("font_disabled_color", Color("5c4630"))
	btn_buy.add_theme_font_size_override("font_size", 15)

func _style_side_panel() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PRPalette.UI_PANEL.r, PRPalette.UI_PANEL.g, PRPalette.UI_PANEL.b, 0.94)
	sb.border_color = PRPalette.UI_PANEL_EDGE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.2)
	sb.shadow_size = 4
	$Root/SidePanel.add_theme_stylebox_override("panel", sb)

func _ensure_empty_state(empty: bool) -> void:
	var existing := lines_box.get_node_or_null("EmptyLines")
	if empty:
		if existing == null:
			var l := Label.new()
			l.name = "EmptyLines"
			l.text = "No lines yet. Tap two stations to build a rail."
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_color_override("font_color", PRPalette.UI_TEXT)
			l.add_theme_font_size_override("font_size", 12)
			lines_box.add_child(l)
	elif existing != null:
		existing.queue_free()

func _scroll_lines_to_end() -> void:
	if lines_scroll == null:
		return
	var bar := lines_scroll.get_v_scroll_bar()
	lines_scroll.scroll_vertical = int(bar.max_value)

func _fmt(v: float) -> String:
	var n := int(round(v))
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	out = s + out
	return ("-" if n < 0 else "") + out
