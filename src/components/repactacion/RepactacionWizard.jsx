import React, { useEffect, useMemo, useState, useCallback } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { Button } from '../ui/Button';
import { Card, CardContent, CardHeader } from '../ui/Card';
import toast from 'react-hot-toast';
import { fetchCurrentGuardian, getOrCreateEnrollment, listEnrollmentStudents, buildRepactacionPayload, renderRepactacionPagare, createRepactacionPagareDocument, sha256, fetchGuardianDebtDetailed } from '../../services/matricula';
import { generatePDFFromHTML, downloadPDFBlob } from '../../services/pdfGenerator';
import { supabase } from '../../services/supabase';

// Clean rewritten component to resolve syntax issues
function HtmlIframePreview({ html, height = 600 }) { return <iframe title="Vista previa repactación" style={{ width:'100%', height, border:0, background:'white' }} srcDoc={html||''}/>; }

export default function RepactacionWizard(){
  const { user } = useAuth();
  const currentYear = new Date().getFullYear();
  const assistedMode = user?.profile === 'ADMIN' || user?.profile === 'ASIST';
  const [guardian,setGuardian]=useState(null);
  const [assistedGuardian,setAssistedGuardian]=useState(null);
  const [guardianSearch,setGuardianSearch]=useState('');
  const [guardianResults,setGuardianResults]=useState([]);
  const [guardianSearchLoading,setGuardianSearchLoading]=useState(false);
  const [enrollment,setEnrollment]=useState(null);
  const [students,setStudents]=useState([]);
  const [debt,setDebt]=useState({ total:0, items:[], source:'fallback'});
  const [selectedDebtIds,setSelectedDebtIds]=useState(()=>new Set());
  const [manualTotal,setManualTotal]=useState('');
  const [schedule,setSchedule]=useState({ total:'', cuotas:'6', dia_vencimiento:'5'});
  const [previewHtml,setPreviewHtml]=useState('');
  const [documentRecord,setDocumentRecord]=useState(null);
  const [loading,setLoading]=useState(false);

  // Load guardian + enrollment + debt
  useEffect(()=>{ if(!user) return; (async()=>{ setLoading(true); try{ let g = guardian; if(assistedMode){ if(!assistedGuardian){ setLoading(false); return;} g=assistedGuardian; } else { const self = await fetchCurrentGuardian(user.id); if(!self){ toast.error('No se encontró apoderado'); return;} g=self; } setGuardian(g); const enr=await getOrCreateEnrollment(g.id,currentYear); if(!enr){ toast.error('No se pudo obtener matrícula'); return;} setEnrollment(enr); const list=await listEnrollmentStudents(enr.id); setStudents(list); try{ const det=await fetchGuardianDebtDetailed(g.id); setDebt(det); const allIds=new Set((det.items||[]).map(it=>it.id)); setSelectedDebtIds(allIds); if(!schedule.total || Number(schedule.total)<=0){ setSchedule(s=>({...s,total:String(Math.round(det.total||0))})); } }catch(e){ console.warn('Detalle deuda',e);} } finally { setLoading(false);} })(); },[user,assistedMode,assistedGuardian?.id]);

  const searchGuardians = useCallback(async(q)=>{ if(!q || q.trim().length<2){ setGuardianResults([]); return;} try{ setGuardianSearchLoading(true); const orFilter=`first_name.ilike.%${q}%,last_name.ilike.%${q}%,run.ilike.%${q}%,email.ilike.%${q}%`; const {data,error}=await supabase.from('guardians').select('id, first_name, last_name, run, email').or(orFilter).limit(10); if(error) throw error; setGuardianResults(data||[]);} catch(e){ console.error('search guardians',e);} finally { setGuardianSearchLoading(false);} },[]);

  const selectedTotal = useMemo(()=>{ if(!debt.items?.length) return 0; if(!selectedDebtIds.size) return 0; return debt.items.filter(it=>selectedDebtIds.has(it.id)).reduce((s,it)=>s+(Number(it.amount)||0),0); },[debt.items,selectedDebtIds]);
  const effectiveTotal = useMemo(()=>{ const m = Number(manualTotal); if(!isNaN(m)&&m>0) return Math.min(m, selectedTotal || debt.total || 0); return selectedTotal || debt.total || 0; },[manualTotal,selectedTotal,debt.total]);

  const handleGenerate = async()=>{ if(!guardian||!enrollment) return; const baseTotal = effectiveTotal || Number(schedule.total)||0; const totalNum = Math.max(0,Math.round(baseTotal)); const cuotasNum = Number(schedule.cuotas)||1; if(totalNum<=0){ toast.error('Ingresa monto total > 0'); return;} if(cuotasNum<1){ toast.error('Cuotas inválidas'); return;} setLoading(true); try{ const payload=buildRepactacionPayload({ guardian, year:currentYear, students, schedule:{ total:totalNum, cuotas:cuotasNum, dia_vencimiento:Number(schedule.dia_vencimiento)||5 }}); payload.folio_number=(enrollment.id? String(enrollment.id).slice(0,8):Date.now().toString().slice(-8)).toUpperCase(); const html=renderRepactacionPagare(payload); setPreviewHtml(html); const hash=await sha256(html); const doc=await createRepactacionPagareDocument({ enrollmentId:enrollment.id, payload, finalContent:html, contentHash:hash }); setDocumentRecord(doc); if(doc) toast.success('Vista previa generada'); } catch(e){ console.error(e); toast.error('Error generando pagaré repactación'); } finally { setLoading(false);} };

  const handleDownloadPDF = async()=>{ if(!previewHtml||!guardian){ toast.error('No hay documento'); return;} try{ toast.loading('Generando PDF...',{id:'repac-pdf'}); const folioNumber = documentRecord?.id ? documentRecord.id.substring(0,8).toUpperCase(): Date.now().toString().slice(-8); const pdfBlob = await generatePDFFromHTML({ htmlContent:previewHtml, includeHeader:true, includeSignatureSection:true, folioNumber, guardianRun:guardian.run }); downloadPDFBlob(pdfBlob,`Pagare_Repactacion_${currentYear}_${guardian.run||'documento'}.pdf`); toast.success('PDF listo',{id:'repac-pdf'}); } catch(e){ console.error(e); toast.error('Error PDF',{id:'repac-pdf'});} finally { toast.dismiss('repac-pdf'); } };

  return <main className="flex-1 p-4 space-y-4">{
    /* Header */
  }<h1 className="text-2xl font-bold">Repactación de Deuda</h1>
    <p className="text-sm text-gray-600 dark:text-gray-400">Genera un pagaré especial para repactar deuda previa.</p>
    {loading && <p className="text-sm">Cargando...</p>}
    {assistedMode && (
      <Card>
        <CardHeader><h2 className="font-semibold">Buscar Apoderado</h2></CardHeader>
        <CardContent className="space-y-3 text-sm">
          <div className="grid md:grid-cols-3 gap-4 items-end">
            <div className="md:col-span-2">
              <label className="block text-xs mb-1 font-medium">Nombre, RUN o email</label>
              <input type="text" className="w-full border rounded px-2 py-1" value={guardianSearch} onChange={e=>{ setGuardianSearch(e.target.value); searchGuardians(e.target.value); }} placeholder="Ej: 12.345.678-9 o apellido" />
            </div>
          </div>
          {guardianSearchLoading && <p className="text-xs">Buscando…</p>}
          {!!guardianResults.length && <ul className="divide-y rounded border max-h-56 overflow-auto">{guardianResults.map(g=> <li key={g.id} className={`p-2 flex items-center justify-between text-sm ${assistedGuardian?.id===g.id?'bg-blue-50 dark:bg-blue-900/30':''}`}><div><div className="font-medium">{[g.first_name,g.last_name].filter(Boolean).join(' ')||'—'}</div><div className="text-xs text-gray-600">{g.run} · {g.email}</div></div><Button size="xs" onClick={()=>{ setAssistedGuardian(g); setPreviewHtml(''); setDocumentRecord(null); setDebt({ total:0, items:[], source:'fallback'}); setSelectedDebtIds(new Set()); setManualTotal(''); }}>Seleccionar</Button></li>)}</ul>}
          {assistedGuardian && <div className="text-xs text-gray-700 dark:text-gray-300">Apoderado seleccionado: <strong>{[assistedGuardian.first_name,assistedGuardian.last_name].filter(Boolean).join(' ')}</strong> ({assistedGuardian.run})</div>}
        </CardContent>
      </Card>
    )}
    {!loading && guardian && (
      <Card>
        <CardHeader><h2 className="font-semibold">Configuración de Repactación</h2></CardHeader>
        <CardContent className="space-y-4 text-sm">
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <h3 className="font-medium">Deuda Detectada</h3>
              <div className="flex gap-2">
                <Button size="xs" variant="outline" onClick={()=> setSelectedDebtIds(new Set((debt.items||[]).map(it=>it.id)))}>Seleccionar todo</Button>
                <Button size="xs" variant="outline" onClick={()=> setSelectedDebtIds(new Set())}>Limpiar</Button>
              </div>
            </div>
            <div className="border rounded max-h-64 overflow-auto">
              <table className="min-w-full text-xs">
                <thead className="bg-gray-50 dark:bg-gray-800 sticky top-0"><tr><th className="p-2 text-left">Sel</th><th className="p-2 text-left">Alumno</th><th className="p-2 text-left">Cuota</th><th className="p-2 text-left">Vence</th><th className="p-2 text-right">Monto</th><th className="p-2 text-left">Estado</th></tr></thead>
                <tbody>{(debt.items||[]).map(it=> <tr key={it.id} className="border-t"><td className="p-2"><input type="checkbox" checked={selectedDebtIds.has(it.id)} onChange={e=>{ setSelectedDebtIds(prev=>{ const next=new Set(prev); if(e.target.checked) next.add(it.id); else next.delete(it.id); return next; }); }} /></td><td className="p-2">{it.student_id?.slice(0,8)||'—'}</td><td className="p-2">{it.numero_cuota??'—'}</td><td className="p-2">{it.due_date? new Date(it.due_date).toLocaleDateString('es-CL'):'—'}</td><td className="p-2 text-right">$ {Number(it.amount||0).toLocaleString('es-CL')}</td><td className="p-2">{it.status}</td></tr>)}{(!debt.items||debt.items.length===0)&& <tr><td colSpan={6} className="p-3 text-center text-gray-500">No hay deuda registrada</td></tr>}</tbody>
              </table>
            </div>
            <div className="text-xs text-gray-700 dark:text-gray-300 flex flex-wrap gap-4 items-center"><div>Subtotal seleccionado: <strong>$ {selectedTotal.toLocaleString('es-CL')}</strong></div><div>Deuda total detectada: <strong>$ {Number(debt.total||0).toLocaleString('es-CL')}</strong> <span className="opacity-60">({debt.source})</span></div></div>
          </div>
          <div className="grid md:grid-cols-3 gap-4">
            <div><label className="block text-xs mb-1 font-medium">Monto Total Adeudado (CLP)</label><input type="number" className="w-full border rounded px-2 py-1" value={manualTotal || schedule.total} onChange={e=>{ setManualTotal(e.target.value); setSchedule({...schedule,total:e.target.value}); }} placeholder="Ej: 500000" /><div className="text-[11px] text-gray-500 mt-1">Ajuste negociado/castigado. No supera subtotal seleccionado.</div></div>
            <div><label className="block text-xs mb-1 font-medium">Cantidad de Cuotas</label><input type="number" min={1} max={36} className="w-full border rounded px-2 py-1" value={schedule.cuotas} onChange={e=> setSchedule({...schedule,cuotas:e.target.value})} /></div>
            <div><label className="block text-xs mb-1 font-medium">Día Vencimiento (1-28)</label><input type="number" min={1} max={28} className="w-full border rounded px-2 py-1" value={schedule.dia_vencimiento} onChange={e=> setSchedule({...schedule,dia_vencimiento:e.target.value})} /></div>
          </div>
          <div className="text-xs text-gray-600 dark:text-gray-400">Monto por cuota estimado: <strong>{(()=>{ const t=Math.max(Number(manualTotal || schedule.total)||0, effectiveTotal||0); const c=Math.max(1, Number(schedule.cuotas)||1); return (Math.round(t/c)).toLocaleString('es-CL'); })()}</strong></div>
          <Button onClick={handleGenerate} disabled={loading || (!schedule.total && effectiveTotal<=0)}>Generar Vista Previa</Button>
        </CardContent>
      </Card>
    )}
    {previewHtml && (
      <Card>
        <CardHeader className="flex items-center justify-between"><h2 className="font-semibold">Vista Previa Pagaré Repactación</h2>{documentRecord && <span className="text-xs px-2 py-1 rounded bg-green-600 text-white">✓ Documento</span>}</CardHeader>
        <CardContent className="space-y-4"><div className="border rounded bg-white dark:bg-gray-800 shadow"><HtmlIframePreview html={previewHtml} height={600}/></div><div className="flex gap-3 flex-wrap"><Button onClick={handleDownloadPDF}>Descargar PDF</Button><Button variant="outline" onClick={()=>{ setPreviewHtml(''); setDocumentRecord(null); }}>Editar Parámetros</Button></div></CardContent>
      </Card>
    )}
  </main>;
}
