extends CanvasLayer
class_name PRHud

signal speed_changed(mult: float)
signal confirm_build
signal cancel_build
signal buy_train_pressed
signal tooltip_request(key: String)

@onready var money_label: Label = $Root/TopBar/MoneyLabel
@onready var day_label: Label = $Root/TopBar/DayLabel
@onready var goal_label: Label = $Root/TopBar/GoalLabel
@onready var lines_box: VBoxContainer = $Root/SidePanel/LinesBox
@onready var preview_panel: PanelContainer = $Root/PreviewPanel
@onready var preview_label: Label = $Root/PreviewPanel/VBox/PreviewLabel
@onready var btn_confirm: Button = $Root/PreviewPanel/VBox/Buttons/Confirm
@onready var btn_cancel: Button = $Root/PreviewPanel/VBox/Buttons/Cancel
@onready var tooltip: Label = $Root/Tooltip
@onready var status_label: Label = $Root/StatusLabel
@onready var selected_line_label: Label = $Root/SidePanel/SelectedLine

var selected_line_id: String = ""

func _ready() -> void:
	preview_panel.visible = false
	tooltip.visible = false
	$Root/TopBar/SpeedPause.pressed.connect(func(): speed_changed.emit(0.0))
	$Root/TopBar/Speed1.pressed.connect(func(): speed_changed.emit(1.0))
	$Root/TopBar/Speed2.pressed.connect(func(): speed_changed.emit(2.0))
	$Root/TopBar/Speed4.pressed.connect(func(): speed_changed.emit(4.0))
	btn_confirm.pressed.connect(func(): confirm_build.emit())
	btn_cancel.pressed.connect(func(): cancel_build.emit())
	$Root/SidePanel/BuyTrain.pressed.connect(func(): buy_train_pressed.emit())
	$Root/TopBar/HelpTrack.pressed.connect(func(): show_tooltip("Tap two stations to lay track. Cost shows first."))
	$Root/TopBar/HelpTrain.pressed.connect(func(): show_tooltip("Buy a train on the selected line to carry passengers & freight."))
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

func refresh_lines(summary: Array) -> void:
	for child in lines_box.get_children():
		child.queue_free()
	for item in summary:
		var b := Button.new()
		b.text = "%s  $%s  (%d trains)" % [item.name, _fmt(item.profit), item.trains]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var lid: String = item.id
		b.pressed.connect(func():
			selected_line_id = lid
			selected_line_label.text = "Line: %s" % item.name
		)
		lines_box.add_child(b)
	if summary.is_empty():
		var l := Label.new()
		l.text = "No lines yet"
		l.add_theme_color_override("font_color", PRPalette.UI_TEXT)
		lines_box.add_child(l)

func _fmt(v: float) -> String:
	var n := int(round(v))
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3, 3) + out
		s = s.substr(0, s.length() - 3)
	out = s + out
	return ("-" if n < 0 else "") + out
