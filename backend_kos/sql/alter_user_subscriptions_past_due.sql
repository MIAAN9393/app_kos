-- Idempotent migration for Railway MySQL.
-- Safe to run more than once. Does not drop data.

ALTER TABLE user_subscriptions
  MODIFY COLUMN status ENUM('active', 'past_due', 'expired', 'cancelled') NOT NULL DEFAULT 'active';

SET @has_grace_until_col := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_subscriptions'
    AND COLUMN_NAME = 'grace_until'
);

SET @sql := IF(
  @has_grace_until_col = 0,
  'ALTER TABLE user_subscriptions ADD COLUMN grace_until DATETIME NULL AFTER expired_at',
  'SELECT ''grace_until column already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_user_status_idx := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_subscriptions'
    AND INDEX_NAME = 'idx_user_subscriptions_user_status'
);

SET @sql := IF(
  @has_user_status_idx = 0,
  'ALTER TABLE user_subscriptions ADD INDEX idx_user_subscriptions_user_status (user_id, status)',
  'SELECT ''idx_user_subscriptions_user_status already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_expired_at_idx := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_subscriptions'
    AND INDEX_NAME = 'idx_user_subscriptions_expired_at'
);

SET @sql := IF(
  @has_expired_at_idx = 0,
  'ALTER TABLE user_subscriptions ADD INDEX idx_user_subscriptions_expired_at (expired_at)',
  'SELECT ''idx_user_subscriptions_expired_at already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_grace_until_col := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_subscriptions'
    AND COLUMN_NAME = 'grace_until'
);

SET @has_grace_until_idx := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_subscriptions'
    AND INDEX_NAME = 'idx_user_subscriptions_grace_until'
);

SET @sql := IF(
  @has_grace_until_col > 0 AND @has_grace_until_idx = 0,
  'ALTER TABLE user_subscriptions ADD INDEX idx_user_subscriptions_grace_until (grace_until)',
  'SELECT ''idx_user_subscriptions_grace_until skipped or already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_source_payment_col := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_subscriptions'
    AND COLUMN_NAME = 'source_payment_id'
);

SET @has_source_payment_idx := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_subscriptions'
    AND INDEX_NAME = 'idx_user_subscriptions_source_payment'
);

SET @sql := IF(
  @has_source_payment_col > 0 AND @has_source_payment_idx = 0,
  'ALTER TABLE user_subscriptions ADD INDEX idx_user_subscriptions_source_payment (source_payment_id)',
  'SELECT ''idx_user_subscriptions_source_payment skipped or already exists'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_grace_until_col := (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'user_subscriptions'
    AND COLUMN_NAME = 'grace_until'
);

SET @sql := IF(
  @has_grace_until_col > 0,
  'UPDATE user_subscriptions SET grace_until = DATE_ADD(expired_at, INTERVAL 10 DAY) WHERE expired_at IS NOT NULL AND grace_until IS NULL AND paket IN (''starter'', ''pro'')',
  'SELECT ''grace_until backfill skipped: column missing'' AS info'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
