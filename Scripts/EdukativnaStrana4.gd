extends Control

const PROJECT_ID = "anketa-mfip"

# Pronalazimo čvorove u hijerarhiji
@onready var naslov = find_child("Naslov")
@onready var sadrzaj = find_child("Sadrzaj")
@onready var ocena = find_child("Ocena")
@onready var dugme_dalje = find_child("DugmeDalje")
@onready var ocena_broj = find_child("OcenaBroj")
@onready var povecaj = find_child("Povecaj")
@onready var smanji = find_child("Smanji")

var broj_strane = 4
var velicina_fonta = 14 # inicijalna vrednost fonta
var font_resurs = "res://Fonts/SomeFont.ttf" # ubaci svoj font fajl ovde

func _ready():
	# Provera da li su čvorovi pronađeni
	var cvorovi = {
		"naslov": naslov,
		"sadrzaj": sadrzaj,
		"ocena": ocena,
		"dugme_dalje": dugme_dalje,
		"ocena_broj": ocena_broj,
		"povecaj": povecaj,
		"smanji": smanji
	}

	for ime in cvorovi.keys():
		if cvorovi[ime] == null:
			print("Čvor nije pronađen:", ime)
		else:
			print("Čvor pronađen:", ime)

	# Povezivanje slidera sa funkcijom koja menja labelu
	if ocena and ocena_broj:
		var c = Callable(self, "_on_ocena_value_changed")
		if not ocena.is_connected("value_changed", c):
			ocena.connect("value_changed", c)
		_on_ocena_value_changed(ocena.value)

	# Povezivanje dugmeta dalje
	if dugme_dalje:
		var c2 = Callable(self, "_on_DugmeDalje_pressed")
		if not dugme_dalje.is_connected("pressed", c2):
			dugme_dalje.connect("pressed", c2)

	# Podesimo inicijalni font
	_update_font()

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
		get_tree().change_scene_to_file("res://Scenes/EdukativnaStrana5.tscn")


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

func _on_smanji_pressed() -> void:
	velicina_fonta = max(8, velicina_fonta - 1)
	_update_font()

func _on_povecaj_pressed() -> void:
	velicina_fonta = min(72, velicina_fonta + 1)
	_update_font()

func _update_font() -> void:
	if sadrzaj:
		# Podesimo veličinu fonta kroz theme override
		sadrzaj.add_theme_font_size_override("normal_font_size", velicina_fonta)
