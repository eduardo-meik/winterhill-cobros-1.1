import React, { useState } from 'react';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';
import { generateAndExportLibroMatricula } from '../../services/libroMatricula';
import toast from 'react-hot-toast';

export function LibroMatriculaReport() {
  const [loading, setLoading] = useState(false);
  const [year, setYear] = useState<number>(new Date().getFullYear());
  const [estado, setEstado] = useState<string>('PRE_MATRICULADO');

  const handleGenerateReport = async () => {
    try {
      setLoading(true);
      toast.loading('Generando reporte del Libro de Matrícula...', { id: 'libro-reporte' });
      
      const count = await generateAndExportLibroMatricula(year, estado || undefined);
      
      toast.success(`✅ Reporte generado exitosamente: ${count} estudiante${count !== 1 ? 's' : ''}`, { 
        id: 'libro-reporte',
        duration: 5000
      });
    } catch (error) {
      console.error('Error generando reporte:', error);
      const errorMessage = error instanceof Error ? error.message : 'Error al generar el reporte';
      toast.error(errorMessage, { id: 'libro-reporte' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card>
      <CardHeader>
        <h2 className="text-xl font-bold flex items-center gap-2">
          📊 Libro de Matrícula - Exportar a Excel
        </h2>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
          <p className="text-sm text-blue-800 dark:text-blue-200">
            <strong>ℹ️ Información:</strong> Este reporte genera un archivo Excel con todos los datos del Libro de Matrícula 
            según los filtros seleccionados. Incluye datos completos de estudiantes y apoderados (titular y suplente).
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-2 text-gray-700 dark:text-gray-300">
              Año Académico
            </label>
            <input
              type="number"
              className="w-full border border-gray-300 dark:border-gray-700 rounded-lg px-3 py-2 
                bg-white dark:bg-dark-card text-gray-900 dark:text-gray-100
                focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
              value={year}
              onChange={(e) => setYear(Number(e.target.value))}
              min={2020}
              max={2030}
            />
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Selecciona el año académico del reporte
            </p>
          </div>
          
          <div>
            <label className="block text-sm font-medium mb-2 text-gray-700 dark:text-gray-300">
              Estado del Estudiante
            </label>
            <select
              className="w-full border border-gray-300 dark:border-gray-700 rounded-lg px-3 py-2
                bg-white dark:bg-dark-card text-gray-900 dark:text-gray-100
                focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
              value={estado}
              onChange={(e) => setEstado(e.target.value)}
            >
              <option value="">Todos los estados</option>
              <option value="PRE_MATRICULADO">📋 Pre-Matriculado (Matrícula en proceso)</option>
              <option value="CONFIRMADO">✅ Confirmado (Pendiente de inicio)</option>
              <option value="CURSANDO">🎓 Cursando</option>
              <option value="RETIRADO">🚫 Retirado</option>
            </select>
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Filtrar por estado específico o todos
            </p>
          </div>
        </div>

        <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-3">
          <p className="text-xs text-amber-800 dark:text-amber-200">
            <strong>💡 Recomendación:</strong> Para generar el Libro de Matrícula oficial, selecciona el estado 
            <strong> "Pre-Matriculado"</strong> para incluir solo estudiantes en proceso de matrícula desde diciembre 8, 2025.
          </p>
        </div>
        
        <Button
          onClick={handleGenerateReport}
          disabled={loading}
          className="w-full"
          variant="primary"
        >
          {loading ? (
            <>
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Generando reporte...
            </>
          ) : (
            <>
              📥 Descargar Excel del Libro de Matrícula
            </>
          )}
        </Button>
        
        <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
          <p className="text-xs text-gray-600 dark:text-gray-400">
            El archivo Excel incluirá <strong>33 columnas</strong> con información completa:
          </p>
          <ul className="text-xs text-gray-600 dark:text-gray-400 mt-2 ml-4 space-y-1">
            <li>• Datos del estudiante (11 campos)</li>
            <li>• Historial académico (2 campos)</li>
            <li>• Apoderado titular (13 campos)</li>
            <li>• Apoderado secundario (5 campos)</li>
            <li>• Información de retiro (2 campos)</li>
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}
