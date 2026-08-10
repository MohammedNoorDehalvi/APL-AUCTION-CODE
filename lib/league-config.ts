import type { LeagueCode } from './types';

export interface LeagueConfig {
  code: LeagueCode;
  brandName: string;
  shortName: string;
  backgroundMode: 'animated' | 'stadium';
  heroBackgroundAsset?: string;
  copyPrefixes: {
    marketing: string;
    auction: string;
  };
  allowedImportSources: string[];
}

export const LEAGUE_REGISTRY: Record<LeagueCode, LeagueConfig> = {
  APL: {
    code: 'APL',
    brandName: 'Ashoka Premier League',
    shortName: 'APL',
    backgroundMode: 'animated',
    copyPrefixes: {
      marketing: 'APL Digital Auction',
      auction: 'APL Live Auction Room',
    },
    allowedImportSources: ['APL', 'FCS'],
  },
  FCS: {
    code: 'FCS',
    brandName: 'Fortune Cup Seasons',
    shortName: 'FCS',
    backgroundMode: 'stadium',
    heroBackgroundAsset: 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?q=80&w=2805&auto=format&fit=crop', // Premium stadium placeholder
    copyPrefixes: {
      marketing: 'FCS Auction',
      auction: 'FCS Live Auction Room',
    },
    allowedImportSources: ['FCS', 'APL'],
  },
};

export function getLeagueConfig(code?: LeagueCode | null): LeagueConfig {
  if (!code || !LEAGUE_REGISTRY[code]) {
    return LEAGUE_REGISTRY['APL']; // Default to APL
  }
  return LEAGUE_REGISTRY[code];
}
