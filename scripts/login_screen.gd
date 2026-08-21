extends Control

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var login_button: Button = %LoginButton
@onready var register_button: Button = %RegisterButton
@onready var error_label: Label = %ErrorLabel
@onready var auth_panel: PanelContainer = %AuthPanel
@onready var slot_panel: PanelContainer = %SlotPanel
@onready var slot_buttons: VBoxContainer = %SlotButtons
@onready var welcome_label: Label = %WelcomeLabel
@onready var logout_button: Button = %LogoutButton

var slot_buttons_list: Array[Button] = []


func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	password_input.text_submitted.connect(_on_password_submitted)
	username_input.text_submitted.connect(func(_t: String) -> void: password_input.grab_focus())
	_show_auth()


func _show_auth() -> void:
	auth_panel.visible = true
	slot_panel.visible = false
	error_label.text = ""
	username_input.text = ""
	password_input.text = ""
	username_input.grab_focus()


func _show_slots() -> void:
	auth_panel.visible = false
	slot_panel.visible = true
	welcome_label.text = "Bem-vindo, %s" % UserManager.current_user
	_populate_slots()


func _on_login_pressed() -> void:
	var err := UserManager.login(username_input.text, password_input.text)
	if not err.is_empty():
		error_label.text = err
		return
	_show_slots()


func _on_register_pressed() -> void:
	var err := UserManager.register_user(username_input.text, password_input.text)
	if not err.is_empty():
		error_label.text = err
		return
	var login_err := UserManager.login(username_input.text, password_input.text)
	if not login_err.is_empty():
		error_label.text = login_err
		return
	_show_slots()


func _on_logout_pressed() -> void:
	UserManager.logout()
	_show_auth()


func _on_password_submitted(_text: String) -> void:
	_on_login_pressed()


func _populate_slots() -> void:
	for child in slot_buttons.get_children():
		if child is Button:
			child.queue_free()
	slot_buttons_list.clear()

	for i in range(1, UserManager.MAX_SLOTS + 1):
		var meta := UserManager.get_slot_metadata(i)
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(400, 60)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if meta.is_empty():
			btn.text = "Slot %d — Vazio" % i
			btn.pressed.connect(_on_new_game.bind(i))
		else:
			var herd_text := "%d animais" % meta.get("herd_size", 0) if meta.get("herd_created", false) else "Sem rebanho"
			btn.text = "Slot %d — Dia %d, Ano %d — R$ %s — %s" % [
				i,
				meta.get("current_day", 1),
				meta.get("current_year", 2025),
				_format_cash(meta.get("cash_balance", 0.0)),
				herd_text,
			]
			btn.pressed.connect(_on_load_slot.bind(i))
		slot_buttons.add_child(btn)
		slot_buttons_list.append(btn)

	var separator := HSeparator.new()
	slot_buttons.add_child(separator)

	var delete_label := Label.new()
	delete_label.text = "Para apagar um slot, clique duas vezes nele:"
	delete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.5))
	slot_buttons.add_child(delete_label)


func _on_new_game(slot: int) -> void:
	UserManager.current_slot = slot
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_load_slot(slot: int) -> void:
	UserManager.current_slot = slot
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _format_cash(value: float) -> String:
	var formatted := "%0.2f" % value
	var parts := formatted.split(".")
	var int_part := parts[0]
	var dec_part := parts[1] if parts.size() > 1 else "00"
	var result := ""
	var count := 0
	for j in range(int_part.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = int_part[j] + result
		count += 1
	return "R$ %s,%s" % [result, dec_part]
