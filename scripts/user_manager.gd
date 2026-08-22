extends Node

signal sync_status_changed(status: String)
signal sync_conflict(slot: int)
signal slots_refreshed

const MAX_SLOTS := 3
const SESSION_PATH := "user://cloud_session.json"
const CACHE_ROOT := "user://cloud_cache"
const SYNC_RETRY_SECONDS := 10.0

var current_user := ""
var current_user_id := ""
var current_email := ""
var current_display_name := ""
var current_slot := -1
var access_token := ""
var refresh_token := ""
var access_token_expires_at := 0
var sync_status := "offline"

var _sync_retry_accumulator := 0.0
var _syncing_slots: Dictionary = {}
var _syncing_all := false


func _process(delta: float) -> void:
	if current_user_id.is_empty() or _syncing_all:
		return
	_sync_retry_accumulator += delta
	if _sync_retry_accumulator < SYNC_RETRY_SECONDS:
		return
	_sync_retry_accumulator = 0.0
	if _has_pending_sync():
		_sync_pending_slots()


func is_authenticated() -> bool:
	return not current_user_id.is_empty()


func is_cloud_configured() -> bool:
	return SupabaseClient.is_configured()


func register_user(display_name: String, email: String, password: String) -> String:
	display_name = display_name.strip_edges()
	email = email.strip_edges().to_lower()
	var validation_error := _validate_registration(display_name, email, password)
	if not validation_error.is_empty():
		return validation_error
	if not SupabaseClient.is_configured():
		return "Serviço online ainda não configurado."
	var response: Dictionary = await SupabaseClient.sign_up(display_name, email, password)
	if not bool(response.get("ok", false)):
		return _friendly_auth_error(str(response.get("error", "Não foi possível criar a conta.")))
	var data = response.get("data", {})
	if not data is Dictionary or str(data.get("access_token", "")).is_empty():
		return "Conta criada, mas o acesso imediato não está habilitado no Supabase."
	_apply_session(data, display_name)
	await SupabaseClient.create_profile(current_display_name, access_token)
	await refresh_slots()
	return ""


func login(email: String, password: String) -> String:
	email = email.strip_edges().to_lower()
	if not _is_valid_email(email) or password.is_empty():
		return "Informe um e-mail válido e a senha."
	if not SupabaseClient.is_configured():
		return "Serviço online ainda não configurado."
	var response: Dictionary = await SupabaseClient.sign_in(email, password)
	if not bool(response.get("ok", false)):
		return _friendly_auth_error(str(response.get("error", "Não foi possível entrar.")))
	var data = response.get("data", {})
	if not data is Dictionary:
		return "Resposta inválida do serviço online."
	_apply_session(data)
	await refresh_slots()
	return ""


func restore_session() -> bool:
	var saved_session := _read_json(SESSION_PATH)
	if saved_session.is_empty():
		return false
	_restore_local_session(saved_session)
	if current_user_id.is_empty():
		_clear_session_file()
		return false
	if not SupabaseClient.is_configured() or refresh_token.is_empty():
		_set_sync_status("offline")
		return true
	var response: Dictionary = await SupabaseClient.refresh_session(refresh_token)
	if bool(response.get("ok", false)) and response.get("data", {}) is Dictionary:
		_apply_session(response["data"], current_display_name)
		await refresh_slots()
		return true
	_set_sync_status("offline")
	return true


func logout() -> void:
	var token := access_token
	_reset_session()
	_clear_session_file()
	if not token.is_empty() and SupabaseClient.is_configured():
		await SupabaseClient.sign_out(token)


func get_slot_path(slot: int) -> String:
	return _user_cache_dir() + "/slot_%d.json" % slot


func slot_exists(slot: int) -> bool:
	var metadata := _read_sync_metadata(slot)
	return not bool(metadata.get("deleted", false)) and FileAccess.file_exists(get_slot_path(slot))


func get_slot_metadata(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var data := _read_json(get_slot_path(slot))
	if data.is_empty():
		return {}
	var sync_metadata := _read_sync_metadata(slot)
	return {
		"version": data.get("version", 0),
		"current_day": data.get("current_day", 1),
		"day_of_year": data.get("day_of_year", 1),
		"current_year": data.get("current_year", 2025),
		"cash_balance": data.get("cash_balance", 0.0),
		"herd_size": data.get("herd_size", 0),
		"herd_created": data.get("herd_created", false),
		"pending_sync": sync_metadata.get("pending_sync", false),
		"conflict": sync_metadata.get("conflict", false),
	}


func queue_slot_sync(slot: int, payload: Dictionary) -> void:
	if slot < 1 or slot > MAX_SLOTS or current_user_id.is_empty():
		return
	_ensure_user_cache_dir()
	_write_json(get_slot_path(slot), payload)
	var metadata := _read_sync_metadata(slot)
	metadata["pending_sync"] = true
	metadata["deleted"] = false
	metadata["conflict"] = false
	metadata["client_saved_at"] = _utc_now_iso()
	metadata["operation_id"] = str(Time.get_ticks_usec())
	_write_sync_metadata(slot, metadata)
	_set_sync_status("salvo_localmente")
	_sync_slot(slot)


func refresh_slots() -> void:
	if current_user_id.is_empty() or _syncing_all:
		return
	_syncing_all = true
	if not await _ensure_access_token():
		_syncing_all = false
		_set_sync_status("offline")
		slots_refreshed.emit()
		return
	_set_sync_status("sincronizando")
	var response: Dictionary = await SupabaseClient.list_saves(access_token)
	if not bool(response.get("ok", false)):
		_syncing_all = false
		_set_sync_status("offline")
		slots_refreshed.emit()
		return
	var rows = response.get("data", [])
	if rows is Array:
		for row in rows:
			if row is Dictionary:
				_merge_remote_slot(row)
	_syncing_all = false
	await _sync_pending_slots()
	if not _has_pending_sync():
		_set_sync_status("sincronizado")
	slots_refreshed.emit()


func delete_slot(slot: int) -> void:
	if slot < 1 or slot > MAX_SLOTS:
		return
	var metadata := _read_sync_metadata(slot)
	metadata["deleted"] = true
	metadata["pending_sync"] = true
	metadata["conflict"] = false
	metadata["operation_id"] = str(Time.get_ticks_usec())
	_write_sync_metadata(slot, metadata)
	_set_sync_status("salvo_localmente")
	await _sync_slot(slot)


func has_conflict(slot: int) -> bool:
	return bool(_read_sync_metadata(slot).get("conflict", false))


func resolve_conflict(slot: int, use_local: bool) -> void:
	var metadata := _read_sync_metadata(slot)
	if not bool(metadata.get("conflict", false)):
		return
	if use_local:
		metadata["revision"] = int(metadata.get("remote_revision", 0))
		metadata["pending_sync"] = true
		metadata["conflict"] = false
		_write_sync_metadata(slot, metadata)
		await _sync_slot(slot)
		return
	var cloud_path := _conflict_path(slot)
	var cloud_payload := _read_json(cloud_path)
	if not cloud_payload.is_empty():
		_write_json(get_slot_path(slot), cloud_payload)
	metadata["revision"] = int(metadata.get("remote_revision", 0))
	metadata["pending_sync"] = false
	metadata["conflict"] = false
	metadata["deleted"] = false
	_write_sync_metadata(slot, metadata)
	_remove_file(cloud_path)
	_set_sync_status("sincronizado")
	slots_refreshed.emit()


func has_any_save() -> bool:
	if current_user_id.is_empty():
		return false
	for slot in range(1, MAX_SLOTS + 1):
		if slot_exists(slot):
			return true
	return false


func _sync_pending_slots() -> void:
	if _syncing_all:
		return
	for slot in range(1, MAX_SLOTS + 1):
		var metadata := _read_sync_metadata(slot)
		if bool(metadata.get("pending_sync", false)) and not bool(metadata.get("conflict", false)):
			await _sync_slot(slot)


func _sync_slot(slot: int) -> void:
	if bool(_syncing_slots.get(slot, false)):
		return
	var metadata := _read_sync_metadata(slot)
	if not bool(metadata.get("pending_sync", false)) or bool(metadata.get("conflict", false)):
		return
	_syncing_slots[slot] = true
	var operation_id := str(metadata.get("operation_id", ""))
	if not await _ensure_access_token():
		_syncing_slots.erase(slot)
		_set_sync_status("offline")
		return
	_set_sync_status("sincronizando")
	if bool(metadata.get("deleted", false)):
		var delete_response: Dictionary = await SupabaseClient.delete_slot(
			slot,
			int(metadata.get("revision", 0)),
			access_token
		)
		_syncing_slots.erase(slot)
		if not bool(delete_response.get("ok", false)):
			_set_sync_status("offline")
			return
		var delete_rows = delete_response.get("data", [])
		if delete_rows is Array and not delete_rows.is_empty() and delete_rows[0] is Dictionary:
			var delete_result: Dictionary = delete_rows[0]
			if bool(delete_result.get("conflict", false)):
				var latest_conflict_metadata := _read_sync_metadata(slot)
				latest_conflict_metadata["conflict"] = true
				latest_conflict_metadata["remote_revision"] = int(delete_result.get("server_revision", 0))
				latest_conflict_metadata["remote_updated_at"] = str(delete_result.get("server_updated_at", ""))
				_write_json(_conflict_path(slot), delete_result.get("server_payload", {}))
				_write_sync_metadata(slot, latest_conflict_metadata)
				_set_sync_status("conflito")
				sync_conflict.emit(slot)
				return
		if delete_rows is Array:
			var latest_delete_metadata := _read_sync_metadata(slot)
			if (
				str(latest_delete_metadata.get("operation_id", "")) == operation_id
				and bool(latest_delete_metadata.get("deleted", false))
			):
				_remove_slot_files(slot)
				_set_sync_status("sincronizado")
				slots_refreshed.emit()
			else:
				latest_delete_metadata["revision"] = 0
				latest_delete_metadata["pending_sync"] = true
				_write_sync_metadata(slot, latest_delete_metadata)
				call_deferred("_sync_slot", slot)
		return
	var payload := _read_json(get_slot_path(slot))
	if payload.is_empty():
		_syncing_slots.erase(slot)
		return
	var response: Dictionary = await SupabaseClient.save_slot(
		slot,
		int(metadata.get("revision", 0)),
		int(payload.get("version", 1)),
		payload,
		str(metadata.get("client_saved_at", _utc_now_iso())),
		access_token
	)
	_syncing_slots.erase(slot)
	if not bool(response.get("ok", false)):
		_set_sync_status("offline")
		return
	var rows = response.get("data", [])
	if not rows is Array or rows.is_empty() or not rows[0] is Dictionary:
		_set_sync_status("offline")
		return
	var result: Dictionary = rows[0]
	if bool(result.get("conflict", false)):
		var latest_conflict_metadata := _read_sync_metadata(slot)
		latest_conflict_metadata["conflict"] = true
		latest_conflict_metadata["remote_revision"] = int(result.get("new_revision", 0))
		latest_conflict_metadata["remote_updated_at"] = str(result.get("server_updated_at", ""))
		_write_json(_conflict_path(slot), result.get("server_payload", {}))
		_write_sync_metadata(slot, latest_conflict_metadata)
		_set_sync_status("conflito")
		sync_conflict.emit(slot)
		return
	var latest_metadata := _read_sync_metadata(slot)
	latest_metadata["revision"] = int(result.get(
		"new_revision",
		int(metadata.get("revision", 0)) + 1
	))
	latest_metadata["conflict"] = false
	latest_metadata["updated_at"] = str(result.get("server_updated_at", ""))
	if str(latest_metadata.get("operation_id", "")) == operation_id:
		latest_metadata["pending_sync"] = false
		_write_sync_metadata(slot, latest_metadata)
		_set_sync_status("sincronizado")
	else:
		latest_metadata["pending_sync"] = true
		_write_sync_metadata(slot, latest_metadata)
		call_deferred("_sync_slot", slot)


func _merge_remote_slot(row: Dictionary) -> void:
	var slot := int(row.get("slot", 0))
	if slot < 1 or slot > MAX_SLOTS:
		return
	var remote_revision := int(row.get("revision", 0))
	var remote_payload = row.get("payload", {})
	if not remote_payload is Dictionary:
		return
	var metadata := _read_sync_metadata(slot)
	var local_revision := int(metadata.get("revision", 0))
	if bool(metadata.get("pending_sync", false)):
		if remote_revision > local_revision:
			metadata["conflict"] = true
			metadata["remote_revision"] = remote_revision
			metadata["remote_updated_at"] = str(row.get("updated_at", ""))
			_write_json(_conflict_path(slot), remote_payload)
			_write_sync_metadata(slot, metadata)
			_set_sync_status("conflito")
			sync_conflict.emit(slot)
		return
	if remote_revision >= local_revision:
		_write_json(get_slot_path(slot), remote_payload)
		metadata["revision"] = remote_revision
		metadata["pending_sync"] = false
		metadata["deleted"] = false
		metadata["conflict"] = false
		metadata["updated_at"] = str(row.get("updated_at", ""))
		_write_sync_metadata(slot, metadata)


func _ensure_access_token() -> bool:
	if current_user_id.is_empty() or not SupabaseClient.is_configured():
		return false
	var now := int(Time.get_unix_time_from_system())
	if not access_token.is_empty() and access_token_expires_at > now + 30:
		return true
	if refresh_token.is_empty():
		return false
	var response: Dictionary = await SupabaseClient.refresh_session(refresh_token)
	if not bool(response.get("ok", false)) or not response.get("data", {}) is Dictionary:
		return false
	_apply_session(response["data"], current_display_name)
	return not access_token.is_empty()


func _apply_session(data: Dictionary, fallback_display_name: String = "") -> void:
	var user_data = data.get("user", {})
	if not user_data is Dictionary:
		user_data = {}
	var metadata = user_data.get("user_metadata", {})
	if not metadata is Dictionary:
		metadata = {}
	current_user_id = str(user_data.get("id", current_user_id))
	current_email = str(user_data.get("email", current_email))
	current_display_name = str(metadata.get("display_name", fallback_display_name)).strip_edges()
	if current_display_name.is_empty():
		current_display_name = current_email.get_slice("@", 0)
	current_user = current_display_name
	access_token = str(data.get("access_token", access_token))
	refresh_token = str(data.get("refresh_token", refresh_token))
	access_token_expires_at = int(data.get(
		"expires_at",
		int(Time.get_unix_time_from_system()) + int(data.get("expires_in", 3600))
	))
	_write_session()


func _restore_local_session(data: Dictionary) -> void:
	current_user_id = str(data.get("user_id", ""))
	current_email = str(data.get("email", ""))
	current_display_name = str(data.get("display_name", ""))
	current_user = current_display_name
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	access_token_expires_at = int(data.get("expires_at", 0))


func _write_session() -> void:
	_write_json(SESSION_PATH, {
		"user_id": current_user_id,
		"email": current_email,
		"display_name": current_display_name,
		"access_token": access_token,
		"refresh_token": refresh_token,
		"expires_at": access_token_expires_at,
	})


func _reset_session() -> void:
	current_user = ""
	current_user_id = ""
	current_email = ""
	current_display_name = ""
	current_slot = -1
	access_token = ""
	refresh_token = ""
	access_token_expires_at = 0
	_set_sync_status("offline")


func _validate_registration(display_name: String, email: String, password: String) -> String:
	if display_name.length() < 2 or display_name.length() > 60:
		return "Informe um nome entre 2 e 60 caracteres."
	if not _is_valid_email(email):
		return "Informe um e-mail válido."
	if password.length() < 6:
		return "A senha deve ter pelo menos 6 caracteres."
	return ""


func _is_valid_email(email: String) -> bool:
	var at_position := email.find("@")
	return at_position > 0 and email.find(".", at_position) > at_position + 1


func _friendly_auth_error(error: String) -> String:
	var normalized := error.to_lower()
	if "invalid login credentials" in normalized:
		return "E-mail ou senha incorretos."
	if "already registered" in normalized or "already been registered" in normalized:
		return "Já existe uma conta com este e-mail."
	if "password" in normalized and "characters" in normalized:
		return "A senha não atende aos requisitos de segurança."
	if "network" in normalized or "conexão" in normalized or "indisponível" in normalized:
		return "Serviço online indisponível. Tente novamente."
	return error


func _user_cache_dir() -> String:
	var safe_user_id := current_user_id if not current_user_id.is_empty() else "sem_sessao"
	return "%s/%s" % [CACHE_ROOT, safe_user_id]


func _ensure_user_cache_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_user_cache_dir()))


func _sync_metadata_path(slot: int) -> String:
	return _user_cache_dir() + "/slot_%d.sync.json" % slot


func _conflict_path(slot: int) -> String:
	return _user_cache_dir() + "/slot_%d.cloud.json" % slot


func _read_sync_metadata(slot: int) -> Dictionary:
	var data := _read_json(_sync_metadata_path(slot))
	if data.is_empty():
		return {
			"revision": 0,
			"pending_sync": false,
			"deleted": false,
			"conflict": false,
		}
	return data


func _write_sync_metadata(slot: int, metadata: Dictionary) -> void:
	_ensure_user_cache_dir()
	_write_json(_sync_metadata_path(slot), metadata)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _write_json(path: String, data: Dictionary) -> bool:
	var directory := path.get_base_dir()
	if not directory.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	return true


func _remove_slot_files(slot: int) -> void:
	_remove_file(get_slot_path(slot))
	_remove_file(_sync_metadata_path(slot))
	_remove_file(_conflict_path(slot))


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _clear_session_file() -> void:
	_remove_file(SESSION_PATH)


func _has_pending_sync() -> bool:
	for slot in range(1, MAX_SLOTS + 1):
		if bool(_read_sync_metadata(slot).get("pending_sync", false)):
			return true
	return false


func _utc_now_iso() -> String:
	return Time.get_datetime_string_from_system(true, true).replace(" ", "T") + "Z"


func _set_sync_status(status: String) -> void:
	if sync_status == status:
		return
	sync_status = status
	sync_status_changed.emit(status)
