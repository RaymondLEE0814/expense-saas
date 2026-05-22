/**
 * S-ORG-001 — 조직 대시보드 (Wave 0 플레이스홀더)
 * 진짜 KPI/차트는 Wave A 에서 채워짐.
 */
import { createClient } from '@/lib/supabase/server';
import type { Database } from '@/types/database';

type OrgPick = Pick<Database['public']['Tables']['organizations']['Row'], 'id' | 'name' | 'slug'>;
type CompanyPick = Pick<Database['public']['Tables']['companies']['Row'], 'id' | 'name' | 'organization_id'>;

export const metadata = { title: '대시보드 — Expense SaaS' };

export default async function DashboardPage() {
  const supabase = await createClient();

  const { data: userData } = await supabase.auth.getUser();
  const orgsRes = await supabase.from('organizations').select('id, name, slug');
  const companiesRes = await supabase.from('companies').select('id, name, organization_id');

  const orgs: OrgPick[] = (orgsRes.data ?? []) as OrgPick[];
  const companies: CompanyPick[] = (companiesRes.data ?? []) as CompanyPick[];

  return (
    <div className="space-y-8">
      <header className="space-y-1">
        <p className="text-caption font-medium text-fg-tertiary uppercase tracking-wider">
          대시보드
        </p>
        <h1 className="text-title-1 text-fg">환영합니다 👋</h1>
        <p className="text-body text-fg-secondary">{userData.user?.email}</p>
      </header>

      <section className="rounded-lg bg-bg-secondary p-6 space-y-4">
        <h2 className="text-title-3 text-fg">접근 가능한 조직</h2>
        {orgs.length > 0 ? (
          <ul className="space-y-2">
            {orgs.map((o) => (
              <li key={o.id} className="rounded-DEFAULT bg-bg px-4 py-3 text-body text-fg">
                <strong className="font-medium">{o.name}</strong>
                <span className="ml-2 text-caption text-fg-tertiary">/{o.slug}</span>
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-body text-fg-secondary">
            아직 소속된 조직이 없습니다. 운영팀에 조직 배정을 요청해주세요.
          </p>
        )}
      </section>

      <section className="rounded-lg bg-bg-secondary p-6 space-y-4">
        <h2 className="text-title-3 text-fg">접근 가능한 회사</h2>
        {companies.length > 0 ? (
          <ul className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {companies.map((c) => (
              <li
                key={c.id}
                className="rounded-DEFAULT bg-bg px-4 py-3 text-body text-fg shadow-sm"
              >
                {c.name}
              </li>
            ))}
          </ul>
        ) : (
          <p className="text-body text-fg-secondary">아직 등록된 회사가 없습니다.</p>
        )}
      </section>

      <section className="rounded-lg border border-dashed border-divider p-6 space-y-2">
        <p className="text-caption font-medium text-fg-tertiary uppercase tracking-wider">
          Wave 0 (현재)
        </p>
        <p className="text-body text-fg-secondary">
          기본 인증 + 데이터 격리(RLS) 검증용 화면입니다.
          <br />
          회사·사업·집행 CRUD 와 정식 대시보드는{' '}
          <strong className="text-fg">Wave A</strong>에서 구현됩니다.
        </p>
      </section>
    </div>
  );
}
