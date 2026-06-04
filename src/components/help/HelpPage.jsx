import React, { useMemo, useState } from 'react';
import clsx from 'clsx';

const WIKI_SECTIONS = [
  {
    id: 'operacion-secretaria',
    title: 'Operacion de secretaria',
    summary: 'Vision general para ejecutar atencion, registro y cierre sin errores administrativos.',
    useCases: [
      'Atencion de familias nuevas o vigentes.',
      'Regularizacion de datos personales o financieros.',
      'Seguimiento de estados de matricula y cobranza.'
    ],
    workflow: [
      'Revisar tablero de inicio para priorizar pendientes.',
      'Validar ficha de estudiante y apoderado antes de modificar datos.',
      'Ejecutar modulo correspondiente (estudiantes, apoderados, matricula, aranceles).',
      'Confirmar en reportes que el cambio impacta correctamente.'
    ],
    checklist: [
      'RUN y RUT sin duplicados.',
      'Curso y ano academico correctos.',
      'Estados actualizados despues de cada gestion.'
    ],
    commonErrors: [
      'Actualizar datos en modulo incorrecto y no validar resultado en reportes.',
      'Cerrar atencion sin dejar trazabilidad de observaciones.'
    ]
  },
  {
    id: 'inicio-dashboard',
    title: 'Inicio (Dashboard)',
    summary: 'Centro de monitoreo para prioridades diarias de secretaria.',
    useCases: [
      'Inicio de jornada para revisar volumen de pendientes.',
      'Deteccion de casos con deuda o matricula incompleta.',
      'Control rapido de evolucion mensual.'
    ],
    workflow: [
      'Abrir Inicio y revisar indicadores principales.',
      'Identificar brechas o alertas que requieran accion inmediata.',
      'Derivar a modulo operativo (matricula, aranceles, estudiantes o apoderados).',
      'Volver a Inicio para verificar disminucion de pendientes.'
    ],
    checklist: [
      'Filtro de ano academico correcto.',
      'Indicadores coherentes con la realidad del dia.',
      'Casos criticos asignados para gestion inmediata.'
    ],
    commonErrors: [
      'Tomar decisiones con ano academico equivocado.',
      'No priorizar casos bloqueados por deuda o estado pendiente.'
    ]
  },
  {
    id: 'crear-apoderado',
    title: 'Apoderados',
    summary: 'Registro, actualizacion y control de responsables legales y financieros.',
    useCases: [
      'Apoderado nuevo en el colegio.',
      'Cambio de tutor legal o adicion de segundo apoderado.',
      'Correccion de contacto o relacion familiar.'
    ],
    workflow: [
      'Ir a Apoderados y seleccionar Agregar Apoderado.',
      'Completar RUT, nombre, telefono, correo y relacion.',
      'Validar que el RUT no exista para evitar duplicados.',
      'Guardar y confirmar que el registro aparece en la tabla.'
    ],
    checklist: [
      'RUT valido y sin duplicidad.',
      'Datos de contacto vigentes.',
      'Relacion coherente con antecedentes del estudiante.'
    ],
    commonErrors: [
      'Crear ficha duplicada en vez de actualizar una existente.',
      'Guardar sin telefono o correo util para notificaciones.'
    ]
  },
  {
    id: 'crear-estudiante',
    title: 'Estudiantes',
    summary: 'Alta y mantenimiento de estudiantes para procesos academicos y de cobro.',
    useCases: [
      'Ingreso de estudiante nuevo.',
      'Reingreso de alumno no activo.',
      'Correccion de curso, estado o datos personales.'
    ],
    workflow: [
      'Ir a Estudiantes y seleccionar Agregar Estudiante.',
      'Completar RUN, nombres, curso y datos requeridos.',
      'Asociar al menos un apoderado responsable.',
      'Verificar que el estado y curso queden correctos.'
    ],
    checklist: [
      'RUN sin duplicados.',
      'Curso correcto para evitar errores de arancel.',
      'Apoderado asociado antes de avanzar a matricula.'
    ],
    commonErrors: [
      'Asignar curso incorrecto en ano activo.',
      'Dejar alumno sin apoderado y bloquear procesos siguientes.'
    ]
  },
  {
    id: 'matricular',
    title: 'Matricula',
    summary: 'Asistente para confirmar inscripcion anual con validaciones academicas y financieras.',
    useCases: [
      'Renovacion anual de estudiante vigente.',
      'Matricula de alumno nuevo con ficha completa.',
      'Regularizacion de estado pendiente a confirmado.'
    ],
    workflow: [
      'Entrar a Matricula e iniciar asistente.',
      'Seleccionar estudiante y validar datos base.',
      'Completar informacion economica y forma de pago.',
      'Previsualizar documentos y finalizar matricula.'
    ],
    checklist: [
      'Sin bloqueos de deuda o condicion administrativa.',
      'Plan de pago coherente con arancel anual.',
      'Estado final actualizado al cerrar el flujo.'
    ],
    commonErrors: [
      'Intentar finalizar con deuda pendiente.',
      'Inconsistencia entre forma de pago y arancel definido.'
    ]
  },
  {
    id: 'aranceles',
    title: 'Aranceles',
    summary: 'Gestion de cuotas, pagos y seguimiento financiero por estudiante.',
    useCases: [
      'Registrar pagos recibidos.',
      'Revisar saldo pendiente por alumno o familia.',
      'Corregir detalle de cuota o medio de pago.'
    ],
    workflow: [
      'Ir a Aranceles y filtrar por estudiante, estado o fechas.',
      'Abrir detalle para validar plan de cuotas y pagos aplicados.',
      'Registrar pago o ajuste segun comprobante.',
      'Confirmar que el saldo y estado reflejen el movimiento.'
    ],
    checklist: [
      'Monto y fecha del pago correctos.',
      'Cuota afectada coincide con respaldo.',
      'Saldo final actualizado despues de guardar.'
    ],
    commonErrors: [
      'Registrar pago en estudiante equivocado por homonimia.',
      'Aplicar monto parcial sin observacion explicativa.'
    ]
  },
  {
    id: 'reportes',
    title: 'Reportes',
    summary: 'Consolidacion para auditoria operativa y validacion de gestiones.',
    useCases: [
      'Cierre diario, semanal o mensual de secretaria.',
      'Validacion de matriculas, pagos y pendientes.',
      'Entrega de informacion a direccion o administracion.'
    ],
    workflow: [
      'Abrir Reportes y elegir rango de fechas o filtros.',
      'Seleccionar tabla o vista requerida para el analisis.',
      'Cruzar resultados con acciones recientes.',
      'Exportar y compartir hallazgos para seguimiento.'
    ],
    checklist: [
      'Filtros y periodo correctos.',
      'Totales consistentes con modulos operativos.',
      'Archivo exportado con nombre y fecha de control.'
    ],
    commonErrors: [
      'Emitir reporte con filtros residuales de una consulta anterior.',
      'No validar diferencias antes de compartir a terceros.'
    ]
  },
  {
    id: 'promocion',
    title: 'Promocion',
    summary: 'Herramienta para procesos de promocion academica anual.',
    useCases: [
      'Cambio masivo de estudiantes al siguiente nivel.',
      'Planificacion de cierre de ano academico.',
      'Revision de casos excepcionales antes de ejecutar promocion.'
    ],
    workflow: [
      'Entrar a Promocion y revisar listado objetivo.',
      'Validar reglas y condiciones previas por curso.',
      'Ejecutar promocion segun calendario autorizado.',
      'Verificar que cursos y estados se actualicen correctamente.'
    ],
    checklist: [
      'Ano origen y ano destino correctos.',
      'Casos excepcionales excluidos o tratados.',
      'Validacion posterior en Estudiantes y Reportes.'
    ],
    commonErrors: [
      'Correr promocion sin validar casos especiales.',
      'No revisar impacto posterior en reportes academicos.'
    ]
  },
  {
    id: 'repactacion',
    title: 'Repactacion',
    summary: 'Gestion de acuerdos de pago para regularizar deuda y continuidad escolar.',
    useCases: [
      'Familia con atraso y necesidad de nuevo plan.',
      'Recalculo de cuotas por acuerdo administrativo.',
      'Seguimiento de compromisos de pago especiales.'
    ],
    workflow: [
      'Ir a Repactacion y buscar estudiante con deuda.',
      'Definir nuevo esquema de cuotas con monto y fechas.',
      'Confirmar acuerdo y registrar observaciones clave.',
      'Controlar cumplimiento en Aranceles y tablero.'
    ],
    checklist: [
      'Acuerdo autorizado segun politica interna.',
      'Cuotas y fechas realistas para cumplimiento.',
      'Registro documentado para auditoria futura.'
    ],
    commonErrors: [
      'Generar plan sin respaldo o aprobacion.',
      'No dejar trazabilidad de condiciones pactadas.'
    ]
  }
];

const BUSINESS_CASES = [
  {
    title: 'Alumno nuevo con apoderado nuevo',
    sequence: ['Apoderados', 'Estudiantes', 'Matricula', 'Aranceles'],
    note: 'Priorizar completitud de ficha y respaldo documental antes de finalizar matricula.'
  },
  {
    title: 'Hermano de alumno vigente',
    sequence: ['Apoderados', 'Estudiantes', 'Matricula'],
    note: 'Reutilizar apoderado existente para evitar duplicidad y errores de contacto.'
  },
  {
    title: 'Matricula bloqueada por deuda',
    sequence: ['Aranceles', 'Repactacion', 'Matricula', 'Reportes'],
    note: 'No cerrar matricula hasta regularizar condicion financiera.'
  },
  {
    title: 'Cierre mensual de secretaria',
    sequence: ['Inicio', 'Aranceles', 'Reportes'],
    note: 'Confirmar consistencia entre pagos registrados y consolidado de reportes.'
  }
];

function WikiSectionButton({ section, isActive, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={clsx(
        'w-full text-left p-3 rounded-lg border transition-colors',
        isActive
          ? 'border-primary bg-primary/10 text-primary'
          : 'border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-dark-hover'
      )}
    >
      <p className="text-sm font-semibold">{section.title}</p>
      <p className="text-xs mt-1 opacity-90">{section.summary}</p>
    </button>
  );
}

export function HelpPage() {
  const [activeSectionId, setActiveSectionId] = useState(WIKI_SECTIONS[0].id);

  const activeSection = useMemo(
    () => WIKI_SECTIONS.find((section) => section.id === activeSectionId) ?? WIKI_SECTIONS[0],
    [activeSectionId]
  );

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in p-4 space-y-4">
        <article className="rounded-xl border border-gray-100 dark:border-gray-800 bg-white dark:bg-dark-card shadow-sm">
          <header className="px-6 py-5 border-b border-gray-100 dark:border-gray-800">
            <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Centro de Ayuda</h1>
            <p className="text-sm text-gray-600 dark:text-gray-300 mt-2 max-w-5xl">
              Manual contextual para los workflows del sistema. Usa el indice para navegar por modulo y resolver casos
              de negocio con pasos claros, controles y errores frecuentes.
            </p>
          </header>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-0">
            <aside className="lg:col-span-4 xl:col-span-3 border-r border-gray-100 dark:border-gray-800 p-4 space-y-4">
              <section>
                <h2 className="text-xs tracking-wide uppercase font-semibold text-gray-500 dark:text-gray-400">Indice</h2>
                <div className="mt-3 space-y-2">
                  {WIKI_SECTIONS.map((section) => (
                    <WikiSectionButton
                      key={section.id}
                      section={section}
                      isActive={section.id === activeSectionId}
                      onClick={() => setActiveSectionId(section.id)}
                    />
                  ))}
                </div>
              </section>

              <section className="rounded-lg border border-gray-200 dark:border-gray-700 p-3 bg-gray-50 dark:bg-dark-hover">
                <h3 className="text-sm font-semibold text-gray-900 dark:text-white">Lectura rapida</h3>
                <p className="text-xs text-gray-700 dark:text-gray-300 mt-2">
                  1) Identifica caso de uso. 2) Abre modulo. 3) Ejecuta pasos operativos. 4) Cierra con validacion en reportes.
                </p>
              </section>
            </aside>

            <section className="lg:col-span-8 xl:col-span-9 p-6 space-y-6">
              <header>
                <h2 className="text-xl font-semibold text-gray-900 dark:text-white">{activeSection.title}</h2>
                <p className="text-sm text-gray-600 dark:text-gray-300 mt-1">{activeSection.summary}</p>
              </header>

              <section>
                <h3 className="text-sm font-semibold text-gray-900 dark:text-white">Cuando usar este workflow</h3>
                <ul className="mt-2 list-disc list-inside text-sm text-gray-700 dark:text-gray-300 space-y-1">
                  {activeSection.useCases.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </section>

              <section>
                <h3 className="text-sm font-semibold text-gray-900 dark:text-white">Pasos operativos</h3>
                <ol className="mt-2 list-decimal list-inside text-sm text-gray-700 dark:text-gray-300 space-y-1">
                  {activeSection.workflow.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ol>
              </section>

              <section className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="rounded-lg border border-gray-200 dark:border-gray-700 p-4">
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-white">Checklist de control</h3>
                  <ul className="mt-2 list-disc list-inside text-sm text-gray-700 dark:text-gray-300 space-y-1">
                    {activeSection.checklist.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </div>
                <div className="rounded-lg border border-gray-200 dark:border-gray-700 p-4">
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-white">Errores comunes</h3>
                  <ul className="mt-2 list-disc list-inside text-sm text-gray-700 dark:text-gray-300 space-y-1">
                    {activeSection.commonErrors.map((item) => (
                      <li key={item}>{item}</li>
                    ))}
                  </ul>
                </div>
              </section>
            </section>
          </div>
        </article>

        <article className="rounded-xl border border-gray-100 dark:border-gray-800 bg-white dark:bg-dark-card shadow-sm">
          <header className="px-6 py-4 border-b border-gray-100 dark:border-gray-800">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Casos frecuentes</h2>
            <p className="text-sm text-gray-600 dark:text-gray-300 mt-1">Secuencias sugeridas por tipo de atencion.</p>
          </header>
          <div className="p-6 grid grid-cols-1 lg:grid-cols-2 gap-4">
            {BUSINESS_CASES.map((item) => (
              <section
                key={item.title}
                className="rounded-lg border border-gray-200 dark:border-gray-700 p-4 bg-gray-50 dark:bg-dark-hover"
              >
                <h3 className="text-sm font-semibold text-gray-900 dark:text-white">{item.title}</h3>
                <p className="text-xs text-gray-700 dark:text-gray-300 mt-2">Ruta sugerida: {item.sequence.join(' -> ')}</p>
                <p className="text-xs text-amber-700 dark:text-amber-300 mt-2">{item.note}</p>
              </section>
            ))}
          </div>
        </article>
      </div>
    </main>
  );
}
