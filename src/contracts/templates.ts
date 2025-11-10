// Import HTML contract templates as raw strings
// Note: paths are relative to this file; templates reside under /contratos at repo root
import prestacionHtml from '../../contratos/prestacion.html?raw';
import pagareHtml from '../../contratos/pagare.html?raw';
import descuentoHtml from '../../contratos/descuento.html?raw';
import pagarerepacHtml from '../../contratos/pagarerepac.html?raw';
import pagareDeudaHtml from '../../contratos/pagare_deuda.html?raw';
import prioritarioHtml from '../../contratos/prioritario.html?raw';

export const templates = {
  prestacion: prestacionHtml,
  pagare: pagareHtml,
  descuento: descuentoHtml,
  pagarerepac: pagarerepacHtml,
  pagare_deuda: pagareDeudaHtml,
  prioritario: prioritarioHtml,
};
