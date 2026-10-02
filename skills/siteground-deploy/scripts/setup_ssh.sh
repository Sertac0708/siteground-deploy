#!/usr/bin/env bash
# SSH access to a SiteGround site, in two steps.
#
#   setup_ssh.sh keygen --name mysite
#       Creates ~/.ssh/mysite_siteground (ed25519) if it does not exist and
#       prints the PUBLIC key to paste into Site Tools > Devs > SSH Keys Manager > Import.
#
#   setup_ssh.sh test --domain example.com --user u12-abcdefgh --key ~/.ssh/mysite_siteground [--host ssh.example.com]
#       Makes exactly one login attempt and lists the site folders.
#
# The private key never leaves this machine and is never printed.
set -u

CMD="${1:-}"; shift || true
NAME="" DOMAIN="" SSH_USER="" KEY="" HOST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --name)   NAME="$2"; shift 2 ;;
    --domain) DOMAIN="$2"; shift 2 ;;
    --user)   SSH_USER="$2"; shift 2 ;;
    --key)    KEY="$2"; shift 2 ;;
    --host)   HOST="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 64 ;;
  esac
done

case "$CMD" in
  keygen)
    [ -n "$NAME" ] || { echo "Required: --name" >&2; exit 64; }
    KEY="$HOME/.ssh/${NAME}_siteground"
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    if [ -f "$KEY" ]; then
      echo "Key already exists, reusing it: $KEY"
    else
      # No passphrase: an agent runs ssh non-interactively and cannot type one.
      ssh-keygen -q -t ed25519 -N "" -C "${NAME}-siteground" -f "$KEY" || exit 1
      chmod 600 "$KEY"
      echo "Created: $KEY"
    fi
    echo
    echo "PUBLIC KEY (paste this into Site Tools > Devs > SSH Keys Manager > Import):"
    cat "$KEY.pub"
    ;;
  test)
    if [ -z "$DOMAIN" ] || [ -z "$SSH_USER" ] || [ -z "$KEY" ]; then
      echo "Required: --domain, --user, --key" >&2; exit 64
    fi
    [ -f "$KEY" ] || { echo "Key file not found: $KEY" >&2; exit 66; }
    HOST="${HOST:-ssh.$DOMAIN}"
    # BatchMode + IdentitiesOnly: offer only this one key and never fall back to
    # a password prompt. Every rejected key counts towards SiteGround's IP ban.
    if ssh -o BatchMode=yes -o IdentitiesOnly=yes -o ConnectTimeout=15 \
         -o StrictHostKeyChecking=accept-new -i "$KEY" -p 18765 "$SSH_USER@$HOST" \
         'echo "login ok: $(whoami)"; echo "sites: $(ls ~/www 2>/dev/null | xargs)"; echo "node: $(node -v 2>/dev/null)"'; then
      exit 0
    fi
    cat >&2 <<'EOF'

Login failed. Stop here and do not try other keys or user names:
SiteGround blocks the client IP for all sites after a few failed attempts.
 - "Permission denied (publickey)": the public key is not imported yet, or the
   user name / host differs from what the SSH Keys Manager shows.
 - "Connection closed" / "Connection reset": the IP is probably blocked already.
   Unblock it in Site Tools > Security > Blocked Traffic, or wait 30-60 minutes.
EOF
    exit 1
    ;;
  *)
    echo "Usage: setup_ssh.sh keygen --name <label> | test --domain <d> --user <u> --key <path> [--host <h>]" >&2
    exit 64
    ;;
esac
