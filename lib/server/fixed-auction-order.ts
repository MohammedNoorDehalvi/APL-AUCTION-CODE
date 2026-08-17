import 'server-only';
import type { Player } from '@/lib/types';

export const FIXED_AUCTION_PLAYER_ORDER = [
  'b7ee6739-b9a0-41a3-9a59-a7fb06201044', // 1. Rehan
  '6ab53e7e-ce97-4423-90ce-dc72ea6819f8', // 2. Noman
  'cf59bde0-3731-4a7b-a70c-2c9277d73582', // 3. Arham
  'e571e563-d889-465e-b003-a42b943481ce', // 4. Kabir
  '17e9ddfe-9812-45d2-911d-81f22072e59b', // 5. Affan Mansuri
  'fedcb838-3ff6-4b8f-8609-a0dc0cced405', // 6. Affan Mota
  '3db2f064-6b25-4820-9ef0-197a348d5bc1', // 7. Naved
  'b58c07ee-d698-4fe9-afe6-594429ba41f4', // 8. Amin Sahab
  'e58b8e98-4f60-48e2-8627-1c4d6f6133c2', // 9. Faiz
  '9ff9c3c1-4209-4d87-a568-3230cb93becd', // 10. Noor
  '604af7f3-4ff3-4ede-b0df-56c7cb73fac0', // 11. Sohail
  '17811a35-0736-4673-ade1-0a10a6730408', // 12. Zefan
  '5341397e-ab03-4b45-b01e-69684f703b1e', // 13. Mohsin
  'a533489d-08a7-4319-bf5a-226f663195d8', // 14. Tehmeed
  '24142db1-fa81-469e-9e33-cda136629e02', // 15. Gaurav
  '5bbae2c7-db04-4f34-8c3c-0101924d372d', // 16. Ali Akbar
] as const;

export const FIXED_AUCTION_PLAYER_NAMES = [
  'Rehan',
  'Noman',
  'Arham',
  'Kabir',
  'Affan Mansuri',
  'Affan Mota',
  'Naved',
  'Amin Sahab',
  'Faiz',
  'Noor',
  'Sohail',
  'Zefan',
  'Mohsin',
  'Tehmeed',
  'Gaurav',
  'Ali Akbar',
] as const;

function normalizeName(name: string) {
  return name.trim().toLowerCase().replace(/\s+/g, ' ');
}

/**
 * Selects the next player in the strict fixed order from the list of pending available players.
 *
 * Checks by UUID first; if player records were re-imported with new UUIDs, falls back to normalized name matching.
 * If all players in the fixed sequence have already been auctioned, falls back to the first available pending player.
 */
export function getNextFixedAuctionPlayer(availablePendingPlayers: Player[]): Player | null {
  if (!availablePendingPlayers || availablePendingPlayers.length === 0) return null;

  const playerById = new Map<string, Player>();
  const playerByName = new Map<string, Player>();

  for (const p of availablePendingPlayers) {
    if (p.id) playerById.set(p.id, p);
    if (p.name) playerByName.set(normalizeName(p.name), p);
  }

  // 1. Check in sequence by exact ID first
  for (const id of FIXED_AUCTION_PLAYER_ORDER) {
    const player = playerById.get(id);
    if (player) return player;
  }

  // 2. Fallback in sequence by normalized name
  for (const name of FIXED_AUCTION_PLAYER_NAMES) {
    const player = playerByName.get(normalizeName(name));
    if (player) return player;
  }

  // 3. Fallback for any other remaining players
  return availablePendingPlayers[0] ?? null;
}
