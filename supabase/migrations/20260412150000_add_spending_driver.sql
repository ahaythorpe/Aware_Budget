-- Add spending_driver column to daily_checkins
-- Stores the behavioural driver tag selected after a check-in.
-- Values: present_bias, social, emotional, convenience, identity, friction_avoid

ALTER TABLE daily_checkins
ADD COLUMN IF NOT EXISTS spending_driver text
CHECK (spending_driver IS NULL OR spending_driver IN (
    'present_bias', 'social', 'emotional', 'convenience', 'identity', 'friction_avoid'
));
