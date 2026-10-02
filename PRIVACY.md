# Privacy policy — SiteGround Deploy

🇩🇪 [Deutsche Fassung weiter unten](#datenschutzerklärung--siteground-deploy)

SiteGround Deploy is a skill for Claude, created by Sertac ·
[NetBoosting GmbH](https://netboosting.de). It consists of instructions and four small helper
scripts that run on your own computer. It runs no server.

## What the skill does NOT do
- It collects **no** personal data and has **no** telemetry, analytics or tracking.
- It sends **nothing** to the author, to NetBoosting GmbH or to any server operated by them.
- It never asks you to paste passwords, tokens or private keys into the chat.
- It does not create, change or delete anything in your SiteGround account on its own. Those
  steps are clicks you make yourself.

## What happens when you use it
- `check_fit.py` and `make_archive.sh` only read files in the project folder you point them at.
- `setup_ssh.sh` creates an SSH key pair in `~/.ssh` on your computer. The private key stays
  there and is never displayed. Only the public key is shown, for you to paste into SiteGround.
- `setup_ssh.sh` and `verify_deploy.sh` connect over SSH to **your own** SiteGround site and
  read build information there. Output from the server is masked for access tokens before it
  is shown. `verify_deploy.sh` also requests your own site over HTTP and HTTPS.
- What Claude sees of the output becomes part of your Claude conversation. How Claude stores
  conversations is governed by your agreement with Anthropic. SiteGround's and GitHub's own
  privacy policies apply to their services.

## Contact
Questions or concerns: open an issue at <https://github.com/Sertac0708/siteground-deploy/issues>.

---

# Datenschutzerklärung — SiteGround Deploy

SiteGround Deploy ist ein Skill für Claude, erstellt von Sertac ·
[NetBoosting GmbH](https://netboosting.de). Er besteht aus Anleitungen und vier kleinen
Hilfsskripten, die auf deinem eigenen Rechner laufen. Er betreibt keinen Server.

## Was der Skill NICHT tut
- Er erhebt **keine** personenbezogenen Daten und hat **keine** Telemetrie, Analyse oder
  Nachverfolgung.
- Er sendet **nichts** an den Autor, an die NetBoosting GmbH oder an einen von ihnen
  betriebenen Server.
- Er bittet dich nie, Passwörter, Tokens oder private Schlüssel in den Chat einzufügen.
- Er legt in deinem SiteGround-Konto nichts selbstständig an, ändert oder löscht nichts. Diese
  Schritte sind Klicks, die du selbst machst.

## Was bei der Nutzung passiert
- `check_fit.py` und `make_archive.sh` lesen nur Dateien im Projektordner, den du angibst.
- `setup_ssh.sh` erzeugt ein SSH-Schlüsselpaar in `~/.ssh` auf deinem Rechner. Der private
  Schlüssel bleibt dort und wird nie angezeigt. Nur der öffentliche Schlüssel wird gezeigt,
  damit du ihn bei SiteGround einfügen kannst.
- `setup_ssh.sh` und `verify_deploy.sh` verbinden sich per SSH mit **deiner eigenen**
  SiteGround-Seite und lesen dort Build-Informationen. Ausgaben des Servers werden vor der
  Anzeige auf Zugriffstokens maskiert. `verify_deploy.sh` ruft außerdem deine eigene Seite per
  HTTP und HTTPS auf.
- Was Claude von der Ausgabe sieht, wird Teil deiner Claude-Unterhaltung. Wie Claude
  Unterhaltungen speichert, regelt deine Vereinbarung mit Anthropic. Für die Dienste von
  SiteGround und GitHub gelten deren eigene Datenschutzerklärungen.

## Kontakt
Fragen oder Bedenken: ein Issue eröffnen unter <https://github.com/Sertac0708/siteground-deploy/issues>.
