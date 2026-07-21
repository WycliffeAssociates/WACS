#!/bin/bash
# ---------------------------------------------------------------------------
# WACS: reverse the Gitea 1.23.8 schema back to the 1.22.0 baseline so that
# Forgejo 10.0.x will accept and forward-migrate the database.
#
# Runs the preflight guard and the reversal from migration/README.md, and
# nothing else. It does NOT back up (take a VM snapshot first), does NOT run
# the 1.22.0 validation boot (do that on a restored copy beforehand), and does
# NOT touch Forgejo (bring it up with your standard deploy afterwards).
#
# MariaDB DDL is not transactional: if a statement fails partway, roll back to
# the snapshot. The preflight is fail-loud so a name mismatch stops the run
# before any DROP executes.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SQL_FILE="$SCRIPT_DIR/demigrate-1.23-to-1.22.mariadb.sql"

cd "$REPO_ROOT"

if [ ! -f "$SQL_FILE" ]; then
  echo "Error: reversal SQL not found at $SQL_FILE" >&2
  exit 1
fi

# --- Credentials (prompted; nothing hardcoded, nothing left in history) ------
read -rp "MariaDB database name [gitea]: " DB_NAME
DB_NAME="${DB_NAME:-gitea}"

read -rsp "MariaDB root password: " DB_ROOT_PW
echo
if [ -z "$DB_ROOT_PW" ]; then
  echo "Error: root password is required." >&2
  exit 1
fi

# Run a query inside the db service. MYSQL_PWD keeps the password off the
# command line (no ps leak, no 'insecure password' warning). -N -B => bare,
# tab-separated rows with no header.
q() {
  docker compose exec -T -e MYSQL_PWD="$DB_ROOT_PW" db \
    mysql -u root -N -B "$DB_NAME" -e "$1"
}

echo "==> Checking connectivity to the db service..."
if ! q "SELECT 1;" >/dev/null 2>&1; then
  echo "Error: cannot connect to database '$DB_NAME' as root via 'docker compose exec db'." >&2
  echo "       Is the stack up (docker compose ps) and the password correct?" >&2
  exit 1
fi

# --- Preflight: confirm the 1.23 artifacts are present -----------------------
# Every check must pass or we abort before touching data.
echo "==> Preflight..."
fail=0

ver="$(q "SELECT version FROM version WHERE id=1;")"
if [ "$ver" = "312" ]; then
  echo "    [ok]   schema version is 312"
else
  echo "    [FAIL] schema version is '$ver', expected 312"
  fail=1
fi

check_row() {
  # $1 = human label, $2 = query expected to return >= 1 row
  local label="$1" query="$2" out
  out="$(q "$query")"
  if [ -n "$out" ]; then
    echo "    [ok]   $label present"
  else
    echo "    [FAIL] $label missing"
    fail=1
  fi
}

check_row "issue.time_estimate column"          "SHOW COLUMNS FROM issue LIKE 'time_estimate';"
check_row "protected_branch.priority column"    "SHOW COLUMNS FROM protected_branch LIKE 'priority';"
check_row "notification IDX_notification_u_s_uu" "SHOW INDEX FROM notification WHERE Key_name='IDX_notification_u_s_uu';"

if [ "$fail" -ne 0 ]; then
  echo "==> Preflight failed. This instance's schema does not match the expected" >&2
  echo "    1.23.8 layout; the reversal SQL must be adjusted before running. Aborting." >&2
  exit 1
fi
echo "==> Preflight passed."

# --- Confirm, then run the reversal ------------------------------------------
echo
echo "About to run the schema reversal against database '$DB_NAME'."
echo "This is destructive DDL and is NOT transactional. Ensure your VM snapshot exists."
read -rp "Type 'yes' to proceed: " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted; no changes made."
  exit 1
fi

echo "==> Running reversal..."
docker compose exec -T -e MYSQL_PWD="$DB_ROOT_PW" db \
  mysql -u root "$DB_NAME" < "$SQL_FILE"

# --- Verify the post-state ---------------------------------------------------
new_ver="$(q "SELECT version FROM version WHERE id=1;")"
if [ "$new_ver" = "299" ]; then
  echo "==> Done. Schema version is now 299 (1.22.0 baseline)."
  echo "    Next: run your standard deploy to bring up Forgejo 10 with config values."
else
  echo "Error: schema version is '$new_ver' after the reversal, expected 299." >&2
  echo "       Inspect the database and consider rolling back to the snapshot." >&2
  exit 1
fi
