extends Control

const PROJECT_ID = "anketa-mfip"

@onready var naslov = find_child("Naslov")
@onready var sadrzaj = find_child("Sadrzaj")
@onready var ocena = find_child("Ocena")
@onready var dugme_dalje = find_child("DugmeDalje")
@onready var ocena_broj = find_child("OcenaBroj")
@onready var odgovor1 = find_child("Odgovor1")
@onready var odgovor2 = find_child("Odgovor2")
@onready var odgovor3 = find_child("Odgovor3")
@onready var odgovor4 = find_child("Odgovor4")
@onready var label = find_child("Label")

var broj_strane = 15
var tacni_odgovor: Button

func _ready():
	var cvorovi = {
		"naslov": naslov,
		"ocena": ocena,
		"dugme_dalje": dugme_dalje,
		"ocena_broj": ocena_broj,
		"label": label,
		"odgovor1": odgovor1,
		"odgovor2": odgovor2,
		"odgovor3": odgovor3,
		"odgovor4": odgovor4
	}

	for ime in cvorovi.keys():
		if cvorovi[ime] == null:
			print("Čvor nije pronađen:", ime)
		else:
			print("Čvor pronađen:", ime)
	
	# Definiši koji je tačan odgovor
	tacni_odgovor = odgovor2  # primer

	# Poveži dugmad
	for btn in [odgovor1, odgovor2, odgovor3, odgovor4]:
		btn.pressed.connect(Callable(self, "_on_odgovor_pressed").bind(btn))

	# Dugme dalje
	if dugme_dalje:
		dugme_dalje.pressed.connect(Callable(self, "_on_DugmeDalje_pressed"))


func _on_odgovor_pressed(dugme: Button) -> void:
	# Onemogući sva dugmad
	for btn in [odgovor1, odgovor2, odgovor3, odgovor4]:
		btn.disabled = true

	if dugme == tacni_odgovor:
		# Ako je tačan odgovor kliknut
		for btn in [odgovor1, odgovor2, odgovor3, odgovor4]:
			if btn == tacni_odgovor:
				btn.text = "Tacno"
			else:
				btn.text = "Netacno"
	else:
		# Ako je kliknut pogrešan
		for btn in [odgovor1, odgovor2, odgovor3, odgovor4]:
			if btn == tacni_odgovor:
				btn.text = "Tacno"
			else:
				btn.text = "Netacno"


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
		get_tree().change_scene_to_file("res://Scenes/EdukativnaStrana16.tscn")


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
