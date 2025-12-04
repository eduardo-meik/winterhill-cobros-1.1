import React, { useEffect, useMemo, useState } from 'react';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';

/**
 * Modal para capturar múltiples cheques (uno por cuota)
 * Props:
 * - isOpen: boolean
 * - onClose: () => void
 * - onSave: (chequesArray) => void
 * - initialData?: Array<{ numero_cuota, numero_serie, banco, fecha_emision, monto, notas }>
 * - cantidadCuotas: number
 * - montoCuota?: number (monto por cuota total, ya con descuentos)
 * - diaVencimiento?: number (día del mes para generar vencimientos desde marzo)
 * - year?: number (año académico de la matrícula)
 */
export function ChequesDataModal({ isOpen, onClose, onSave, initialData = [], cantidadCuotas = 1, montoCuota = 0, diaVencimiento, year }) {
  const today = useMemo(() => new Date().toISOString().slice(0, 10), []);
  const montoCuotaBase = useMemo(
    () => Math.max(0, Number(montoCuota) || 0),
    [montoCuota]
  );
  const [rows, setRows] = useState(() => {
    const N = Math.max(1, Number(cantidadCuotas) || 1);
    const base = Array.from({ length: N }, (_, i) => ({
      numero_cuota: i + 1,
      numero_serie: '',
      banco: '',
      fecha_emision: today,
      monto: montoCuotaBase,
      notas: ''
    }));
    // Apply initialData if provided
    if (Array.isArray(initialData) && initialData.length) {
      initialData.forEach((r) => {
        const idx = (r.numero_cuota ? r.numero_cuota - 1 : -1);
        if (idx >= 0 && idx < base.length) base[idx] = { ...base[idx], ...r };
      });
    }
    return base;
  });

  const [errors, setErrors] = useState({});

  // Adjust rows when cantidadCuotas changes
  useEffect(() => {
    const N = Math.max(1, Number(cantidadCuotas) || 1);
    setRows((prev) => {
      const next = [...prev];
      if (next.length < N) {
        for (let i = next.length; i < N; i++) {
          next.push({ numero_cuota: i + 1, numero_serie: '', banco: '', fecha_emision: today, monto: montoCuotaBase, notas: '' });
        }
      } else if (next.length > N) {
        next.length = N; // truncate
      }
      // re-number cuotas to ensure 1..N
      return next.map((r, i) => ({ ...r, numero_cuota: i + 1 }));
    });
  }, [cantidadCuotas, montoCuotaBase, today]);

  const setField = (idx, field, value) => {
    setRows((prev) => prev.map((r, i) => (i === idx ? { ...r, [field]: value } : r)));
    const key = `${idx}.${field}`;
    if (errors[key]) setErrors((e) => ({ ...e, [key]: '' }));
  };

  const validate = () => {
    const e = {};
    rows.forEach((r, idx) => {
      if (!r.numero_serie?.trim()) e[`${idx}.numero_serie`] = 'Requerido';
      if (!r.banco?.trim()) e[`${idx}.banco`] = 'Requerido';
      if (!r.fecha_emision) e[`${idx}.fecha_emision`] = 'Requerido';
      if (!r.monto || Number(r.monto) <= 0) e[`${idx}.monto`] = 'Debe ser > 0';
    });
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleAutoFill = () => {
    setRows((prev) => {
      const N = prev.length;
      const baseDay = Number(diaVencimiento) && Number(diaVencimiento) > 0 ? Math.min(28, Number(diaVencimiento)) : null;
      const baseYear = Number(year) || new Date().getFullYear();

      // Buscar primer banco no vacío para usarlo como default
      const firstBanco = prev.find(r => r.banco && r.banco.trim())?.banco || '';

      const buildDate = (monthOffset) => {
        if (!baseDay) return today;
        const monthIndex = 2 + monthOffset; // 2 = marzo (0-based)
        const d = new Date(Date.UTC(baseYear, monthIndex, baseDay));
        return d.toISOString().slice(0, 10);
      };

      return prev.map((r, idx) => ({
        ...r,
        monto: montoCuotaBase,
        fecha_emision: buildDate(idx),
        banco: firstBanco || r.banco || '',
      }));
    });
  };

  const handleReset = () => {
    setRows((prev) => prev.map((r) => ({ ...r, numero_serie: '', banco: '', fecha_emision: today, monto: montoCuotaBase, notas: '' })));
    setErrors({});
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!validate()) return;
    onSave(rows.map((r) => ({
      numero_cuota: r.numero_cuota,
      numero_serie: r.numero_serie.trim(),
      banco: r.banco.trim(),
      fecha_emision: r.fecha_emision,
      monto: Number(r.monto),
      notas: r.notas?.trim() || ''
    })));
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <Card className="w-full max-w-5xl max-h-[90vh] overflow-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">🧾 Cheques por Cuota</h2>
            <button onClick={onClose} className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">✕</button>
          </div>
          <p className="text-xs text-gray-600 dark:text-gray-400 mt-2">
            Definiste {cantidadCuotas} cuotas. Completa los datos de cada cheque.
            Usa “Autocompletar” para rellenar automáticamente el monto de cada cheque con el monto por cuota total
            (sumando todos los estudiantes y aplicando descuentos) y las fechas de emisión mensuales desde marzo según el día de vencimiento definido.
          </p>
        </CardHeader>
        <CardContent>
          <div className="flex gap-2 mb-3">
            <Button variant="outline" onClick={handleAutoFill}>↻ Autocompletar</Button>
            <Button variant="outline" onClick={handleReset}>🧹 Reset</Button>
          </div>
          <form onSubmit={handleSubmit}>
            <div className="overflow-auto border rounded">
              <table className="min-w-full text-sm">
                <thead className="bg-gray-100 dark:bg-gray-800">
                  <tr>
                    <th className="px-3 py-2 text-left">Cuota</th>
                    <th className="px-3 py-2 text-left">N° Serie</th>
                    <th className="px-3 py-2 text-left">Banco</th>
                    <th className="px-3 py-2 text-left">Fecha Emisión</th>
                    <th className="px-3 py-2 text-left">Monto (CLP)</th>
                    <th className="px-3 py-2 text-left">Notas</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((r, idx) => (
                    <tr key={idx} className="border-t">
                      <td className="px-3 py-2 w-16">{r.numero_cuota}</td>
                      <td className="px-3 py-2 min-w-[160px]">
                        <input
                          type="text"
                          value={r.numero_serie}
                          onChange={(e) => setField(idx, 'numero_serie', e.target.value)}
                          className={`w-full px-2 py-1 border rounded ${errors[`${idx}.numero_serie`] ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'} dark:bg-gray-800 dark:text-white`}
                          placeholder="Ej: 123456789"
                        />
                        {errors[`${idx}.numero_serie`] && <div className="text-red-500 text-xs">{errors[`${idx}.numero_serie`]}</div>}
                      </td>
                      <td className="px-3 py-2 min-w-[160px]">
                        <select
                          value={r.banco}
                          onChange={(e) => setField(idx, 'banco', e.target.value)}
                          className={`w-full px-2 py-1 border rounded ${errors[`${idx}.banco`] ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'} dark:bg-gray-800 dark:text-white`}
                        >
                          <option value="">Seleccione</option>
                          <option value="Banco de Chile">Banco de Chile</option>
                          <option value="Banco Estado">Banco Estado</option>
                          <option value="BancoEstado">BancoEstado</option>
                          <option value="Santander">Santander</option>
                          <option value="BCI">BCI</option>
                          <option value="Scotiabank">Scotiabank</option>
                          <option value="Itaú">Itaú</option>
                          <option value="Security">Security</option>
                          <option value="Falabella">Falabella</option>
                          <option value="Ripley">Ripley</option>
                          <option value="Consorcio">Consorcio</option>
                          <option value="BICE">BICE</option>
                          <option value="Otro">Otro</option>
                        </select>
                        {errors[`${idx}.banco`] && <div className="text-red-500 text-xs">{errors[`${idx}.banco`]}</div>}
                      </td>
                      <td className="px-3 py-2 w-44">
                        <input
                          type="date"
                          value={r.fecha_emision}
                          onChange={(e) => setField(idx, 'fecha_emision', e.target.value)}
                          className={`w-full px-2 py-1 border rounded ${errors[`${idx}.fecha_emision`] ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'} dark:bg-gray-800 dark:text-white`}
                        />
                        {errors[`${idx}.fecha_emision`] && <div className="text-red-500 text-xs">{errors[`${idx}.fecha_emision`]}</div>}
                      </td>
                      <td className="px-3 py-2 w-40">
                        <input
                          type="number"
                          min="1"
                          step="1"
                          value={r.monto}
                          onChange={(e) => setField(idx, 'monto', Number(e.target.value))}
                          className={`w-full px-2 py-1 border rounded ${errors[`${idx}.monto`] ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'} dark:bg-gray-800 dark:text-white`}
                        />
                        {errors[`${idx}.monto`] && <div className="text-red-500 text-xs">{errors[`${idx}.monto`]}</div>}
                      </td>
                      <td className="px-3 py-2">
                        <input
                          type="text"
                          value={r.notas}
                          onChange={(e) => setField(idx, 'notas', e.target.value)}
                          className="w-full px-2 py-1 border rounded border-gray-300 dark:border-gray-600 dark:bg-gray-800 dark:text-white"
                          placeholder="Opcional"
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="flex gap-3 pt-4">
              <Button type="button" variant="outline" onClick={onClose} className="flex-1">Cancelar</Button>
              <Button type="submit" className="flex-1">Guardar Cheques</Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

export default ChequesDataModal;
