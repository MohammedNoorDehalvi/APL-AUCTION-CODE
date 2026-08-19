-- Revert database schema changes introduced by:
--   1b03796e9bf7143490bcfdc1d2958094aaca4e0b (BPL)
--   a635f5260c1ce5cc7ae9e277426baf98d1a65a8b (BPL Fix)
--
-- The other requested commits did not introduce an applied Supabase DDL migration.
-- This restores the schema expected before those two migrations:
--   1. league_code accepts only APL and FCS.
--   2. season_number is globally unique again.
--
-- Safety: this migration refuses to continue if BPL seasons or duplicate
-- season numbers exist. It never deletes or rewrites season data automatically.

DO $$
BEGIN
  IF to_regclass('public.seasons') IS NULL THEN
    RAISE EXCEPTION 'Rollback aborted: public.seasons does not exist in this database.';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.seasons
    WHERE league_code = 'BPL'
  ) THEN
    RAISE EXCEPTION
      'Rollback aborted: BPL season rows exist. Move or delete them explicitly before removing BPL support.';
  END IF;

  IF EXISTS (
    SELECT season_number
    FROM public.seasons
    GROUP BY season_number
    HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION
      'Rollback aborted: duplicate season_number values exist across leagues. Resolve them before restoring global uniqueness.';
  END IF;
END
$$;

-- Revert migration 003: remove composite uniqueness.
ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_league_code_season_number_key;

DROP INDEX IF EXISTS public.seasons_league_code_season_number_key;

-- Restore the original global uniqueness on season_number.
ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_season_number_key;

ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_season_number_unique;

DROP INDEX IF EXISTS public.idx_seasons_season_number;

ALTER TABLE public.seasons
ADD CONSTRAINT seasons_season_number_key
UNIQUE (season_number);

-- Revert migration 002: remove BPL from the allowed league codes.
ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS check_league_code;

ALTER TABLE public.seasons
ADD CONSTRAINT check_league_code
CHECK (league_code IN ('APL', 'FCS'));
