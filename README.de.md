# 🚀 SiteGround Deploy — ein Claude-Plugin, das dein Node.js-Projekt auf SiteGround bringt

> **Erstellt von Sertac · [NetBoosting GmbH](https://netboosting.de)** · Kostenlos nutzbar unter der MIT-Lizenz. · 🇬🇧 [English version](README.md)

Seit Oktober 2026 kann SiteGround Node.js-Apps hosten: GitHub-Repository verbinden oder ein ZIP
hochladen, und SiteGround baut und startet die App. Die Funktion ist neu, im Dashboard gibt es
viele Stellen zum Klicken, und manches klappt nur, wenn man es vorher weiß.

**SiteGround Deploy** macht daraus einen geführten Weg. Sag Claude *„Bring dieses Projekt auf
SiteGround"*, und es

- **prüft, ob dein Projekt passt** (Node.js ja; Python-Dienste, Docker, Redis und zusätzliche
  Worker nein) und sagt dir, was du vorher ändern musst
- **bereitet das Projekt vor**: Startbefehl, Port, Ablageort für Daten, keine Geheimnisse im Repo
- **führt dich durch jeden Klick** im SiteGround-Dashboard, Schritt für Schritt, mit den
  genauen Werten zum Eintragen — über **GitHub mit automatischer Bereitstellung** oder per
  **ZIP-Upload**
- **richtet den SSH-Zugang sicher ein** (es erzeugt den Schlüssel, du fügst eine Zeile ein)
- **erklärt Umgebungsvariablen, Datenbanken und Cron-Jobs** für genau das, was deine App braucht
- **prüft das Ergebnis selbst**: Build-Status, welcher Commit live ist, ob die Seite antwortet
- **schaltet mit dir HTTPS ein** und kontrolliert, dass die Umleitung funktioniert
- **verbindet deine eigene Domain**: DNS, Zertifikat, HTTPS, angepasste Adressen
- **vergleicht SiteGround mit Railway** und sagt ehrlich, was umziehen kann und was nicht

Es antwortet in deiner Sprache (Deutsch und Englisch eingebaut).

> Inoffiziell. Dieses Plugin steht in keiner Verbindung zu SiteGround und wird von SiteGround
> nicht unterstützt.

## Was automatisch geht und was du klickst

SiteGround bietet keine öffentliche Schnittstelle, um Projekte anzulegen oder Einstellungen zu
ändern. Diese Schritte bleiben deshalb bei dir. Das Plugin erklärt jeden einzelnen und prüft
danach das Ergebnis.

| Claude erledigt | Du klickst (Claude sagt dir, wo) |
|---|---|
| Eignungsprüfung, Korrekturen im Projekt, Upload packen | Projekt anlegen, GitHub verbinden oder hochladen |
| SSH-Schlüssel erzeugen, Anmeldung testen | Öffentlichen Schlüssel einfügen |
| Build-Status, aktiven Commit und Build-Protokoll lesen | Bereitstellungsoptionen, Umgebungsvariablen |
| HTTP, HTTPS und Umleitungen prüfen | Datenbank, Cron-Job, HTTPS-Schalter |
| DNS abfragen, Cache leeren | Domain und Zertifikat |

## Installation

**Der schnelle Weg:** Diesen Satz in Claude Code einfügen, den Rest erledigt Claude.

```
Installiere das Plugin von https://github.com/Sertac0708/siteground-deploy
```

Claude führt die beiden Befehle unten für dich aus. Danach Claude Code neu starten.

**Voraussetzungen:** [Claude Code](https://claude.com/claude-code) mit `ssh`, `git`, `python3`,
`curl` und `zip` (auf macOS und den meisten Linux-Systemen vorinstalliert) sowie ein
SiteGround-Tarif mit Node.js-Projekten (GrowBig, GoGeek oder Cloud).

```bash
claude plugin marketplace add Sertac0708/siteground-deploy
```
```bash
claude plugin install siteground-deploy@siteground-deploy
```

Claude Code neu starten. Später aktualisieren mit:

```bash
claude plugin update siteground-deploy@siteground-deploy
```

Auf claude.ai (ohne Terminal) kann der Skill dich weiterhin durchs Dashboard führen, die
Prüfungen aber nicht selbst ausführen.

## So benutzt du es

Öffne deinen Projektordner in Claude Code und sag zum Beispiel:

- *„Bring dieses Projekt auf SiteGround."*
- *„Kann diese App auf SiteGround laufen?"*
- *„Verbinde meine Domain beispiel.de mit meiner SiteGround-App."*
- *„Stell das ohne GitHub auf SiteGround bereit."*
- *„Was ist der Unterschied zwischen SiteGround und Railway? Kann ich mein Projekt umziehen?"*

## Was drin ist

```
skills/siteground-deploy/
├── SKILL.md                    der Weg, Phase für Phase
├── scripts/
│   ├── check_fit.py            passt das Projekt? welche Einstellungen?
│   ├── make_archive.sh         packt das Projekt für den Upload-Weg
│   ├── setup_ssh.sh            erzeugt den SSH-Schlüssel, testet die Anmeldung
│   └── verify_deploy.sh        Build-Status, aktiver Commit, HTTP-Prüfungen
└── references/
    ├── en/ und de/
    │   ├── dashboard.md        jeder Klickweg
    │   ├── how-it-works.md     was auf dem Server passiert
    │   └── vs-railway.md       Vergleich und Umzugs-Checkliste
```

## Was das Plugin ausführt und womit es sich verbindet

Das Plugin hat keine Hooks, keinen MCP-Server und keinen Hintergrundprozess. Nichts läuft von
allein: Claude startet ein Skript nur als Teil der Schritte oben. Vollständig:

| Skript | Was es ausführt | Womit es sich verbindet |
|---|---|---|
| `check_fit.py` | Liest `package.json`, Lock-Dateien, das Dockerfile und Quelldateien des Projektordners | Nichts |
| `make_archive.sh` | `git archive` oder `zip`, schreibt eine Archivdatei neben das Projekt | Nichts |
| `setup_ssh.sh keygen` | `ssh-keygen`: erzeugt ein Schlüsselpaar in `~/.ssh` auf deinem Rechner und zeigt die öffentliche Hälfte | Nichts |
| `setup_ssh.sh test` | Eine `ssh`-Anmeldung mit diesem Schlüssel, listet die Ordner der Seite | Deine SiteGround-Seite, Port 18765 |
| `verify_deploy.sh` | Eine `ssh`-Anmeldung, die Build-Status, aktiven Commit und Build-Protokoll liest; zwei `curl`-Abrufe | Deine SiteGround-Seite (SSH) und deine eigene Domain (HTTP, HTTPS) |

Während der Anleitung kann Claude außerdem `dig` ausführen, um die DNS-Einträge deiner Domain
nachzuschlagen, und auf deiner SiteGround-Seite SiteGrounds eigenes `site-tools-client`, um
Einstellungen zu lesen oder den Cache zu leeren.

Das Plugin sendet keine Daten an den Autor oder an Dritte, hat keine Telemetrie und lädt
nichts herunter. Zugriffstokens, die in SiteGrounds Build-Dateien stehen, werden vor der
Anzeige maskiert. Passwörter, Tokens und private Schlüssel werden nie im Chat abgefragt. Siehe
[PRIVACY.md](PRIVACY.md).

## Wie verlässlich ist das?

Alles wurde im Oktober 2026 auf einem echten SiteGround-Cloud-Tarif beobachtet, wenige Tage
nach dem Start der Funktion, per SSH und im Dashboard. SiteGround wird Details ändern. Der
Skill sagt es, wenn ein Bildschirm anders aussieht, und kennzeichnet Punkte, die nicht
getestet wurden (zum Beispiel, ob Dateien im Build-Ordner eine erneute Bereitstellung
überleben, oder WebSockets), statt zu raten.

Etwas hat sich geändert? Bitte [ein Issue eröffnen](https://github.com/Sertac0708/siteground-deploy/issues).

## Lizenz

MIT — siehe [LICENSE](LICENSE).
