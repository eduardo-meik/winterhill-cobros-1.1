import React from 'react';
import { Button } from '../ui/Button';

const currentYear = new Date().getFullYear();
const years = Array.from({ length: 10 }, (_, i) => (currentYear - 5 + i).toString()); // Last 5 years + next 4 years

const months = [
  { value: '1', label: 'Enero' }, { value: '2', label: 'Febrero' },
  { value: '3', label: 'Marzo' }, { value: '4', label: 'Abril' },
  { value: '5', label: 'Mayo' }, { value: '6', label: 'Junio' },
  { value: '7', label: 'Julio' }, { value: '8', label: 'Agosto' },
  { value: '9', label: 'Septiembre' }, { value: '10', label: 'Octubre' },
  { value: '11', label: 'Noviembre' }, { value: '12', label: 'Diciembre' },
];

const paymentMethods = [
  { value: 'EFECTIVO', label: 'Efectivo' },
  { value: 'TRANSFERENCIA', label: 'Transferencia' },
  { value: 'TARJETA_CREDITO', label: 'Tarjeta de Crédito' },
  { value: 'TARJETA_DEBITO', label: 'Tarjeta de Débito' },
  { value: 'CHEQUE', label: 'Cheque' },
  { value: 'OTRO', label: 'Otro' },
];

export function PaymentsFilters({
  filters,
  onFiltersChange,
  availableCursos, // --- Recibir cursos disponibles ---
  onClearFilters
}) {
  const handleFilterChange = (filterName, value) => {
    onFiltersChange(prev => ({ ...prev, [filterName]: value }));
  };

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4 p-4 border-b border-gray-200 dark:border-gray-700">
      {/* Status Filter */}
      <select
        value={filters.status}
        onChange={(e) => handleFilterChange('status', e.target.value)}
        className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      >
        <option value="all">Todos los Estados</option>
        <option value="paid">Pagado</option>
        <option value="pending">Pendiente</option>
        <option value="overdue">Vencido</option>
        <option value="cancelled">Anulado</option>
      </select>

      {/* Month Filter */}
      <select
        value={filters.month}
        onChange={(e) => handleFilterChange('month', e.target.value)}
        className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      >
        <option value="all">Todos los Meses</option>
        {months.map(month => (
          <option key={month.value} value={month.value}>{month.label}</option>
        ))}
      </select>

      {/* Year Filter */}
      <select
        value={filters.year}
        onChange={(e) => handleFilterChange('year', e.target.value)}
        className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      >
        <option value="all">Todos los Años</option>
        {years.map(year => (
          <option key={year} value={year}>{year}</option>
        ))}
      </select>

      {/* Payment Method Filter */}
      <select
        value={filters.paymentMethod}
        onChange={(e) => handleFilterChange('paymentMethod', e.target.value)}
        className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      >
        <option value="all">Todos los Métodos</option>
        {paymentMethods.map(method => (
          <option key={method.value} value={method.value}>{method.label}</option>
        ))}
      </select>

      {/* --- Curso Filter --- */}
      <select
        value={filters.curso}
        onChange={(e) => handleFilterChange('curso', e.target.value)}
        className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      >
        <option value="all">Todos los Cursos</option>
        {availableCursos.map(curso => (
          <option key={curso} value={curso}>{curso}</option>
        ))}
      </select>
      {/* --- Fin --- */}

      {/* Search Input - Nuevo Filtro */}
      <input
        type="text"
        value={filters.search}
        onChange={(e) => handleFilterChange('search', e.target.value)}
        placeholder="Buscar por nombre..."
        className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      />

      <Button
        onClick={onClearFilters}
        variant="outline"
        className="w-full sm:w-auto"
      >
        Limpiar Filtros
      </Button>
    </div>
  );
}