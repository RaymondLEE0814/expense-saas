import { differenceInCalendarDays, format, parseISO } from 'date-fns';

/** date 또는 ISO 문자열을 'YYYY-MM-DD' 로 표시. */
export function formatDate(value: string | Date | null | undefined): string {
  if (!value) return '-';
  const d = typeof value === 'string' ? parseISO(value) : value;
  if (Number.isNaN(d.getTime())) return '-';
  return format(d, 'yyyy-MM-dd');
}

/** 'YYYY년 M월 D일' 한국어 표시. */
export function formatDateKo(value: string | Date | null | undefined): string {
  if (!value) return '-';
  const d = typeof value === 'string' ? parseISO(value) : value;
  if (Number.isNaN(d.getTime())) return '-';
  return format(d, 'yyyy년 M월 d일');
}

/** 종료일까지의 D-day. 음수면 종료됨. */
export function dDay(endDate: string | Date | null | undefined, from: Date = new Date()): number | null {
  if (!endDate) return null;
  const d = typeof endDate === 'string' ? parseISO(endDate) : endDate;
  if (Number.isNaN(d.getTime())) return null;
  return differenceInCalendarDays(d, from);
}

/** D-day 라벨 (D-12, D-day, D+5) */
export function dDayLabel(endDate: string | Date | null | undefined): string {
  const n = dDay(endDate);
  if (n === null) return '';
  if (n === 0) return 'D-day';
  if (n > 0) return `D-${n}`;
  return `D+${Math.abs(n)}`;
}

export type DDayLevel = 'safe' | 'warning' | 'danger' | 'past';

export function dDayLevel(endDate: string | Date | null | undefined): DDayLevel | null {
  const n = dDay(endDate);
  if (n === null) return null;
  if (n < 0) return 'past';
  if (n <= 7) return 'danger';
  if (n <= 30) return 'warning';
  return 'safe';
}
