extends Control

const PROJECT_ID = "anketa-mfip"

@onready var naslov = find_child("Naslov")
@onready var ocena = find_child("Ocena")
@onready var dugme_dalje = find_child("DugmeDalje")
@onready var ocena_broj = find_child("OcenaBroj")
@onready var label = find_child("Label")

@onready var audio_player = find_child("AudioStreamPlayer")
@onready var play_pause = find_child("PlayPause")
@onready var replay = find_child("Replay")
@onready var mute = find_child("Mute")
@onready var volume_slider = find_child("Volume")

var broj_strane = 13
var je_pusteno = false
var prethodna_jacina = 0.0
var poslednja_pozicija: float = 0.0


func _ready():
	var cvorovi = {
		"naslov": naslov,
		"ocena": ocena,
		"dugme_dalje": dugme_dalje,
		"ocena_broj": ocena_broj,
		"label": label,
		"audio_player": audio_player,
		"play_pause": play_pause,
		"replay": replay,
		"mute": mute,
		"volume_slider": volume_slider
	}

	for ime in cvorovi.keys():
		if cvorovi[ime] == null:
			print("Čvor nije pronađen:", ime)
		else:
			print("Čvor pronađen:", ime)

	# Ocena slider
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

	# Play/Pause
	if play_pause:
		var c3 = Callable(self, "_on_PlayPause_pressed")
		if not play_pause.is_connected("pressed", c3):
			play_pause.connect("pressed", c3)

	# Replay
	if replay:
		var c4 = Callable(self, "_on_Replay_pressed")
		if not replay.is_connected("pressed", c4):
			replay.connect("pressed", c4)

	# Mute
	if mute:
		var c5 = Callable(self, "_on_Mute_toggled")
		if not mute.is_connected("toggled", c5):
			mute.connect("toggled", c5)

	# Volume slider
	if volume_slider:
		var c6 = Callable(self, "_on_Volume_value_changed")
		if not volume_slider.is_connected("value_changed", c6):
			volume_slider.connect("value_changed", c6)

		# Inicijalno postavi slider na maksimum
		volume_slider.value = 100
		_on_Volume_value_changed(volume_slider.value)

	# Kad se audio završi, resetuj stanje
	if audio_player:
		audio_player.connect("finished", Callable(self, "_on_Audio_finished"))


# --- AUDIO KONTROLE ---

func _on_PlayPause_pressed() -> void:
	if not audio_player:
		return

	if je_pusteno:
		# Pauziraj — zapamti poziciju
		poslednja_pozicija = audio_player.get_playback_position()
		audio_player.stop()
		play_pause.text = "▶️"
	else:
		# Nastavi od pozicije
		audio_player.play(poslednja_pozicija)
		play_pause.text = "❚❚"

	je_pusteno = !je_pusteno


func _on_Replay_pressed() -> void:
	if audio_player:
		audio_player.stop()
		audio_player.play()
		play_pause.text = "❚❚"
		poslednja_pozicija = 0.0
		je_pusteno = true


func _on_Mute_toggled(checked: bool) -> void:
	if audio_player:
		if checked:
			prethodna_jacina = audio_player.volume_db
			audio_player.volume_db = -80 # tišina
		else:
			audio_player.volume_db = prethodna_jacina


func _on_Volume_value_changed(vrednost: float) -> void:
	if audio_player:
		# 0–100 → -60 do 0 dB (postepeno od tišine do punog zvuka)
		var db = lerp(-80.0, 0.0, vrednost / 100.0)
		audio_player.volume_db = db
		prethodna_jacina = db


func _on_Audio_finished() -> void:
	play_pause.text = "▶️"
	je_pusteno = false
	poslednja_pozicija = 0.0


# --- OCENA ---

func _on_ocena_value_changed(vrednost: float) -> void:
	if ocena_broj:
		ocena_broj.text = str(int(vrednost))


# --- DALJE DUGME ---

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
		get_tree().change_scene_to_file("res://Scenes/EdukativnaStrana14.tscn")


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
