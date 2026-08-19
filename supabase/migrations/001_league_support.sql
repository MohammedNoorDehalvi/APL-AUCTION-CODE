-- 001_league_support.sql
-- Migration to add multi-league support (FCS) to the APL Auction schema.

-- 1. Add the new league_code column to the seasons table
ALTER TABLE public.seasons
ADD COLUMN league_code text;

-- 2. Backfill existing seasons to 'APL'
UPDATE public.seasons
SET league_code = 'APL'
WHERE league_code IS NULL;

-- 3. Enforce NOT NULL constraint and default value
ALTER TABLE public.seasons
ALTER COLUMN league_code SET NOT NULL,
ALTER COLUMN league_code SET DEFAULT 'APL';

-- 4. Add a check constraint to restrict the values to APL and FCS
ALTER TABLE public.seasons
ADD CONSTRAINT check_league_code CHECK (league_code IN ('APL', 'FCS'));

-- (Optional) If you have a types or enum defined in postgres, you could alter that instead of check constraint,
-- but a check constraint is more portable and easier to manage for simple strings.
