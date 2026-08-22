extends Control

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var username_input: LineEdit = %UsernameInput
@onready var password_input: LineEdit = %PasswordInput
@onready var display_name_label: Label = %DisplayNameLabel
@onready var display_name_input: LineEdit = %DisplayNameInput
@onready var confirm_password_label: Label = %ConfirmPasswordLabel
@onready var confirm_password_input: LineEdit = %ConfirmPasswordInput
@onready var login_button: Button = %LoginButton
@onready var register_button: Button = %RegisterButton
@onready var error_label: Label = %ErrorLabel
@onready var auth_panel: PanelContainer = %AuthPanel
@onready var slot_panel: PanelContainer = %SlotPanel
@onready var slot_buttons: VBoxContainer = %SlotButtons
@onready var welcome_label: Label = %WelcomeLabel
@onready var logout_button: Button = %LogoutButton
@onready var sync_status_label: Label = %SyncStatusLabel
@onready var conflict_dialog: ConfirmationDialog = %ConflictDialog
@onready var delete_dialog: ConfirmationDialog = %DeleteDialog

var slot_buttons_list: Array[Button] = []
var registering := false
var pending_conflict_slot := -1
var pending_delete_slot := -1


func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	logout_button.pressed.connect(_on_logout_pressed)
	conflict_dialog.confirmed.connect(_on_conflict_use_local)
	conflict_dialog.canceled.connect(_on_conflict_use_cloud)
	delete_dialog.confirmed.connect(_on_delete_confirmed)
	UserManager.sync_status_changed.connect(_on_sync_status_changed)
	UserManager.sync_conflict.connect(_on_sync_conflict)
	UserManager.slots_refreshed.connect(_populate_slots)
	password_input.text_submitted.connect(_on_password_submitted)
	username_input.text_submitted.connect(func(_t: String) -> void: password_input.grab_focus())
	_show_auth()
	if await UserManager.restore_session():
		await _show_slots()


func _show_auth() -> void:
	auth_panel.visible = true
	slot_panel.visible = false
	error_label.text = ""
	username_input.text = ""
	password_input.text = ""
	display_name_input.text = ""
	confirm_password_input.text = ""
	_set_registering(false)
	username_input.grab_focus()


func _show_slots() -> void:
	auth_panel.visible = false
	slot_panel.visible = true
	welcome_label.text = "Bem-vindo, %s" % UserManager.current_user
	_on_sync_status_changed(UserManager.sync_status)
	await UserManager.refresh_slots()
	_populate_slots()


func _on_login_pressed() -> void:
	if registering:
		_set_registering(false)
		return
	_set_auth_busy(true)
	var err := await UserManager.login(username_input.text, password_input.text)
	_set_auth_busy(false)
	if not err.is_empty():
		error_label.text = err
		return
	await _show_slots()


func _on_register_pressed() -> void:
	if not registering:
		_set_registering(true)
		return
	if password_input.text != confirm_password_input.text:
		error_label.text = "As senhas não são iguais."
		return
	_set_auth_busy(true)
	var err := await UserManager.register_user(
		display_name_input.text,
		username_input.text,
		password_input.text
	)
	_set_auth_busy(false)
	if not err.is_empty():
		error_label.text = err
		return
	await _show_slots()


func _on_logout_pressed() -> void:
	await UserManager.logout()
	_show_auth()


func _on_password_submitted(_text: String) -> void:
	if registering:
		confirm_password_input.grab_focus()
	else:
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
			var cloud_state := ""
			if bool(meta.get("conflict", false)):
				cloud_state = " — CONFLITO"
			elif bool(meta.get("pending_sync", false)):
				cloud_state = " — Pendente"
			btn.text = "Slot %d — Dia %d, Ano %d — %s — %s%s" % [
				i,
				meta.get("current_day", 1),
				meta.get("current_year", 2025),
				_format_cash(meta.get("cash_balance", 0.0)),
				herd_text,
				cloud_state,
			]
			btn.pressed.connect(_on_load_slot.bind(i))
			btn.gui_input.connect(_on_slot_gui_input.bind(i))
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
	if UserManager.has_conflict(slot):
		_on_sync_conflict(slot)
		return
	UserManager.current_slot = slot
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _set_registering(enabled: bool) -> void:
	registering = enabled
	display_name_label.visible = enabled
	display_name_input.visible = enabled
	confirm_password_label.visible = enabled
	confirm_password_input.visible = enabled
	login_button.text = "Voltar" if enabled else "Entrar"
	register_button.text = "Criar conta" if enabled else "Cadastrar"
	subtitle_label.text = "Crie sua conta" if enabled else "Gerencie sua fazenda"
	error_label.text = ""
	if enabled:
		display_name_input.grab_focus()


func _set_auth_busy(busy: bool) -> void:
	login_button.disabled = busy
	register_button.disabled = busy
	error_label.text = "Conectando..." if busy else ""


func _on_sync_status_changed(status: String) -> void:
	var labels := {
		"salvo_localmente": "Salvo no dispositivo. Aguardando nuvem.",
		"sincronizando": "Sincronizando com a nuvem...",
		"sincronizado": "Partidas sincronizadas.",
		"offline": "Offline. Alterações ficarão neste dispositivo.",
		"conflito": "Conflito encontrado. Escolha qual versão manter.",
	}
	sync_status_label.text = str(labels.get(status, ""))


func _on_sync_conflict(slot: int) -> void:
	pending_conflict_slot = slot
	conflict_dialog.dialog_text = (
		"O slot %d tem versões diferentes. Escolha qual delas deve continuar."
		% slot
	)
	conflict_dialog.popup_centered()


func _on_conflict_use_local() -> void:
	if pending_conflict_slot >= 1:
		await UserManager.resolve_conflict(pending_conflict_slot, true)
	pending_conflict_slot = -1
	_populate_slots()


func _on_conflict_use_cloud() -> void:
	if pending_conflict_slot >= 1:
		await UserManager.resolve_conflict(pending_conflict_slot, false)
	pending_conflict_slot = -1
	_populate_slots()


func _on_slot_gui_input(event: InputEvent, slot: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
		pending_delete_slot = slot
		delete_dialog.dialog_text = "Apagar o slot %d do dispositivo e da nuvem?" % slot
		delete_dialog.popup_centered()


func _on_delete_confirmed() -> void:
	if pending_delete_slot >= 1:
		await UserManager.delete_slot(pending_delete_slot)
	pending_delete_slot = -1
	_populate_slots()


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
