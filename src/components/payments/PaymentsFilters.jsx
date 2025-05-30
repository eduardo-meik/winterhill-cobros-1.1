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
  { value: 'TARJETA', label: 'Tarjeta de Crédito/Débito' },
  { value: 'CHEQUE', label: 'Cheque' },
  { value: 'DESCUENTO PLANILLA', label: 'Descuento de Planilla' },
  { value: 'OTRO', label: 'Otro' },
];

export function PaymentsFilters({
  filters,
  onFiltersChange,
  onClearFilters,
  filterOptions = { cursos: [], years: [], cuotas: [] }
}) {
  const handleFilterChange = (filterName, value) => {
    // For date changes, ensure endDate is not before startDate
    if (filterName === 'startDate' && value && filters.endDate && new Date(value) > new Date(filters.endDate)) {
      onFiltersChange(prev => ({ ...prev, startDate: value, endDate: value }));
    } else if (filterName === 'endDate' && value && filters.startDate && new Date(value) < new Date(filters.startDate)) {
      onFiltersChange(prev => ({ ...prev, startDate: value, endDate: value }));
    } else {
      onFiltersChange(prev => ({ ...prev, [filterName]: value }));
    }
  };

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4 p-4 border-b border-gray-200 dark:border-gray-700"> {/* Adjusted xl:grid-cols-6 */}
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
        {/* Use dynamic years from data if available */}
        {filterOptions.years.length > 0 ? 
          filterOptions.years.map(year => (
            <option key={year} value={year}>{year}</option>
          ))
          :
          years.map(year => (
            <option key={year} value={year}>{year}</option>
          ))
        }
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

      {/* Curso Filter */}
      <select
        value={filters.curso}
        onChange={(e) => handleFilterChange('curso', e.target.value)}
        className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      >
        <option value="all">Todos los Cursos</option>
        {filterOptions.cursos.map(curso => (
          <option key={curso} value={curso}>{curso}</option>
        ))}
      </select>

      {/* Cuota Filter - NEW */}
      <select
        value={filters.cuota}
        onChange={(e) => handleFilterChange('cuota', e.target.value)}
        className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      >
        <option value="all">Todas las Cuotas</option>
        {filterOptions.cuotas.map(cuota => (
          <option key={cuota} value={cuota}>Cuota {cuota}</option>
        ))}
      </select>

      {/* Start Date Filter - NEW */}
      <div>
        <label htmlFor="startDate" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Fecha Inicial</label>
        <input
          type="date"
          id="startDate"
          value={filters.startDate || ''}
          onChange={(e) => handleFilterChange('startDate', e.target.value)}
          className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
        />
      </div>

      {/* End Date Filter - NEW */}
      <div>
        <label htmlFor="endDate" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Fecha Final</label>
        <input
          type="date"
          id="endDate"
          value={filters.endDate || ''}
          onChange={(e) => handleFilterChange('endDate', e.target.value)}
          min={filters.startDate || ''}
          className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
          disabled={!filters.startDate} // Optionally disable if start date is not set
        />
      </div>
      
      {/* Search Input */}
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