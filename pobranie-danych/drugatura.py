from bs4 import BeautifulSoup
import re
import urllib
import urllib.request
import sys

baseUrl = "http://prezydent2015.pkw.gov.pl"

outObwody = "obwody.csv"
outProt   = "protokoly.csv"
outWyniki = "wyniki.csv"

#http://www.crummy.com/software/BeautifulSoup/bs4/doc/#a-string

def quoteItem(text):
	return(text.replace("\r\n"," ").replace("\r"," ").replace("\n"," ").replace('"','\\"').replace(';','\;'))
		
def quoteForCSV(data):
	return([quoteItem(item) for item in data])

def is_the_only_string_within_a_tag(s):
    """Return True if this string is the only child of its parent tag."""
    return (s == s.parent.string)

def parseObwod(obwodfile,obwodadres):
	obwodid = re.search("/(\d+)$",obwodfile.url).group(1)
	print("      Obwod: "+obwodid)
	soupobwod = BeautifulSoup(obwodfile)
	for karty in soupobwod.find_all("div",class_="kom_karta_box"):
		# czy rozliczenie kart?
		if karty.find_all("div",text="Rozliczenie kart do głosowania"):
#			print("rozliczenie"+karty.text)
			prot1=[x for x in karty.find_all(text=is_the_only_string_within_a_tag) if x!='\n' and x!="Rozliczenie kart do głosowania"]
		# nie, czy ustalenie wynikow?
		elif karty.find_all("div",text="Ustalenie wyników głosowania"):
			prot2=[x for x in karty.find_all(text=is_the_only_string_within_a_tag) if x!='\n' and x!="Ustalenie wyników głosowania"]
#			print("ustalenie"+karty.text)
		else:
		# nie, czyli nagłówek
#			print("nagłówek"+karty.text)
			obwodinfo = ['id',obwodid,'nazwa']+karty.find_all(text=is_the_only_string_within_a_tag)
			# bez adresu, niepotrzebny
			obwodinfo = [x for x in obwodinfo if x!="Adres"] + ["Adres",obwodadres]
			# przeplatanka co drugiego elementu, tuple <klucz>,<wartosc>
#			obwodinfo = zip(obwodinfo[0::2],obwodinfo[1::2])
			# ..aaalbo zapisac tylko wartosci
			outObwodyFile.write(";".join(quoteForCSV(obwodinfo[1::2]))+"\n")
#			print(obwodinfo)
	# zapisac protokół
	prot = prot1+prot2
	# przeplatac trójki elementów z pominięciem środkowego (nazwa pola) - potrzeba tylko id i wartość
	prot = zip(prot[0::3],prot[2::3])
#	print(prot)
	for item in prot:
		outProtFile.write(obwodid+";"+";".join(item)+"\n")	# wyniki wyborów w tabeli

	# wynik głosowania
	rezultat = []
	wyniktabela = soupobwod.find("table",class_="jstable").find("tbody").find_all("tr")
	for wiersz in wyniktabela:
		cells = wiersz.find_all("td")
		if len(cells)>2:
			rezultat.append([cells[0].text,cells[1].text,cells[2].text])
#	print(rezultat)
#	print("wynik"+wyniktabela.text)
	# dopisac do wynikow
	for item in rezultat:
		outWynikiFile.write(obwodid+";"+";".join(item)+"\n")

def parseGmina(gminafile):
	soupgmina = BeautifulSoup(gminafile)
	for tables in soupgmina.find_all("table",class_="jstable"):
		if tables.find_all("th",text="Nazwa jednostki"):
			for tds in tables.find_all("td",{"class":""}):
				for obwodAnchor in tds.find_all("a"):
#					print("      Obwod: "+obwodAnchor.text+"\t:: "+obwodAnchor.get("href"))
#					print("      Obwod: "+obwodAnchor.text)
					obwodfile = urllib.request.urlopen(baseUrl+obwodAnchor.get("href"))
					for e in obwodAnchor.find_all("br"):
						e.replace_with(", ")
					parseObwod(obwodfile,obwodAnchor.text)

def parsePowiat(powiatfile):
	souppowiat = BeautifulSoup(powiatfile)
	for tables in souppowiat.find_all("table",class_="jstable"):
		if tables.find_all("th",text="Nazwa jednostki"):
			for tds in tables.find_all("td",{"class":""}):
				for gminaAnchor in tds.find_all("a"):
#					print("    Gmina: "+gminaAnchor.text+"\t:: "+gminaAnchor.get("href"))
					print("    Gmina: "+gminaAnchor.text)
					gminafile = urllib.request.urlopen(baseUrl+gminaAnchor.get("href"))
					parseGmina(gminafile)
					

def parseWoj(wojfile):
	soupwoj = BeautifulSoup(wojfile)
	for tables in soupwoj.find_all("table",{"class":"jstable"}):
		if tables.find_all("th",text="Nazwa jednostki"):
			for tds in tables.find_all("td",{"class":""}):
				for powiatAnchor in tds.find_all("a"):
					print("  Powiat: "+powiatAnchor.text+"\t:: "+powiatAnchor.get("href"))
					powiatfile = urllib.request.urlopen(baseUrl+powiatAnchor.get("href"))
					parsePowiat(powiatfile)

def main():
	global outObwodyFile
	global outProtFile
	global outWynikiFile

	outObwodyFile = open(outObwody,"wt",encoding="utf-8")
	outProtFile = open(outProt,"wt",encoding="utf-8")
	outWynikiFile = open(outWyniki,"wt",encoding="utf-8")

#	wojewodztwa=['02','04']
	wojewodztwa=['02','04','06','08','10','12','14','16','18','20','22','24','26','28','30','32']
	for woj in wojewodztwa:
		print("Wojewodztwo "+woj)
		wojfile = urllib.request.urlopen(baseUrl+"/325_Ponowne_glosowanie/"+woj)
		parseWoj(wojfile)

#	obwodfile = urllib.request.urlopen(baseUrl+"/327_protokol_komisji_obwodowej/1")
#	parseObwod(obwodfile,"Adres adres")

#	gminafile = urllib.request.urlopen(baseUrl+"/325_Ponowne_glosowanie/020101")
#	parseGmina(gminafile)


	outObwodyFile.close()
	outProtFile.close()
	outWynikiFile.close()

if __name__ == '__main__':
    main()
