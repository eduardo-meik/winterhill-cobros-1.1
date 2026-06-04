import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { PaymentDetailsModal } from './PaymentDetailsModal';
import { sendEmailViaFunction } from '../../services/email';

const mockUpdateFeeMutateAsync = jest.fn();
const mockDeleteFeeMutateAsync = jest.fn();
const mockFrom = jest.fn();

jest.mock('react-hot-toast', () => {
  const toast = {
    success: jest.fn(),
    error: jest.fn(),
    loading: jest.fn(),
    dismiss: jest.fn(),
  };

  return {
    __esModule: true,
    default: toast,
    ...toast,
  };
});

jest.mock('clsx', () => ({
  __esModule: true,
  default: (...classes) => classes.filter(Boolean).join(' '),
}));

jest.mock('../../hooks/usePermissions', () => ({
  usePermissions: () => ({
    showEditPaymentButton: true,
    showDeletePaymentButton: false,
    isAssistant: () => false,
    user: {
      email: 'admin@winterhill.cl',
      user_metadata: { full_name: 'Caja Winterhill' },
    },
  }),
}));

jest.mock('../../hooks/mutations/useFeeMutations', () => ({
  useFeeMutations: () => ({
    updateFee: {
      isPending: false,
      mutateAsync: mockUpdateFeeMutateAsync,
    },
    deleteFee: {
      isPending: false,
      mutateAsync: mockDeleteFeeMutateAsync,
    },
  }),
}));

jest.mock('../../services/receiptGenerator', () => ({
  generateReceiptPdf: jest.fn(),
  buildReceiptEmailHtml: jest.fn(() => '<html>comprobante</html>'),
}));

jest.mock('../../services/email', () => ({
  sendEmailViaFunction: jest.fn(),
}));

jest.mock('../../services/supabase', () => ({
  supabase: {
    from: (...args) => mockFrom(...args),
  },
}));

function createStudentGuardianBuilder(rows) {
  const builder = {
    select: jest.fn(() => builder),
    eq: jest.fn(() => builder),
    order: jest.fn(() => Promise.resolve({ data: rows, error: null })),
  };

  return builder;
}

describe('PaymentDetailsModal', () => {
  const onClose = jest.fn();
  const onSuccess = jest.fn();

  const payment = {
    id: 'fee-1',
    status: 'pending',
    amount: 150000,
    payment_date: '2026-03-15',
    payment_method: 'TRANSFERENCIA',
    numero_cuota: 3,
    mov_bancario: 'TX-9981',
    notes: null,
    due_date: null,
    student: {
      id: 'student-1',
      whole_name: 'Alumno Demo',
      curso: { nom_curso: '6A' },
    },
  };

  beforeEach(() => {
    jest.clearAllMocks();

    mockFrom.mockImplementation((table) => {
      if (table === 'student_guardian') {
        return createStudentGuardianBuilder([
          {
            guardian_role: 'PEDAGOGICO',
            is_primary: true,
            guardian: {
              id: 'g-1',
              first_name: 'Ana',
              last_name: 'Pedagogica',
              email: 'pedagogico@example.com',
              phone: '111',
              relationship_type: 'Madre',
            },
          },
          {
            guardian_role: 'ECONOMICO',
            is_primary: false,
            guardian: {
              id: 'g-2',
              first_name: 'Luis',
              last_name: 'Economico',
              email: 'economico@example.com',
              phone: '222',
              relationship_type: 'Padre',
            },
          },
        ]);
      }

      return createStudentGuardianBuilder([]);
    });

    jest.spyOn(window, 'confirm').mockReturnValue(false);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('envia automaticamente el recibo al apoderado economico cuando cambia a pagado', async () => {
    render(
      <PaymentDetailsModal
        payment={payment}
        onClose={onClose}
        onSuccess={onSuccess}
      />
    );

    await waitFor(() => {
      expect(screen.getByText('economico@example.com')).toBeInTheDocument();
    });

    fireEvent.click(screen.getByRole('button', { name: 'Editar Pago' }));

    const statusSelect = document.querySelector('select[name="status"]');
    expect(statusSelect).not.toBeNull();
    fireEvent.change(statusSelect, { target: { value: 'paid' } });

    fireEvent.click(screen.getByRole('button', { name: 'Guardar Cambios' }));

    await waitFor(() => {
      expect(mockUpdateFeeMutateAsync).toHaveBeenCalledTimes(1);
    });

    await waitFor(() => {
      expect(sendEmailViaFunction).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'economico@example.com',
          type: 'receipt',
          related_id: 'fee-1',
        })
      );
    });
  });
});
