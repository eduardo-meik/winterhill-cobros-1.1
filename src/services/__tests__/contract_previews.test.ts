import * as fs from 'fs';
import * as path from 'path';

jest.mock('../supabase', () => ({
  supabase: {
    from: () => ({
      select: () => ({
        eq: () => ({
          eq: () => ({
            limit: () => ({ maybeSingle: async () => ({ data: null, error: null }) })
          })
        })
      })
    })
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

jest.mock('../../contracts/templates', () => {
  const fs = require('fs');
  const pathMod = require('path');
  const load = (file: string) => fs.readFileSync(pathMod.join(process.cwd(), 'contratos', file), 'utf8');
  return {
    templates: {
      prestacion: load('prestacion.html'),
      pagare: load('pagare.html'),
      descuento: load('descuento.html'),
      pagarerepac: load('pagarerepac.html'),
      pagare_deuda: load('pagare_deuda.html'),
      prioritario: load('prioritario.html'),
    }
  };
});

import { computeEnrollmentDocumentPlan } from '../autodoc';
import {
  buildPrestacionPayload,
  GuardianRecord,
  StudentRecord,
  renderPrestacionWithAnnex,
} from '../matricula';

describe('Contrato de Prestación + anexos', () => {
  const outputDir = path.join(process.cwd(), 'dist', 'contract-previews');

  beforeAll(() => {
    fs.mkdirSync(outputDir, { recursive: true });
  });

  const guardian: GuardianRecord = {
    id: 'guardian-1',
    owner_id: 'owner-1',
    first_name: 'Ana',
    last_name: 'González',
    run: '12.345.678-9',
    email: 'ana@example.com',
    address: 'Calle Falsa 123',
    comuna: 'Viña del Mar',
    profesion: 'Ingeniera',
    estado_civil: 'Casada',
  };

  const students: StudentRecord[] = [
    {
      id: 'student-1',
      whole_name: 'Alumno Uno',
      run: '11.111.111-1',
      curso_nombre: '4° Medio A',
    },
    {
      id: 'student-2',
      whole_name: 'Alumno Dos',
      run: '22.222.222-2',
      curso_nombre: '2° Básico B',
    },
  ];

  const economic = {
    monto_matricula: 150000,
    colegiatura_anual: 3600000,
    cantidad_cuotas: 10,
    monto_cuota: 360000,
    dia_vencimiento: 5,
  };

  type Scenario = {
    name: string;
    prioritario?: boolean;
    descuentoPlanilla?: boolean;
    payment: {
      cheques?: boolean;
      transferencia?: boolean;
      efectivo?: boolean;
      tarjeta?: boolean;
      pagare?: boolean;
    };
    descuento?: {
      porcentaje?: number;
      motivo?: string;
      condiciones?: string;
    } | null;
    cheques?: Array<{
      numero_cuota?: number;
      numero_serie?: string;
      banco?: string;
      fecha_emision?: string;
      monto?: number;
      notas?: string;
    }>;
    expectedAnnex: 'descuento' | 'pagare' | null;
  };

  const scenarios: Scenario[] = [
    {
      name: 'prestacion_base',
      payment: { transferencia: true },
      expectedAnnex: null,
    },
    {
      name: 'prestacion_descuento',
      descuentoPlanilla: true,
      payment: { transferencia: true },
      descuento: { porcentaje: 15, motivo: 'Convenio empresa', condiciones: 'Mantener asistencia' },
      expectedAnnex: 'descuento',
    },
    {
      name: 'prestacion_pagare',
      payment: { pagare: true },
      expectedAnnex: 'pagare',
    },
    {
      name: 'prestacion_descuento_y_pagare',
      descuentoPlanilla: true,
      payment: { transferencia: true, pagare: true },
      descuento: { porcentaje: 20, motivo: 'Beca hermanos', condiciones: 'Sujetos a rendimiento' },
      expectedAnnex: 'descuento',
    },
    {
      name: 'prestacion_prioritario',
      prioritario: true,
      descuentoPlanilla: true,
      payment: { pagare: true },
      descuento: { porcentaje: 25, motivo: 'Estudiante prioritario', condiciones: 'Condiciones PIE' },
      expectedAnnex: null,
    },
  ];

  it.each(scenarios)('genera %s', (scenario) => {
    const plan = computeEnrollmentDocumentPlan({
      prioritario: !!scenario.prioritario,
      descuentoPlanilla: !!scenario.descuentoPlanilla,
      paymentMethod: {
        cheques: !!scenario.payment.cheques,
        pagare: !!scenario.payment.pagare,
      },
      debtTotal: 0,
    });

    expect(plan.types).toContain('PRESTACION');
    expect(plan.prestacionAnnex).toBe(scenario.expectedAnnex);

    const payload = buildPrestacionPayload({
      guardian,
      year: 2025,
      students,
      economic: scenario.prioritario ? undefined : economic,
      paymentMethod: scenario.prioritario ? undefined : scenario.payment,
      cheques: scenario.cheques,
      descuento: scenario.descuento,
    });

    const html = renderPrestacionWithAnnex(payload, { annex: scenario.expectedAnnex });

    const clauseMatches = html.match(/<strong>Undécimo\.<\/strong>/g) ?? [];
    expect(clauseMatches.length).toBe(1);

    if (scenario.expectedAnnex === 'descuento') {
      expect(html).toContain('Contrato Anexo sobre Beca y Autorización de Descuento por Planilla');
    }
    if (scenario.expectedAnnex === 'pagare') {
      expect(html).toContain('Anexo - Pagaré');
    }

    const outputPath = path.join(outputDir, `${scenario.name}.html`);
    fs.writeFileSync(outputPath, html, 'utf8');
    console.log(`📄 Contrato generado: ${outputPath}`);
  });
});
