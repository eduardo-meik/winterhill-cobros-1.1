import { computeEnrollmentDocumentPlan } from '../autodoc';

describe('computeEnrollmentDocumentPlan', () => {
  it('always includes PRESTACION and no annex by default', () => {
    const plan = computeEnrollmentDocumentPlan({});
    expect(plan.types).toContain('PRESTACION');
    expect(plan.types.length).toBe(1);
    expect(plan.prestacionAnnex).toBeNull();
  });

  it('prioritario adds PRIORITARIO and suppresses annexes', () => {
    const plan = computeEnrollmentDocumentPlan({ prioritario: true, descuentoPlanilla: true, paymentMethod: { pagare: true, cheques: true } });
    expect(plan.types).toEqual(expect.arrayContaining(['PRESTACION','PRIORITARIO']));
    expect(plan.prestacionAnnex).toBeNull();
  });

  it('embeds descuento when selected (highest precedence)', () => {
    const plan = computeEnrollmentDocumentPlan({ descuentoPlanilla: true, paymentMethod: { pagare: true, cheques: true } });
    expect(plan.types).toContain('PRESTACION');
    expect(plan.types).not.toContain('PRIORITARIO');
    expect(plan.prestacionAnnex).toBe('descuento');
  });

  it('embeds pagare when no descuento and pagare is selected', () => {
    const plan = computeEnrollmentDocumentPlan({ paymentMethod: { pagare: true } });
    expect(plan.prestacionAnnex).toBe('pagare');
  });

  it('does not create annex for cheques-only selection', () => {
    const plan = computeEnrollmentDocumentPlan({ paymentMethod: { cheques: true } });
    expect(plan.prestacionAnnex).toBeNull();
    expect(plan.types).toEqual(['PRESTACION']);
  });

  it('precedence selects descuento when descuento + pagare + cheques all true', () => {
    const plan = computeEnrollmentDocumentPlan({ descuentoPlanilla: true, paymentMethod: { pagare: true, cheques: true } });
    expect(plan.prestacionAnnex).toBe('descuento');
    expect(plan.types).toContain('PRESTACION');
  });

  it('adds PAGARE_DEUDA when debtTotal > 0 regardless of prioritario', () => {
    const plan1 = computeEnrollmentDocumentPlan({ debtTotal: 1000 });
    expect(plan1.types).toContain('PAGARE_DEUDA');

    const plan2 = computeEnrollmentDocumentPlan({ prioritario: true, debtTotal: 1 });
    expect(plan2.types).toEqual(expect.arrayContaining(['PRESTACION','PRIORITARIO','PAGARE_DEUDA']));
  });
});
