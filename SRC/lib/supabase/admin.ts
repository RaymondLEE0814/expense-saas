/**
 * Service-role 클라이언트 — RLS 우회.
 * !!! 절대 클라이언트 코드에서 import 금지 !!!
 * 사용처: 멤버 초대 메일 발송, 관리자 작업 등 서버 사이드 전용.
 */
import { createClient as createSupabaseClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

let cached: ReturnType<typeof createSupabaseClient<Database>> | null = null;

export function createAdminClient() {
  if (cached) return cached;

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) {
    throw new Error('Supabase admin env missing — service_role 키 필요');
  }

  cached = createSupabaseClient<Database>(url, key, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  return cached;
}
