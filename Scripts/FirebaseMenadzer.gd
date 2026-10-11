extends Node

const PROJECT_ID = "anketa-mfip"

# Kreira korisnika prvi put u Firestore ako dokument ne postoji
func kreiraj_korisnika(uid: String, id_token: String) -> void:
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/korisnici/%s" % [PROJECT_ID, uid]
	var body = {"fields": {}}
	var zahtev = HTTPRequest.new()
	add_child(zahtev)
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	]
	zahtev.request(url, headers, HTTPClient.METHOD_PUT, JSON.stringify(body))
	zahtev.connect("request_completed", Callable(self, "_on_request_completed"))

# Čuva ocenu (PATCH) u Firestore
func sacuvaj_ocenu_firestore(uid: String, strana: String, ocena: int, id_token: String) -> void:
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/korisnici/%s?currentDocument.exists=true" % [PROJECT_ID, uid]

	var body = {
		"fields": {
			strana: {"integerValue": ocena}
		}
	}

	var zahtev = HTTPRequest.new()
	add_child(zahtev)

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	]

	var query_params = "?updateMask.fieldPaths=" + strana
	zahtev.request("https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/korisnici/%s%s" % [PROJECT_ID, uid, query_params],
		headers,
		HTTPClient.METHOD_PATCH,
		JSON.stringify(body)
	)
	zahtev.connect("request_completed", Callable(self, "_on_request_completed"))


func _on_request_completed(result, response_code, headers, body):
	if response_code >= 200 and response_code < 300:
		print("Operacija uspešna!")
	else:
		print("Greška:", response_code, body.get_string_from_utf8())
