import React from 'react';

export function TableContainer({ children, maxHeight = 'calc(100vh - 400px)' }) {
  return (
    <div className="relative overflow-x-auto" style={{ maxHeight }}>
      <table className="w-full min-w-[800px]">
        {children}
      </table>
    </div>
  );
}