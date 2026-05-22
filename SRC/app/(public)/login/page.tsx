/**
 * S-AUTH-001 — 로그인
 * MVP: 가입 / 비번 재설정은 Wave C에서 추가. 현재는 관리자가 계정을 발급해 공급.
 */
import Link from 'next/link';
import { LoginForm } from './login-form';

export const metadata = { title: '로그인 — Expense SaaS' };

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ redirect?: string }>;
}) {
  const params = await searchParams;
  const redirectTo = params.redirect;

  return (
    <div className="w-full max-w-md">
      <div className="rounded-lg bg-bg p-8 shadow-sm">
        <div className="mb-8 text-center space-y-2">
          <p className="text-caption font-medium text-fg-tertiary uppercase tracking-wider">
            Expense SaaS
          </p>
          <h1 className="text-title-2 text-fg">다시 만나서 반가워요</h1>
          <p className="text-body text-fg-secondary">
            계정 정보로 로그인해주세요
          </p>
        </div>

        <LoginForm defaultRedirect={redirectTo} />

        <p className="mt-8 text-center text-caption text-fg-tertiary">
          계정 발급은 운영팀에 문의해주세요
        </p>
      </div>

      <p className="mt-6 text-center text-caption text-fg-tertiary">
        <Link href="/" className="hover:text-fg-secondary transition-colors">
          ← 홈으로
        </Link>
      </p>
    </div>
  );
}
