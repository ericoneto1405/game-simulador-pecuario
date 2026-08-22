extends Node

const CONFIG_PATH := "res://config/supabase.json"

var base_url := ""
var publishable_key := ""


func _ready() -> void:
	_load_config()


func _load_config() -> void:
	base_url = OS.get_environment("SUPABASE_URL").strip_edges().trim_suffix("/")
	publishable_key = OS.get_environment("SUPABASE_PUBLISHABLE_KEY").strip_edges()
	if not base_url.is_empty() and not publishable_key.is_empty():
		return
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		base_url = str(parsed.get("url", "")).strip_edges().trim_suffix("/")
		publishable_key = str(parsed.get("publishable_key", "")).strip_edges()


func is_configured() -> bool:
	return base_url.begins_with("https://") and not publishable_key.is_empty()


func sign_up(display_name: String, email: String, password: String) -> Dictionary:
	return await _request(
		HTTPClient.METHOD_POST,
		"/auth/v1/signup",
		{"email": email, "password": password, "data": {"display_name": display_name}}
	)


func sign_in(email: String, password: String) -> Dictionary:
	return await _request(
		HTTPClient.METHOD_POST,
		"/auth/v1/token?grant_type=password",
		{"email": email, "password": password}
	)


func refresh_session(refresh_token: String) -> Dictionary:
	return await _request(
		HTTPClient.METHOD_POST,
		"/auth/v1/token?grant_type=refresh_token",
		{"refresh_token": refresh_token}
	)


func sign_out(access_token: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/auth/v1/logout", {}, access_token)


func create_profile(display_name: String, access_token: String) -> Dictionary:
	return await _request(
		HTTPClient.METHOD_POST,
		"/rest/v1/rpc/create_own_profile",
		{"p_display_name": display_name},
		access_token
	)


func list_saves(access_token: String) -> Dictionary:
	return await _request(
		HTTPClient.METHOD_GET,
		"/rest/v1/game_saves?select=slot,save_version,revision,payload,updated_at&order=slot.asc",
		{},
		access_token
	)


func save_slot(
	slot: int,
	expected_revision: int,
	save_version: int,
	payload: Dictionary,
	client_saved_at: String,
	access_token: String
) -> Dictionary:
	return await _request(
		HTTPClient.METHOD_POST,
		"/rest/v1/rpc/save_game_slot",
		{
			"p_slot": slot,
			"p_expected_revision": expected_revision,
			"p_save_version": save_version,
			"p_payload": payload,
			"p_client_saved_at": client_saved_at,
		},
		access_token
	)


func delete_slot(slot: int, expected_revision: int, access_token: String) -> Dictionary:
	return await _request(
		HTTPClient.METHOD_POST,
		"/rest/v1/rpc/delete_game_slot",
		{"p_slot": slot, "p_expected_revision": expected_revision},
		access_token
	)


func _request(
	method: HTTPClient.Method,
	path: String,
	body: Dictionary = {},
	access_token: String = ""
) -> Dictionary:
	if not is_configured():
		return {"ok": false, "offline": true, "error": "Supabase não configurado."}
	var request := HTTPRequest.new()
	request.timeout = 15.0
	add_child(request)
	var headers := PackedStringArray([
		"apikey: %s" % publishable_key,
		"Content-Type: application/json",
	])
	if not access_token.is_empty():
		headers.append("Authorization: Bearer %s" % access_token)
	var serialized_body := "" if method == HTTPClient.METHOD_GET else JSON.stringify(body)
	var start_error := request.request(base_url + path, headers, method, serialized_body)
	if start_error != OK:
		request.queue_free()
		return {"ok": false, "offline": true, "error": "Serviço indisponível."}
	var completed: Array = await request.request_completed
	request.queue_free()
	var result_code := int(completed[0])
	var response_code := int(completed[1])
	var response_body: PackedByteArray = completed[3]
	var response_text := response_body.get_string_from_utf8()
	var parsed = JSON.parse_string(response_text) if not response_text.is_empty() else {}
	if result_code != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "offline": true, "error": "Sem conexão com a nuvem."}
	if response_code < 200 or response_code >= 300:
		var message := "Erro no serviço online."
		if parsed is Dictionary:
			message = str(parsed.get("msg", parsed.get("message", parsed.get("error_description", message))))
		return {"ok": false, "status": response_code, "error": message, "data": parsed}
	return {"ok": true, "status": response_code, "data": parsed}
