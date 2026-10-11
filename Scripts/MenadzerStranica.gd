extends Node

var sadrzaji = {
	1: "Kratki tekst sa manjim fontom.",
	2: "Dugačak tekst.",
	3: "Unos teksta.",
	4: "Manipulacija velicine teksta.",
	5: "Brojac karaktera unetog teksta.",
	6: "Klik na dugme.",
	7: "Klik na dugme koje menja boju polja random bojom.",
	8: "Colorpicker dugme.",
	9: "Slika edukativnog karaktera.",
	10: "Slika i zvuk.",
	11: "Video bez zvuka.",
	12: "Video sa zvukom.",
	13: "Pesma sa podesavanjima",
	14: "Video sa podesavanjima",
	15: "Kviz pitanje.",
	16: "Iks oks.",
	17: "Animacija loptice koja odskace.",
}

func dohvati_sadrzaj(broj: int) -> String:
	return sadrzaji.get(broj, "Nema sadržaja")
	
func promeni_stranicu(putanja: String) -> void:
	if ResourceLoader.exists(putanja):
		get_tree().change_scene_to_file(putanja)
	else:
		print("Stranica ne postoji:", putanja)

func info(prikaz: bool, prozor: Window) -> void:
	if prozor == null:
		print("Greška: prozor nije prosleđen funkciji info().")
		return

	if prikaz:
		if not prozor.visible:
			prozor.show()
			print("Info prozor prikazan.")
	else:
		if prozor.visible:
			prozor.hide()
			print("Info prozor sakriven.")
