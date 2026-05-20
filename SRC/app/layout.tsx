import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Expense SaaS — 사업비 정산 관리',
  description: '정부지원 사업비를 운영하는 스타트업·법인을 위한 멀티 테넌트 사업비 정산 SaaS.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko" className="h-full antialiased">
      <body className="min-h-full flex flex-col">{children}</body>
    </html>
  );
}
