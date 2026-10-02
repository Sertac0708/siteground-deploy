# How SiteGround's Node.js hosting works (English)

Observed over SSH and in Site Tools on a Cloud plan, October 2026.

## For beginners: what is a Node.js project?

A Node.js project is a program written in JavaScript (or TypeScript) that runs on a server
instead of in the browser. You recognise it by a file called `package.json` in the project
folder: it lists the building blocks the program needs and the command that starts it
(usually `npm start`). If the folder has a `requirements.txt` instead, it is Python; if it
only has a `Dockerfile`, it is a container. Neither is a Node.js project.

What can be a Node.js project:
- web apps built with a framework (Next.js, Nuxt, Remix, Astro, SvelteKit)
- pure front ends that are built once into static files (React, Vue, Angular, Svelte)
- APIs and back ends (Express, Fastify, NestJS, Koa)
- a small hand-written server in a single `server.js`

SiteGround has three kinds of sites: classic PHP sites (WordPress and similar), static sites
(uploaded HTML), and since October 2026 Node.js projects. Every site also gets MySQL and
PostgreSQL databases, cron jobs, email, SSL and SSH.

## What happens on a deploy

1. A push to the linked branch (or "Save and deploy", or a new upload) triggers a build.
2. SiteGround makes a shallow clone of the repository into a build folder.
3. It runs the package manager's install (`npm install` by default), limited to 5 minutes.
4. If a build command is set, it runs it with `NODE_ENV=production`, limited to 5 minutes.
5. On success the build is switched live. Exit code 2 means the install failed or timed out,
   3 means the build command failed.

There is no container. The app runs as an ordinary process of the site's own Linux user, on
the same server as the account's other sites.

## Where things live on the server

```
~/www/<domain>/
├── .nodejs_version              Node major version of the site
└── public_html/
    └── .nodeapp/
        ├── app.json             package manager, install and build command
        ├── .env-local           environment variables (the build script loads it if present)
        ├── latest -> <build>    the live build
        └── <build>/
            ├── app_source/      the code, plus node_modules
            ├── git_info         commit, author, branch, subject of the live commit
            ├── build_info.json  {"status":"completed"} or {"status":"failed"}
            ├── build_script.exit_code
            ├── current          the build log
            ├── build_script.sh  the script SiteGround ran
            └── build_settings.json   contains the Git URL with an access token
```

`.nodeapp` is not reachable from the web (HTTP 403).

The home directory (`/home/customer`) is persistent and writable. That is the place for data
the app must keep: create a folder there and pass its path to the app as an environment
variable. Whether files written inside `app_source/` survive the next deploy was not tested.

## Tools on the server

Reached over SSH (port 18765): Node.js 18, 20, 22, 24 and 26, npm, git, Python 3 with pip and
venv, PHP, Ruby, ffmpeg, ImageMagick, `psql`, `mysql`, curl, rsync. Outbound HTTPS works. No
Docker, no Go, no Java. The shell is restricted: no process list, no `crontab` command.

`site-tools-client` is SiteGround's own command-line client. What works for a site user:

| Command | Result |
|---|---|
| `site-tools-client app list -j` | the Node.js app (contains a private notification URL: mask it) |
| `site-tools-client domain list -j` | domains with settings such as `https_enforce`, cache flags, Node version |
| `site-tools-client domain update id=<id> flush_cache=1` | flushes the cache |
| `site-tools-client cron list -j` | cron jobs |
| `site-tools-client dns list -j` | DNS records of the zone |
| `site-tools-client site list -j` | disk usage and plan features |
| `site-tools-client uservice list -j` | services of the site (`apache`, `nodejs-1`) |

Changing settings (`https_enforce`), creating cron jobs or domain aliases through this client
is rejected: those are dashboard-only. The client allows five connections per second.

## Limits seen

- One supervised Node.js process per project. No second process type for workers.
- Install and build: 5 minutes each.
- Upload archive: 128 MB.
- Per-user limits on the observed server: 160 processes, about 2 GB memory per process.
- Disk and memory are shared with the account's other sites.
- Backups are daily and kept up to 30 days; the first one appears about 6 hours after the
  project is created.

## Not verified

- Whether files inside the build folder survive a redeploy.
- How the start command is chosen (`npm start` or `main`): set both.
- Where the running app's console output goes.
- WebSockets.
- Whether an idle app is put to sleep.
- A root-directory setting for monorepos (none was found).
