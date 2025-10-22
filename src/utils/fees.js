/**
 * Compute totals for a list of fee rows.
 * @param {Array<{amount:number,status:string}>} fees
 * @returns {{ total:number, paid:number, pending:number, overdue:number }}
 */
export function computeFeeTotals(fees) {
  const safe = Array.isArray(fees) ? fees : [];
  let total = 0, paid = 0, pending = 0, overdue = 0;
  for (const f of safe) {
    const amt = Number(f?.amount || 0);
    total += amt;
    const st = String(f?.status || '').toLowerCase();
    if (st === 'paid') paid += amt;
    else if (st === 'pending') pending += amt;
    else if (st === 'overdue') overdue += amt;
  }
  return { total, paid, pending, overdue };
}
