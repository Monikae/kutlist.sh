#!/bin/bash
# kutlist.sh
Stand="02.06.2018"

# Konfiguration
Kommentar="Mit kutlist.sh erstellt"			# Standard Kommentar, kann jeweils noch ergaenzt oder ersetzt werden 
ConvertUTF=1						# Bei Problemen mit Umlauten
Zeige_fertige_Cutlist_am_Ende=0				# Moechtest Du die Rohdaten vorm Upload angezeigt bekommen
Cutlist_hochladen_Frage=0				# 0 laedt die cutlist ohne zu fragen hoch
Loeschen_der_fertigen_Cutlist=0				# Braucht man die noch wenn der Film eh schon geschnitten ist???
							# (Zur Not hat Cutlist.at ja eine Kopie :-))

if [ ! -e ~/.cutlist.at ] ; then			# pers. URL schon gespeichert ?
CutListAT="http://www.cutlist.at"			# Nein -> Standard URL verwenden
else 
CutListAT=$(cat ~/.cutlist.at | head -n 1)		# Ja -> URL auslesen
fi

# Funktionen
checkSystem () {					# Ueberpruefe ob alle noetigen Programme installiert sind
if ! type kdialog > /dev/null 2>/dev/null ; then
echo -e "\nKdialog ist nicht verfuegbar.\nBitte installiere es!"
exit 1
fi

if type avidemux2_gtk > /dev/null 2>/dev/null ; then avidemux="avidemux2_gtk"
elif type avidemux2 > /dev/null 2>/dev/null ; then avidemux="avidemux2"
else avidemux="avidemux"
fi
if ! type $avidemux > /dev/null 2>/dev/null ; then
kdialog --error "Avidemux ist nicht verfuegbar.\nBitte installiere es!"
exit 1
fi

if ! type curl > /dev/null 2>/dev/null ; then
kdialog --error "Curl ist nicht verfuegbar.\nBitte installiere es!"
exit 1
fi
}
writeCutlistHeader () {					# Kopfdaten fuer die Cutlist schreiben
cat << HEADER > $2
[General]
Application=kutlist.sh
Version=0.2
comment1=Diese Cutlist unterliegt den Nutzungsbedingungen von cutlist.at (Stand: 14.Oktober 2008)
comment2=http://cutlist.at/terms/
ApplyToFile=$1
OriginalFileSizeBytes=$filesize
FramesPerSecond=25
IntendedCutApplication=Avidemux
IntendedCutApplicationVersion=2.5.4
IntendedCutApplicationOptions=
NoOfCuts=$number_of_cuts
[Info]
Author=$author
RatingByAuthor=$rating
EPGError=$EPGError
ActualContent=$ActualContent
MissingBeginning=$MissingBeginning
MissingEnding=$MissingEnding
MissingAudio=$MissingAudio
MissingVideo=$MissingVideo
OtherError=$OtherError
OtherErrorDescription=$OtherErrorDescription
SuggestedMovieName=$suggest
UserComment=$comment
HEADER
}
writeCutlistSegment () {				# Schnitte in die Cutlist schreiben
echo "[Cut" $1 "]" | tr -d " " >> $3
echo "Start=" $(expr $(echo $2 | cut -d"," -f2)*0.04 | bc) | tr -d " " >> $3
echo "StartFrame=" $(echo $2 | cut -d"," -f2) | tr -d " " >> $3
echo "Duration=" $(expr $(echo $2 | cut -d"," -f3 | cut -d")" -f1)*0.04 | bc) | tr -d " " >> $3
echo "DurationFrames=" $(echo $2 | cut -d"," -f3 | cut -d")" -f1) | tr -d " " >> $3 #" Geany workaround
}
showInfoDialog () {					# Kurze Anleitung zum Umgang mit Kutlist und Avidemux schreiben
kdialog --title "Kutlist (2/6): Film schneiden" --msgbox "ACHTUNG !!!\n Dieses Fenster erst dann mit OK schliessen wenn folgende vier Schritte durchgefuehrt wurden! \n\n 1. Du musst die Teile des Films markieren, die du herausschneiden möchtest. Also die Teile die du nicht mehr haben möchtest (Werbung etc.).\n\n Die Verwendung von Avidemux ist relativ einfach und intuitiv. Deshalb nur einige wichtige Tipps:\n\n Am einfachsten kann man sich mithilfe der Nummernblocktasten im Film bewegen. 4 und 6 springt dabei zwischen Einzelframes hin und her, wohingegen 2 und 8 sich zwischen den einzelnen I-Frames bewegt. Pos 1 springt ganz zum Anfang, Ende ganz zum Ende. Auswahlen werden mit Button A (Startframe) und Button B (Endframe) getroffen. Alternativ kann man auch die rechteckigen Klammern benutzen. Will man eine Auswahl entfernen, betätigt man Entf. Dabei wird die gesamte Auswahl inklusive Startframe A herausgeschnitten. Nur das letzte Frame - Endframe B bleibt erhalten. \n\n 2. Wenn man damit fertig ist waehlt man noch File -> Save Project (nicht Save Project as!) aus dem Menu (Wichtig damit die Schnittliste auf Cutlist.at geladen werden kann). \n\n 3. Danach kann man sich den geschnittenen Film für sich selbst abspeichern. Dieses geht mit File -> Save -> Save Video \n Idealerweise wählt man hier sinnige Namen für die Filme oder Sendungen wie z.B. fuer die Datei 'James_Bond_007_Im_Angesicht_des_Todes_07.06.09_22-55_ard_125_TVOON_DE.mpg.avi' den Dateinamen 'James Bond - Im Angesicht des Todes.avi' oder für 'King_of_Queens_07.06.25_18-15_kabel1_30_TVOON_DE.mpg.avi' den Namen '07x10 King of Queens - Spanische Doerfer.avi' und kopiert sich diesen Namen bei der Gelegenheit gleich noch in die Zwischenablage damit man ihn anschliessend fuer den vorgeschlagenen Dateinamen und/oder Kommentar der Cutlist wieder verwenden kann. Umlaute sollten vermieden werden. \n\n 4. Jetzt sollte man Avidemux wieder beenden und die folgenden Fragen zur Cutlist beantworten! \n\n "
}
writeAvidemuxProject () {				# Schreibe Avidemux Projekt Datei
cat <<  ADMP > $2
//AD
var app = new Avidemux();
app.load("/$1");
app.rebuildIndex();
//End of script
ADMP
}
uploadCutlist () {					# Schreibe Avidemux Projekt Datei
if [ $ConvertUTF -eq 1 ] ; then
	iconv -f utf-8 -t iso-8859-1 $1 --output $1.conv
	mv $1.conv $1
fi
curl -F userfile[]=@$1 -F MAX_FILE_SIZE=10000000 -F confirm=true -F type=blank -F userid=$2 -F version=1 "$CutListAT/index.php?upload=2"
if [ $? -eq 0 ] ; then									
kdialog --title "$1" --passivepopup "Erfolgreich zu Cutlist.at hochgeladen" 5 &
else
# kdialog --title "$1" --passivepopup "cutlist.at ist nicht erreichbar, verwende cutlist.de !" 5 &
# curl -F userfile[]=@$1 -F MAX_FILE_SIZE=10000000 -F confirm=true -F type=blank -F userid=$2 -F version=1 "www.cutlist.de/index.php?upload=2"
# if [ $? -eq 0 ] ; then									
# kdialog --title "$1" --passivepopup "Erfolgreich zu Cutlist.de hochgeladen" 5 &
# else
Cutlist_diesmal_nicht_loeschen=1
# fi
fi
echo
}
cutlistDFS () {						# Cutlist vom Server loeschen
userid=$(cat ~/.kutlist.rc | tail -n 1)
cutlistdfs=$(echo $1 | rev | cut -d"=" -f1 | rev)
wget -U "kutlist.sh/$Stand" -q -O - "$CutListAT/delete_cutlist.php?cutlistid=$cutlistdfs&userid=$userid&version=1"
echo
}
help () {
cat << END
Aufruf:
$0 [options] files

Moegliche Optionen:

-dfs	Cutlist vom Server loeschen
        z.B.: kutlist.sh -dfs http://cutlist.at/getfile.php?id=123456
        oder  kutlist.sh -dfs 123456
-url	persönliche Cutlist.at URL speichern
        (-url http://www.cutlist.at/user/0123456789abcdef
        ohne letzten Schraegstrich ! )	

(c) bowmore@otrforum $Stand
END
exit 1
}

# Start
while [ "$1" != "${1#-}" ] ; do				# solange der naechste parameter mit "-" anfaengt...
  case ${1#-} in
    dfs) cutlistDFS $2; exit 0;;
    url) shift;echo $1 > ~/.cutlist.at;exit 0;;
    *) help; exit 1;;
  esac
done
checkSystem 1						# Teste das System
if [ $# -eq 0 ] ; then					# Parameteruebergabe ?
wahl=`kdialog --title "Kutlist (1/6): Den zu schneidenden Film auswaehlen" --getopenfilename ~/download_video/edit/ "*.mpg.avi | mpg.avi von OTR"`
if [ $? -eq 1 ] ; then									# Skript_Ende bei Abbruch
exit 1
fi
else
											# sonst Parameter verarbeiten
wahl=${@:-*}

fi
for auswahl in $wahl ; do				# Für alle Parameter das Skript durchlaufen

if [ `echo $auswahl | grep / | wc -l` -eq 0 ] ; then
auswahl=$PWD/$auswahl
fi

avidemux_project=$(echo $auswahl | sed 's/.avi*./.js/g' -)				# Variablen bestimmen
cutlist=$(echo $auswahl | sed 's/.avi*./.cutlist/g' -)
filesize=$(ls $auswahl -l | awk '{ print $5 }')
file=$(echo $auswahl | rev | cut -d"/" -f1 | rev)
cutfile=$(echo $cutlist | rev | cut -d"/" -f1 | rev)

writeAvidemuxProject $auswahl $avidemux_project						# Avidemux im Hintergrund (!) starten
$avidemux --force-smart --run $avidemux_project 1>/dev/null 2>/dev/null &
											# Versatz-Pause, damit das Info-Fenster
sleep 8											# moeglichst im Vordergrund ist

while [ $(ps -C $avidemux >/dev/null && echo $?) ]; do			# Info Dialog Anzeigen
showInfoDialog $1									# solange Avidemux laeuft
done

number_of_cuts=`grep -c "app.addSegment" $avidemux_project`				# Wie viele Schnitte gibt es?
if [ $number_of_cuts -eq 0 ] ; then							# Abbruch bei Null Schnitte
kdialog --error "Du hast in Avidemux keine Schnitte definiert,\n oder vergessen diese zu speichern (File -> Save Project)\nDann gibt es hier nichts mehr zu machen!"
rm $avidemux_project									# temporaeres Datei loeschen
exit 1
fi
											# Bewertungs-Dialog
rating=`kdialog --title "Kutlist (3/6): Film Bewerten" \
		--menu "Bitte eine Bewertung für $file abgeben:" \
		0 "[0] Test (schlechteste Wertung)" \
		1 "[1] Anfang und Ende grob geschnitten" \
		2 "[2] Anfang und Ende geschnitten" \
		3 "[3] Schnitt ist annehmbar, Werbung entfernt" \
		4 "[4] Framegenau, Werbung entfernt" \
		5 "[5] Perfekt" \
		9 "keine Cutlist erstellen"`
if [ $? -eq 1 ] ; then									# Skript_Ende bei Abbruch
exit 1
elif [ $rating -eq 9 ] ; then 								# Abbruch sofern keine Cutlist
exit 2											# erstellt werden soll
fi

											# Zustands-Dialog
infos=`kdialog --title "Kutlist (4/6): Information zum Film" \
		--menu "Information fuer $file:" \
		1 "Alles in Ordnung" \
		2 "Falscher Inhalt / EPG-Fehler" \
		3 "Fehlender Anfang" \
		4 "Fehlendes Ende" \
		5 "Tonspur fehlt" \
		6 "Videospur fehlt" \
		7 "Sonstiger Fehler"`
if [ $? -eq 1 ] ; then									# Skript_Ende bei Abbruch
exit 1
fi

EPGError="0"										# Setze zunaechst einmal
ActualContent=""									# neutrale Werte fuer
MissingBeginning="0"									# die Cutlist
MissingEnding="0"
MissingAudio="0"
MissingVideo="0"
OtherError="0"
OtherErrorDescription=""
comment=""

case $infos in										# Setze nun spezifische Werte
2) EPGError="1";ActualContent=`kdialog --title "Kutlist (4/6): Information zum Film" \
					--inputbox "Tatsaechlicher Inhalt von $file:"`;;
3) MissingBeginning="1";;
4) MissingEnding="1";;
5) MissingAudio="1";;
6) MissingVideo="1";;
7) OtherError="1";OtherErrorDescription=`kdialog --title "Kutlist (4/6): Information zum Film" \
					--inputbox "Fehler Beschreibung zu $file:"`;;
esac
											# Vorschlag generieren
# sugfile=`echo $file | rev | cut -d"-" -f2 | cut -d"." -f3 | cut -d"_" -f2,3,4,5,6,7,8,9 | rev | tr "_" " "`
											# Vorschlag abfragen
suggest=`kdialog --title "Kutlist (5/6): Filmname vorschlagen" \
		--inputbox "Vorschlag fuer den Dateinamen: (Abbruch fuer keinen Vorschlag!)" ""`
if [ $? -eq 1 ] ; then									# kein Vorschlag bei Abbruch
suggest=""
fi
											# Kommentar abfragen
comment=`kdialog --title "Kutlist (6/6): Kommentar zum Film" \
		--inputbox "Kommentar zu $file:" ""`

if [ ! -e ~/.kutlist.rc ] ; then							# Nickname schon gespeichert ?
author=`kdialog --title "Kutlist: Nickname eingeben" --inputbox "Autor: (wird in /home/user/.kutlist.rc gespeichert)" "Kutlist"` 
echo $author > ~/.kutlist.rc
uptime | sha1sum | tr "[:lower:]" "[:upper:]" | cut -b 1-20 >> ~/.kutlist.rc		# UserId generieren
userid=$(cat ~/.kutlist.rc | tail -n 1)							# Nein -> Abfrage und speichern
else 
author=$(cat ~/.kutlist.rc | head -n 1)							# Ja -> Namen auslesen
userid=$(cat ~/.kutlist.rc | tail -n 1)	
fi

cuts=`grep "app.addSegment" $avidemux_project`
writeCutlistHeader $file $cutlist							# Berechne Schnittdaten
count=0											# fuer die Cutlist
for cut in $cuts ; do									# und schreibe
writeCutlistSegment $count $cut $cutlist						# die endgueltige
count=$(expr $count + 1)								# Cutlist
done

rm $avidemux_project									# temporaeres Datei loeschen

if [ $Zeige_fertige_Cutlist_am_Ende -eq 1 ] ; then					# Zeige fertige Cutlist
kdialog --textbox $cutlist 550 800							
fi
											# Upload zu cutlist.at
if [ $Cutlist_hochladen_Frage -eq 1 ] ; then
kdialog --title "Kutlist" --yesno "Soll die erstellte Cutlist\n zu Cutlist.at geladen werden ?"
if [ $? -eq 0 ] ; then
uploadCutlist $cutlist $userid
Cutlist_diesmal_nicht_loeschen=0
else
Cutlist_diesmal_nicht_loeschen=1
fi
else											# Upload-Frage = 0
uploadCutlist $cutlist $userid								# standardmäßig uploaden
Cutlist_diesmal_nicht_loeschen=0
fi

if [ $Loeschen_der_fertigen_Cutlist -eq 1 ] && [ $Cutlist_diesmal_nicht_loeschen -ne 1 ] ; then
rm $cutlist										# Cutlist lokal loeschen
Cutlist_diesmal_nicht_loeschen=0
fi

done											# Ende der Parameter Schleife
exit 0
