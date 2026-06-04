import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { MatriculaWizard } from '../MatriculaWizard';
import * as matriculaService from '../../../services/matricula';

const mockUseAuth = jest.fn();
const mockUseLocation = jest.fn();
const mockNavigate = jest.fn();

jest.mock('../../../contexts/AuthContext', () => ({
  useAuth: () => mockUseAuth(),
}));

jest.mock('react-hot-toast', () => ({
  success: jest.fn(),
  error: jest.fn(),
  loading: jest.fn(),
  dismiss: jest.fn(),
}));

jest.mock('clsx', () => ({
  __esModule: true,
  default: (...classes) => classes.filter(Boolean).join(' '),
}));

jest.mock('react-router-dom', () => ({
  useNavigate: () => mockNavigate,
  useLocation: () => mockUseLocation(),
}));

jest.mock('../FinalizeEnrollmentModal', () => ({
  __esModule: true,
  default: () => null,
}));
jest.mock('../ChequesDataModal', () => ({
  __esModule: true,
  ChequesDataModal: () => null,
}));
jest.mock('../../guardians/GuardianFormModal', () => ({
  __esModule: true,
  GuardianFormModal: ({ isOpen }) => (isOpen ? <div data-testid="guardian-modal" /> : null),
}));
jest.mock('../../students/StudentFormModal', () => ({
  __esModule: true,
  StudentFormModal: ({ isOpen }) => (isOpen ? <div data-testid="student-modal" /> : null),
}));

jest.mock('../../../services/matricula', () => ({
  fetchCurrentGuardian: jest.fn(),
  getOrCreateEnrollment: jest.fn(),
  listEnrollmentStudents: jest.fn(),
  addStudentToEnrollment: jest.fn(),
  removeStudentFromEnrollment: jest.fn(),
  updateEnrollmentMeta: jest.fn(),
  getActivePagareTemplate: jest.fn(),
  buildPagarePayload: jest.fn(),
  renderTemplate: jest.fn(),
  createPagareDocument: jest.fn(),
  getGuardianOutstandingDebt: jest.fn(),
  buildPagareDeudaPayload: jest.fn(),
  renderPagareDeuda: jest.fn(),
  createDebtPagareDocument: jest.fn(),
  hasSignedRegularization: jest.fn(),
  signEnrollmentDocument: jest.fn(),
  sha256: jest.fn(),
  buildEnrollmentPaymentPlan: jest.fn(),
  finalizeEnrollmentPreview: jest.fn(),
  finalizeEnrollmentConfirm: jest.fn(),
  buildPrestacionPayload: jest.fn(),
  renderPrestacionWithAnnex: jest.fn(),
  createPrestacionDocument: jest.fn(),
  ensureEnrollmentDocuments: jest.fn(),
  saveChequesForEnrollment: jest.fn(),
}));

jest.mock('../../../services/autorizacionDescuento', () => ({
  buildAutorizacionPayload: jest.fn(),
  generateAutorizacionHTML: jest.fn().mockResolvedValue('<html></html>'),
}));

jest.mock('../../../services/pdfGenerator', () => ({
  generatePDFFromHTML: jest.fn().mockResolvedValue(new Blob()),
  downloadPDFBlob: jest.fn(),
}));

jest.mock('../../../services/email', () => ({
  sendEmailViaFunction: jest.fn(),
  blobToBase64: jest.fn().mockResolvedValue('base64'),
}));

jest.mock('../../../services/supabase', () => {
  const mockFrom = jest.fn();
  const createBuilder = (response) => {
    const builder = {
      select: jest.fn(() => builder),
      eq: jest.fn(() => builder),
      in: jest.fn(() => builder),
      or: jest.fn(() => builder),
      limit: jest.fn(() => builder),
      maybeSingle: jest.fn(() => Promise.resolve({ data: response.single ?? response.data ?? null, error: null })),
      then: (resolve, reject) => Promise.resolve(response).then(resolve, reject),
      catch: (reject) => Promise.resolve(response).catch(reject),
      finally: (cb) => Promise.resolve(response).finally(cb),
    };
    return builder;
  };

  const defaultResponse = { data: [], error: null };

  mockFrom.mockImplementation((table) => {
    if (table === 'guardians') {
      return createBuilder({ data: [], error: null, single: { id: 'db-guardian', first_name: 'DB', last_name: 'Guardian' } });
    }
    if (table === 'student_guardian') {
      return createBuilder({ data: [], error: null });
    }
    if (table === 'enrollment_documents') {
      return createBuilder({ data: [], error: null });
    }
    return createBuilder(defaultResponse);
  });

  return { supabase: { from: (table) => mockFrom(table) } };
});

const assistedUser = {
  id: 'admin-1',
  profile: 'ADMIN',
  email: 'admin@example.com',
};

beforeEach(() => {
  jest.clearAllMocks();
  mockUseAuth.mockReturnValue({ user: assistedUser });
  mockUseLocation.mockReturnValue({ state: undefined });
  mockNavigate.mockReset();

  matriculaService.getOrCreateEnrollment.mockResolvedValue({ id: 'enr-1', year: 2025, meta: {} });
  matriculaService.listEnrollmentStudents.mockResolvedValue([]);
  matriculaService.getGuardianOutstandingDebt.mockResolvedValue({ total: 0, items: [] });
  matriculaService.hasSignedRegularization.mockResolvedValue(false);
  matriculaService.ensureEnrollmentDocuments.mockResolvedValue();
  matriculaService.updateEnrollmentMeta.mockResolvedValue();
  matriculaService.buildEnrollmentPaymentPlan.mockReturnValue({ schedule: [] });
});

describe('MatriculaWizard assisted modals', () => {
  test('shows guardian creation shortcut while searching in assisted mode', async () => {
    render(<MatriculaWizard />);
    const button = await screen.findByRole('button', { name: '➕ Nuevo apoderado' });
    expect(button).toBeInTheDocument();
  });

  test('shows student registration shortcut when guardian has no students', async () => {
    mockUseLocation.mockReturnValue({
      state: {
        guardianSnapshot: {
          id: 'guardian-1',
          first_name: 'Ada',
          last_name: 'Lovelace',
          run: '1-9',
          email: 'ada@example.com',
        },
      },
    });

    render(<MatriculaWizard />);

    await waitFor(() => {
      expect(screen.getByText('Mis Alumnos Asociados')).toBeInTheDocument();
    });

    expect(screen.getByRole('button', { name: 'Registrar estudiante' })).toBeInTheDocument();
  });
});
