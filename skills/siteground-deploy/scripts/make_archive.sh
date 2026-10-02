#!/usr/bin/env bash
# Pack a project for SiteGround's "Upload your files" deploy method.
#
#   make_archive.sh [project-dir] [output.zip]
#
# SiteGround accepts .zip, .tar.gz and .tgz up to 128 MB. package.json has to be
# at the top level of the archive, so the archive is built from inside the
# project folder. node_modules, .git and local secrets are left out: SiteGround
# installs dependencies itself, and secrets belong in the environment variables.
set -u

SRC="$(cd "${1:-.}" && pwd)" || { echo "Folder not found: ${1:-.}" >&2; exit 66; }
OUT="${2:-$SRC/../$(basename "$SRC")-siteground.zip}"
LIMIT_MB=128

[ -f "$SRC/package.json" ] || { echo "No package.json in $SRC: this is not the root of a Node.js project." >&2; exit 65; }
case "$OUT" in /*) ;; *) OUT="$PWD/$OUT" ;; esac
rm -f "$OUT"

cd "$SRC" || exit 1
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ "$(git rev-parse --show-toplevel)" = "$SRC" ]; then
  # Tracked files only: respects .gitignore, so build output and secrets stay out.
  if [ -n "$(git status --porcelain)" ]; then
    echo "Note: there are uncommitted changes. Only committed files go into the archive." >&2
  fi
  git archive --format=zip -o "$OUT" HEAD || exit 1
else
  zip -qr "$OUT" . \
    -x "node_modules/*" "*/node_modules/*" ".git/*" ".env" ".env.*" "*.pem" "*.key" \
       ".next/*" "dist/*" "build/*" ".DS_Store" "*/.DS_Store" "*.log" || exit 1
fi

SIZE_MB=$(( ($(wc -c < "$OUT") + 1048575) / 1048576 ))
echo "Archive: $OUT (${SIZE_MB} MB)"
if unzip -l "$OUT" | grep -q -E ' \.env($|\.)'; then
  echo "WARNING: the archive contains a .env file. Remove it and set the values as environment variables in Site Tools." >&2
  exit 1
fi
if [ "$SIZE_MB" -gt "$LIMIT_MB" ]; then
  echo "Too large: the upload limit is ${LIMIT_MB} MB. Remove large assets or use the GitHub method." >&2
  exit 1
fi
echo "OK: within the ${LIMIT_MB} MB upload limit."
