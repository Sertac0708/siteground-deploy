---
name: siteground-deploy
description: >-
  Get a Node.js project live on SiteGround's Node.js hosting, step by step, from zero to a custom domain with HTTPS. Checks whether the project fits (Node.js yes; Python services, Docker, Redis and extra workers no), prepares the repo, walks the user through every dashboard click (new project via GitHub auto-deploy or ZIP upload, deploy options, environment variables, MySQL/PostgreSQL, cron jobs, SSH key, HTTPS Enforce, domain and DNS), does everything else itself over SSH, verifies the live deploy, and explains how SiteGround differs from Railway and what can move over. Use whenever the user mentions SiteGround, Site Tools, sg-host.com, "Node.js project" hosting, deploying or uploading an app to their web hosting, connecting a domain to a SiteGround app, or moving off Railway, Vercel, Render or Heroku to SiteGround — also for "can this run on SiteGround?" and for German requests such as "auf SiteGround deployen", "Domain verbinden" or "Railway ersetzen".
license: MIT
metadata:
  author: Sertac
  publisher: NetBoosting GmbH (https://netboosting.de)
  version: "1.0.0"
  created: "2026-10-02"
---

# SiteGround Deploy

Take a Node.js project from a folder on the user's machine to a running app on SiteGround,
reachable under their own domain with HTTPS. Many people using this skill are not developers:
lead them, one step at a time, and do every part yourself that can be done from a terminal.

**Language:** answer in the user's language. The reference files exist in English and German:
read `references/en/…` or `references/de/…` to match (for any other language, read the English
ones and translate). Dashboard labels are given in both languages inside the files.

## What you do and what the user clicks

SiteGround has no public API for this, and the command-line client on the server is read-only
(turning on HTTPS, creating a cron job or attaching a domain were all rejected when tested).
So the work splits cleanly:

| You do it (terminal, SSH, HTTP) | The user clicks it (dashboard) |
|---|---|
| Fit check, repo fixes, packing the upload archive | Creating the project, connecting GitHub, uploading |
| Generating the SSH key, testing the login | Importing the public key |
| Reading the build result, live commit, build log | Deploy options, environment variables |
| Checking HTTP/HTTPS, redirects, cache headers | Database, cron job, HTTPS Enforce |
| Flushing the cache, DNS lookups | Domain, SSL certificate |

For every dashboard step: give the click path and the exact values to paste (from
`references/<lang>/dashboard.md`), one step at a time, wait until the user says it is done, then
**check the result yourself** instead of asking them whether it worked. If you have a browser
tool and the user wants you to click for them, you may, but confirm before anything that saves,
creates or deletes, and never type passwords.

Never ask the user to paste passwords, tokens or private keys into the chat. Secrets go
straight from the user into the SiteGround form.

## How current this knowledge is

Everything here was observed on a SiteGround Cloud plan in October 2026, days after the feature
launched. SiteGround will change things. If a page looks different from the description, say
so and work from what the user sees. Points marked *unverified* below were not tested: test
them on the user's project before promising anything.

## The route

Work through the phases in order. Skip a phase only if it is already done, and say that you
skipped it.

### 0. Clarify (one short round of questions)

- Which folder is the project? Is it on GitHub?
- Which SiteGround plan? Node.js projects: StartUp none, GrowBig 5, GoGeek 10, Cloud unlimited.
- GitHub auto-deploy (recommended: every push deploys) or upload of a ZIP (no GitHub needed,
  every update is a new upload)?
- Is there a domain that should point to the app later?

### 1. Fit check

```bash
python3 scripts/check_fit.py <project-dir>
```

It reads `package.json`, lock files, the Dockerfile and source files, and prints a verdict
(fits / fits with changes / does not fit), the reasons, and the values for the deploy options.
Explain the result in plain words. If it does not fit, stop and say what the alternatives are
(`references/<lang>/vs-railway.md`): do not try to force Python, Docker or Redis onto SiteGround.

### 2. Prepare the project

Fix what the fit check listed, then confirm these four things, because SiteGround gives no
way to work around them later:

- **Start:** Site Tools has no start-command field. `npm start` must start the server, and
  `"main"` in `package.json` should point at the server file.
- **Port:** listen on `process.env.PORT`. A hard-coded port is a gamble.
- **Data on disk:** every deploy is built in its own folder. Files the app writes next to its
  code (uploads, SQLite, JSON state) should live outside it, at a path taken from an
  environment variable such as `DATA_DIR=/home/customer/data`. Whether files inside the build
  folder survive a redeploy is *unverified*, so do not rely on it.
- **Secrets:** nothing secret in the repo or the archive. Values go into the environment
  variables in Site Tools.

If the project is a monorepo with the app in a subfolder: no root-directory setting was found,
so the app needs to be at the root of its repository or get its own repository.

### 3. Create the project

Guide the user with section A (GitHub) or B (upload) of `references/<lang>/dashboard.md`.
For the upload method, build the archive first:

```bash
bash scripts/make_archive.sh <project-dir>
```

It packs tracked files only (no `node_modules`, no `.git`, no `.env`), keeps `package.json`
at the top level and checks the 128 MB limit. Tell the user where the file is.

Give the user the deploy-option values from the fit check. When the first build has run, the
project gets a temporary address like `something.sg-host.com`. Ask the user for it.

### 4. SSH access (once per project)

Each SiteGround site has its own SSH user. Port is always 18765.

```bash
bash scripts/setup_ssh.sh keygen --name <short-label>
```

Show the user the public key it prints and guide them through section E of the dashboard file
(import the key, then read host and user name from the same page). Then:

```bash
bash scripts/setup_ssh.sh test --domain <domain> --user <ssh-user> --key ~/.ssh/<short-label>_siteground
```

**Only ever connect with a key and user you know are right, one attempt at a time.** SiteGround
blocks the client IP for *all* of the account's sites after a few rejected keys. If the login
fails, stop and fix the cause with the user. Always pass `-o BatchMode=yes -o IdentitiesOnly=yes`
in your own ssh commands (the scripts already do).

### 5. Settings the app needs

Only what this project needs, each from the matching section of the dashboard file:

- **Environment variables** (section D), then "Save and deploy" so they take effect.
- **Database** (section F): MySQL or PostgreSQL, created in Site Tools, connection details
  entered as environment variables by the user.
- **Cron jobs** (section G) for scheduled tasks. A cron job runs a shell command on the server.

### 6. Verify

```bash
bash scripts/verify_deploy.sh --domain <domain> --user <ssh-user> --key <key> --repo <project-dir> --path /
```

It shows the build status, the commit that is live, whether it matches the local repo, the
names (not values) of the environment variables, the end of the build log, and the HTTP
answers. A deploy is only done when the build is `completed`, the live commit is the expected
one, and the page answers. If the build failed, read the log it printed: exit code 2 is the
install step (or its 5-minute limit), 3 is the build step.

### 7. HTTPS

A new project answers on plain `http://` without redirecting. Guide the user through section H
(one switch), then run the verify script again and confirm that `http://` now redirects.

### 8. Connect the domain

Section I of the dashboard file: choose between changing the project's main domain and adding
the domain as an extra (parked) one, set DNS, get the certificate, turn on HTTPS Enforce for the
new domain. Check DNS yourself with `dig +short <domain>` against the site IP before the user
goes on. Afterwards:

- Update every environment variable that contains a URL (base URL, API URL, allowed origins),
  then "Save and deploy". Frameworks such as Next.js bake public variables in at build time, so
  a rebuild is required.
- If the main domain was changed, the SSH host name and the folder under `~/www/` may change
  with it (*unverified*): read both again from the SSH Keys Manager and `ls ~/www`.
- Run the verify script against the new domain.

### 9. Final report

End with a short summary: address, how updates are deployed from now on (push or new upload),
what was set up (variables by name, database, cron, HTTPS, domain), the SSH command for later,
and anything still open.

## Traps

- **IP block after failed SSH logins.** See phase 4. Unblock: Site Tools → Security → Blocked
  Traffic, or wait 30–60 minutes.
- **Secrets in build files.** `build_settings.json` and the build log on the server contain the
  Git URL including an access token, and `site-tools-client app list` prints a private
  notification URL. Never print these unmasked (the scripts mask them) and never copy them
  into a chat, an issue or a commit.
- **The lock file may be ignored.** In the observed build SiteGround deleted
  `package-lock.json` before `npm install`. Pin exact versions in `package.json` if a
  dependency must not move.
- **Caching in front of the app.** Responses pass SiteGround's cache (look for the
  `x-proxy-cache` header). API routes should send `Cache-Control: no-store`. To flush:
  `site-tools-client domain update id=<id> flush_cache=1` on the server (the id comes from
  `site-tools-client domain list -j`).
- **Same repo connected twice.** If the branch is also connected to Railway, Vercel or similar,
  every push deploys to both. Pause one of them.
- **`site-tools-client` rate limit.** Five connections per second, then errors. Pause a second
  between calls.
- **No runtime log was found.** Neither Site Tools nor SSH showed the app's console output.
  For debugging, write to a log file in the data directory, or use an external log service.

## SiteGround or Railway?

Read `references/<lang>/vs-railway.md` when the user asks what the difference is, whether they
can replace Railway (or a similar platform), or when the fit check says no. Short version:
SiteGround runs one Node.js process per project on a server shared with the user's other
sites, with MySQL/PostgreSQL, cron and email included in a flat price. Railway runs any
container (Python, Docker, Redis, workers) with resources per service.

## More detail

- `references/<lang>/dashboard.md`: every click path, with copy-ready values and what to check
  afterwards.
- `references/<lang>/how-it-works.md`: what a Node.js project is (for beginners), what happens
  on the server during a deploy, where files live, limits.
- `references/<lang>/vs-railway.md`: comparison and a checklist for moving a service over.
