/**
 * Helper functions for Matricula logic
 */

/**
 * Builds the economic data patch object for enrollment updates.
 * Ensures that if 'prioritario' is true, all payment method flags are forced to false.
 * 
 * @param {Object} params
 * @param {Object} params.economic - Raw economic form data
 * @param {number} params.colegiaturaAnual - Calculated annual fee
 * @param {number} params.cantidadCuotas - Number of installments
 * @param {number} params.montoCuota - Amount per installment
 * @param {Object} params.paymentMethod - Payment method flags (cheques, pagare, etc.)
 * @param {boolean} params.descuentoPlanilla - Payroll deduction flag
 * @param {boolean} params.prioritario - Priority/Scholarship flag
 * @param {Object} params.descuentoInfo - Discount information
 * @returns {Object} The sanitized patch object ready for the API
 */
export function buildEconomicPatch({
  economic,
  colegiaturaAnual,
  cantidadCuotas,
  montoCuota,
  paymentMethod,
  descuentoPlanilla,
  prioritario,
  descuentoInfo
}) {
  // If prioritario is true, force all payment methods to false
  const isPrioritario = !!prioritario;
  
  return {
    // Economic data
    monto_matricula: Number(economic.monto_matricula) || 0,
    colegiatura_anual: colegiaturaAnual,
    cantidad_cuotas: cantidadCuotas,
    monto_cuota: montoCuota,
    dia_vencimiento: Number(economic.dia_vencimiento) || 0,
    
    // Payment methods - cleared if prioritario
    forma_pago_cheques: isPrioritario ? false : (paymentMethod.cheques || false),
    forma_pago_transferencia: isPrioritario ? false : (paymentMethod.transferencia || false),
    forma_pago_efectivo: isPrioritario ? false : (paymentMethod.efectivo || false),
    forma_pago_tarjeta: isPrioritario ? false : (paymentMethod.tarjeta || false),
    forma_pago_pagare: isPrioritario ? false : (paymentMethod.pagare || false),
    forma_pago_descuento_planilla: isPrioritario ? false : (descuentoPlanilla || false),
    
    prioritario: isPrioritario,
    porcentaje_descuento: descuentoInfo.porcentaje_descuento || 0,
    monto_total_descuento: descuentoInfo.monto_total_descuento || 0
  };
}
