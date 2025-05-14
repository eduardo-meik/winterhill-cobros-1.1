import React, { useState, useCallback } from 'react';
import { format } from 'date-fns';
import debounce from 'lodash.debounce';
import { Combobox } from '@headlessui/react';
import { Card } from '../ui/Card';

export function ReportFilters({ 
  filters, 
  onFiltersChange, 
  guardians = [], 
  courses = [], 
  onApplyFilters,
  onResetFilters,
  loading = false 
}) {
  const [localFilters, setLocalFilters] = useState(filters);
  
  const debouncedFiltersChange = useCallback(
    debounce((newFilters) => {
      onFiltersChange(newFilters);
    }, 300),
    []
  );

  const handleFilterChange = (key, value) => {
    const newFilters = { ...localFilters, [key]: value };
    setLocalFilters(newFilters);
    debouncedFiltersChange(newFilters);
  };

  return (
    <Card className="mb-6">
      <div className="p-4 space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Status Filter */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Estado
            </label>
            <select
              value={localFilters.status}
              onChange={(e) => handleFilterChange('status', e.target.value)}
              className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
            >
              <option value="all">Todos</option>
              <option value="active">Activos</option>
              <option value="inactive">Inactivos</option>
            </select>
          </div>

          {/* Guardian Selector */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Apoderados
            </label>
            <Combobox
              value={localFilters.guardians}
              onChange={(value) => handleFilterChange('guardians', value)}
              multiple
            >
              <div className="relative">
                <Combobox.Input
                  className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  placeholder="Seleccionar apoderados..."
                  displayValue={(selected) =>
                    selected.map(id => 
                      guardians.find(g => g.id === id)?.name
                    ).join(', ')
                  }
                />
                <Combobox.Options className="absolute z-10 w-full mt-1 bg-white dark:bg-dark-card rounded-md shadow-lg max-h-60 overflow-auto">
                  {guardians.map((guardian) => (
                    <Combobox.Option
                      key={guardian.id}
                      value={guardian.id}
                      className={({ active }) =>
                        `${active ? 'bg-primary text-white' : 'text-gray-900 dark:text-white'}
                        cursor-pointer select-none relative py-2 pl-10 pr-4`
                      }
                    >
                      {guardian.name}
                    </Combobox.Option>
                  ))}
                </Combobox.Options>
              </div>
            </Combobox>
          </div>

          {/* Course Selector */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Cursos
            </label>
            <Combobox
              value={localFilters.courses}
              onChange={(value) => handleFilterChange('courses', value)}
              multiple
            >
              <div className="relative">
                <Combobox.Input
                  className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  placeholder="Seleccionar cursos..."
                  displayValue={(selected) =>
                    selected.map(id => 
                      courses.find(c => c.id === id)?.nom_curso
                    ).join(', ')
                  }
                />
                <Combobox.Options className="absolute z-10 w-full mt-1 bg-white dark:bg-dark-card rounded-md shadow-lg max-h-60 overflow-auto">
                  {courses.map((course) => (
                    <Combobox.Option
                      key={course.id}
                      value={course.id}
                      className={({ active }) =>
                        `${active ? 'bg-primary text-white' : 'text-gray-900 dark:text-white'}
                        cursor-pointer select-none relative py-2 pl-10 pr-4`
                      }
                    >
                      {course.nom_curso}
                    </Combobox.Option>
                  ))}
                </Combobox.Options>
              </div>
            </Combobox>
          </div>

          {/* Date Range */}
          <div className="space-y-2">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Fecha Inicio
              </label>
              <input
                type="date"
                value={localFilters.startDate}
                onChange={(e) => handleFilterChange('startDate', e.target.value)}
                className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Fecha Fin
              </label>
              <input
                type="date"
                value={localFilters.endDate}
                min={localFilters.startDate}
                onChange={(e) => handleFilterChange('endDate', e.target.value)}
                className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
              />
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex justify-end gap-3 pt-4">
          <button
            type="button"
            onClick={onResetFilters}
            disabled={loading}
            className="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-lg transition-colors"
          >
            Limpiar Filtros
          </button>
          <button
            type="button"
            onClick={() => onApplyFilters(localFilters)}
            disabled={loading}
            className="px-4 py-2 text-sm font-medium text-white bg-primary hover:bg-primary-light rounded-lg transition-colors disabled:opacity-50"
          >
            {loading ? 'Aplicando...' : 'Aplicar Filtros'}
          </button>
        </div>
      </div>
    </Card>
  );
}