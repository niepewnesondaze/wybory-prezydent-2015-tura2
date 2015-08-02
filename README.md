
Analiza wyników drugiej tury wyborów prezydenckich 2015
=========================================================

#Pobranie danych
Skrypt pobranie-danych/pierwszatura.py jest napisany w Pythonie i ściąga raporty [wizualizacji udostępnionej przez PKW](http://prezydent2015.pkw.gov.pl).

Skrypt działa w sposób rekurencyjny:
- dla każdego województwa z listy w funkcji main() wchodzi na odpowiednią stronę: np. http://prezydent2015.pkw.gov.pl/325_Ponowne_glosowanie
	- dla każdego powiatu wymienionego na tej stronie wchodzi na odpowiednią stronę z listą gmin
		- dla każdej gminy przegląda listę obwodów
			- dla każdego obwodu znajduje raport z konkretnego lokalu wyborczego
		- wyjątkiem są powiaty grodzkie (roboczo nazwane w kodzie gminami miejskimi), gdzie lista obwodów znajduje się poziom wyżej - nie ma dostępnej listy gmin

Z raportu [(przykład)](http://prezydent2015.pkw.gov.pl/327_protokol_komisji_obwodowej/6795) wyciągane są wszystkie udostępnione informacje:
- informacje o obwodzie
- rozliczenie kart do głosowania
- adnotacje i uwagi
- liczba głosów na poszczególnych kandydatów

Dzięki temu, w jaki sposób Python obsługuje dane wejściowe program można uruchomić i testować podając albo url albo
otwarty plik ze ściągniętym HTML do jednej z funkcji działających na odpowiednim poziomie:
```
	parseWoj(plik)
	parsePowiat(plik)
	parseGmina(plik)
	parseObwod(plik)
```

#Pliki wynikowe
Skrypt zapisuje wyniki do następujących plików:
- obwody.csv - informacje o obwodach
- protokoly.csv - rozliczenie kart, uwagi i adnotacje dla każdego obwodu
- wyniki.csv - kandydaci, listy i liczba głosów w każdym pojedynczym obwodzie

#Pliki pomocnicze
- protokolyitem.csv - klucz do kolejnych pozycji w protokoly.csv
- gminyteryt.csv - rodzaje gmin (wiejska, miejska, miasto) wg kodów teryt z [listy obwodów PKW z wyborów samorządowych](http://wybory2014.pkw.gov.pl/pl/pliki)

#Struktura danych
- dbload.sql to kod SQL, który tworzy bazę danych i odpowiednie tabele oraz ładuje wyżej wymienione pliki

Wewnątrz tego pliku znajdują się polecenia CREATE TABLE z nazwami i typami kolejnych kolumn w powyższych plikach csv.

Do analizy używam bazy danych [Infobright](http://www.infobright.org/) - MySQL z dodatkowym silnikiem brighthouse, 

który fantastycznie szybko dokonuje wyszukiwania, łączenia i agregacji danych.
Po niewielkich zmianach za pomocą dbload.sql można załadować te dane do standardowego MySQL

#Przykład użycia
W pliku analiza.R jest kod, którego użyłem do [napisania tego wpisu](http://niepewnesondaze.blogspot.com/2015/07/czy-druga-tura-wyborow-prezydenckich.html).

Przykładowe dane przetworzone tak, jak na początku pliku analiza.R są w załączonym data.Rda.

