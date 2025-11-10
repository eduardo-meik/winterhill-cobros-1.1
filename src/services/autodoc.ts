export type PrestacionAnnex = 'pagare' | 'descuento' | null;

export interface AutoDocInput {
  prioritario?: boolean;
  paymentMethod?: { cheques?: boolean; pagare?: boolean } | null;
  descuentoPlanilla?: boolean;
  debtTotal?: number | null;
}

export interface AutoDocPlan {
  types: string[]; // e.g., ['PRESTACION','PRIORITARIO','PAGARE_DEUDA']
  prestacionAnnex: PrestacionAnnex; // which annex (if any) is embedded into PRESTACION
}

/**
 * Compute the set of enrollment_documents to ensure based on enrollment meta and debt status.
 * Rules:
 * - Always generate PRESTACION.
 * - If prioritario is true → do NOT embed annexes in PRESTACION and also generate PRIORITARIO as a separate doc.
 * - If NOT prioritario → embed at most one annex into PRESTACION with precedence:
 *     descuentoPlanilla > pagare > cheques.
 * - If debtTotal > 0 → also generate PAGARE_DEUDA as a separate doc.
 */
export function computeEnrollmentDocumentPlan(input: AutoDocInput): AutoDocPlan {
  const prioritario = !!input?.prioritario;
  const descuento = !!input?.descuentoPlanilla;
  const pm = input?.paymentMethod || {};
  const hasPagare = !!pm.pagare;
  // Cheques do not influence annex selection; they only affect PRESTACION payload table
  const debt = typeof input?.debtTotal === 'number' ? (input?.debtTotal || 0) : 0;

  const types: string[] = ['PRESTACION'];
  let prestacionAnnex: PrestacionAnnex = null;

  if (prioritario) {
    types.push('PRIORITARIO');
    prestacionAnnex = null; // no annexes when prioritario
  } else {
    if (descuento) prestacionAnnex = 'descuento';
    else if (hasPagare) prestacionAnnex = 'pagare';
    // Cheques never becomes a separate annex; it's always included via cheques_table in PRESTACION
  }

  if (debt > 0) {
    types.push('PAGARE_DEUDA');
  }

  return { types, prestacionAnnex };
}
