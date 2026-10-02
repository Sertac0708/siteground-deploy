#!/usr/bin/env bash
# Verify a SiteGround Node.js deploy: which commit is live, did the build pass,
# does the site answer. Read-only. Opens exactly one SSH connection.
#
# Usage:
#   verify_deploy.sh --domain example.com --user u12-abcdefgh --key ~/.ssh/example_siteground \
#                    [--host ssh.example.com] [--repo /path/to/local/repo] [--path /health]
set -u

DOMAIN="" SSH_USER="" KEY="" HOST="" REPO="" URL_PATH="/"
while [ $# -gt 0 ]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2 ;;
    --user)   SSH_USER="$2"; shift 2 ;;
    --key)    KEY="$2"; shift 2 ;;
    --host)   HOST="$2"; shift 2 ;;
    --repo)   REPO="$2"; shift 2 ;;
    --path)   URL_PATH="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 64 ;;
  esac
done
if [ -z "$DOMAIN" ] || [ -z "$SSH_USER" ] || [ -z "$KEY" ]; then
  echo "Required: --domain, --user, --key" >&2; exit 64
fi
[ -f "$KEY" ] || { echo "Key file not found: $KEY" >&2; exit 66; }
HOST="${HOST:-ssh.$DOMAIN}"

# The build log and build settings contain the Git URL including an access
# token, so everything read from the server is masked before it is printed.
mask() { sed -E 's#(https?://)[^@/ "]+@#\1***@#g'; }

# One connection, one known key, no password prompt: SiteGround bans the client
# IP for every site on the account after a few failed attempts.
REMOTE=$(ssh -o BatchMode=yes -o IdentitiesOnly=yes -o ConnectTimeout=15 \
  -o StrictHostKeyChecking=accept-new -i "$KEY" -p 18765 "$SSH_USER@$HOST" "
    R=~/www/$DOMAIN/public_html/.nodeapp/latest
    [ -d \"\$R\" ] || { echo 'NO_NODEAPP'; exit 0; }
    echo '== build =='; echo \"id: \$(basename \"\$(readlink -f \"\$R\")\")\"
    echo \"status: \$(cat \"\$R/build_info.json\" 2>/dev/null)\"
    echo \"exit_code: \$(cat \"\$R/build_script.exit_code\" 2>/dev/null)\"
    echo '== commit =='; cat \"\$R/git_info\" 2>/dev/null
    echo '== env =='; if [ -f \"\$R/../.env-local\" ]; then grep -E '^[A-Z][A-Z0-9_]*=' \"\$R/../.env-local\" | cut -d= -f1 | xargs echo 'names:'; else echo 'no variables set'; fi
    echo '== build log (up to the exit line) =='; grep -v -E 'source_git_url' \"\$R/current\" 2>/dev/null | sed '/Exiting with/q' | tail -n 12
  " 2>&1) || {
  echo "SSH failed. Do not retry with other keys or users (IP ban)." >&2
  echo "$REMOTE" | mask >&2
  exit 1
}
if [ "$REMOTE" = "NO_NODEAPP" ]; then
  echo "No .nodeapp folder for $DOMAIN: this site is not a Node.js project (or the domain is wrong)." >&2
  exit 1
fi
echo "$REMOTE" | mask

LIVE=$(echo "$REMOTE" | awk '/^commit: /{print $2; exit}')
STATUS=0
if [ -n "$REPO" ]; then
  LOCAL=$(git -C "$REPO" rev-parse HEAD 2>/dev/null || true)
  echo "== local vs live =="
  if [ -n "$LOCAL" ] && [ "$LOCAL" = "$LIVE" ]; then
    echo "match: $LIVE"
  else
    echo "MISMATCH: local ${LOCAL:-unknown} / live ${LIVE:-unknown}"; STATUS=1
  fi
fi
echo "$REMOTE" | grep -q '"status":"completed"' || { echo "BUILD NOT COMPLETED"; STATUS=1; }

echo "== http =="
CODE=$(curl -sS -m 20 -o /dev/null -w '%{http_code}' "https://$DOMAIN$URL_PATH" || echo 000)
echo "https://$DOMAIN$URL_PATH -> $CODE"
case "$CODE" in 2*|3*) ;; *) STATUS=1 ;; esac
PLAIN=$(curl -sS -m 20 -o /dev/null -w '%{http_code}' "http://$DOMAIN/" || echo 000)
case "$PLAIN" in
  30*) echo "http:// redirects ($PLAIN): HTTPS is enforced" ;;
  *)   echo "http:// answers $PLAIN without redirect: turn on 'HTTPS Enforce' in Site Tools" ;;
esac
exit $STATUS
