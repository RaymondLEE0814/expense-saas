/** 한국 사업자등록번호 (10자리) 형식·체크섬 검증 + 표시 포맷. */

/** 입력 문자열 → 숫자만 추출. */
export function normalizeBusinessNumber(input: string): string {
  return input.replace(/[^\d]/g, '');
}

/** 표시용 포맷: 123-45-67890 */
export function formatBusinessNumber(input: string | null | undefined): string {
  if (!input) return '';
  const digits = normalizeBusinessNumber(input);
  if (digits.length !== 10) return digits;
  return `${digits.slice(0, 3)}-${digits.slice(3, 5)}-${digits.slice(5)}`;
}

/** 체크섬까지 검증. 잘못된 형식이면 false. */
export function isValidBusinessNumber(input: string | null | undefined): boolean {
  if (!input) return false;
  const digits = normalizeBusinessNumber(input);
  if (!/^\d{10}$/.test(digits)) return false;

  // 국세청 체크섬 알고리즘
  const weights = [1, 3, 7, 1, 3, 7, 1, 3, 5];
  let sum = 0;
  for (let i = 0; i < 9; i++) {
    sum += Number(digits[i]) * weights[i];
  }
  sum += Math.floor((Number(digits[8]) * 5) / 10);
  const check = (10 - (sum % 10)) % 10;
  return check === Number(digits[9]);
}
