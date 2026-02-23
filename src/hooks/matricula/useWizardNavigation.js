import { useState, useMemo } from 'react';
import toast from 'react-hot-toast';

const STEPS = [
  'Seleccionar Alumnos',
  'Datos Económicos',
  'Vista Previa y Descarga'
];

/**
 * Manages wizard step navigation with validation guards.
 *
 * @param {Object} deps
 * @param {Array} deps.students - enrolled students
 * @param {Object} deps.economic - global economic data
 * @param {boolean} deps.prioritario - global prioritario flag
 * @param {string} deps.previewHtml - HTML preview content
 * @param {Object} deps.debtInfo - debt information { total, items }
 * @param {boolean} deps.hasRegularized - whether debt has been regularized
 * @param {Object|null} deps.debtDoc - debt document record
 */
export function useWizardNavigation({
  students,
  economic,
  prioritario,
  previewHtml,
  debtInfo,
  hasRegularized,
  debtDoc,
}) {
  const [step, setStep] = useState(0);

  const canProceed = () => {
    if (step === 0) {
      const debtBlocked = debtInfo.total > 0 && !hasRegularized && !debtDoc;
      return students.length > 0 && !debtBlocked;
    }
    if (step === 1) {
      if (prioritario) return true;
      return economic.colegiatura_anual && economic.cantidad_cuotas && economic.dia_vencimiento;
    }
    if (step === 2) return !!previewHtml;
    return true;
  };

  const next = () => {
    if (step < STEPS.length - 1 && canProceed()) {
      setStep(step + 1);
    } else if (!canProceed()) {
      toast.error(
        'Complete todos los datos requeridos antes de continuar. Verifique que haya seleccionado al menos un estudiante y completado los datos económicos.'
      );
    }
  };

  const back = () => {
    if (step > 0) setStep(step - 1);
  };

  return {
    STEPS,
    step,
    setStep,
    canProceed,
    next,
    back,
  };
}
