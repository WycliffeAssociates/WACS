# Gitea 1.23.8 → Forgejo 10.0.x migration

Forgejo only accepts a Gitea database at the **1.22 schema baseline** (Forgejo
docs: "up to Gitea v1.22 included"). WACS runs Gitea **1.23.8**, whose schema is
ahead of that baseline (schema `version` 312 vs 299). This directory reverses
the 1.23 schema changes so Forgejo 10.0.x will accept and forward-migrate the
database.

We take **Path A (true schema reversal)**, not the `UPDATE version SET
version=305` "version-pin and let Forgejo reconcile forward" shortcut. Path A
produces a genuinely valid 1.22 database, which is more stable and verifiable.

## Full upgrade path

The end-to-end path is:

```
gitea 1.23.8 → gitea 1.22.6 → forgejo 10 → forgejo 15
```

This directory only covers the **1.23 → 1.22 schema reversal** — the one step
Forgejo cannot do itself, because Forgejo only adopts a Gitea database at the
1.22 baseline. Everything after that is a normal Forgejo forward-migration:
Forgejo 10 adopts the 1.22 database and runs its own migrations on boot, and
Forgejo 15 forward-migrates from the 10 schema on boot. No further de-migration
script is needed for the 10 → 15 step.

Work is split across two branches: `forgejo-10-migration` holds the migration
tooling and the Forgejo 10 rebase; `forgejo15` carries the image bump to
Forgejo 15 on top of it.

## Why this is data-preserving

`demigrate-1.23-to-1.22.mariadb.sql` was derived by diffing fresh-install schema
dumps of Gitea 1.22.0 vs 1.23.0. Every 1.23 change is **additive** (new columns,
new indexes, one new table), so on MariaDB we reverse each with an in-place
`ALTER TABLE ... DROP COLUMN` / `DROP INDEX` / `DROP TABLE`. No issue, comment,
OAuth-application, or branch-protection **rows** are lost. (Contrast the
upstream xlrl SQLite script, which `DROP TABLE`s and recreates — losing data —
because old SQLite can't drop columns in place.)

The only data removed is the `repo_license` table, a regenerable
license-detection cache.

### Exactly what 1.23 changed (and this script reverses)

| Object | 1.23 change | reversal |
|---|---|---|
| `oauth2_application` | +col `skip_secondary_authorization` | DROP COLUMN |
| `comment` | +cols `content_version`, `comment_meta_data` | DROP COLUMN ×2 |
| `issue` | +cols `content_version`, `time_estimate` | DROP COLUMN ×2 |
| `protected_branch` | +7 cols (force-push allowlist, `block_admin_merge_override`, `priority`) | DROP COLUMN ×7 |
| `repo_license` | new table | DROP TABLE |
| `action` | +index `IDX_action_c_u` | DROP INDEX |
| `action_task` | +index `IDX_action_task_stopped_log_expired` | DROP INDEX |
| `release` | +index `IDX_release_sha1` | DROP INDEX |
| `notification` | 2 single-col indexes → 1 composite `IDX_notification_u_s_uu` | drop composite, restore the 2 |
| `version` | 312 | set to 299 |

Gitea's `models/migrations/migrations.go` is byte-identical across tags
`v1.23.0`..`v1.23.8`, so no point release added a migration — this delta is
exact for 1.23.8.

## Runbook

**Always run against a restored copy of production first.** MariaDB DDL is not
transactional; if a statement fails partway, restore from the dump.

### 0. Back up

```bash
docker compose exec db mysqldump -u root -p<root_pw> --single-transaction gitea \
  > gitea-1.23.8-backup.sql
```

### 1. Preflight — confirm the 1.23 artifacts are present

Every `DROP` in the script is fail-loud (no `IF EXISTS`) so a name mismatch
surfaces immediately. Confirm first:

```sql
SELECT version FROM version WHERE id=1;                                    -- expect 312
SHOW COLUMNS FROM issue LIKE 'time_estimate';                              -- expect 1 row
SHOW COLUMNS FROM protected_branch LIKE 'priority';                        -- expect 1 row
SHOW INDEX FROM notification WHERE Key_name='IDX_notification_u_s_uu';     -- expect rows
```

If any is missing, stop — index/column names differ on this instance and the
script must be adjusted before running.

### 2. Run the reversal

```bash
docker compose exec -T db mysql -u root -p<root_pw> gitea \
  < migration/demigrate-1.23-to-1.22.mariadb.sql
```

### 3. Validate as real Gitea 1.22.0 (the key confidence step)

Point a stock `gitea/gitea:1.22.0` image at the de-migrated MariaDB (reuse the
compose DB env vars; skip the custom entrypoint). It must reach *"Starting new
Web server"*, and you must be able to log in and open a repo, an issue, and the
OAuth application settings. A clean 1.22.0 boot proves the database is a valid
1.22 database.

### 4. Hand to Forgejo 10.0.x

Bring up the Forgejo 10 image (see the Dockerfile change). It reads schema
`version` 299, runs its own forward migrations, and starts. WACS uses
`ISSUE_INDEXER_TYPE=db`, so there is likely no bleve `indexers/` dir; if one
exists, `rm -rf /var/lib/gitea/data/indexers` before boot is harmless insurance.

## Residual risks

- **Version `299`** is the literal value from a fresh 1.22.0 dump and matches the
  schema this script produces. Forgejo 10 forward-migrates from it. The step-3
  validation boot catches any mismatch before Forgejo touches data; Forgejo
  refuses to start (rather than corrupting) on a wrong version.
- **Data-only 1.23 migrations** leave no schema trace and need no reversal;
  Forgejo runs its own migration lineage from 299, so there is no double-apply of
  Gitea's 1.23 migrations.

## Sources

- Forgejo: migrating from Gitea — https://forgejo.org/docs/latest/admin/upgrade/from-gitea/
- xlrl/prepare-gitea-migration-to-forgejo (schema dumps this delta was derived from) — https://codeberg.org/xlrl/prepare-gitea-migration-to-forgejo
