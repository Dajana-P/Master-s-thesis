extends Control

# Database URL = Firestore project ID se koristi kasnije
const API_KLJUC = "AIzaSyDYVrUP0sos6unp0gGDb5Pia3C67dXCfoM"
const URL_PRIJAVA = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + API_KLJUC

@onready var email_polje = $VBoxContainer/EmailPolje
@onready var lozinka_polje = $VBoxContainer/LozinkaPolje
@onready var dugme_prijava = $VBoxContainer/PrijavaDugme
@onready var dugme_registracija = $VBoxContainer/DugmeRegistrujSe
@onready var upozorenje_email = $VBoxContainer/UpozorenjeEmail
@onready var upozorenje_lozinka = $VBoxContainer/UpozorenjeLozinka

func _obradi_odgovor_prijave(status, kod, zaglavlja, telo):
	var odgovor = JSON.parse_string(telo.get_string_from_utf8())
	if odgovor.has("localId") and odgovor.has("idToken"):
		Podaci.korisnik_uid = odgovor["localId"]
		Podaci.id_token = odgovor["idToken"]
		print("Prijava uspešna! UID:", Podaci.korisnik_uid)
		MenadzerStranica.promeni_stranicu("res://Scenes/EdukativnaStrana1.tscn")
	else:
		print("Greška pri prijavi:", odgovor)
		if odgovor.has("error"):
			print("Poruka:", odgovor["error"]["message"])

func _on_prijava_dugme_pressed() -> void:
	var email = email_polje.text
	var lozinka = lozinka_polje.text
	
	if email == "":
		upozorenje_email.text = "Email ne sme biti prazan!"
		return
		
	if lozinka == "":
		upozorenje_lozinka.text = "Lozinka ne sme biti prazna!"
		return
	
	var telo = {
		"email": email,
		"password": lozinka,
		"returnSecureToken": true
	}
	
	var zahtev = HTTPRequest.new()
	add_child(zahtev)
	zahtev.request(URL_PRIJAVA, [], HTTPClient.METHOD_POST, JSON.stringify(telo))
	zahtev.connect("request_completed", Callable(self, "_obradi_odgovor_prijave"))

func _on_registruj_se_dugme_pressed() -> void:
	MenadzerStranica.promeni_stranicu("res://Scenes/Registracija.tscn")


func _on_izadji_pressed() -> void:
	get_tree().quit()
