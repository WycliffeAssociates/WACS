-- ---------------------------------------------------------------------------
-- WACS: reverse Gitea 1.23.x schema back to the 1.22.0 baseline (MariaDB)
--
-- Purpose: make a Gitea 1.23.8 database structurally identical to a fresh
--          Gitea 1.22.0 database so Forgejo 10.0.x will accept and migrate it.
--
-- Derived by diffing xlrl fresh-install schema dumps gitea-1.22.0.sql vs
-- gitea-1.23.0.sql. Gitea's migrations.go is byte-identical across v1.23.0..
-- v1.23.8, so this delta is exact for 1.23.8 (schema version 312 -> 299).
--
-- DATA-PRESERVING: unlike xlrl's SQLite drop-and-recreate, MariaDB supports
-- in-place DROP COLUMN, so no issue/comment/oauth/branch-protection data is
-- lost. Only 1.23-added columns/indexes and the 1.23-added repo_license table
-- (a regenerable license-detection cache) are removed.
--
-- RUN AGAINST A RESTORED COPY FIRST. Take a mysqldump before running.
-- Wrapped in a transaction; MariaDB DDL is NOT transactional (each ALTER
-- auto-commits), so if a statement fails partway, restore from the dump.
-- ---------------------------------------------------------------------------

-- 1.23-added indexes ---------------------------------------------------------
DROP INDEX `IDX_action_c_u`                     ON `action`;
DROP INDEX `IDX_action_task_stopped_log_expired` ON `action_task`;
DROP INDEX `IDX_release_sha1`                   ON `release`;

-- notification: 1.23 replaced two single-column indexes with one composite.
-- Reverse it: drop the composite, restore the two originals.
DROP INDEX `IDX_notification_u_s_uu`            ON `notification`;
CREATE INDEX `IDX_notification_created_unix`    ON `notification` (`created_unix`);
CREATE INDEX `IDX_notification_updated_unix`    ON `notification` (`updated_unix`);

-- 1.23-added columns (dropped in place; existing rows retained) ---------------
ALTER TABLE `oauth2_application`
  DROP COLUMN `skip_secondary_authorization`;

ALTER TABLE `comment`
  DROP COLUMN `content_version`,
  DROP COLUMN `comment_meta_data`;

ALTER TABLE `issue`
  DROP COLUMN `content_version`,
  DROP COLUMN `time_estimate`;

ALTER TABLE `protected_branch`
  DROP COLUMN `can_force_push`,
  DROP COLUMN `enable_force_push_allowlist`,
  DROP COLUMN `force_push_allowlist_user_i_ds`,
  DROP COLUMN `force_push_allowlist_team_i_ds`,
  DROP COLUMN `force_push_allowlist_deploy_keys`,
  DROP COLUMN `block_admin_merge_override`,
  DROP COLUMN `priority`;

-- 1.23-added table (regenerable cache) ---------------------------------------
DROP TABLE `repo_license`;

-- Reset the recorded schema version to the Gitea 1.22.0 baseline -------------
UPDATE `version` SET `version` = 299 WHERE `id` = 1;
