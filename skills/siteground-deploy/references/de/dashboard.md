# Schritte im Dashboard (Deutsch)

Klickwege für alles, was es nur im SiteGround-Dashboard gibt. Gib dem Nutzer immer nur einen
Abschnitt auf einmal. Jeder Abschnitt endet mit **Prüfen**: Das kontrollierst du danach selbst.

Die Bezeichnungen wurden im Oktober 2026 in der deutschen Oberfläche gesehen.

Gesehen, aber beim Schreiben nicht selbst durchgeführt: der Upload-Weg (B), das Anlegen eines
Datenbank-Nutzers (F, Schritte 2 bis 5) und das Anbinden einer Domain (I). Diese Abschnitte
folgen den gesehenen Seiten und der SiteGround-Dokumentation. Sieht der Bildschirm des Nutzers
anders aus, gilt der Bildschirm, und du sagst, was abweicht.

Zwei Orte:
- **Kundenbereich**: `my.siteground.com`, die Konto-Ebene (Liste der Seiten und Projekte).
- **Site Tools**: die Verwaltung einer einzelnen Seite, erreichbar über den Knopf „Site Tools"
  neben der Seite.

## Inhalt
A. Neues Projekt aus GitHub · B. Neues Projekt per Upload · C. Bereitstellungsoptionen ·
D. Umgebungsvariablen · E. SSH-Schlüssel · F. Datenbank · G. Cron-Job · H. HTTPS erzwingen ·
I. Domain · J. Protokolle · K. Neu bereitstellen, pausieren, wechseln, löschen

## A. Neues Projekt aus GitHub

1. Kundenbereich → **Websites** → Reiter **Node.js-Projekte** → **Neues Projekt**.
2. **Git-Repository importieren** wählen → **Fortsetzen**.
3. Nur beim ersten Mal: GitHub öffnet sich und fragt, ob die SiteGround-App installiert werden
   darf. Konto wählen und entweder alle Repositories oder nur ausgewählte freigeben. Ein
   GitHub-Konto lässt sich nur mit einem einzigen SiteGround-Kundenbereich verbinden.
4. Repository in der Liste aussuchen → **Wählen** → **Fortsetzen**. Fehlt es, unter der Liste
   auf „Fehlt ein Repository? Hier klicken, um es hinzuzufügen" gehen und den Zugriff freigeben.
5. Falls der Assistent nach Einstellungen fragt, die Werte aus der Eignungsprüfung bestätigen
   und starten. Während des Builds wird das Protokoll angezeigt.
6. Nach dem Ende die vorläufige Adresse notieren (`….sg-host.com`) und **Site Tools** öffnen.

Ab jetzt baut und veröffentlicht jeder Push auf den verknüpften Branch automatisch.

**Prüfen:** `curl -sI https://<vorläufige-adresse>/` antwortet. Sobald SSH eingerichtet ist,
`verify_deploy.sh` ausführen.

## B. Neues Projekt per Upload

1. Archiv mit `scripts/make_archive.sh` bauen und dem Nutzer sagen, wo die Datei liegt.
2. Kundenbereich → **Websites** → **Node.js-Projekte** → **Neues Projekt**.
3. **Ihre Dateien hochladen** wählen → **Fortsetzen**.
4. Datei auswählen (.zip, .tar.gz oder .tgz, höchstens 128 MB) und starten.
5. Vorläufige Adresse notieren und **Site Tools** öffnen.

Jede spätere Änderung ist ein neuer Upload: Site Tools → Node.js → Bereitstellungsoptionen →
Drei-Punkte-Menü in der Projektzeile → neues Archiv hochladen.

**Prüfen:** wie bei A.

## C. Bereitstellungsoptionen

Site Tools → **Node.js** → **Bereitstellungsoptionen**.

| Feld | Was hinein gehört |
|---|---|
| Framework-Voreinstellung | Next.js, Nuxt, React, Vue, Angular, SvelteKit, Astro, Remix, Gatsby, Express, NestJS oder Custom. Wert aus der Eignungsprüfung nehmen; „Custom" für eine einfache `server.js`. |
| Branch | Der Branch, der veröffentlicht werden soll (nur beim GitHub-Weg). |
| Node-Version | 18, 20, 22, 24 oder 26. |
| Paketmanager | npm, yarn oder pnpm. |
| Build-Befehl | Das Feld zeigt den Paketmanager schon an. Nur den Rest eintragen, z. B. `run build`. Leer lassen, wenn das Projekt keinen Build-Schritt hat. |
| Ausgabeverzeichnis | Nur bei Projekten, die statische Dateien bauen, z. B. `dist`. Sonst leer. |

Ein Feld für den Startbefehl gibt es nicht.

- **Speichern** sichert die Werte.
- **Speichern und bereitstellen** sichert sie und startet eine neue Bereitstellung ohne Push.

**Prüfen:** `verify_deploy.sh` zeigt einen neuen Build mit Status `completed`.

## D. Umgebungsvariablen

Gleiche Seite, Abschnitt **Neue Umgebungsvariablen hinzufügen**: **Schlüssel**, **Wert**,
**Erstellen**. Die App liest sie als `process.env.SCHLUESSEL`.

Gib dem Nutzer die Liste der Schlüssel, die die App braucht, und woher der jeweilige Wert
kommt. Die Werte tippt er selbst ein; Geheimnisse laufen nicht durch den Chat. Danach
**Speichern und bereitstellen**, denn eine laufende App übernimmt neue Variablen nicht.

**Prüfen:** `verify_deploy.sh` listet unter `== env ==` die Namen der Variablen (nie die Werte).

## E. SSH-Schlüssel

1. Du führst `scripts/setup_ssh.sh keygen --name <kürzel>` aus und zeigst dem Nutzer den
   öffentlichen Schlüssel (eine Zeile, die mit `ssh-ed25519` beginnt).
2. Site Tools → **Devs** → **SSH-Schlüssel-Manager** → Reiter **Importieren** (nicht „Erzeugen").
3. Beliebigen Schlüsselnamen vergeben, öffentlichen Schlüssel einfügen, **Importieren**.
4. Auf derselben Seite im Kasten **SSH-Anmeldeinformationen**: Der Nutzer nennt dir
   **Hostname** (z. B. `ssh.beispiel.de`) und **Benutzername** (z. B. `u12-abcdefgh`).
   Der Port ist 18765.

**Prüfen:** `scripts/setup_ssh.sh test …` meldet `login ok`. Nur ein Versuch.

## F. Datenbank

Site Tools → **Site** → **PostgreSQL** oder **MySQL**.

1. Reiter **Datenbanken** → **Datenbank erstellen**. Der Name wird automatisch vergeben.
2. Reiter **Benutzer** → Nutzer anlegen. SiteGround erzeugt das Passwort: Der Nutzer kopiert es
   direkt in seinen Passwort-Manager oder ins Formular für die Umgebungsvariablen.
3. Dem Nutzer Zugriff auf die Datenbank geben (im Reiter Benutzer: Zugriff verwalten / zur
   Datenbank hinzufügen).
4. Verbindung als Umgebungsvariablen eintragen (Abschnitt D), zum Beispiel `DATABASE_URL` oder
   einzeln `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`. Host ist `localhost`;
   Ports sind 5432 (PostgreSQL) und 3306 (MySQL).
5. Nur wenn etwas außerhalb von SiteGround auf die Datenbank zugreifen muss: Reiter **Remote** →
   IP-Adresse dieses Rechners hinzufügen.

**Prüfen:** per SSH `psql -h localhost -U <db-nutzer> -d <db-name> -c 'select 1'` (fragt nach
dem Passwort: Das führt der Nutzer selbst aus) oder einfach eine Seite der App aufrufen, die
aus der Datenbank liest.

## G. Cron-Job

Site Tools → **Devs** → **Cron-Jobs**.

1. **Befehl**: ein vollständiger Shell-Befehl mit absoluten Pfaden, zum Beispiel
   `cd /home/customer/www/<domain>/public_html/.nodeapp/latest/app_source && /usr/local/bin/node scripts/task.js`
2. **Intervall**: Vorgabe wählen oder die fünf Cron-Felder eintragen
   (Minute Stunde Tag Monat Wochentag).
3. **Erstellen**. Der zweite Reiter verwaltet die Benachrichtigungs-Mails bei Fehlern.

Ein Cron-Job ist ein eigener kurzer Prozess, kein Teil der laufenden App. Er bekommt die
Umgebungsvariablen der App nicht automatisch: Das Skript muss selbst laden, was es braucht.

**Prüfen:** per SSH zeigt `site-tools-client cron list -j` den Job. Nach dem ersten geplanten
Lauf das Ergebnis des Jobs kontrollieren.

## H. HTTPS erzwingen

Site Tools → **Sicherheit** → **HTTPS erzwingen** → Schalter bei der Domain einschalten.

**Prüfen:** `curl -sI http://<domain>/` antwortet mit 301 und einer Zeile
`Location: https://…`. `verify_deploy.sh` meldet das ebenfalls.

## I. Domain

Zuerst die IP der Seite heraussuchen: Site Tools → **Dashboard** → „IP- und Namenserver" →
**Standort-IP**.

**Schritt 1: Domain mit dem Projekt verbinden.** Zwei Wege:

- **Zur Hauptdomain machen** (empfohlen, wenn die App unter dieser Domain laufen soll):
  Kundenbereich → Websites → Node.js-Projekte → Drei-Punkte-Menü des Projekts →
  **Domainnamen ändern**.
- **Als zusätzliche Domain hinzufügen**, die dieselbe App öffnet: Site Tools → **Domain** →
  **Geparkte Domains** → Domain eintragen → **Hinzufügen**. SiteGround verlangt, dass die
  Domain registriert ist und ihr DNS bereits auf SiteGround zeigt (also erst Schritt 2).

**Schritt 2: DNS dort einstellen, wo die Domain registriert ist.** Zwei Wege:

- **Nur A-Einträge** (E-Mail und alles andere bleibt, wo es ist): A-Eintrag für `@` und für
  `www` auf die Standort-IP setzen.
- **Namenserver** `ns1.siteground.net` und `ns2.siteground.net`: Dann verwaltet SiteGround die
  ganze Zone (Site Tools → Domain → DNS-Zonen-Editor). Die Mail-Einträge ziehen mit um,
  bestehende E-Mail funktioniert also nicht mehr, solange ihre Einträge dort nicht neu angelegt
  sind. Vorher nachfragen, bevor du das empfiehlst.

Die Verteilung prüfst du selbst: `dig +short <domain>` und `dig +short www.<domain>` müssen
die Standort-IP liefern. Das dauert Minuten bis einige Stunden.

**Schritt 3: Zertifikat.** Site Tools → Sicherheit → **SSL-Manager**: Steht für die neue Domain
kein Zertifikat in der Liste, Domain auswählen, **Let's Encrypt** wählen und anfordern. Das
klappt erst, wenn das DNS auf SiteGround zeigt.

**Schritt 4:** HTTPS erzwingen für die neue Domain (Abschnitt H).

**Schritt 5:** Umgebungsvariablen mit Adressen anpassen und **Speichern und bereitstellen**
(Abschnitt D).

**Prüfen:** `curl -sI https://<domain>/` antwortet mit 200 und gültigem Zertifikat,
`http://<domain>/` leitet um, `www.<domain>` verhält sich wie gewünscht.

## J. Protokolle

- **Build-Protokolle:** Site Tools → Node.js → **Protokolle**. Eine Zeile pro Bereitstellung
  mit Autor, Branch, Commit, Zeit und Status; Drei-Punkte-Menü → **Build-Log anzeigen**.
- **HTTP-Fehler:** Site Tools → **Statistiken** → **Fehlerprotokoll** (die letzten 300 Fehler)
  und **Zugriff auf das Protokoll**.
- Die Konsolenausgabe der laufenden App war nirgends zu finden.

## K. Neu bereitstellen, pausieren, wechseln, löschen

Site Tools → Node.js → Bereitstellungsoptionen → Drei-Punkte-Menü in der Projektzeile:
**Pausieren** (automatische Bereitstellung anhalten), **Repository wechseln**, **Trennen**
(von GitHub), **Manuell hochladen** (auf den Upload-Weg umstellen).

Ganzes Projekt löschen: Kundenbereich → Websites → Node.js-Projekte → Drei-Punkte-Menü →
**Löschen**. Das entfernt die Seite samt Dateien und Datenbanken: nur auf ausdrücklichen Wunsch
des Nutzers, und nur er selbst klickt.
