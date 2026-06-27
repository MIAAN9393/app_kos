ALTER TABLE user_subscriptions
  MODIFY COLUMN status ENUM('active', 'past_due', 'expired', 'cancelled') NOT NULL DEFAULT 'active';

ALTER TABLE user_subscriptions
  ADD COLUMN grace_until DATETIME NULL AFTER expired_at;

CREATE INDEX idx_user_subscriptions_grace_until
  ON user_subscriptions (grace_until);

UPDATE user_subscriptions
SET grace_until = DATE_ADD(expired_at, INTERVAL 10 DAY)
WHERE expired_at IS NOT NULL
  AND grace_until IS NULL
  AND paket IN ('starter', 'pro');
