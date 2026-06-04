jest.mock('../supabase', () => ({
  supabase: {
    rpc: jest.fn(),
    from: jest.fn(() => ({ select: jest.fn() })),
    storage: { from: jest.fn(() => ({ remove: jest.fn() })) }
  }
}));

jest.mock('react-hot-toast', () => ({
  __esModule: true,
  default: {
    success: jest.fn(),
    error: jest.fn(),
    loading: jest.fn(),
    dismiss: jest.fn(),
  },
}));

jest.mock('../../contracts/templates', () => ({
  templates: {
    prestacion: '<div></div>',
    pagare: '<div></div>',
    descuento: '<div></div>',
    pagarerepac: '<div></div>',
    pagare_deuda: '<div></div>',
    prioritario: '<div></div>'
  }
}));

import { buildEnrollmentPaymentPlan } from '../matricula';

describe('buildEnrollmentPaymentPlan', () => {
  it('builds cuotas array with derived payment method', () => {
    const plan = buildEnrollmentPaymentPlan({
      enrollmentYear: 2026,
      economic: {
        colegiatura_anual: 1200000,
        cantidad_cuotas: 10,
        dia_vencimiento: 5,
      },
      paymentMethodFlags: { transferencia: true }
    });

    expect(plan).not.toBeNull();
    if (!plan) return;
    expect(plan.n_cuotas).toBe(10);
    expect(plan.payment_method).toBe('TRANSFERENCIA');
    expect(plan.cuotas[0]).toEqual({ numero: 1, amount: plan.monto_por_cuota, due_date: '2026-03-05' });
  });

  it('falls back to monto_total / cuotas and clamps day of month', () => {
    const plan = buildEnrollmentPaymentPlan({
      enrollmentYear: 2025,
      economic: {
        colegiatura_anual: 800000,
        cantidad_cuotas: 4,
        dia_vencimiento: 40
      },
      paymentMethodFlags: { pagare: true, cheques: true }
    });

    expect(plan).not.toBeNull();
    if (!plan) return;
    expect(plan.dia_vencimiento).toBe(28);
    expect(plan.monto_por_cuota).toBe(200000);
    expect(plan.payment_method).toBe('PAGARE');
    expect(plan.cuotas[3].due_date).toBe('2025-06-28');
  });

  it('returns null when required fields are missing', () => {
    const plan = buildEnrollmentPaymentPlan({
      enrollmentYear: 2025,
      economic: {
        cantidad_cuotas: '',
        dia_vencimiento: ''
      }
    });

    expect(plan).toBeNull();
  });
});
