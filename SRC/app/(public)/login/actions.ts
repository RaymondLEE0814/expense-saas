'use server';

import { redirect } from 'next/navigation';
import { z } from 'zod';
import { createClient } from '@/lib/supabase/server';

const LoginInput = z.object({
  email: z.string().email('올바른 이메일 형식이 아니에요'),
  password: z.string().min(1, '비밀번호를 입력해주세요'),
  redirect: z.string().optional(),
});

export type LoginResult =
  | { ok: true }
  | { ok: false; code: 'VALIDATION' | 'CREDENTIALS' | 'UNVERIFIED' | 'INTERNAL'; message: string; fieldErrors?: Record<string, string> };

export async function loginAction(prevState: LoginResult | null, formData: FormData): Promise<LoginResult> {
  const parsed = LoginInput.safeParse({
    email: formData.get('email'),
    password: formData.get('password'),
    redirect: formData.get('redirect') ?? undefined,
  });

  if (!parsed.success) {
    const fieldErrors: Record<string, string> = {};
    for (const issue of parsed.error.issues) {
      const key = issue.path[0]?.toString();
      if (key) fieldErrors[key] = issue.message;
    }
    return { ok: false, code: 'VALIDATION', message: '입력값을 확인해주세요', fieldErrors };
  }

  const supabase = await createClient();
  const { data, error } = await supabase.auth.signInWithPassword({
    email: parsed.data.email,
    password: parsed.data.password,
  });

  if (error) {
    if (error.message?.toLowerCase().includes('email not confirmed')) {
      return { ok: false, code: 'UNVERIFIED', message: '이메일 인증이 필요합니다.' };
    }
    return { ok: false, code: 'CREDENTIALS', message: '이메일 또는 비밀번호가 올바르지 않습니다.' };
  }

  if (!data.session) {
    return { ok: false, code: 'INTERNAL', message: '로그인은 됐지만 세션이 발급되지 않았어요. 다시 시도해주세요.' };
  }

  const redirectTo = parsed.data.redirect && parsed.data.redirect.startsWith('/') ? parsed.data.redirect : '/app';
  redirect(redirectTo);
}

export async function logoutAction() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect('/login');
}
