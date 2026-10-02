# SiteGround oder Railway? (Deutsch)

Nutze das, wenn jemand nach dem Unterschied fragt, wissen will, ob SiteGround Railway ersetzen
kann (für Render, Fly.io oder Heroku gilt dieselbe Überlegung), oder wenn die Eignungsprüfung
Nein sagt.

## Der Grundunterschied

- **Railway** startet für jeden Dienst einen eigenen Container. Was darin läuft, ist egal:
  Node.js, Python, Redis, alles mit einem Dockerfile. Jeder Dienst hat eigene Ressourcen und
  wird nach Verbrauch abgerechnet.
- **SiteGround** ist ein Server mit festen Dienst-Typen. Eine Seite bekommt einen Webserver für
  PHP und, bei einem Node.js-Projekt, genau einen Node.js-Prozess. Alle Seiten des Kontos
  teilen sich Arbeitsspeicher und Platte des Servers, zum Festpreis.

## Punkt für Punkt

| Fähigkeit | Railway | SiteGround Node.js-Projekt |
|---|---|---|
| Node.js-App aus GitHub, Bereitstellung per Push | ja | ja |
| Bereitstellung ohne GitHub | Upload per Kommandozeile | ZIP-Upload im Dashboard |
| Python-Webdienst (FastAPI, Django, Flask) | ja | nein |
| Docker / Dockerfile | ja | nein |
| Weitere Dauerläufer (Worker, Bots, Warteschlangen) | ja, als eigene Dienste | nein, ein Node.js-Prozess pro Projekt |
| Zeitgesteuerte Aufgaben | Cron-Dienste, je ein eigener Container | Cron-Jobs: ein Shell-Befehl nach Zeitplan |
| PostgreSQL | ja, als Dienst | ja, in Site Tools angelegt |
| MySQL | ja, als Dienst | ja, in Site Tools angelegt |
| Redis | ja | kein nutzbares Redis gefunden |
| Dauerhafte Dateien | Volumes | das Home-Verzeichnis |
| Umgebungsvariablen | ja | ja |
| Eigener Startbefehl | ja | kein Feld dafür |
| App in einem Unterordner des Repos | Einstellung für das Stammverzeichnis | keine solche Einstellung gefunden |
| Laufzeit-Protokolle | ja | nicht gefunden; nur Build-Protokoll und HTTP-Fehlerprotokoll |
| Ressourcen | pro Dienst, skalierbar | geteilt mit den anderen Seiten des Kontos |
| Eigene Domain und SSL | ja | ja, dazu DNS-Zone und E-Mail-Hosting |
| E-Mail-Postfächer | nein | ja |
| Backups | Volume-Backups, je nach Tarif | automatische tägliche Backups der ganzen Seite, bis 30 Tage |
| Preis | nach Verbrauch | im Hosting-Tarif enthalten |

## Was umziehen kann, was bleibt

**Zieht gut um:** Node.js-Web-Apps und Schnittstellen mit einem Prozess, Oberflächen (Next.js,
React, Vue und ähnliche), kleine Express-Server, Apps, die nur MySQL oder PostgreSQL brauchen.

**Bleibt auf Railway (oder Ähnlichem):** alles in Python, das dauerhaft laufen muss, alles,
was ein Dockerfile braucht, Redis, Warteschlangen-Worker, mehrere Prozesse, Browser ohne
Oberfläche, schwere Video- oder Bildverarbeitung, Apps, deren Protokolle man live mitlesen muss.

**Möglich, aber erst testen:** Skripte nach Zeitplan. Ein SiteGround-Cron kann ein Node.js-
oder Python-Skript starten, teilt sich den Server aber mit den Webseiten und ist nicht
abgeschottet. Eine Oberfläche kann umziehen, während ihr Python-Backend bleibt: Dann muss die
API-Adresse der Oberfläche auf die öffentliche Adresse des Backends zeigen, und das Backend
muss die neue Herkunft erlauben (CORS).

## Einen Dienst umziehen: Checkliste

1. Eignungsprüfung auf den Ordner des Dienstes laufen lassen. Aufhören, wenn er nicht passt.
2. Auflisten, was der Dienst auf Railway nutzt: Umgebungsvariablen, Datenbank, Volume,
   Cron-Zeitplan, eigene Domain.
3. SiteGround-Projekt anlegen (GitHub oder Upload) und die Umgebungsvariablen setzen. Railway
   weiterlaufen lassen.
4. Datenbank: auf SiteGround anlegen, aus Railway exportieren (`pg_dump` oder `mysqldump`) und
   per SSH importieren. Dabei die App anhalten oder nur lesen lassen, damit während des
   Kopierens nichts geschrieben wird.
5. Dateien aus einem Volume: in einen Ordner im SiteGround-Home-Verzeichnis kopieren und der
   App den Pfad per Umgebungsvariable geben.
6. Cron: jeden Zeitplan in Site Tools als Befehl neu anlegen.
7. Alles unter der vorläufigen `sg-host.com`-Adresse testen.
8. DNS auf SiteGround umstellen, Zertifikat holen, HTTPS erzwingen einschalten.
9. Jede Adress-Variable auf beiden Seiten anpassen (Basis-Adresse, API-Adresse, erlaubte
   Herkünfte) und neu bereitstellen.
10. Hängen beide Plattformen am selben Branch, stellt jeder Push doppelt bereit: die
    automatische Bereitstellung dort pausieren, wo man weggeht. Den Railway-Dienst erst
    entfernen, wenn der neue ein paar Tage sauber gelaufen ist.
