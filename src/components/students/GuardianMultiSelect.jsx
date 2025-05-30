import React, { useState, useEffect } from 'react';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';

export function GuardianMultiSelect({ selectedGuardiansInfo = [], onChange, error }) {
  const [allGuardians, setAllGuardians] = useState([]);
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
          relationship_type,
          tipo_apoderado 
        `)
        .order('last_name', { ascending: true });

      if (fetchError) throw fetchError;
      setAllGuardians(data || []);
    } catch (fetchError) {
      console.error('Error fetching guardians:', fetchError);
      toast.error('Error al cargar los apoderados');
    } finally {
      setLoading(false);
    }
  };

  const filteredGuardians = allGuardians.filter(guardian => {
    const searchLower = searchTerm.toLowerCase();
    const nameMatch = `${guardian.first_name} ${guardian.last_name}`.toLowerCase().includes(searchLower);
    const runMatch = guardian.run?.toLowerCase().includes(searchLower);
    return nameMatch || runMatch;
  });

  const handleCheckboxChange = (guardianId) => {
    const guardian = allGuardians.find(g => g.id === guardianId);
    if (!guardian) return;

    const isCurrentlySelected = selectedGuardiansInfo.some(sg => sg.guardian_id === guardianId);
    let newSelectedGuardiansInfo;

    if (isCurrentlySelected) {
      newSelectedGuardiansInfo = selectedGuardiansInfo.filter(sg => sg.guardian_id !== guardianId);
    } else {
      // Add new guardian with a default role. The student_id will be set in the parent form.
      newSelectedGuardiansInfo = [...selectedGuardiansInfo, { guardian_id: guardian.id, guardian_role: '' }];
    }
    onChange(newSelectedGuardiansInfo);
  };

  const handleRoleChange = (guardianId, newRole) => {
    const newSelectedGuardiansInfo = selectedGuardiansInfo.map(sg =>
      sg.guardian_id === guardianId ? { ...sg, guardian_role: newRole } : sg
    );
    onChange(newSelectedGuardiansInfo);
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
          filteredGuardians.map(guardian => {
            const currentSelection = selectedGuardiansInfo.find(sg => sg.guardian_id === guardian.id);
            const isChecked = !!currentSelection;

            return (
              <div key={guardian.id} className="p-3 border-b border-gray-200 dark:border-gray-700 last:border-b-0 hover:bg-gray-50 dark:hover:bg-dark-input rounded-md transition-colors duration-150 ease-in-out">
                <div className="flex items-start gap-3">
                  <input
                    type="checkbox"
                    checked={isChecked}
                    onChange={() => handleCheckboxChange(guardian.id)}
                    className="mt-1 h-4 w-4 text-primary focus:ring-primary border-gray-300 dark:border-gray-600 rounded"
                  />
                  <div className="flex-1">
                    <p className="text-sm font-medium text-gray-900 dark:text-white">
                      {guardian.first_name} {guardian.last_name}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">
                      RUT: {guardian.run}
                      {guardian.relationship_type ? ` • Relación: ${guardian.relationship_type}` : ''}
                      {guardian.tipo_apoderado ? ` • Tipo General: ${guardian.tipo_apoderado}` : ''}
                    </p>
                  </div>
                </div>
                {isChecked && (
                  <div className="mt-2 ml-7 pl-1"> {/* Indent role selector slightly */}
                    <label htmlFor={`role-${guardian.id}`} className="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-0.5">
                      Rol para este estudiante:
                    </label>
                    <select
                      id={`role-${guardian.id}`}
                      value={currentSelection.guardian_role || ''}
                      onChange={(e) => handleRoleChange(guardian.id, e.target.value)}
                      className="w-full sm:w-auto px-3 py-1.5 text-xs rounded-md border border-gray-300 dark:border-gray-600 bg-white dark:bg-dark-bg focus:ring-1 focus:ring-primary focus:border-primary shadow-sm"
                    >
                      <option value="">-- Seleccionar Rol --</option>
                      <option value="ECONOMICO">Económico</option>
                      <option value="PEDAGOGICO">Pedagógico</option>
                      <option value="AMBOS">Ambos (Económico y Pedagógico)</option>
                      <option value="OTRO">Otro</option>
                    </select>
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>
      {error && (
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
    </div>
  );
}