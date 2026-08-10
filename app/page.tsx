import { Hero3D } from '@/components/home/Hero3D';
import { HomeAuctionGate } from '@/components/home/HomeAuctionGate';
import { ScrollShowcase } from '@/components/home/ScrollShowcase';
import { HomepageScrollBackground } from '@/components/home/HomepageScrollBackground';

import { getActiveSeason } from '@/lib/season-server';
import { createSupabaseAdmin } from '@/lib/supabase/admin';
import { getLeagueConfig } from '@/lib/league-config';

export default async function HomePage() {
  const supabase = createSupabaseAdmin();
  const season = await getActiveSeason(supabase).catch(() => null);
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
