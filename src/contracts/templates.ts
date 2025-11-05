// Import HTML contract templates as raw strings
// Note: paths are relative to this file; templates reside under /contratos at repo root
import prestacionHtml from '../../contratos/prestacion.html?raw';
import pagareHtml from '../../contratos/pagare.html?raw';
import descuentoHtml from '../../contratos/descuento.html?raw';

export const templates = {
  prestacion: prestacionHtml,
  pagare: pagareHtml,
  descuento: descuentoHtml,
};
