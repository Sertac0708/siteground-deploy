# 🚀 SiteGround Deploy — a Claude plugin that gets your Node.js project live on SiteGround

> **Created by Sertac · [NetBoosting GmbH](https://netboosting.de)** · Free to use under the MIT license. · 🇩🇪 [Deutsche Anleitung](README.de.md)

Since October 2026 SiteGround can host Node.js apps: connect a GitHub repository or upload a
ZIP, and SiteGround builds and runs it. The feature is new, the dashboard has many places to
click, and some things only work if you know them beforehand.

**SiteGround Deploy** turns that into a guided route. Tell Claude *"put this project on
SiteGround"* and it

- **checks whether your project fits** (Node.js yes; Python services, Docker, Redis and extra
  workers no) and tells you what to change first
- **prepares the project**: start command, port, where data is stored, no secrets in the repo
- **walks you through every click** in the SiteGround dashboard, one step at a time, with the
  exact values to enter — via **GitHub auto-deploy** or via **ZIP upload**
- **sets up SSH access** safely (it creates the key, you paste one line)
- **explains environment variables, databases and cron jobs** for exactly what your app needs
- **verifies the result itself**: build status, which commit is live, does the page answer
- **turns on HTTPS** with you and checks that the redirect works
- **connects your own domain**: DNS, certificate, HTTPS, updated addresses
- **compares SiteGround with Railway** and tells you honestly what can move and what cannot

It answers in your language (German and English built in).

> Unofficial. This plugin is not affiliated with or endorsed by SiteGround.

## What is automatic and what you click

SiteGround offers no public interface for creating projects or changing settings, so those
steps stay with you. The plugin explains each one and checks the result afterwards.

| Claude does it | You click it (Claude tells you where) |
|---|---|
| Fit check, fixes in the project, packing the upload | Create the project, connect GitHub or upload |
| Creating the SSH key, testing the login | Paste the public key |
| Reading build status, live commit and build log | Deploy options, environment variables |
| Checking HTTP, HTTPS and redirects | Database, cron job, HTTPS switch |
| DNS lookups, flushing the cache | Domain and certificate |

## Installation

**The quick way:** paste this sentence into Claude Code and let it do the rest.

```
Install the plugin from https://github.com/Sertac0708/siteground-deploy
```

Claude runs the two commands below for you. Restart Claude Code afterwards.

**Requirements:** [Claude Code](https://claude.com/claude-code) with `ssh`, `git`, `python3`,
`curl` and `zip` (preinstalled on macOS and most Linux systems), and a SiteGround plan that
includes Node.js projects (GrowBig, GoGeek or Cloud).

```bash
claude plugin marketplace add Sertac0708/siteground-deploy
```
```bash
claude plugin install siteground-deploy@siteground-deploy
```

Restart Claude Code. Update later with:

```bash
claude plugin update siteground-deploy@siteground-deploy
```

On claude.ai (without a terminal) the skill can still guide you through the dashboard, but it
cannot run the checks itself.

## How to use it

Open your project folder in Claude Code and say, for example:

- *"Put this project on SiteGround."*
- *"Can this app run on SiteGround?"*
- *"Connect my domain example.com to my SiteGround app."*
- *"Deploy this to SiteGround without GitHub."*
- *"What is the difference between SiteGround and Railway? Can I move my project?"*

## What is inside

```
skills/siteground-deploy/
├── SKILL.md                    the route, phase by phase
├── scripts/
│   ├── check_fit.py            does the project fit? which settings?
│   ├── make_archive.sh         packs the project for the upload method
│   ├── setup_ssh.sh            creates the SSH key, tests the login
│   └── verify_deploy.sh        build status, live commit, HTTP checks
└── references/
    ├── en/ and de/
    │   ├── dashboard.md        every click path
    │   ├── how-it-works.md     what happens on the server
    │   └── vs-railway.md       comparison and moving checklist
```

## What the plugin runs and connects to

The plugin has no hooks, no MCP server and no background process. Nothing runs on its own:
Claude runs a script only as part of the steps above. In full:

| Script | What it runs | What it connects to |
|---|---|---|
| `check_fit.py` | Reads `package.json`, lock files, the Dockerfile and source files of the project folder | Nothing |
| `make_archive.sh` | `git archive` or `zip` to write one archive file next to the project | Nothing |
| `setup_ssh.sh keygen` | `ssh-keygen`: creates a key pair in `~/.ssh` on your machine and prints the public half | Nothing |
| `setup_ssh.sh test` | One `ssh` login with that key, lists the site folders | Your SiteGround site, port 18765 |
| `verify_deploy.sh` | One `ssh` login that reads build status, live commit and build log; two `curl` requests | Your SiteGround site (SSH) and your own domain (HTTP, HTTPS) |

While guiding you, Claude may also run `dig` to look up your domain's DNS records and, on your
SiteGround site, SiteGround's own `site-tools-client` to read settings or flush the cache.

The plugin sends no data to the author or to any third party, has no telemetry, and downloads
nothing. Access tokens that appear in SiteGround's build files are masked before output is
shown. Passwords, tokens and private keys are never requested in the chat. See
[PRIVACY.md](PRIVACY.md).

## How reliable is this?

Everything was observed on a real SiteGround Cloud plan in October 2026, a few days after the
feature launched, over SSH and in the dashboard. SiteGround will change details. The skill
says so when a screen looks different, and it marks points that were not tested (for example
whether files in the build folder survive a redeploy, or WebSockets) instead of guessing.

Found something that changed? Please [open an issue](https://github.com/Sertac0708/siteground-deploy/issues).

## License

MIT — see [LICENSE](LICENSE).
