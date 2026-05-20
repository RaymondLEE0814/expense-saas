/**
 * 금액 포맷 / 파싱 헬퍼.
 * DB 저장: 원 단위 정수.
 * UI 표시: 천 단위 콤마.
 */

const KO_FORMATTER = new Intl.NumberFormat('ko-KR');

export function formatMoney(amount: number | string | null | undefined): string {
  if (amount === null || amount === undefined || amount === '') return '-';
  const n = typeof amount === 'string' ? Number(amount) : amount;
  if (Number.isNaN(n)) return '-';
  return KO_FORMATTER.format(n);
}

export function formatWon(amount: number | string | null | undefined): string {
  const s = formatMoney(amount);
  return s === '-' ? '-' : `₩${s}`;
}

/** 콤마/공백 포함 문자열에서 숫자 추출 (음수/소수 X). */
export function parseMoney(input: string): number {
  const digits = input.replace(/[^\d]/g, '');
  if (!digits) return 0;
  return Number.parseInt(digits, 10);
}

/** 1억 / 1.2억 / 8,800만원 식의 축약 표시 (대시보드용). */
export function formatMoneyShort(amount: number | string | null | undefined): string {
  if (amount === null || amount === undefined || amount === '') return '-';
  const n = typeof amount === 'string' ? Number(amount) : amount;
  if (Number.isNaN(n) || n === 0) return '₩0';

  const abs = Math.abs(n);
  const sign = n < 0 ? '-' : '';

  if (abs >= 1_0000_0000) {
    const eok = abs / 1_0000_0000;
    const formatted = eok >= 10 ? Math.round(eok).toString() : eok.toFixed(1).replace(/\.0$/, '');
    return `${sign}₩${formatted}억`;
  }
  if (abs >= 1_0000) {
    const man = Math.round(abs / 1_0000);
    return `${sign}₩${KO_FORMATTER.format(man)}만`;
  }
  return `${sign}₩${KO_FORMATTER.format(abs)}`;
}
