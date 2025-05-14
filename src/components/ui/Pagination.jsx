import React from 'react';
import { Button } from './Button';

export function Pagination({ 
  currentPage,
  totalPages,
  onPageChange,
  totalRecords,
  pageSize,
  onPageSizeChange
}) {
  const pageSizeOptions = [10, 25, 50, 100];

  const handlePageSizeChange = (e) => {
    const newSize = parseInt(e.target.value);
    onPageSizeChange(newSize);
    // Reset to first page when changing page size
    onPageChange(1);
  };

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between gap-4 mt-4 px-4">
      <div className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300">
        <span>Mostrar</span>
        <select
          value={pageSize}
          onChange={handlePageSizeChange}
          className="px-2 py-1 rounded border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover"
        >
          {pageSizeOptions.map(size => (
            <option key={size} value={size}>{size}</option>
          ))}
        </select>
        <span>registros por página</span>
        <span className="mx-4">|</span>
        <span>Total: {totalRecords} registros</span>
      </div>

      <div className="flex items-center gap-2">
        <Button
          variant="secondary"
          onClick={() => onPageChange(1)}
          disabled={currentPage === 1}
        >
          Primera
        </Button>
        <Button
          variant="secondary"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage === 1}
        >
          Anterior
        </Button>
        
        <span className="px-4 py-2 text-sm text-gray-700 dark:text-gray-300">
          Página {currentPage} de {totalPages}
        </span>
        
        <Button
          variant="secondary"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage === totalPages}
        >
          Siguiente
        </Button>
        <Button
          variant="secondary"
          onClick={() => onPageChange(totalPages)}
          disabled={currentPage === totalPages}
        >
          Última
        </Button>
      </div>
    </div>
  );
}