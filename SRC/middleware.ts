import { NextResponse, type NextRequest } from 'next/server';
import { updateSession } from '@/lib/supabase/middleware';

const PUBLIC_PATHS = [
  '/login',
  '/signup',
  '/forgot-password',
  '/reset-password',
  '/verify-email',
  '/invitations',
];

const AUTH_REDIRECT_PATHS = ['/login', '/signup'];

export async function middleware(request: NextRequest) {
  const { response, user } = await updateSession(request);
  const path = request.nextUrl.pathname;

  const isPublic = PUBLIC_PATHS.some((p) => path === p || path.startsWith(`${p}/`));

  // 비로그인 + 보호 라우트 → /login
  if (!user && !isPublic && path.startsWith('/app')) {
    const url = request.nextUrl.clone();
    url.pathname = '/login';
    if (path !== '/app') url.searchParams.set('redirect', path);
    return NextResponse.redirect(url);
  }

  // 로그인 + 로그인/가입 페이지 → /app
  if (user && AUTH_REDIRECT_PATHS.includes(path)) {
    const url = request.nextUrl.clone();
    url.pathname = '/app';
    return NextResponse.redirect(url);
  }

  return response;
}

export const config = {
  matcher: [
    /*
     * 다음을 제외한 모든 경로:
     * - _next/static (정적 파일)
     * - _next/image (이미지 최적화)
     * - favicon.ico, sitemap.xml, robots.txt
     * - 이미지·아이콘 확장자
     */
    '/((?!_next/static|_next/image|favicon.ico|sitemap.xml|robots.txt|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)',
  ],
};
