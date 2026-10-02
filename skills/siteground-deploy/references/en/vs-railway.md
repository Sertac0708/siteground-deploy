# SiteGround or Railway? (English)

Use this when someone asks what the difference is, whether SiteGround can replace Railway
(the same reasoning applies to Render, Fly.io or Heroku), or when the fit check says no.

## The basic difference

- **Railway** starts a separate container for every service. What runs inside does not
  matter: Node.js, Python, Redis, anything with a Dockerfile. Each service has its own
  resources and is billed by usage.
- **SiteGround** is one server with fixed service types. A site gets a web server for PHP and,
  for a Node.js project, exactly one Node.js process. All sites of the account share the
  server's memory and disk, at a flat price.

## Feature by feature

| Capability | Railway | SiteGround Node.js project |
|---|---|---|
| Node.js app from GitHub, deploy on push | yes | yes |
| Deploy without GitHub | CLI upload | ZIP upload in the dashboard |
| Python web service (FastAPI, Django, Flask) | yes | no |
| Docker / Dockerfile | yes | no |
| Extra always-on processes (workers, bots, queues) | yes, as separate services | no, one Node.js process per project |
| Scheduled jobs | cron services, each its own container | cron jobs: a shell command on a schedule |
| PostgreSQL | yes, as a service | yes, created in Site Tools |
| MySQL | yes, as a service | yes, created in Site Tools |
| Redis | yes | no usable Redis found |
| Persistent files | volumes | the home directory |
| Environment variables | yes | yes |
| Custom start command | yes | no field for it |
| App in a subfolder of the repo | root directory setting | no such setting found |
| Runtime logs | yes | not found; build log and HTTP error log only |
| Resources | per service, scalable | shared with the account's other sites |
| Custom domain and SSL | yes | yes, plus DNS zone and email hosting |
| Email mailboxes | no | yes |
| Backups | volume backups, depending on plan | automatic daily backups of the whole site, up to 30 days |
| Pricing | usage-based | included in the hosting plan |

## What can move, what stays

**Moves well:** Node.js web apps and APIs with one process, front ends (Next.js, React, Vue
and similar), small Express servers, apps that only need MySQL or PostgreSQL.

**Stays on Railway (or similar):** anything in Python that must run permanently, anything
that needs a Dockerfile, Redis, queue workers, several processes, headless browsers, heavy
video or image processing, apps whose logs you need to watch live.

**Possible but test first:** scripts on a schedule. SiteGround cron can run a Node.js or
Python script, but it shares the server with the websites and has no isolation. A front end
can move while its Python back end stays: then the front end's API URL must point to the
back end's public address, and the back end must allow the new origin (CORS).

## Moving one service over: checklist

1. Run the fit check on the service's folder. Stop if it does not fit.
2. List what the service uses on Railway: environment variables, database, volume, cron
   schedule, custom domain.
3. Create the SiteGround project (GitHub or upload) and set the environment variables. Leave
   Railway running.
4. Database: create it on SiteGround, export from Railway (`pg_dump` or `mysqldump`) and
   import it over SSH. Do this with the app stopped or read-only, so nothing is written
   during the copy.
5. Files from a volume: copy them into a folder in the SiteGround home directory and point the
   app at it with an environment variable.
6. Cron: recreate each schedule in Site Tools as a command.
7. Test everything on the temporary `sg-host.com` address.
8. Switch DNS to SiteGround, get the certificate, turn on HTTPS Enforce.
9. Update every URL variable on both sides (base URL, API URL, allowed origins) and redeploy.
10. If both platforms are connected to the same branch, every push deploys twice: pause
    auto-deploy on the one you are leaving. Remove the Railway service only after the new one
    has run cleanly for a few days.
