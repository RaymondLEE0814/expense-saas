/**
 * App Shell — 로그인 후 영역 공통 레이아웃 ([layouts.md §1](docs/02-design/layouts.md)).
 * Wave 0: 간소화된 헤더 + 콘텐츠 영역. 사이드바는 Wave B 폴리시에서 추가.
 */
import { redirect } from 'next/navigation';
import Link from 'next/link';
import { createClient } from '@/lib/supabase/server';
import { logoutAction } from '../(public)/login/actions';

export default async function AppLayout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  return (
    <div className="min-h-screen flex flex-col bg-bg">
      <header className="sticky top-0 z-40 h-14 border-b border-divider bg-bg/95 backdrop-blur">
        <div className="mx-auto flex h-full max-w-screen-2xl items-center justify-between px-6 md:px-8">
          <Link href="/app" className="text-title-3 font-semibold text-fg">
            Expense SaaS
          </Link>
          <div className="flex items-center gap-3 text-body text-fg-secondary">
            <span className="hidden sm:inline">{user.email}</span>
            <form action={logoutAction}>
              <button
                type="submit"
                className="rounded-pill px-4 py-1.5 text-body text-accent hover:bg-bg-tertiary transition-colors"
              >
                로그아웃
              </button>
            </form>
          </div>
        </div>
      </header>

      <main className="flex-1">
        <div className="mx-auto max-w-screen-2xl px-6 py-8 md:px-8">{children}</div>
      </main>
    </div>
  );
}
