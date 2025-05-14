import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { GuardiansTable } from './GuardiansTable';
import { SearchBar } from './SearchBar';
import { GuardianDetailsModal } from './GuardianDetailsModal';
import { GuardianFormModal } from './GuardianFormModal';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';
import { usePagination } from '../../hooks/usePagination';
import { Pagination } from '../ui/Pagination';

export function GuardiansPage() {
  const [guardians, setGuardians] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedGuardian, setSelectedGuardian] = useState(null);
  const [isFormModalOpen, setIsFormModalOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [relationshipType, setRelationshipType] = useState('all');

  useEffect(() => {
    fetchGuardians();
  }, []);

  useEffect(() => {
    const normalizeText = (text = '') => text
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "");

    const filterGuardians = () => {
      setIsSearching(true);
      const searchNormalized = normalizeText(searchTerm);

      const results = guardians.filter(guardian => {
        if (relationshipType !== 'all' && guardian.relationship_type !== relationshipType) return false;
        if (!searchTerm) return true;

        const fullName = `${guardian.first_name || ''} ${guardian.last_name || ''}`;
        const normalizedName = normalizeText(fullName);
        const normalizedRut = normalizeText(guardian.rut || '');

        return normalizedName.includes(searchNormalized) ||
               normalizedRut.includes(searchNormalized);
      });

      setSearchResults(results);
      setIsSearching(false);
    };

    const debounceTimer = setTimeout(filterGuardians, 300);
    return () => clearTimeout(debounceTimer);

  }, [searchTerm, relationshipType, guardians]);

  const fetchGuardians = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('guardians')
        .select('*')
        .order('last_name', { ascending: true });

      if (error) throw error;

      const fetchedGuardians = data || [];
      setGuardians(fetchedGuardians);
      setSearchResults(fetchedGuardians);
    } catch (error) {
      toast.error('Error al cargar los apoderados');
      console.error('Error:', error);
      setGuardians([]);
      setSearchResults([]);
    } finally {
      setLoading(false);
    }
  };

  const {
    currentPage,
    pageSize,
    setPageSize,
    totalPages,
    paginatedItems,
    handlePageChange
  } = usePagination(searchResults);

  const handleCloseDetails = () => {
    setSelectedGuardian(null);
  };

  const handleCloseAddGuardian = () => {
    setIsFormModalOpen(false);
  };

  const handleAddGuardianSuccess = () => {
    setIsFormModalOpen(false);
    fetchGuardians();
    toast.success('Apoderado agregado exitosamente');
  };

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        <div className="flex flex-wrap items-center justify-between gap-4 p-4">
          <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Apoderados</h1>
          <Button 
            onClick={() => setIsFormModalOpen(true)}
            className="flex items-center gap-2"
            aria-label="Agregar nuevo apoderado"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Agregar Apoderado
          </Button>
        </div>

        <div className="p-4">
          <Card>
            <CardHeader>
              <div className="flex flex-wrap items-center gap-4">
                <SearchBar
                  value={searchTerm}
                  onChange={setSearchTerm}
                  isSearching={isSearching}
                  placeholder="Buscar por nombre o RUT del apoderado..."
                  aria-label="Buscar apoderados"
                />
                <select
                  value={relationshipType}
                  onChange={(e) => setRelationshipType(e.target.value)}
                  className="px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                  aria-label="Filtrar por tipo de relación"
                >
                  <option value="all">Todos los Tipos</option>
                  <option value="Padre">Padre</option>
                  <option value="Madre">Madre</option>
                  <option value="Tutor">Tutor</option>
                </select>
              </div>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
                </div>
              ) : !loading && searchResults.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 text-gray-500 dark:text-gray-400">
                  <p>No se encontraron apoderados que coincidan con los filtros.</p>
                  {(searchTerm || relationshipType !== 'all') && (
                    <button
                      onClick={() => {
                        setSearchTerm('');
                        setRelationshipType('all');
                      }}
                      className="mt-2 text-primary hover:text-primary-light"
                    >
                      Limpiar filtros
                    </button>
                  )}
                </div>
              ) : (
                <>
                  <GuardiansTable
                    guardians={paginatedItems}
                    onViewDetails={setSelectedGuardian}
                  />
                  <Pagination
                    currentPage={currentPage}
                    totalPages={totalPages}
                    onPageChange={handlePageChange}
                    totalRecords={searchResults.length}
                    pageSize={pageSize}
                    onPageSizeChange={setPageSize}
                  />
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>

      {selectedGuardian && (
        <GuardianDetailsModal
          guardian={selectedGuardian}
          onClose={() => setSelectedGuardian(null)}
          onSuccess={fetchGuardians}
        />
      )}

      {isFormModalOpen && (
        <GuardianFormModal
          isOpen={isFormModalOpen}
          onClose={handleCloseAddGuardian}
          onSuccess={handleAddGuardianSuccess}
        />
      )}

    </main>
  );
}