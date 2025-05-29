import React, { useState, useEffect } from 'react';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

export function GuardianMultiSelect({ selectedIds = [], onChange, error }) {
  const [guardians, setGuardians] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchGuardians();
  }, []);

  const fetchGuardians = async () => {
    try {
      setLoading(true);
      const { data, error: fetchError } = await supabase
        .from('guardians')
        .select(`
          id,
          first_name,
          last_name,
          run,
          relationship_type
        `)
        .order('last_name', { ascending: true });

      if (fetchError) throw fetchError;
      setGuardians(data || []);
    } catch (fetchError) {
      console.error('Error fetching guardians:', fetchError);
      toast.error('Error al cargar los apoderados');
    } finally {
      setLoading(false);
    }
  };

  const filteredGuardians = guardians.filter(guardian => {
    const searchLower = searchTerm.toLowerCase();
    const nameMatch = `${guardian.first_name} ${guardian.last_name}`.toLowerCase().includes(searchLower);
    const runMatch = guardian.run?.toLowerCase().includes(searchLower);
    return nameMatch || runMatch;
  });

  const handleCheckboxChange = (guardianId) => {
    const newSelectedIds = selectedIds.includes(guardianId)
      ? selectedIds.filter(id => id !== guardianId)
      : [...selectedIds, guardianId];
    onChange(newSelectedIds);
  };

  return (
    <div className="space-y-2">
      <input
        type="text"
        placeholder="Buscar apoderado por nombre o RUN..."
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
      />
      <div className="max-h-60 overflow-y-auto border border-gray-200 dark:border-gray-700 rounded-lg p-2 space-y-2">
        {loading ? (
          <p className="text-gray-500 dark:text-gray-400 text-center py-4">Cargando apoderados...</p>
        ) : filteredGuardians.length === 0 ? (
          <p className="text-gray-500 dark:text-gray-400 text-center py-4">No se encontraron apoderados.</p>
        ) : (
          filteredGuardians.map(guardian => (
            <label key={guardian.id} className="flex items-center gap-3 p-2 hover:bg-gray-50 dark:hover:bg-dark-hover rounded-md cursor-pointer">
              <input
                type="checkbox"
                checked={selectedIds.includes(guardian.id)}
                onChange={() => handleCheckboxChange(guardian.id)}
                className="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
              />
              <div>
                <p className="text-sm font-medium text-gray-900 dark:text-white">
                  {guardian.first_name} {guardian.last_name}
                </p>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {guardian.run} {guardian.relationship_type ? `(${guardian.relationship_type})` : ''}
                </p>
              </div>
            </label>
          ))
        )}
      </div>
      {error && (
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
    </div>
  );
}