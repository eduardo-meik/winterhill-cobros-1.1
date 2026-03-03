import React, { useRef, useEffect } from 'react';
import { Card, CardContent, CardHeader } from '../../ui/Card';
import { Button } from '../../ui/Button';

// Renders full HTML inside an iframe for accurate preview
function HtmlIframePreview({ html, height = 600 }) {
  const iframeRef = useRef(null);
  useEffect(() => {
    const iframe = iframeRef.current;
    if (!iframe) return;
    const doc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document);
    if (!doc) return;
    doc.open();
    doc.write(html || '');
    doc.close();
  }, [html]);
  return (
    <iframe
      ref={iframeRef}
      title="Vista previa del documento"
      style={{ width: '100%', height: `${height}px`, border: '0', background: 'white' }}
    />
  );
}

/**
 * Step 2: Document preview + PDF download/email/print actions + finalization.
 *
 * @param {Object} props
 * @param {string} props.previewHtml - full HTML preview
 * @param {Object|null} props.previewParts - per-document preview parts
 * @param {Function} props.setPreviewParts - setter for previewParts
 * @param {Object|null} props.documentRecord - document record from DB
 * @param {boolean} props.loading - loading state
 * @param {Array} props.students - enrolled students
 * @param {boolean} props.prioritario - global prioritario flag
 * @param {boolean} props.assistedMode - staff assisted mode
 * @param {Object} props.paymentMethod - payment method flags
 * @param {boolean} props.descuentoPlanilla - descuento por planilla
 * @param {Object|null} props.guardian - guardian record
 * @param {boolean} props.sendingPagare - sending pagare email state
 * @param {boolean} props.finalizing - finalizing state
 * @param {Object|null} props.finalizeAlert - finalize alert message
 * @param {Function} props.setStep - step setter
 * @param {Function} props.setPreviewHtml - setter for previewHtml
 * @param {Function} props.setDocumentRecord - setter for documentRecord
 * @param {Function} props.setFinalizeAlert - setter for finalizeAlert
 * @param {Function} props.handleGeneratePagare - generate preview handler
 * @param {Function} props.handleDownloadPDF - download bundle PDF
 * @param {Function} props.handlePrint - print handler
 * @param {Function} props.handleDownloadIndividualPDF - download single document
 * @param {Function} props.handleSendPagareEmail - email handler
 * @param {Function} props.handleFinalizePreview - finalize preview handler
 */
export function PreviewStep({
  previewHtml,
  previewParts,
  setPreviewParts,
  documentRecord,
  loading,
  students,
  prioritario,
  assistedMode,
  paymentMethod,
  descuentoPlanilla,
  guardian,
  sendingPagare,
  finalizing,
  finalizeAlert,
  setStep,
  setPreviewHtml,
  setDocumentRecord,
  setFinalizeAlert,
  handleGeneratePagare,
  handleDownloadPDF,
  handlePrint,
  handleDownloadIndividualPDF,
  handleSendPagareEmail,
  handleFinalizePreview,
}) {
  return (
    <Card>
      <CardHeader className="flex items-center justify-between">
        <h2 className="font-semibold">Vista Previa del Contrato de Prestación y Anexos</h2>
        <div className="flex gap-2 items-center">
          {documentRecord && (
            <span className="text-xs px-2 py-1 rounded bg-green-600 text-white">✓ Documento Generado</span>
          )}
          {documentRecord?.status === 'signed' && (
            <span className="text-xs px-2 py-1 rounded bg-blue-600 text-white">✓ Firmado</span>
          )}
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {!previewParts && !loading && (
          <div className="text-center py-8">
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              Haga clic en "Generar Vista Previa" para crear el documento.
            </p>
            <Button onClick={handleGeneratePagare} disabled={loading || students.length === 0}>
              📄 Generar Vista Previa
            </Button>
            {students.length === 0 && (
              <p className="text-sm text-red-600 dark:text-red-400 mt-2">
                Debe agregar al menos un alumno en el paso anterior
              </p>
            )}
          </div>
        )}

        {previewParts && (
          <>
            {/* Document selector + HTML Preview */}
            <div className="space-y-2">
              <div className="flex flex-wrap items-center gap-2 text-xs">
                <span className="font-medium text-gray-700 dark:text-gray-200">Documento a visualizar:</span>
                <button
                  type="button"
                  className={`px-2 py-1 rounded border text-xs ${previewParts.selected === 'contract' ? 'bg-blue-600 text-white border-blue-600' : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 border-gray-300 dark:border-gray-700'}`}
                  onClick={() => setPreviewParts(p => ({ ...p, selected: 'contract' }))}
                  disabled={previewParts.excluded?.contract}
                >
                  Contrato de Prestación
                </button>
                {previewParts.pagareHtml && !prioritario && (
                  <button
                    type="button"
                    className={`px-2 py-1 rounded border text-xs ${previewParts.selected === 'pagare' ? 'bg-blue-600 text-white border-blue-600' : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 border-gray-300 dark:border-gray-700'}`}
                    onClick={() => setPreviewParts(p => ({ ...p, selected: 'pagare' }))}
                    disabled={previewParts.excluded?.pagare}
                  >
                    Pagaré
                  </button>
                )}
                {previewParts.descuentoHtml && !prioritario && (
                  <button
                    type="button"
                    className={`px-2 py-1 rounded border text-xs ${previewParts.selected === 'descuento' ? 'bg-blue-600 text-white border-blue-600' : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 border-gray-300 dark:border-gray-700'}`}
                    onClick={() => setPreviewParts(p => ({ ...p, selected: 'descuento' }))}
                    disabled={previewParts.excluded?.descuento}
                  >
                    Anexo Descuento
                  </button>
                )}
              </div>

              <div className="bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-800 dark:to-gray-900 rounded-lg p-1">
                <div className="border-2 border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 shadow-lg">
                  {(() => {
                    let currentHtml = previewParts.contractHtml;
                    if (previewParts.selected === 'pagare') currentHtml = previewParts.pagareHtml || previewParts.contractHtml;
                    if (previewParts.selected === 'descuento') currentHtml = previewParts.descuentoHtml || previewParts.contractHtml;
                    return <HtmlIframePreview html={currentHtml || previewHtml} height={600} />;
                  })()}
                </div>
              </div>
            </div>

            {finalizeAlert && (
              <div
                className={`p-3 rounded border text-sm ${
                  finalizeAlert.type === 'success'
                    ? 'border-green-300 bg-green-50 text-green-800 dark:bg-green-900/20 dark:border-green-700 dark:text-green-100'
                    : 'border-amber-300 bg-amber-50 text-amber-800 dark:bg-amber-900/20 dark:border-amber-700 dark:text-amber-100'
                }`}
              >
                {finalizeAlert.message}
              </div>
            )}

            {/* Action Buttons */}
            <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
              <h3 className="text-sm font-semibold mb-2 text-blue-900 dark:text-blue-100">📋 Acciones del Documento</h3>
              <p className="text-xs text-blue-700 dark:text-blue-300 mb-4">
                Revise el contenido del documento. Puede descargarlo como PDF o imprimirlo directamente.
              </p>
              <div className="flex flex-col gap-3 w-full">
                <div className="flex gap-3 flex-wrap">
                  <Button variant="default" onClick={handleDownloadPDF} disabled={loading} className="bg-blue-600 hover:bg-blue-700 text-white">
                    📥 Descargar Todo (Bundle)
                  </Button>
                  <Button variant="outline" onClick={handlePrint} disabled={loading}>🖨️ Imprimir</Button>
                  <Button variant="outline" onClick={handleSendPagareEmail} disabled={loading || sendingPagare || !guardian?.email} title={!guardian?.email ? 'Apoderado sin email' : ''}>
                    {sendingPagare ? 'Enviando…' : 'Enviar por correo'}
                  </Button>
                  <Button variant="outline" onClick={() => { setStep(1); setPreviewHtml(''); setDocumentRecord(null); setFinalizeAlert(null); }} disabled={loading}>
                    ✏️ Editar Datos
                  </Button>
                  {assistedMode && (
                    <Button onClick={handleFinalizePreview} disabled={finalizing || students.length === 0} className="ml-auto bg-primary text-white">
                      {finalizing ? 'Preparando…' : 'Confirmar matrícula'}
                    </Button>
                  )}
                </div>

                {/* Individual Downloads */}
                <div className="flex gap-2 items-center pt-2 border-t border-blue-200 dark:border-blue-700">
                  <span className="text-xs text-blue-700 dark:text-blue-300 font-medium">Descargas individuales:</span>
                  <Button variant="outline" size="xs" onClick={() => handleDownloadIndividualPDF('contract')} disabled={loading}>📄 Contrato</Button>
                  {!prioritario && paymentMethod.pagare && (
                    <Button variant="outline" size="xs" onClick={() => handleDownloadIndividualPDF('pagare')} disabled={loading}>📜 Pagaré</Button>
                  )}
                  {!prioritario && descuentoPlanilla && (
                    <Button variant="outline" size="xs" onClick={() => handleDownloadIndividualPDF('descuento')} disabled={loading}>🎁 Anexo Descuento</Button>
                  )}
                </div>

                {/* Include/exclude toggles */}
                <div className="flex flex-wrap gap-2 items-center pt-2 border-t border-blue-200 dark:border-blue-700 mt-2">
                  <span className="text-xs text-blue-700 dark:text-blue-300 font-medium">Incluir en vista previa:</span>
                  <label className="flex items-center gap-1 text-[11px]">
                    <input
                      type="checkbox"
                      checked={!previewParts.excluded?.contract}
                      onChange={e => {
                        const checked = e.target.checked;
                        setPreviewParts(p => {
                          const nextExcluded = { ...(p?.excluded || {}), contract: !checked };
                          let nextSelected = p?.selected || 'contract';
                          if (!checked && p?.selected === 'contract') {
                            if (!nextExcluded.pagare && p?.pagareHtml) nextSelected = 'pagare';
                            else if (!nextExcluded.descuento && p?.descuentoHtml) nextSelected = 'descuento';
                          }
                          return { ...p, excluded: nextExcluded, selected: nextSelected };
                        });
                      }}
                    />
                    <span>Contrato</span>
                  </label>
                  {previewParts.pagareHtml && !prioritario && (
                    <label className="flex items-center gap-1 text-[11px]">
                      <input
                        type="checkbox"
                        checked={!previewParts.excluded?.pagare}
                        onChange={e => {
                          const checked = e.target.checked;
                          setPreviewParts(p => {
                            const nextExcluded = { ...(p?.excluded || {}), pagare: !checked };
                            let nextSelected = p?.selected || 'contract';
                            if (!checked && p?.selected === 'pagare') {
                              if (!nextExcluded.contract) nextSelected = 'contract';
                              else if (!nextExcluded.descuento && p?.descuentoHtml) nextSelected = 'descuento';
                            }
                            return { ...p, excluded: nextExcluded, selected: nextSelected };
                          });
                        }}
                      />
                      <span>Pagaré</span>
                    </label>
                  )}
                  {previewParts.descuentoHtml && !prioritario && (
                    <label className="flex items-center gap-1 text-[11px]">
                      <input
                        type="checkbox"
                        checked={!previewParts.excluded?.descuento}
                        onChange={e => {
                          const checked = e.target.checked;
                          setPreviewParts(p => {
                            const nextExcluded = { ...(p?.excluded || {}), descuento: !checked };
                            let nextSelected = p?.selected || 'contract';
                            if (!checked && p?.selected === 'descuento') {
                              if (!nextExcluded.contract) nextSelected = 'contract';
                              else if (!nextExcluded.pagare && p?.pagareHtml) nextSelected = 'pagare';
                            }
                            return { ...p, excluded: nextExcluded, selected: nextSelected };
                          });
                        }}
                      />
                      <span>Anexo Descuento</span>
                    </label>
                  )}
                </div>
              </div>
              {assistedMode && (
                <p className="text-[11px] text-gray-600 dark:text-gray-400 mt-2">
                  Este paso deja a los estudiantes en estado Pre-Matriculado (valor MATRICULADO) hasta que el equipo marque Confirmado (valor ACTIVO) o Retirado desde el módulo de Estudiantes.
                </p>
              )}
              <div className="mt-4 pt-4 border-t border-blue-200 dark:border-blue-700">
                <p className="text-xs text-blue-600 dark:text-blue-400">
                  💡 <strong>Importante:</strong> El PDF se genera con formato profesional incluyendo:
                </p>
                <ul className="text-xs text-blue-600 dark:text-blue-400 mt-2 ml-4 space-y-1">
                  <li>✓ Logo y datos del colegio</li>
                  <li>✓ Secciones con bordes profesionales</li>
                  <li>✓ Áreas de firma para apoderado y corporación</li>
                  <li>✓ Anexos según forma de pago (Descuento por Planilla / Pagaré)</li>
                </ul>
              </div>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
