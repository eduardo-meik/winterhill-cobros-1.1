import { reconcileDayAttendance } from '@/utils/attendanceReconciliation';
import { excelSerialToDate } from '@/utils/excelSerialDate';

describe('excelSerialToDate', () => {
  it('convierte serial 0 al epoch de Excel', () => {
    const result = excelSerialToDate(0);
    expect(result.toISOString()).toBe('1899-12-30T00:00:00.000Z');
  });

  it('convierte serial con fraccion de dia', () => {
    const result = excelSerialToDate(1.5);
    expect(result.toISOString()).toBe('1899-12-31T12:00:00.000Z');
  });
});

describe('reconcileDayAttendance', () => {
  const bloque = {
    inicioPlanificado: new Date('2026-05-25T08:00:00.000Z'),
    finPlanificado: new Date('2026-05-25T16:00:00.000Z'),
  };

  it('marca cumplimiento cuando cumple tolerancia', () => {
    const result = reconcileDayAttendance(
      bloque,
      [
        { tipoMarca: 'entrada', fechaHoraMarca: new Date('2026-05-25T08:01:00.000Z') },
        { tipoMarca: 'salida', fechaHoraMarca: new Date('2026-05-25T16:00:00.000Z') },
      ],
      1,
    );

    expect(result.estado).toBe('cumplimiento');
    expect(result.minutosAtraso).toBe(0);
  });

  it('marca atraso cuando supera tolerancia', () => {
    const result = reconcileDayAttendance(
      bloque,
      [
        { tipoMarca: 'entrada', fechaHoraMarca: new Date('2026-05-25T08:05:00.000Z') },
        { tipoMarca: 'salida', fechaHoraMarca: new Date('2026-05-25T16:00:00.000Z') },
      ],
      1,
    );

    expect(result.estado).toBe('atraso');
    expect(result.minutosAtraso).toBe(4);
  });

  it('marca salida anticipada cuando corresponde', () => {
    const result = reconcileDayAttendance(
      bloque,
      [
        { tipoMarca: 'entrada', fechaHoraMarca: new Date('2026-05-25T08:00:00.000Z') },
        { tipoMarca: 'salida', fechaHoraMarca: new Date('2026-05-25T15:50:00.000Z') },
      ],
      1,
    );

    expect(result.estado).toBe('salida_anticipada');
    expect(result.minutosSalidaAnticipada).toBe(9);
  });

  it('marca incompleto cuando faltan marcas', () => {
    const result = reconcileDayAttendance(
      bloque,
      [{ tipoMarca: 'entrada', fechaHoraMarca: new Date('2026-05-25T08:00:00.000Z') }],
      1,
    );

    expect(result.estado).toBe('incompleto');
    expect(result.minutosEfectivos).toBe(0);
  });

  it('marca sin_horario cuando no hay bloque planificado', () => {
    const result = reconcileDayAttendance(null, [], 1);

    expect(result.estado).toBe('sin_horario');
    expect(result.minutosPlanificados).toBe(0);
  });
});
