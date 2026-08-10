import { Hero3D } from '@/components/home/Hero3D';
import { HomeAuctionGate } from '@/components/home/HomeAuctionGate';
import { ScrollShowcase } from '@/components/home/ScrollShowcase';
import { HomepageScrollBackground } from '@/components/home/HomepageScrollBackground';

import { getActiveSeason } from '@/lib/season-server';
import { createSupabaseAdmin } from '@/lib/supabase/admin';
import { getLeagueConfig } from '@/lib/league-config';

export default async function HomePage() {
  let season = null;
  try {
    const supabase = createSupabaseAdmin();
    season = await getActiveSeason(supabase);
  } catch (e) {
    // Ignore error during static generation or if env vars are missing
  }
  
  const leagueConfig = getLeagueConfig(season?.league_code);
  const isAnimatedBackground = leagueConfig.backgroundMode === 'animated';

  return (
    <>
      {isAnimatedBackground && <HomepageScrollBackground />}
      <HomeAuctionGate>
        {isAnimatedBackground && <Hero3D />}
        <ScrollShowcase />
      </HomeAuctionGate>
    </>
  );
}
