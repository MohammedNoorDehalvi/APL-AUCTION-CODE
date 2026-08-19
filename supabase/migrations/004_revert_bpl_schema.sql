-- Revert database changes introduced by:
--   1b03796e9bf7143490bcfdc1d2958094aaca4e0b (BPL)
--   a635f5260c1ce5cc7ae9e277426baf98d1a65a8b (BPL Fix)
--
-- The other requested commits did not add an applied Supabase DDL migration.
--
-- Live-state handling:
--   * BPL 1 currently conflicts with FCS 1 under the original global
--     UNIQUE (season_number) rule.
--   * Before removing BPL data, this migration snapshots the BPL season and
--     all directly season-scoped records into the non-public
--     rollback_archive schema.
--   * The singleton auction row is preserved and reset to NOT_STARTED rather
--     than deleted.
--   * BPL live rows are then removed and the pre-BPL constraints restored.
--
-- The archive schema is intentionally outside public, so it is not exposed by
-- the normal public PostgREST API configuration.

DO $$
BEGIN
  IF to_regclass('public.seasons') IS NULL THEN
    RAISE EXCEPTION 'Rollback aborted: public.seasons does not exist.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'seasons'
      AND column_name = 'league_code'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: public.seasons.league_code does not exist.';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'seasons'
      AND column_name = 'season_number'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: public.seasons.season_number does not exist.';
  END IF;
END
$$;

LOCK TABLE public.seasons IN SHARE ROW EXCLUSIVE MODE;

CREATE SCHEMA IF NOT EXISTS rollback_archive;

CREATE TABLE rollback_archive.rollback_004_seasons AS
SELECT *
FROM public.seasons
WHERE league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_auction AS
SELECT a.*
FROM public.auction a
JOIN public.seasons s ON s.id = a.season_id
WHERE s.league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_auction_action_history AS
SELECT t.*
FROM public.auction_action_history t
JOIN public.seasons s ON s.id = t.season_id
WHERE s.league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_auction_events AS
SELECT t.*
FROM public.auction_events t
JOIN public.seasons s ON s.id = t.season_id
WHERE s.league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_bids AS
SELECT t.*
FROM public.bids t
JOIN public.seasons s ON s.id = t.season_id
WHERE s.league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_captains AS
SELECT t.*
FROM public.captains t
JOIN public.seasons s ON s.id = t.season_id
WHERE s.league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_matches AS
SELECT t.*
FROM public.matches t
JOIN public.seasons s ON s.id = t.season_id
WHERE s.league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_players AS
SELECT t.*
FROM public.players t
JOIN public.seasons s ON s.id = t.season_id
WHERE s.league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_points_table AS
SELECT t.*
FROM public.points_table t
JOIN public.seasons s ON s.id = t.season_id
WHERE s.league_code = 'BPL';

CREATE TABLE rollback_archive.rollback_004_teams AS
SELECT t.*
FROM public.teams t
JOIN public.seasons s ON s.id = t.season_id
WHERE s.league_code = 'BPL';

COMMENT ON SCHEMA rollback_archive IS
  'Database-side snapshots created before destructive rollback migrations.';

COMMENT ON TABLE rollback_archive.rollback_004_seasons IS
  'BPL season snapshot captured before migration 004 removed BPL support.';

DO $$
BEGIN
  IF (
    SELECT count(*) FROM rollback_archive.rollback_004_seasons
  ) <> (
    SELECT count(*) FROM public.seasons WHERE league_code = 'BPL'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: BPL season archive verification failed.';
  END IF;

  IF (
    SELECT count(*) FROM rollback_archive.rollback_004_auction_action_history
  ) <> (
    SELECT count(*)
    FROM public.auction_action_history t
    JOIN public.seasons s ON s.id = t.season_id
    WHERE s.league_code = 'BPL'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: auction_action_history archive verification failed.';
  END IF;

  IF (
    SELECT count(*) FROM rollback_archive.rollback_004_auction_events
  ) <> (
    SELECT count(*)
    FROM public.auction_events t
    JOIN public.seasons s ON s.id = t.season_id
    WHERE s.league_code = 'BPL'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: auction_events archive verification failed.';
  END IF;

  IF (
    SELECT count(*) FROM rollback_archive.rollback_004_bids
  ) <> (
    SELECT count(*)
    FROM public.bids t
    JOIN public.seasons s ON s.id = t.season_id
    WHERE s.league_code = 'BPL'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: bids archive verification failed.';
  END IF;

  IF (
    SELECT count(*) FROM rollback_archive.rollback_004_captains
  ) <> (
    SELECT count(*)
    FROM public.captains t
    JOIN public.seasons s ON s.id = t.season_id
    WHERE s.league_code = 'BPL'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: captains archive verification failed.';
  END IF;

  IF (
    SELECT count(*) FROM rollback_archive.rollback_004_players
  ) <> (
    SELECT count(*)
    FROM public.players t
    JOIN public.seasons s ON s.id = t.season_id
    WHERE s.league_code = 'BPL'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: players archive verification failed.';
  END IF;

  IF (
    SELECT count(*) FROM rollback_archive.rollback_004_teams
  ) <> (
    SELECT count(*)
    FROM public.teams t
    JOIN public.seasons s ON s.id = t.season_id
    WHERE s.league_code = 'BPL'
  ) THEN
    RAISE EXCEPTION 'Rollback aborted: teams archive verification failed.';
  END IF;
END
$$;

-- Preserve the singleton auction control row and return it to the same neutral
-- state used when a new season is initialized by the pre-BPL application.
UPDATE public.auction
SET
  season_id = NULL,
  auction_status = 'NOT_STARTED',
  current_player_id = NULL,
  highest_bid = 0,
  highest_bidder_id = NULL,
  highest_bidder_team_id = NULL,
  highest_bidder_captain_name = NULL,
  highest_team_name = NULL,
  manual_picker_hidden = FALSE,
  bid_processing = FALSE,
  bid_lock_started_at = NULL,
  bid_lock_player_id = NULL,
  started_at = NULL,
  ended_at = NULL,
  updated_at = now()
WHERE season_id IN (
  SELECT id FROM rollback_archive.rollback_004_seasons
);

-- Remove BPL-scoped live data after it has been archived. Child rows are
-- removed before players/captains to avoid relying on cascading side effects.
DELETE FROM public.auction_action_history
WHERE season_id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DELETE FROM public.auction_events
WHERE season_id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DELETE FROM public.bids
WHERE season_id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DELETE FROM public.matches
WHERE season_id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DELETE FROM public.points_table
WHERE season_id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DELETE FROM public.teams
WHERE season_id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DELETE FROM public.players
WHERE season_id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DELETE FROM public.captains
WHERE season_id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DELETE FROM public.seasons
WHERE id IN (SELECT id FROM rollback_archive.rollback_004_seasons);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.seasons WHERE league_code = 'BPL') THEN
    RAISE EXCEPTION 'Rollback aborted: BPL seasons remain after cleanup.';
  END IF;

  IF EXISTS (
    SELECT season_number
    FROM public.seasons
    GROUP BY season_number
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION
      'Rollback aborted: duplicate season_number values remain after BPL cleanup.';
  END IF;
END
$$;

-- Revert migration 003: restore global season_number uniqueness.
ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_league_code_season_number_key;

DROP INDEX IF EXISTS public.seasons_league_code_season_number_key;

ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_season_number_key;

ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS seasons_season_number_unique;

DROP INDEX IF EXISTS public.idx_seasons_season_number;

ALTER TABLE public.seasons
ADD CONSTRAINT seasons_season_number_key
UNIQUE (season_number);

-- Revert migration 002: allow only the original APL and FCS league codes.
ALTER TABLE public.seasons
DROP CONSTRAINT IF EXISTS check_league_code;

ALTER TABLE public.seasons
ADD CONSTRAINT check_league_code
CHECK (league_code IN ('APL', 'FCS'));
