import React, { useState } from 'react';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';

export function ChequeDataModal({ isOpen, onClose, onSave, initialData = null }) {
  const [chequeData, setChequeData] = useState({
    numero_serie: initialData?.numero_serie || '',
    banco: initialData?.banco || '',
    fecha_emision: initialData?.fecha_emision || '',
    monto: initialData?.monto || '',
    notas: initialData?.notas || ''
  });

  const [errors, setErrors] = useState({});

  const handleChange = (field, value) => {
    setChequeData(prev => ({ ...prev, [field]: value }));
    // Clear error when user types
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  const validate = () => {
    const newErrors = {};

    if (!chequeData.numero_serie.trim()) {
      newErrors.numero_serie = 'Número de serie es requerido';
    }

    if (!chequeData.banco.trim()) {
      newErrors.banco = 'Banco es requerido';
    }

    if (!chequeData.fecha_emision) {
      newErrors.fecha_emision = 'Fecha de emisión es requerida';
    }

    if (!chequeData.monto || Number(chequeData.monto) <= 0) {
      newErrors.monto = 'Monto debe ser mayor a 0';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (validate()) {
      onSave({
        ...chequeData,
        monto: Number(chequeData.monto)
      });
      onClose();
    }
  };

  const handleCancel = () => {
    setChequeData({
      numero_serie: '',
      banco: '',
      fecha_emision: '',
      monto: '',
      notas: ''
    });
    setErrors({});
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <Card className="w-full max-w-lg max-h-[90vh] overflow-auto">
        <CardHeader>
          <div className="flex items-center justify-between">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
              📝 Datos del Cheque
            </h2>
            <button
              onClick={handleCancel}
              aria-label="Cerrar"
              className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            >
              ✕
            </button>
          </div>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Número de Serie */}
            <div>
              <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">
                Número de Serie *
              </label>
              <input
                type="text"
                value={chequeData.numero_serie}
                onChange={(e) => handleChange('numero_serie', e.target.value)}
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent ${
                  errors.numero_serie ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                } dark:bg-gray-800 dark:text-white`}
                placeholder="Ej: 123456789"
              />
              {errors.numero_serie && (
                <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.numero_serie}</p>
              )}
            </div>

            {/* Banco */}
            <div>
              <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">
                Banco *
              </label>
              <select
                value={chequeData.banco}
                onChange={(e) => handleChange('banco', e.target.value)}
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent ${
                  errors.banco ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                } dark:bg-gray-800 dark:text-white`}
              >
                <option value="">Seleccione un banco</option>
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
              {errors.banco && (
                <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.banco}</p>
              )}
            </div>

            {/* Fecha de Emisión */}
            <div>
              <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">
                Fecha de Emisión *
              </label>
              <input
                type="date"
                value={chequeData.fecha_emision}
                onChange={(e) => handleChange('fecha_emision', e.target.value)}
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent ${
                  errors.fecha_emision ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                } dark:bg-gray-800 dark:text-white`}
              />
              {errors.fecha_emision && (
                <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.fecha_emision}</p>
              )}
            </div>

            {/* Monto */}
            <div>
              <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">
                Monto (CLP) *
              </label>
              <input
                type="number"
                value={chequeData.monto}
                onChange={(e) => handleChange('monto', e.target.value)}
                className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent ${
                  errors.monto ? 'border-red-500' : 'border-gray-300 dark:border-gray-600'
                } dark:bg-gray-800 dark:text-white`}
                placeholder="Ej: 500000"
                min="1"
                step="1"
              />
              {errors.monto && (
                <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.monto}</p>
              )}
            </div>

            {/* Notas (Opcional) */}
            <div>
              <label className="block text-sm font-medium mb-1 text-gray-700 dark:text-gray-300">
                Notas (Opcional)
              </label>
              <textarea
                value={chequeData.notas}
                onChange={(e) => handleChange('notas', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent dark:bg-gray-800 dark:text-white"
                rows="3"
                placeholder="Información adicional sobre el cheque..."
              />
            </div>

            {/* Buttons */}
            <div className="flex gap-3 pt-4 border-t">
              <Button
                type="button"
                variant="outline"
                onClick={handleCancel}
                className="flex-1"
              >
                Cancelar
              </Button>
              <Button
                type="submit"
                variant="default"
                className="flex-1"
              >
                Guardar Cheque
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

export default ChequeDataModal;
