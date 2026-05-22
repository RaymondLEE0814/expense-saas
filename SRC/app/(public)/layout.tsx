/**
 * Auth Shell — 비로그인 영역 공통 레이아웃 ([layouts.md §2](docs/02-design/layouts.md))
 */
export default function PublicLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-bg-secondary px-6 py-12">
      {children}
    </div>
  );
}
