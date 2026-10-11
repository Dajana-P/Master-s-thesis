extends Control

const API_KLJUC = "AIzaSyDYVrUP0sos6unp0gGDb5Pia3C67dXCfoM"
const URL_REGISTRACIJA = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + API_KLJUC

@onready var email_polje = $VBoxContainer/EmailPolje
@onready var lozinka_polje = $VBoxContainer/LozinkaPolje
@onready var lozinka_potvrda_polje = $VBoxContainer/LozinkaPotvrdaPolje

@onready var upozorenje_email = $VBoxContainer/UpozorenjeEmail
@onready var upozorenje_lozinka = $VBoxContainer/UpozorenjeLozinka

func _obradi_odgovor_registracije(status, kod, zaglavlja, telo):
	var odgovor = JSON.parse_string(telo.get_string_from_utf8())
	if odgovor.has("localId"):
		Podaci.korisnik_uid = odgovor["localId"]
		print("Registracija uspešna! UID:", Podaci.korisnik_uid)
		MenadzerStranica.promeni_stranicu("res://Scenes/Login.tscn")
	else:
		print("Greška pri registraciji:", odgovor)


func _on_registruj_se_dugme_pressed() -> void:
	if(email_polje.text == ""):
		upozorenje_email.text = "Email ne sme biti prazan!"
		return
		
	if(!lozinka_polje || !lozinka_potvrda_polje):
		upozorenje_lozinka.text = "Oba polja za lozinku moraju biti popunjena!"
		return
	
	var email = email_polje.text
	var lozinka = lozinka_polje.text
	
	var telo = {
		"email": email,
		"password": lozinka,
		"returnSecureToken": true
	}
	
	var zahtev = HTTPRequest.new()
	add_child(zahtev)
	zahtev.request(URL_REGISTRACIJA, [], HTTPClient.METHOD_POST, JSON.stringify(telo))
	zahtev.connect("request_completed", Callable(self, "_obradi_odgovor_registracije"))


func _on_prijavi_se_dugme_pressed() -> void:
	MenadzerStranica.promeni_stranicu("res://Scenes/Login.tscn")
