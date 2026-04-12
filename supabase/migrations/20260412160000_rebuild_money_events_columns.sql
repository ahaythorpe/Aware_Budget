-- Migration: align money_events columns with PRD v1.1 Swift model
-- Old columns: category, event_type
-- New columns: planned_status, behaviour_tag, life_event

-- 1. Add new columns
ALTER TABLE money_events
ADD COLUMN IF NOT EXISTS planned_status text
CHECK (planned_status IN ('planned', 'surprise', 'impulse'))
DEFAULT 'planned';

ALTER TABLE money_events
ADD COLUMN IF NOT EXISTS behaviour_tag text;

ALTER TABLE money_events
ADD COLUMN IF NOT EXISTS life_event text;

-- 2. Migrate existing data: map event_type → planned_status
UPDATE money_events
SET planned_status = CASE
    WHEN event_type = 'surprise' THEN 'surprise'
    WHEN event_type = 'win'      THEN 'planned'
    WHEN event_type = 'expected' THEN 'planned'
    ELSE 'planned'
END
WHERE planned_status IS NULL OR planned_status = 'planned';

-- 3. Drop old columns
ALTER TABLE money_events DROP COLUMN IF EXISTS category;
ALTER TABLE money_events DROP COLUMN IF EXISTS event_type;
