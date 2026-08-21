extends Node

const USERS_PATH := "user://users.json"
const MAX_SLOTS := 3

var current_user: String = ""
var current_slot: int = -1


func _hash_password(password: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(password.to_utf8_buffer())
	return ctx.finish().hex_encode()


func _load_users() -> Dictionary:
	if not FileAccess.file_exists(USERS_PATH):
		return {}
	var f := FileAccess.open(USERS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}


func _save_users(users: Dictionary) -> String:
	var base := USERS_PATH.get_base_dir()
	if not base.is_empty():
		DirAccess.make_dir_recursive_absolute(base)
	var f := FileAccess.open(USERS_PATH, FileAccess.WRITE)
	if f == null:
		var err := FileAccess.get_open_error()
		push_warning("UserManager: falha ao salvar users.json (erro %d)" % err)
		return "Erro ao salvar dados (código %d)." % err
	f.store_string(JSON.stringify(users))
	f.close()
	return ""


func register_user(username: String, password: String) -> String:
	username = username.strip_edges()
	if username.is_empty():
		return "Informe um nome de usuário."
	if password.length() < 4:
		return "A senha deve ter pelo menos 4 caracteres."
	var users := _load_users()
	if users.has(username):
		return "Usuário já existe."
	users[username] = {"password": _hash_password(password)}
	var save_err := _save_users(users)
	if not save_err.is_empty():
		return save_err
	DirAccess.make_dir_recursive_absolute(_user_saves_dir(username))
	return ""


func login(username: String, password: String) -> String:
	username = username.strip_edges()
	if username.is_empty() or password.is_empty():
		return "Preencha usuário e senha."
	var users := _load_users()
	if not users.has(username):
		return "Usuário não encontrado."
	var stored_hash: String = users[username].get("password", "")
	if _hash_password(password) != stored_hash:
		return "Senha incorreta."
	current_user = username
	return ""


func logout() -> void:
	current_user = ""
	current_slot = -1


func get_slot_path(slot: int) -> String:
	return _user_saves_dir(current_user) + "/slot_%d.json" % slot


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_slot_path(slot))


func get_slot_metadata(slot: int) -> Dictionary:
	var path := get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed
	return {
		"version": data.get("version", 0),
		"current_day": data.get("current_day", 1),
		"day_of_year": data.get("day_of_year", 1),
		"current_year": data.get("current_year", 2025),
		"cash_balance": data.get("cash_balance", 0.0),
		"herd_size": data.get("herd_size", 0),
		"herd_created": data.get("herd_created", false),
	}


func delete_slot(slot: int) -> void:
	var path := get_slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func has_any_save() -> bool:
	if current_user.is_empty():
		return false
	for i in range(1, MAX_SLOTS + 1):
		if slot_exists(i):
			return true
	return false


func _user_saves_dir(username: String) -> String:
	return "user://saves/%s" % username
