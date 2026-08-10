import { randomInt } from 'crypto';

import { jsonError, requireAdminRequest, selectCurrentPlayer } from '@/lib/auction-server';
import { getActiveSeason } from '@/lib/season-server';
import type { Player } from '@/lib/types';

export const runtime = 'nodejs';

function pickRandomPlayer(players: Player[]) {
  if (players.length === 0) return null;
  return players[randomInt(players.length)] ?? null;
}

export async function POST(request: Request) {
  const { response, supabase } = requireAdminRequest(request);
  if (response || !supabase) return response;

  const season = await getActiveSeason(supabase);
  if (!season) {
    return jsonError('No current season going. Start a season first.');
  }

  const { data, error } = await supabase
    .from('players')
    .select('*')
    .eq('season_id', season.id)
    .eq('approval_status', 'Approved')
    .eq('status', 'Available')
    .eq('auction_status', 'PENDING');

  if (error) {
    return jsonError(error.message, 500);
  }

  const players = (data || []) as Player[];
  if (players.length === 0) {
    return jsonError('No approved unsold players are available.');
  }

  let player: Player | null = null;

  if (season.use_secret_sequence) {
    const { data: sequenceData, error: seqError } = await supabase
      .from('fcs_secret_sequence')
      .select('player_id, sequence_position')
      .eq('season_id', season.id)
      .order('sequence_position', { ascending: true });

    if (seqError) {
      return jsonError('Error fetching secret sequence: ' + seqError.message, 500);
    }

    if (sequenceData && sequenceData.length > 0) {
      const pendingPlayerIds = new Set(players.map((p) => p.id));
      for (const seq of sequenceData) {
        if (pendingPlayerIds.has(seq.player_id)) {
          player = players.find((p) => p.id === seq.player_id) || null;
          break;
        }
      }

      if (!player) {
        return jsonError('The predefined secret player sequence has completed.');
      }
    } else {
      // If sequence is enabled but table is empty, we probably shouldn't fall back to random.
      return jsonError('Secret sequence is enabled but no sequence data was found.');
    }
  } else {
    player = pickRandomPlayer(players);
  }

  if (!player) {
    return jsonError('No approved unsold players are available.');
  }

  return (await selectCurrentPlayer(supabase, player.id, true)).response;
}
