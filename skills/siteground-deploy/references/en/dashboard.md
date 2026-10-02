# Dashboard steps (English)

Click paths for everything that only exists in SiteGround's dashboard. Give the user one
section at a time. Each section ends with **Check**: what you verify yourself afterwards.

The labels were observed in the German interface in October 2026. English labels follow
SiteGround's documentation and may differ slightly; the German label is given in brackets
where it helps.

Seen but not carried out while writing this: the upload method (B), creating a database user
(F, steps 2 to 5) and attaching a domain (I). Those follow the pages as seen plus SiteGround's
documentation. If the user's screen differs, follow the screen and tell them what differs.

Two places:
- **Client Area**: `my.siteground.com`, the account level (list of sites and projects).
- **Site Tools**: the control panel of one site, opened with the "Site Tools" button next to it.

## Contents
A. New project from GitHub · B. New project from an upload · C. Deploy options ·
D. Environment variables · E. SSH key · F. Database · G. Cron job · H. HTTPS Enforce ·
I. Domain · J. Logs · K. Redeploy, pause, switch, delete

## A. New project from GitHub

1. Client Area → **Websites** → tab **Node.js Projects** [Node.js-Projekte] → **New Project** [Neues Projekt].
2. Choose **Import Git repository** [Git-Repository importieren] → **Continue**.
3. First time only: GitHub opens and asks to install the SiteGround app. Choose the account and
   either all repositories or only selected ones. One GitHub account can be linked to only one
   SiteGround Client Area.
4. Pick the repository from the list → **Select** [Wählen] → **Continue**. If it is missing,
   use the link "Missing a repository? Click here to add it" below the list to grant access.
5. Confirm the settings if the assistant asks (values from the fit check) and start. The build
   log is shown while it runs.
6. When it finishes, note the temporary address (`….sg-host.com`) and open **Site Tools**.

From now on every push to the linked branch builds and deploys automatically.

**Check:** `curl -sI https://<temporary-address>/` answers. After SSH is set up, run
`verify_deploy.sh`.

## B. New project from an upload

1. Build the archive with `scripts/make_archive.sh` and tell the user where the file is.
2. Client Area → **Websites** → **Node.js Projects** → **New Project**.
3. Choose **Upload your files** [Ihre Dateien hochladen] → **Continue**.
4. **Browse Files**, pick the archive (.zip, .tar.gz or .tgz, at most 128 MB), start.
5. Note the temporary address and open **Site Tools**.

Every later update is a new upload: Site Tools → Node.js → Deployment Options → the three-dot
menu of the project row → **Upload new archive**.

**Check:** as in A.

## C. Deploy options

Site Tools → **Node.js** → **Deployment Options** [Bereitstellungsoptionen].

| Field | What to enter |
|---|---|
| Framework preset [Framework-Voreinstellung] | Next.js, Nuxt, React, Vue, Angular, SvelteKit, Astro, Remix, Gatsby, Express, NestJS or Custom. Use the value from the fit check; "Custom" for a plain `server.js`. |
| Branch | The branch that should deploy (GitHub method only). |
| Node version | 18, 20, 22, 24 or 26. |
| Package manager [Paketmanager] | npm, yarn or pnpm. |
| Build command [Build-Befehl] | The field already shows the package manager. Enter only the rest, e.g. `run build`. Leave empty if the project has no build step. |
| Output directory [Ausgabeverzeichnis] | Only for projects that build static files, e.g. `dist`. Otherwise empty. |

There is no field for a start command.

- **Save** [Speichern] stores the values.
- **Save and deploy** [Speichern und bereitstellen] stores them and starts a new deploy
  without a push.

**Check:** `verify_deploy.sh` shows a new build with status `completed`.

## D. Environment variables

Same page, section **Add new environment variables** [Neue Umgebungsvariablen hinzufügen]:
**Key** [Schlüssel], **Value** [Wert], **Create** [Erstellen]. The app reads them as
`process.env.KEY`.

Give the user the list of keys the app needs and where each value comes from. They type the
values themselves; secrets do not go through the chat. Afterwards **Save and deploy**, because
a running app does not pick up new variables.

**Check:** `verify_deploy.sh` lists the variable names under `== env ==` (never the values).

## E. SSH key

1. You run `scripts/setup_ssh.sh keygen --name <label>` and show the user the public key
   (one line starting with `ssh-ed25519`).
2. Site Tools → **Devs** → **SSH Keys Manager** [SSH-Schlüssel-Manager] → tab **Import**
   [Importieren] (not "Generate").
3. Any key name, paste the public key, **Import**.
4. On the same page, box **SSH credentials** [SSH-Anmeldeinformationen]: the user tells you
   **Hostname** (e.g. `ssh.example.com`) and **Username** (e.g. `u12-abcdefgh`). Port is 18765.

**Check:** `scripts/setup_ssh.sh test …` prints `login ok`. One attempt only.

## F. Database

Site Tools → **Site** → **PostgreSQL** or **MySQL**.

1. Tab **Databases** [Datenbanken] → **Create database** [Datenbank erstellen]. The name is
   generated automatically.
2. Tab **Users** [Benutzer] → create a user. SiteGround generates the password: the user copies
   it straight into a password manager or the environment variable form.
3. Give the user access to the database (in the Users tab: manage access / add to database).
4. Enter the connection as environment variables (section D), for example `DATABASE_URL` or
   separate `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`. Host is `localhost`;
   ports are 5432 (PostgreSQL) and 3306 (MySQL).
5. Only if something outside SiteGround must reach the database: tab **Remote** → add the IP
   address of that machine.

**Check:** over SSH, `psql -h localhost -U <db-user> -d <db-name> -c 'select 1'` (it asks for
the password: let the user run this one) or simply call a route of the app that reads from
the database.

## G. Cron job

Site Tools → **Devs** → **Cron Jobs**.

1. **Command** [Befehl]: a full shell command with absolute paths, for example
   `cd /home/customer/www/<domain>/public_html/.nodeapp/latest/app_source && /usr/local/bin/node scripts/task.js`
2. **Interval** [Intervall]: pick a preset or enter the five cron fields
   (minute hour day month weekday).
3. **Create** [Erstellen]. The second tab manages notification emails for failed runs.

A cron job is a separate short process, not part of the running app. It does not get the
app's environment variables automatically: the script has to load what it needs.

**Check:** over SSH `site-tools-client cron list -j` shows the job. After its first scheduled
run, check whatever the job produces.

## H. HTTPS Enforce

Site Tools → **Security** [Sicherheit] → **HTTPS Enforce** [HTTPS erzwingen] → turn the switch
on for the domain.

**Check:** `curl -sI http://<domain>/` answers 301 with a `Location: https://…` header.
`verify_deploy.sh` reports this too.

## I. Domain

Find the site IP first: Site Tools → **Dashboard** → "IP and Name Servers" → **Site IP**.

**Step 1: attach the domain to the project.** Two ways:

- **Make it the main domain** (recommended when the app should live under this domain):
  Client Area → Websites → Node.js Projects → three-dot menu of the project →
  **Change Domain Name** [Domainnamen ändern].
- **Add it as an extra domain** that opens the same app: Site Tools → **Domain** →
  **Parked Domains** [Geparkte Domains] → enter the domain → **Add**. SiteGround requires the
  domain to be registered and its DNS to point to SiteGround already (step 2 first).

**Step 2: DNS at the place where the domain is registered.** Two ways:

- **Only A records** (keeps email and everything else where it is): set the A record for `@`
  and for `www` to the site IP.
- **Name servers** `ns1.siteground.net` and `ns2.siteground.net`: SiteGround then manages the
  whole zone (Site Tools → Domain → DNS Zone Editor). Mail records move too, so existing email
  stops working unless its records are recreated there. Ask before recommending this.

You check propagation: `dig +short <domain>` and `dig +short www.<domain>` must return the
site IP. This can take from minutes to a few hours.

**Step 3: certificate.** Site Tools → Security → **SSL Manager**: if the new domain has no
certificate listed, select the domain, choose **Let's Encrypt** and **Get**. This only works
once DNS points to SiteGround.

**Step 4:** HTTPS Enforce for the new domain (section H).

**Step 5:** update URL-related environment variables and **Save and deploy** (section D).

**Check:** `curl -sI https://<domain>/` answers 200 with a valid certificate,
`http://<domain>/` redirects, `www.<domain>` behaves as intended.

## J. Logs

- **Build logs:** Site Tools → Node.js → **Logs** [Protokolle]. One row per deploy with author,
  branch, commit, time and status; three-dot menu → **View build log** [Build-Log anzeigen].
- **HTTP errors:** Site Tools → **Statistics** [Statistiken] → **Error Log** [Fehlerprotokoll]
  (last 300 errors) and **Access Log**.
- Console output of the running app was not found anywhere.

## K. Redeploy, pause, switch, delete

Site Tools → Node.js → Deployment Options → three-dot menu of the project row:
**Pause** auto-deploy, **Switch repositories**, **Disconnect** from GitHub,
**Upload manually** (switch to the upload method).

Deleting the whole project: Client Area → Websites → Node.js Projects → three-dot menu →
**Delete**. This removes the site with its files and databases: only on the user's explicit
wish, and only they click it.
