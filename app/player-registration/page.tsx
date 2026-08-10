import { PlayerRegistrationForm } from '@/components/forms/PlayerRegistrationForm';
import { PageHeader, PageShell } from '@/components/ui/PageShell';
import { getActiveSeason } from '@/lib/season-server';
import { createSupabaseAdmin } from '@/lib/supabase/admin';
import { getLeagueConfig } from '@/lib/league-config';

export default async function PlayerRegistrationPage() {
  const supabase = createSupabaseAdmin();
  const season = await getActiveSeason(supabase).catch(() => null);
  const leagueConfig = getLeagueConfig(season?.league_code);

  return (
    <PageShell>
      <PageHeader
        eyebrow="Player entry"
        title={`Register for ${leagueConfig.shortName} Auction`}
        description="Submit your profile and photo. Admin will approve, edit if needed, and set your base price."
      />
      <div className="mt-10">
        <PlayerRegistrationForm />
      </div>
    </PageShell>
  );
}
