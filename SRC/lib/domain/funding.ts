import type { Database } from '@/types/database';

export type FundingSourceType = Database['public']['Enums']['funding_source'];

export const FUNDING_LABELS: Record<FundingSourceType, string> = {
  gov_grant: '정부지원금',
  self_cash: '자기부담현금',
  self_in_kind: '자기부담현물',
};

export const FUNDING_SHORT: Record<FundingSourceType, string> = {
  gov_grant: '지원금',
  self_cash: '현금',
  self_in_kind: '현물',
};

export const FUNDING_COLORS: Record<FundingSourceType, string> = {
  gov_grant: 'var(--color-funding-gov)',
  self_cash: 'var(--color-funding-cash)',
  self_in_kind: 'var(--color-funding-inkind)',
};

export const FUNDING_ORDER: FundingSourceType[] = ['gov_grant', 'self_cash', 'self_in_kind'];
