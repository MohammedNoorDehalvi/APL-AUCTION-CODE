-- Migration 002: Add BPL (Brothers Premier League) to check_league_code constraint
-- Updates the check constraint on seasons table to allow 'APL', 'FCS', and 'BPL'
-- Preserves all existing seasons and data.

ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS check_league_code;

ALTER TABLE public.seasons
ADD CONSTRAINT check_league_code
CHECK (league_code IN ('APL', 'FCS', 'BPL'));
