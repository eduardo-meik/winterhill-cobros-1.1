import { computeFeeTotals } from './fees';

describe('computeFeeTotals', () => {
  it('handles empty and null inputs', () => {
    expect(computeFeeTotals(null)).toEqual({ total: 0, paid: 0, pending: 0, overdue: 0 });
    expect(computeFeeTotals([])).toEqual({ total: 0, paid: 0, pending: 0, overdue: 0 });
  });

  it('sums amounts by status', () => {
    const fees = [
      { amount: 1000, status: 'paid' },
      { amount: 2000, status: 'pending' },
      { amount: 3000, status: 'overdue' },
      { amount: 4000, status: 'unknown' },
    ];
    const res = computeFeeTotals(fees);
    expect(res.total).toBe(1000 + 2000 + 3000 + 4000);
    expect(res.paid).toBe(1000);
    expect(res.pending).toBe(2000);
    expect(res.overdue).toBe(3000);
  });
});
