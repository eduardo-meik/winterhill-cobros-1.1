jest.mock('../supabase', () => ({
  supabase: {
    from: jest.fn(),
    rpc: jest.fn(),
    storage: { from: jest.fn(() => ({ remove: jest.fn() })) },
  },
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

import { supabase } from '../supabase';
import { syncEnrollmentStudentCourses } from '../matricula';

describe('syncEnrollmentStudentCourses', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('updates students to the selected target course before finalization', async () => {
    const eq = jest.fn().mockResolvedValue({ error: null });
    const update = jest.fn(() => ({ eq }));
    (supabase.from as jest.Mock).mockReturnValue({ update });

    const result = await syncEnrollmentStudentCourses({
      students: [
        {
          id: 'student-1',
          curso_id: 'curso-2025',
          target_course_id: undefined,
        },
      ],
      studentEconomicMap: {
        'student-1': {
          curso_sugerido: 'curso-2026',
        },
      },
      availableYearCourses: [
        { id: 'curso-2026', nivel: '8' },
      ],
    });

    expect(result).toEqual({ updated: 1, skipped: 0 });
    expect(supabase.from).toHaveBeenCalledWith('students');
    expect(update).toHaveBeenCalledWith(expect.objectContaining({ curso: 'curso-2026', nivel: '8' }));
    expect(eq).toHaveBeenCalledWith('id', 'student-1');
  });

  it('skips students when the selected course already matches the persisted one', async () => {
    const eq = jest.fn().mockResolvedValue({ error: null });
    const update = jest.fn(() => ({ eq }));
    (supabase.from as jest.Mock).mockReturnValue({ update });

    const result = await syncEnrollmentStudentCourses({
      students: [
        {
          id: 'student-1',
          curso_id: 'curso-2026',
        },
      ],
      studentEconomicMap: {
        'student-1': {
          curso_sugerido: 'curso-2026',
        },
      },
      availableYearCourses: [
        { id: 'curso-2026', nivel: '8' },
      ],
    });

    expect(result).toEqual({ updated: 0, skipped: 1 });
    expect(update).not.toHaveBeenCalled();
  });
});