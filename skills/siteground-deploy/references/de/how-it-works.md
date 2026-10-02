# So funktioniert das Node.js-Hosting von SiteGround (Deutsch)

Per SSH und in Site Tools auf einem Cloud-Tarif beobachtet, Oktober 2026.

## Für Einsteiger: Was ist ein Node.js-Projekt?

Ein Node.js-Projekt ist ein Programm, das in JavaScript (oder TypeScript) geschrieben ist und
auf einem Server läuft statt im Browser. Man erkennt es an einer Datei namens `package.json`
im Projektordner: Darin steht, welche Bausteine das Programm braucht und mit welchem Befehl es
startet (meist `npm start`). Liegt stattdessen eine `requirements.txt` im Ordner, ist es
Python; liegt nur ein `Dockerfile` darin, ist es ein Container. Beides ist kein Node.js-Projekt.

Was ein Node.js-Projekt sein kann:
- Web-Apps mit Framework (Next.js, Nuxt, Remix, Astro, SvelteKit)
- reine Oberflächen, die einmal zu fertigen Dateien gebaut werden (React, Vue, Angular, Svelte)
- Schnittstellen und Backends (Express, Fastify, NestJS, Koa)
- ein kleiner, selbst geschriebener Server in einer einzelnen `server.js`

SiteGround kennt drei Arten von Seiten: klassische PHP-Seiten (WordPress und ähnliche),
statische Seiten (hochgeladenes HTML) und seit Oktober 2026 Node.js-Projekte. Zu jeder Seite
gehören außerdem MySQL- und PostgreSQL-Datenbanken, Cron-Jobs, E-Mail, SSL und SSH.

## Was bei einer Bereitstellung passiert

1. Ein Push auf den verknüpften Branch (oder „Speichern und bereitstellen", oder ein neuer
   Upload) startet einen Build.
2. SiteGround klont das Repository flach in einen Build-Ordner.
3. Es führt die Installation des Paketmanagers aus (standardmäßig `npm install`), begrenzt
   auf 5 Minuten.
4. Ist ein Build-Befehl eingetragen, läuft er mit `NODE_ENV=production`, begrenzt auf 5 Minuten.
5. Bei Erfolg wird der Build live geschaltet. Exit-Code 2 heißt: Installation fehlgeschlagen
   oder Zeit überschritten; 3 heißt: Build-Befehl fehlgeschlagen.

Es gibt keinen Container. Die App läuft als gewöhnlicher Prozess des Linux-Nutzers der Seite,
auf demselben Server wie die anderen Seiten des Kontos.

## Wo was auf dem Server liegt

```
~/www/<domain>/
├── .nodejs_version              Node-Hauptversion der Seite
└── public_html/
    └── .nodeapp/
        ├── app.json             Paketmanager, Installations- und Build-Befehl
        ├── .env-local           Umgebungsvariablen (das Build-Skript lädt sie, falls vorhanden)
        ├── latest -> <build>    der aktive Build
        └── <build>/
            ├── app_source/      der Code samt node_modules
            ├── git_info         Commit, Autor, Branch, Betreff des aktiven Commits
            ├── build_info.json  {"status":"completed"} oder {"status":"failed"}
            ├── build_script.exit_code
            ├── current          das Build-Protokoll
            ├── build_script.sh  das Skript, das SiteGround ausgeführt hat
            └── build_settings.json   enthält die Git-Adresse mit einem Zugriffstoken
```

`.nodeapp` ist von außen nicht erreichbar (HTTP 403).

Das Home-Verzeichnis (`/home/customer`) bleibt dauerhaft bestehen und ist beschreibbar. Dorthin
gehören Daten, die die App behalten muss: dort einen Ordner anlegen und seinen Pfad per
Umgebungsvariable an die App geben. Ob Dateien, die innerhalb von `app_source/` geschrieben
werden, die nächste Bereitstellung überleben, wurde nicht getestet.

## Werkzeuge auf dem Server

Per SSH erreichbar (Port 18765): Node.js 18, 20, 22, 24 und 26, npm, git, Python 3 mit pip und
venv, PHP, Ruby, ffmpeg, ImageMagick, `psql`, `mysql`, curl, rsync. Ausgehendes HTTPS
funktioniert. Kein Docker, kein Go, kein Java. Die Shell ist eingeschränkt: keine Prozessliste,
kein `crontab`-Befehl.

`site-tools-client` ist SiteGrounds eigenes Kommandozeilen-Werkzeug. Was für den Nutzer einer
Seite funktioniert:

| Befehl | Ergebnis |
|---|---|
| `site-tools-client app list -j` | die Node.js-App (enthält eine private Benachrichtigungs-Adresse: maskieren) |
| `site-tools-client domain list -j` | Domains mit Einstellungen wie `https_enforce`, Cache-Schaltern, Node-Version |
| `site-tools-client domain update id=<id> flush_cache=1` | leert den Cache |
| `site-tools-client cron list -j` | Cron-Jobs |
| `site-tools-client dns list -j` | DNS-Einträge der Zone |
| `site-tools-client site list -j` | Plattenverbrauch und Tarif-Merkmale |
| `site-tools-client uservice list -j` | Dienste der Seite (`apache`, `nodejs-1`) |

Einstellungen ändern (`https_enforce`), Cron-Jobs oder Domain-Aliase anlegen wird über dieses
Werkzeug abgelehnt: Das geht nur im Dashboard. Erlaubt sind fünf Verbindungen pro Sekunde.

## Beobachtete Grenzen

- Ein überwachter Node.js-Prozess pro Projekt. Kein zweiter Prozesstyp für Worker.
- Installation und Build: je 5 Minuten.
- Upload-Archiv: 128 MB.
- Grenzen pro Nutzer auf dem beobachteten Server: 160 Prozesse, rund 2 GB Speicher pro Prozess.
- Platte und Arbeitsspeicher werden mit den anderen Seiten des Kontos geteilt.
- Backups laufen täglich und werden bis zu 30 Tage aufbewahrt; das erste erscheint etwa
  6 Stunden nach dem Anlegen des Projekts.

## Nicht überprüft

- Ob Dateien im Build-Ordner eine erneute Bereitstellung überleben.
- Wie der Startbefehl gewählt wird (`npm start` oder `main`): beides setzen.
- Wo die Konsolenausgabe der laufenden App landet.
- WebSockets.
- Ob eine untätige App schlafen gelegt wird.
- Eine Einstellung für das Stammverzeichnis bei Monorepos (es wurde keine gefunden).
