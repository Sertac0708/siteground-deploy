#!/usr/bin/env python3
"""Check whether a project can run as a SiteGround Node.js project.

Usage: check_fit.py [project-dir] [--json]

Reads only local files (package.json, lock files, Dockerfile, a few source
files). Sends nothing anywhere. Exit code: 0 = fits, 1 = fits with changes,
2 = does not fit.
"""
import json
import os
import re
import sys

NODE_VERSIONS = [18, 20, 22, 24, 26]  # offered in Site Tools, October 2026

# Order matters: the first match wins.
PRESETS = [
    ("next", "Next.js"), ("nuxt", "Nuxt"), ("@sveltejs/kit", "SvelteKit"),
    ("astro", "Astro"), ("@remix-run/node", "Remix"), ("@remix-run/react", "Remix"),
    ("gatsby", "Gatsby"), ("@nestjs/core", "NestJS"), ("@angular/core", "Angular"),
    ("express", "Express"), ("vue", "Vue"), ("react", "React"),
]

OTHER_RUNTIMES = [
    ("requirements.txt", "Python"), ("pyproject.toml", "Python"), ("Pipfile", "Python"),
    ("go.mod", "Go"), ("Cargo.toml", "Rust"), ("pom.xml", "Java"),
    ("build.gradle", "Java"), ("Gemfile", "Ruby"),
]

REDIS = {"redis", "ioredis", "bullmq", "bull", "connect-redis", "bee-queue"}
SQL = {"pg", "postgres", "mysql", "mysql2", "prisma", "@prisma/client", "sequelize",
       "knex", "drizzle-orm", "typeorm"}
MONGO = {"mongodb", "mongoose"}
SOCKETS = {"ws", "socket.io", "uWebSockets.js"}
BROWSERS = {"puppeteer", "playwright", "playwright-core"}
NATIVE = {"sharp", "better-sqlite3", "sqlite3", "canvas", "bcrypt", "node-gyp"}
LOCAL_FILES = {"better-sqlite3", "sqlite3", "lowdb", "nedb", "multer"}
SKIP_DIRS = {"node_modules", ".git", ".next", "dist", "build", ".nuxt", ".output", "coverage"}


def read_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def source_files(root, limit=200):
    out = []
    for base, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".")]
        for name in files:
            if name.endswith((".js", ".mjs", ".cjs", ".ts")):
                out.append(os.path.join(base, name))
                if len(out) >= limit:
                    return out
    return out


def scan_sources(root):
    """Look for a hard-coded port and for files written inside the project."""
    hard_port = writes = uses_env_port = False
    for path in source_files(root):
        try:
            with open(path, encoding="utf-8", errors="ignore") as f:
                text = f.read(200_000)
        except OSError:
            continue
        if "process.env.PORT" in text:
            uses_env_port = True
        if re.search(r"\.listen\(\s*\d{2,5}\b", text):
            hard_port = True
        if re.search(r"\b(writeFile(Sync)?|appendFile(Sync)?|createWriteStream)\(", text):
            writes = True
    return hard_port and not uses_env_port, writes


def pick_node(engines):
    wanted = re.findall(r"\d+", str(engines or ""))
    if not wanted:
        return 22, "no engines.node in package.json, so the current LTS"
    major = int(wanted[0])
    if str(engines).strip().startswith(">") and major <= 22:
        return 22, f"engines.node is '{engines}', so the current LTS"
    for v in NODE_VERSIONS:
        if v >= major:
            return v, f"engines.node is '{engines}'"
    return NODE_VERSIONS[-1], f"engines.node is '{engines}'"


def check(root):
    blockers, changes, notes, settings = [], [], [], {}
    pkg = read_json(os.path.join(root, "package.json"))
    others = sorted({lang for f, lang in OTHER_RUNTIMES if os.path.exists(os.path.join(root, f))})

    if pkg is None:
        if others:
            blockers.append(f"This is a {'/'.join(others)} project. SiteGround only runs Node.js as a "
                            "long-running service; other languages work for cron scripts at most.")
        elif os.path.exists(os.path.join(root, "composer.json")) or os.path.exists(os.path.join(root, "index.php")):
            blockers.append("This is a PHP project: use a normal SiteGround website, not a Node.js project.")
        elif os.path.exists(os.path.join(root, "index.html")):
            blockers.append("Plain static site: upload it to a normal SiteGround website, no Node.js project needed.")
        else:
            sub = [d for d in sorted(os.listdir(root))
                   if os.path.isfile(os.path.join(root, d, "package.json"))]
            if sub:
                blockers.append("No package.json at the repo root, only in: " + ", ".join(sub) +
                                ". No root-directory setting was found in Site Tools, so the app has to "
                                "live at the root of its repository (or get its own repo).")
            else:
                blockers.append("No package.json found: not a Node.js project.")
        return blockers, changes, notes, settings

    deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
    scripts = pkg.get("scripts", {}) or {}

    preset = next((label for dep, label in PRESETS if dep in deps), "Custom")
    if os.path.exists(os.path.join(root, "pnpm-lock.yaml")):
        manager = "pnpm"
    elif os.path.exists(os.path.join(root, "yarn.lock")):
        manager = "yarn"
    else:
        manager = "npm"
    node, why = pick_node((pkg.get("engines") or {}).get("node"))
    settings = {"framework_preset": preset, "package_manager": manager,
                "node_version": node, "node_version_reason": why,
                "build_command": "run build" if "build" in scripts else "",
                "output_directory": ""}
    if preset in ("React", "Vue") and "build" in scripts:
        settings["output_directory"] = "build" if "react-scripts" in deps else "dist"
    if preset == "Angular":
        settings["output_directory"] = "dist/<project-name>/browser"

    static_build = preset in ("React", "Vue", "Angular") and "express" not in deps
    if not static_build and "start" not in scripts and not pkg.get("main"):
        changes.append('package.json has neither "scripts.start" nor "main". Site Tools has no '
                       "start-command field, so add both (e.g. \"start\": \"node server.js\").")

    hard_port, writes = scan_sources(root)
    if hard_port:
        changes.append("The server listens on a hard-coded port. Listen on process.env.PORT instead.")
    if writes or LOCAL_FILES & set(deps):
        changes.append("The app writes files. Keep them outside the build folder (e.g. a path from an "
                       "env variable pointing into the home directory): each deploy has its own folder.")

    if REDIS & set(deps):
        changes.append("Uses Redis (" + ", ".join(sorted(REDIS & set(deps))) + "). No usable Redis was "
                       "found on SiteGround: point it at an external Redis or remove the dependency.")
    if MONGO & set(deps):
        notes.append("Uses MongoDB: SiteGround offers MySQL and PostgreSQL only, so keep MongoDB external.")
    if SQL & set(deps):
        notes.append("Uses SQL (" + ", ".join(sorted(SQL & set(deps))) + "): create the database and "
                     "user in Site Tools first, then set the connection as environment variables.")
    if SOCKETS & set(deps):
        notes.append("Uses WebSockets: not verified on SiteGround yet, test before relying on it.")
    if BROWSERS & set(deps):
        changes.append("Uses a headless browser. Its system libraries cannot be installed "
                       "(no Docker, no root): expect this part to fail.")
    if NATIVE & set(deps):
        notes.append("Native modules (" + ", ".join(sorted(NATIVE & set(deps))) + "): read the build "
                     "log, the install step has a 5-minute limit.")
    if "concurrently" in deps or "npm-run-all" in deps:
        notes.append("Runs several processes via concurrently/npm-run-all: only one Node process "
                     "per project is supervised.")
    if "workspaces" in pkg:
        notes.append("Monorepo with workspaces: the app that should run must be startable from the repo root.")

    dockerfile = os.path.join(root, "Dockerfile")
    if os.path.exists(dockerfile):
        with open(dockerfile, encoding="utf-8", errors="ignore") as f:
            docker = f.read()
        apt = re.findall(r"apt-get install[^\n\\]*(?:\\\n[^\n\\]*)*", docker)
        extra = " System packages installed there will be missing." if apt else ""
        notes.append("A Dockerfile exists but SiteGround ignores it." + extra)
    if others:
        notes.append(f"The repo also contains {'/'.join(others)} code: that part cannot run as a service here.")
    if os.path.exists(os.path.join(root, "Procfile")):
        notes.append("Procfile is ignored: only the Node start command runs.")
    if not any(os.path.exists(os.path.join(root, f))
               for f in ("package-lock.json", "yarn.lock", "pnpm-lock.yaml")):
        notes.append("No lock file: dependency versions are resolved fresh on every deploy.")
    return blockers, changes, notes, settings


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    root = os.path.abspath(args[0] if args else ".")
    if not os.path.isdir(root):
        sys.exit(f"Not a directory: {root}")
    blockers, changes, notes, settings = check(root)
    verdict = "does not fit" if blockers else ("fits with changes" if changes else "fits")

    if "--json" in sys.argv:
        print(json.dumps({"verdict": verdict, "blockers": blockers, "changes": changes,
                          "notes": notes, "settings": settings}, indent=2))
    else:
        print(f"Project: {root}\nVerdict: {verdict.upper()}")
        for title, items in (("Blockers", blockers), ("Change before deploying", changes), ("Good to know", notes)):
            if items:
                print(f"\n{title}:")
                for item in items:
                    print(f"  - {item}")
        if settings:
            print("\nSuggested deploy options in Site Tools:")
            print(f"  Framework preset : {settings['framework_preset']}")
            print(f"  Node version     : {settings['node_version']} ({settings['node_version_reason']})")
            print(f"  Package manager  : {settings['package_manager']}")
            print(f"  Build command    : {settings['build_command'] or '(leave empty)'}")
            print(f"  Output directory : {settings['output_directory'] or '(leave empty)'}")
    sys.exit(2 if blockers else (1 if changes else 0))


if __name__ == "__main__":
    main()
