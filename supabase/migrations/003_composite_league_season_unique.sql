-- Migration 003: Replace standalone season_number unique constraint with composite unique (league_code, season_number)
-- This allows each league (APL, FCS, BPL) to have its own season 1, 2, etc., while preventing duplicate season numbers within the same league.

-- 1. Drop any potential standalone unique constraints or unique indexes on season_number
ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_season_number_key;

ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_season_number_unique;

DROP INDEX IF EXISTS public.seasons_season_number_key;
DROP INDEX IF EXISTS public.idx_seasons_season_number;

-- 2. Drop existing composite constraint if previously created (idempotent)
ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_league_code_season_number_key;

-- 3. Add composite unique constraint on (league_code, season_number)
ALTER TABLE public.seasons
ADD CONSTRAINT seasons_league_code_season_number_key
UNIQUE (league_code, season_number);
