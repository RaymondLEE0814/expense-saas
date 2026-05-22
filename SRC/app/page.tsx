import Link from 'next/link';

export default function Home() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-bg-secondary px-6">
      <div className="max-w-xl w-full text-center space-y-8">
        <div className="space-y-3">
          <p className="text-caption font-medium text-fg-tertiary uppercase tracking-wider">
            Expense SaaS
          </p>
          <h1 className="text-title-1 text-fg leading-tight">
            정산, 다시 간단해집니다
          </h1>
          <p className="text-body-lg text-fg-secondary">
            정부지원 사업비를 한 곳에서. 회사·사업·비목·집행을 실시간으로 추적하세요.
          </p>
        </div>

        <div className="flex items-center justify-center gap-3">
          <Link
            href="/login"
            className="inline-flex items-center justify-center h-12 px-7 rounded-pill bg-accent hover:bg-accent-hover text-fg-inverse text-body-lg font-medium transition-all duration-200 hover:-translate-y-0.5 hover:shadow"
          >
            로그인
          </Link>
          <Link
            href="/signup"
            className="inline-flex items-center justify-center h-12 px-7 rounded-pill text-accent text-body-lg font-medium hover:bg-bg-tertiary transition-colors duration-200"
          >
            가입하기 →
          </Link>
        </div>

        <p className="text-caption text-fg-tertiary pt-10">
          현재 Phase 1 (MVP α) 개발 중 · 자사((주)슈퍼런) 우선 적용
        </p>
      </div>
    </main>
  );
}
