import React, { useRef } from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { TabsContainer, TabButton } from "../ui/Tabs";
import { GuardianReportTable } from "./tables/GuardianReportTable";
import { StudentReportTable } from "./tables/StudentReportTable";
import { ReportFilters } from './ReportFilters';
import { PaymentsOverview } from './graphs/PaymentsOverview';
import { PaymentStatusChart } from './graphs/PaymentStatusChart';
import { PaymentMethodsChart } from './graphs/PaymentMethodsChart';
import { PaymentsTable } from './tables/PaymentsTable';
import { useReportData } from '../../hooks/reporting/useReportData';
import { useReportExport } from '../../hooks/reporting/useReportExport';
import { ActiveFiltersBar } from '../ui/ActiveFiltersBar';
import { useAcademicYear } from '../../contexts/AcademicYearContext';

export function ReportingPage() {
  // Refs for charts to capture for PDF export
  const paymentsOverviewRef = useRef(null);
  const paymentStatusRef = useRef(null);
  const paymentMethodsRef = useRef(null);

  const {
    filters, setFilters, loading, data, filteredData,
    guardians, courses, students, guardianDebtMap,
    activeTab, setActiveTab,
    getFilteredData, handleApplyFilters, handleResetFilters,
  } = useReportData();

  const {
    exporting, handleExport,
    handleExportLibroMatricula, handleExportFicon, handleExportCheques,
  } = useReportExport({
    data, filters, guardians, courses, getFilteredData,
    chartRefs: {
      paymentsOverview: paymentsOverviewRef,
      paymentStatus: paymentStatusRef,
      paymentMethods: paymentMethodsRef,
    },
  });

  const { academicYear } = useAcademicYear();
  const noStudentData = filters.students.length > 0 && data.length === 0;

  const statusLabels = { paid: 'Pagado', pending: 'Pendiente', overdue: 'Vencido' };
  const monthNames = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
  const activeBarFilters = [
    filters.status !== 'all' && { key: 'status', label: 'Estado', value: statusLabels[filters.status] || filters.status, onRemove: () => setFilters(f => ({ ...f, status: 'all' })) },
    filters.month !== 'all' && { key: 'month', label: 'Mes', value: monthNames[parseInt(filters.month) - 1], onRemove: () => setFilters(f => ({ ...f, month: 'all' })) },
    filters.guardians.length > 0 && { key: 'guardians', label: 'Apoderados', value: `${filters.guardians.length}`, onRemove: () => setFilters(f => ({ ...f, guardians: [] })) },
    filters.courses.length > 0 && { key: 'courses', label: 'Cursos', value: `${filters.courses.length}`, onRemove: () => setFilters(f => ({ ...f, courses: [] })) },
    filters.students.length > 0 && { key: 'students', label: 'Estudiantes', value: `${filters.students.length}`, onRemove: () => setFilters(f => ({ ...f, students: [] })) },
  ].filter(Boolean);

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        <div className="flex flex-wrap items-center justify-between gap-4 p-4">
          <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Reportes</h1>
          <div className="flex items-center gap-2 flex-wrap justify-end">
            <Button
              onClick={() => handleExport('pdf')}
              disabled={exporting || data.length === 0 || loading}
              variant="secondary"
              className="flex items-center gap-2"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 256 256">
                <path d="M224,48H32A16,16,0,0,0,16,64V192a16,16,0,0,0,16,16H224a16,16,0,0,0,16-16V64A16,16,0,0,0,224,48ZM32,64H224V96H32Zm0,128V112H224v80Z"/>
              </svg>
              {exporting ? 'Generando...' : 'Exportar PDF'}
            </Button>
            <Button
              variant="secondary"
              onClick={() => handleExport('excel')}
              disabled={exporting || data.length === 0 || loading}
            >
              Exportar Excel
            </Button>
          </div>
        </div>

        <div className="px-4 pb-4">
          <ReportFilters
            filters={filters}
            onFiltersChange={setFilters}
            guardians={guardians}
            courses={courses}
            students={students}
            onApplyFilters={handleApplyFilters}
            onResetFilters={handleResetFilters}
            loading={loading}
          />
        </div>

        <div className="px-4">
          <ActiveFiltersBar
            yearLabel={filters.year !== 'all' ? filters.year : String(academicYear)}
            filters={activeBarFilters}
            onClearAll={() => handleResetFilters()}
            className="rounded-lg mb-3"
          />
          <TabsContainer>
            <TabButton
              isActive={activeTab === 'payments'}
              onClick={() => setActiveTab('payments')}
            >
              Aranceles 
              {filteredData.length !== data.length && (
                <span className="ml-2 text-xs bg-indigo-100 dark:bg-indigo-900/30 text-indigo-800 dark:text-indigo-300 py-0.5 px-1.5 rounded-full">
                  {filteredData.length}
                </span>
              )}
            </TabButton>
            <TabButton
              isActive={activeTab === 'matricula'}
              onClick={() => setActiveTab('matricula')}
            >
              Matrícula
            </TabButton>
            <TabButton
              isActive={activeTab === 'students'}
              onClick={() => setActiveTab('students')}
            >
              Estudiantes
            </TabButton>
            <TabButton
              isActive={activeTab === 'guardians'}
              onClick={() => setActiveTab('guardians')}
            >
              Apoderados
            </TabButton>
          </TabsContainer>
        </div>

        {activeTab === 'payments' && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 p-4">
            {/* Revenue Overview */}
            <Card className="lg:col-span-2">
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Resumen de Pagos</h2>
              </CardHeader>
              <CardContent>
                {noStudentData ? (
                  <div className="py-6 text-center">
                    <p className="text-gray-500 dark:text-gray-400">
                      No se encontraron datos para el estudiante seleccionado.
                    </p>
                  </div>
                ) : (
                  <PaymentsOverview 
                    ref={paymentsOverviewRef} 
                    data={filteredData}
                    loading={loading} 
                  />
                )}
              </CardContent>
            </Card>

            {/* Payment Status Distribution */}
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Estado de Pagos</h2>
              </CardHeader>
              <CardContent>
                {noStudentData ? (
                  <div className="py-6 text-center">
                    <p className="text-gray-500 dark:text-gray-400">
                      No se encontraron datos para el estudiante seleccionado.
                    </p>
                  </div>
                ) : (
                  <PaymentStatusChart 
                    ref={paymentStatusRef} 
                    data={filteredData}
                    loading={loading} 
                  />
                )}
              </CardContent>
            </Card>

            {/* Payment Methods Distribution */}
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Métodos de Pago</h2>
              </CardHeader>
              <CardContent>
                {noStudentData ? (
                  <div className="py-6 text-center">
                    <p className="text-gray-500 dark:text-gray-400">
                      No se encontraron datos para el estudiante seleccionado.
                    </p>
                  </div>
                ) : (
                  <PaymentMethodsChart 
                    ref={paymentMethodsRef} 
                    data={filteredData} 
                    loading={loading} 
                  />
                )}
              </CardContent>
            </Card>

            {/* Payments Table */}
            <Card className="lg:col-span-2">
              <CardHeader className="flex flex-wrap justify-between items-center">
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Detalle de Pagos</h2>
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  {filteredData.length} {filteredData.length === 1 ? 'registro' : 'registros'} encontrados
                </div>
              </CardHeader>
              <CardContent>
                {noStudentData ? (
                  <div className="py-6 text-center">
                    <p className="text-gray-500 dark:text-gray-400">
                      No se encontraron aranceles para el estudiante seleccionado.
                    </p>
                    <p className="text-sm text-gray-400 dark:text-gray-500 mt-2">
                      Prueba seleccionando otro estudiante o elimina los filtros.
                    </p>
                  </div>
                ) : (
                  <PaymentsTable 
                    data={filteredData} 
                    loading={loading}
                    filteredCount={filteredData.length}
                    totalCount={data.length}
                    isFiltered={filteredData.length !== data.length}
                  />
                )}
              </CardContent>
            </Card>
          </div>
        )}

        {activeTab === 'matricula' && (
          <div className="p-4">
            <Card>
              <CardHeader className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Reportes de Matrícula</h2>
                  <p className="text-sm text-gray-500 dark:text-gray-400">Agrupados y filtrados a matrículas finalizadas/estudiantes matriculados.</p>
                </div>
                <span className="text-xs text-gray-500 dark:text-gray-400">Incluye folio de matrícula y pagaré cuando aplica.</span>
              </CardHeader>
              <CardContent>
                <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                  <div className="p-4 border border-gray-200 dark:border-gray-800 rounded-lg bg-white dark:bg-gray-900 shadow-sm flex flex-col h-full">
                    <div className="text-sm font-semibold text-gray-900 dark:text-white">Libro de Matrícula</div>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Excel académico con folio de matrícula y datos de curso.</p>
                    <Button
                      variant="secondary"
                      className="mt-auto w-full"
                      onClick={handleExportLibroMatricula}
                      disabled={exporting || loading}
                    >
                      Exportar
                    </Button>
                  </div>
                  <div className="p-4 border border-gray-200 dark:border-gray-800 rounded-lg bg-white dark:bg-gray-900 shadow-sm flex flex-col h-full">
                    <div className="text-sm font-semibold text-gray-900 dark:text-white">FICON</div>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Excel financiero (medios de pago, arancel, matrícula, folio).</p>
                    <Button
                      variant="secondary"
                      className="mt-auto w-full"
                      onClick={handleExportFicon}
                      disabled={exporting || loading}
                    >
                      Exportar
                    </Button>
                  </div>
                  <div className="p-4 border border-gray-200 dark:border-gray-800 rounded-lg bg-white dark:bg-gray-900 shadow-sm flex flex-col h-full">
                    <div className="text-sm font-semibold text-gray-900 dark:text-white">Cheques</div>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">Cheques asociados a matrícula (folio matrícula y pagaré/documento).</p>
                    <Button
                      variant="secondary"
                      className="mt-auto w-full"
                      onClick={handleExportCheques}
                      disabled={exporting || loading}
                    >
                      Exportar
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {activeTab === 'students' && (
          <div className="p-4">
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Estudiantes</h2>
              </CardHeader>
              <CardContent>
                {noStudentData ? (
                  <div className="py-6 text-center">
                    <p className="text-gray-500 dark:text-gray-400">
                      No se encontraron aranceles para el estudiante seleccionado.
                    </p>
                    <p className="text-sm text-gray-400 dark:text-gray-500 mt-2">
                      El estudiante no tiene aranceles registrados o revisa los filtros aplicados.
                    </p>
                  </div>
                ) : (
                  <StudentReportTable 
                    data={
                      filters.students.length > 0
                        ? students
                            .filter(s => filters.students.includes(String(s.id)))
                            .map(student => {
                              const feeWithStudent = data.find(fee => 
                                fee.student && String(fee.student.id) === String(student.id)
                              );
                              return feeWithStudent?.student || student;
                            })
                      : Array.from(new Set(data.map(item => item.student?.id)))
                          .map(id => {
                            const item = data.find(i => i.student?.id === id);
                            return item?.student;
                          })
                          .filter(Boolean)
                    } 
                    loading={loading}
                    filteredByGuardians={filters.guardians.length > 0}
                    guardiansSelected={filters.guardians.length > 0 ? 
                      guardians.filter(g => filters.guardians.includes(g.id)).map(g => g.name).join(", ") : 
                      null
                    }
                  />
                )}
              </CardContent>
            </Card>
          </div>
        )}

        {activeTab === 'guardians' && (
          <div className="p-4">
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Apoderados</h2>
              </CardHeader>
              <CardContent>
                {noStudentData ? (
                  <div className="py-6 text-center">
                    <p className="text-gray-500 dark:text-gray-400">
                      No se encontraron aranceles para el estudiante seleccionado.
                    </p>
                    <p className="text-sm text-gray-400 dark:text-gray-500 mt-2">
                      El estudiante no tiene aranceles registrados o revisa los filtros aplicados.
                    </p>
                  </div>
                ) : (
                  <GuardianReportTable 
                    data={
                      filters.guardians.length > 0 
                        ? guardians.filter(g => filters.guardians.includes(g.id))
                        : guardians
                    } 
                    loading={loading} 
                    debtMap={guardianDebtMap}
                    filteredByStudents={filters.students.length > 0}
                    studentsSelected={filters.students.length > 0 ? 
                      students.filter(s => filters.students.includes(String(s.id))).map(s => s.name).join(", ") : 
                      null
                    }
                  />
                )}
              </CardContent>
            </Card>
          </div>
        )}
      </div>
    </main>
  );
}