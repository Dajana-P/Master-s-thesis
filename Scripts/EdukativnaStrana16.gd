extends Control

const PROJECT_ID = "anketa-mfip"

@onready var naslov = find_child("Naslov")
@onready var ocena = find_child("Ocena")
@onready var dugme_dalje = find_child("DugmeDalje")
@onready var ocena_broj = find_child("OcenaBroj")
@onready var polje11 = find_child("Polje11")
@onready var polje21 = find_child("Polje21")
@onready var polje31 = find_child("Polje31")
@onready var polje12 = find_child("Polje12")
@onready var polje22 = find_child("Polje22")
@onready var polje32 = find_child("Polje32")
@onready var polje13 = find_child("Polje13")
@onready var polje23 = find_child("Polje23")
@onready var polje33 = find_child("Polje33")
@onready var reset = find_child("Reset")
@onready var label = find_child("Label")

var broj_strane = 16
var board = ["","","","","","","","",""] # tabla 0–8
var polja = []
var igra_zavrsena = false

func _ready():
	polja = [polje11, polje12, polje13, polje21, polje22, polje23, polje31, polje32, polje33]

	var cvorovi = {
		"naslov": naslov,
		"ocena": ocena,
		"dugme_dalje": dugme_dalje,
		"ocena_broj": ocena_broj,
		"label": label,
		"polje11": polje11,
		"polje12": polje12,
		"polje13": polje13,
		"polje21": polje21,
		"polje22": polje22,
		"polje23": polje23,
		"polje31": polje31,
		"polje32": polje32,
		"polje33": polje33,
		"reset": reset
	}

	for ime in cvorovi.keys():
		if cvorovi[ime] == null:
			print("Čvor nije pronađen:", ime)
		else:
			print("Čvor pronađen:", ime)

	for i in range(9):
		polja[i].pressed.connect(Callable(self, "_on_polje_pressed").bind(i))

	if reset:
		reset.pressed.connect(Callable(self, "_on_reset_pressed"))

	if dugme_dalje:
		dugme_dalje.pressed.connect(Callable(self, "_on_DugmeDalje_pressed"))

	label.text = "Na potezu: X"


func _on_polje_pressed(index):
	if igra_zavrsena or board[index] != "":
		return

	# Igrac X
	board[index] = "X"
	polja[index].text = "X"
	polja[index].modulate = Color(0.8, 0.8, 0.8) # tamno sivo za X

	if _check_winner("X"):
		label.text = "Iks (X) je pobedio!"
		igra_zavrsena = true
		return

	# Potez kompjutera O
	_potez_komp()

	if _check_winner("O"):
		label.text = "Oks (O) je pobedio!"
		igra_zavrsena = true
		return

	if not board.has(""):
		label.text = "Nereseno!"
		igra_zavrsena = true


func _potez_komp():
	# 1. Probaj da pobedis
	for i in range(9):
		if board[i] == "":
			board[i] = "O"
			if _check_winner("O"):
				polja[i].text = "O"
				polja[i].modulate = Color(0.8, 0.8, 0.8) # svetlije sivo za O
				return
			board[i] = ""

	# 2. Blokiraj X ako preti da pobedi
	for i in range(9):
		if board[i] == "":
			board[i] = "X"
			if _check_winner("X"):
				board[i] = "O"
				polja[i].text = "O"
				polja[i].modulate = Color(0.8, 0.8, 0.8)
				return
			board[i] = ""

	# 3. Zauzmi centar ako je slobodan
	if board[4] == "":
		board[4] = "O"
		polja[4].text = "O"
		polja[4].modulate = Color(0.8, 0.8, 0.8)
		return

	# 4. Zauzmi prvo slobodno polje
	for i in range(9):
		if board[i] == "":
			board[i] = "O"
			polja[i].text = "O"
			polja[i].modulate = Color(0.8, 0.8, 0.8)
			return


func _check_winner(simbol):
	var lines = [
		[0,1,2],[3,4,5],[6,7,8],
		[0,3,6],[1,4,7],[2,5,8],
		[0,4,8],[2,4,6]
	]
	for line in lines:
		if board[line[0]] == simbol and board[line[1]] == simbol and board[line[2]] == simbol:
			return true
	return false


func _on_reset_pressed():
	board = ["","","","","","","","",""]
	igra_zavrsena = false
	label.text = "Na potezu: X"
	for btn in polja:
		btn.text = ""
		btn.modulate = Color(1,1,1) # vraca se na belo


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
		get_tree().change_scene_to_file("res://Scenes/EdukativnaStrana17.tscn")


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
