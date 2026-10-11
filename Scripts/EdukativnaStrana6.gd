extends Control

const PROJECT_ID = "anketa-mfip"

@onready var naslov = find_child("Naslov")
@onready var ocena = find_child("Ocena")
@onready var dugme_dalje = find_child("DugmeDalje")
@onready var ocena_broj = find_child("OcenaBroj")
@onready var brojac_klikova = find_child("BrojacKlikova")
@onready var button = find_child("Button")
@onready var label = find_child("Label")

var broj_strane = 6

var broj_klikova = 0

func _ready():
	var cvorovi = {
		"naslov": naslov,
		"ocena": ocena,
		"dugme_dalje": dugme_dalje,
		"ocena_broj": ocena_broj,
		"brojac_klikova": brojac_klikova,
		"button": button,
		"label": label
	}

	for ime in cvorovi.keys():
		if cvorovi[ime] == null:
			print("Čvor nije pronađen:", ime)
		else:
			print("Čvor pronađen:", ime)

	# Slider → Labela
	if ocena and ocena_broj:
		var c = Callable(self, "_on_ocena_value_changed")
		if not ocena.is_connected("value_changed", c):
			ocena.connect("value_changed", c)
		_on_ocena_value_changed(ocena.value)

	# Dugme dalje
	if dugme_dalje:
		var c2 = Callable(self, "_on_DugmeDalje_pressed")
		if not dugme_dalje.is_connected("pressed", c2):
			dugme_dalje.connect("pressed", c2)

	# Dugme za LineEdit → Label
	if button:
		var c3 = Callable(self, "_on_button_pressed")
		if not button.is_connected("pressed", c3):
			button.connect("pressed", c3)

func _on_ocena_value_changed(vrednost: float) -> void:
	if ocena_broj:
		ocena_broj.text = str(int(vrednost))

func _on_DugmeDalje_pressed() -> void:
	if ocena:
		var vrednost = int(ocena.value)
		if ocena_broj:
			ocena_broj.text = str(vrednost)
		
		# Čuvanje ocene u Firestore
		if Podaci.id_token != "":
			FirebaseMenadzer.sacuvaj_ocenu_firestore(
				Podaci.korisnik_uid,
				"strana_" + str(broj_strane),
				vrednost,
				Podaci.id_token
			)
		else:
			print("ID token nije postavljen, prijavite se prvo!")

		broj_strane += 1
		get_tree().change_scene_to_file("res://Scenes/EdukativnaStrana7.tscn")


# Firestore PATCH funkcija
func sacuvaj_ocenu_firestore(uid: String, strana: String, ocena: int, id_token: String) -> void:
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/korisnici/%s" % [PROJECT_ID, uid]

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

	# PATCH bez exists=true: kreira dokument ako ne postoji
	zahtev.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(body))
	zahtev.connect("request_completed", Callable(self, "_on_request_completed"))

func _on_button_pressed() -> void:
	broj_klikova += 1
	if brojac_klikova:
		brojac_klikova.text = str(broj_klikova)
