import React, { useEffect, useMemo, useState } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { fetchCurrentGuardian, getOrCreateEnrollment } from '../../services/matricula';
// Intake need now provided through gate hook caching; we also traeremos el registro para rellenar campos
import { Link, useNavigate } from 'react-router-dom';
import { useGuardianIntakeGate } from '../../hooks/useGuardianIntakeGate';
import { fetchCurrentIntake } from '../../services/guardianIntake';
import { supabase } from '../../services/supabase';

// Simple status chips
const Chip = ({ children, color = 'bg-gray-200 text-gray-800' }) => (
  <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${color}`}>{children}</span>
);

const EMPTY_FEE_TOTALS = { totalPaid: 0, totalPending: 0, totalOverdue: 0, count: 0 };

const formatCurrency = (value) => new Intl.NumberFormat('es-CL').format(Math.round(Number(value) || 0));

const normalizeStudentForDisplay = (studentRow) => {
  if (!studentRow) return null;
  const wholeNameCandidate = (studentRow.whole_name || `${studentRow.first_name || ''} ${studentRow.last_name || ''}`).trim();
  const tokens = wholeNameCandidate ? wholeNameCandidate.split(/\s+/) : [];
  const firstName = studentRow.first_name || tokens[0] || '';
  const remaining = tokens.length > 1 ? tokens.slice(1).join(' ') : (studentRow.last_name || '');
  return {
    id: studentRow.id,
    displayName: wholeNameCandidate || `${firstName} ${remaining}`.trim(),
    run: studentRow.run || '',
    courseLabel: studentRow.cursos?.nom_curso || studentRow.curso || '',
    firstName,
    lastNames: remaining,
  };
};

export const GuardianWelcomePage = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [guardian, setGuardian] = useState(null);
  const [students, setStudents] = useState([]);
  const [intakeNeeded, setIntakeNeeded] = useState(false);
  const { intakeNeeded: gateIntakeNeeded } = useGuardianIntakeGate();
  const [enrollment, setEnrollment] = useState(null);
  const [intake, setIntake] = useState(null);
  const [feeTotals, setFeeTotals] = useState({ totalPaid: 0, totalPending: 0, totalOverdue: 0, count: 0 });
  const navigate = useNavigate();

  useEffect(() => {
    let active = true;
    const run = async () => {
      // Esperar a que exista usuario y rol
      if (!user) { setLoading(false); return; }
      if (user.role !== 'guardian') { setLoading(false); return; }
      try {
        const currentYear = new Date().getFullYear();
        // 1. Guardian record con reintentos (posible delay en RPC ensure_guardian_for_user)
        let g = null;
        for (let attempt = 0; attempt < 3 && active; attempt++) {
          g = await fetchCurrentGuardian(user.id).catch(() => null);
            if (g?.id) break;
            // pequeño delay antes del siguiente intento
            if (attempt < 2) {
              await new Promise(r => setTimeout(r, 500));
            }
        }
        if (!active) return;
        setGuardian(g);

        // 2. Intake record + flag (prefer gate cached flag; traemos el record para rellenar campos)
        let intakeRec = null;
        try {
          intakeRec = await fetchCurrentIntake();
        } catch {}
        if (active) setIntake(intakeRec);
        if (gateIntakeNeeded !== null && gateIntakeNeeded !== undefined) {
          setIntakeNeeded(gateIntakeNeeded);
        }

        // 3. Enrollment requires guardian id
        let linkedStudentIds = [];
        if (g?.id) {
          const { data: links, error: linkErr } = await supabase
            .from('student_guardian')
            .select('student_id')
            .eq('guardian_id', g.id);
          if (!linkErr && links?.length) {
            linkedStudentIds = links
              .map(l => l.student_id)
              .filter((id) => Boolean(id));
          }
        }

        if (linkedStudentIds.length) {
          const { data: studentRows, error: stuErr } = await supabase
            .from('students')
            .select('id, first_name, last_name, whole_name, run, curso, cursos:curso(nom_curso)')
            .in('id', linkedStudentIds);
          if (!stuErr && active) {
            const normalized = (studentRows || [])
              .map(normalizeStudentForDisplay)
              .filter(Boolean);
            setStudents(normalized);
          } else if (active) {
            setStudents([]);
          }
        } else if (active) {
          setStudents([]);
        }

        let enr = null;
        if (g?.id) {
          enr = await getOrCreateEnrollment(g.id, currentYear).catch(() => null);
          if (!active) return;
          setEnrollment(enr);
        } else {
          setEnrollment(null);
        }

        if (linkedStudentIds.length) {
          const { data: feeRows, error: feeErr } = await supabase
            .from('fee')
            .select('amount, status, year')
            .in('student_id', linkedStudentIds)
            .eq('year', currentYear);
          if (!feeErr && feeRows && active) {
            const totalPaid = feeRows.filter(f => f.status === 'paid').reduce((a,b)=>a+Number(b.amount||0),0);
            const totalPending = feeRows.filter(f => f.status === 'pending').reduce((a,b)=>a+Number(b.amount||0),0);
            const totalOverdue = feeRows.filter(f => f.status === 'overdue').reduce((a,b)=>a+Number(b.amount||0),0);
            setFeeTotals({ totalPaid, totalPending, totalOverdue, count: feeRows.length });
          } else if (active) {
            setFeeTotals(EMPTY_FEE_TOTALS);
          }
        } else if (active) {
          setFeeTotals(EMPTY_FEE_TOTALS);
        }
      } finally {
        if (active) setLoading(false);
      }
    };
    run();
    return () => { active = false; };
  }, [user, gateIntakeNeeded]);

  // Auto-redirect to Intake when pending
  useEffect(() => {
    if (!loading && intakeNeeded) {
      navigate('/apoderado/encuesta', { replace: true });
    }
  }, [loading, intakeNeeded, navigate]);

  if (!user) {
    return <div className="p-6">No autenticado.</div>;
  }
  if (user.role !== 'guardian') {
    return <div className="p-6">Esta página es solo para apoderados.</div>;
  }
  if (loading) {
    return (
      <div className="flex-1 flex items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary" />
      </div>
    );
  }

  const enrollmentStatus = enrollment?.status || 'sin_estado';

  // Merge de datos: priorizamos los de intake (guardian_*) si existen, luego guardian (tabla guardians), luego user
  const mergedGuardian = guardian || {};
  const guardianLastNames = ((mergedGuardian.last_name || '').trim().length ? (mergedGuardian.last_name || '').trim().split(/\s+/).filter(Boolean) : []);
  const display = {
    firstName: intake?.guardian_first_name || mergedGuardian.guardian_first_name || (mergedGuardian.first_name || '').trim(),
    lastNameP: intake?.guardian_last_name_paterno || mergedGuardian.guardian_last_name_paterno || guardianLastNames[0] || '',
    lastNameM: intake?.guardian_last_name_materno || mergedGuardian.guardian_last_name_materno || guardianLastNames.slice(1).join(' '),
    relationship: intake?.guardian_relationship
      || mergedGuardian.guardian_relationship
      || mergedGuardian.family_tie
      || mergedGuardian.relationship_type
      || '—',
    rut: intake?.guardian_rut || mergedGuardian.guardian_rut || mergedGuardian.run || '—',
    email: intake?.guardian_email || mergedGuardian.guardian_email || mergedGuardian.email || user.email,
    phone: intake?.guardian_phone || mergedGuardian.guardian_phone || mergedGuardian.phone || '—',
    address: intake?.guardian_address || mergedGuardian.guardian_address || mergedGuardian.address || '—',
    commune: intake?.guardian_commune || mergedGuardian.guardian_commune || '—',
    education: intake?.guardian_education_level || mergedGuardian.guardian_education_level || '—'
  };
  const welcomeName = display.firstName || mergedGuardian.first_name || '';

  return (
    <div className="w-full p-6 space-y-8 overflow-y-auto">
      <div>
        <h1 className="text-2xl font-semibold mb-2">Bienvenido{welcomeName ? `, ${welcomeName}` : ''}</h1>
        <p className="text-sm text-gray-600 dark:text-gray-400">Panel inicial de apoderados. Cuando la Encuesta Anual de Ingreso esté enviada, verás tu resumen aquí.</p>
      </div>

      {/* Si intakeNeeded, ya redirigimos automáticamente */}

      {!guardian && (
        <div className="border border-red-300 bg-red-50 dark:bg-red-900/30 dark:border-red-600 p-4 rounded-md">
          <h2 className="font-medium text-red-800 dark:text-red-200 mb-1">Apoderado no disponible aún</h2>
          <p className="text-sm mb-2">No pudimos cargar (o crear) el registro del apoderado todavía. Esto puede deberse a un ligero retraso en la propagación. Puedes recargar la página en unos segundos.</p>
          <button onClick={() => window.location.reload()} className="px-3 py-2 bg-red-600 hover:bg-red-700 text-white rounded text-sm">Reintentar</button>
        </div>
      )}

      {/* Dashboard resumen visible cuando la encuesta está enviada */}
      {!intakeNeeded && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-md border bg-white dark:bg-gray-800">
            <div className="text-xs text-gray-500 mb-1">Estudiantes asociados</div>
            <div className="text-2xl font-semibold">{students.length}</div>
          </div>
          <div className="p-4 rounded-md border bg-white dark:bg-gray-800">
            <div className="text-xs text-gray-500 mb-1">Total Pagado (año)</div>
            <div className="text-xl font-semibold">${formatCurrency(feeTotals.totalPaid)}</div>
          </div>
          <div className="p-4 rounded-md border bg-white dark:bg-gray-800">
            <div className="text-xs text-gray-500 mb-1">Pendiente (año)</div>
            <div className="text-xl font-semibold text-amber-600">${formatCurrency(feeTotals.totalPending)}</div>
          </div>
          <div className="p-4 rounded-md border bg-white dark:bg-gray-800">
            <div className="text-xs text-gray-500 mb-1">Atrasado (año)</div>
            <div className="text-xl font-semibold text-red-600">${formatCurrency(feeTotals.totalOverdue)}</div>
          </div>
        </div>
      )}

      <div className="grid md:grid-cols-3 gap-6">
        <div className="col-span-1 border rounded-md bg-white dark:bg-gray-800 p-4 shadow-sm">
          <h3 className="font-medium mb-3 text-sm text-gray-500 uppercase tracking-wide">Datos del Apoderado</h3>
          {guardian || intake ? (
            <ul className="text-sm space-y-1">
              <li><span className="font-medium">Nombre:</span> {display.firstName || '—'} {display.lastNameP || ''} {display.lastNameM || ''}</li>
              <li><span className="font-medium">RUN/RUT:</span> {display.rut}</li>
              <li><span className="font-medium">Relación:</span> {display.relationship}</li>
              <li><span className="font-medium">Email:</span> {display.email}</li>
              <li><span className="font-medium">Teléfono:</span> {display.phone}</li>
              <li><span className="font-medium">Dirección:</span> {display.address}</li>
              <li><span className="font-medium">Comuna:</span> {display.commune}</li>
              <li><span className="font-medium">Nivel Educacional:</span> {display.education}</li>
            </ul>
          ) : <div className="text-sm text-gray-500">No se encontraron datos del apoderado.</div>}
          <div className="mt-4">
            <Link to="/apoderado/encuesta" className="text-primary text-sm hover:underline">Ver / editar encuesta</Link>
          </div>
        </div>

        <div className="col-span-1 border rounded-md bg-white dark:bg-gray-800 p-4 shadow-sm">
          <h3 className="font-medium mb-3 text-sm text-gray-500 uppercase tracking-wide">Estudiantes Asociados</h3>
          {students.length > 0 ? (
            <ul className="text-sm divide-y divide-gray-200 dark:divide-gray-700">
              {students.map(s => (
                <li key={s.id} className="py-2 flex items-center justify-between">
                  <div>
                    <div className="font-medium">{s.displayName || 'Sin nombre'}</div>
                    {s.run && <div className="text-xs text-gray-500">{s.run}</div>}
                  </div>
                  <Chip>{s.courseLabel || 'Sin curso'}</Chip>
                </li>
              ))}
            </ul>
          ) : <div className="text-sm text-gray-500">Aún no hay estudiantes vinculados.</div>}
          <div className="mt-4">
            <Link to="/matricula" className="text-primary text-sm hover:underline">Ir a matrícula</Link>
          </div>
        </div>

        <div className="col-span-1 border rounded-md bg-white dark:bg-gray-800 p-4 shadow-sm">
          <h3 className="font-medium mb-3 text-sm text-gray-500 uppercase tracking-wide">Estado de Matrícula</h3>
          <div className="flex items-center gap-2 mb-2">
            <span className="font-medium">Estado:</span>
            <Chip color={enrollmentStatus === 'completed' ? 'bg-green-200 text-green-800' : 'bg-blue-200 text-blue-800'}>{enrollmentStatus}</Chip>
          </div>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">Revisa y completa los pasos necesarios para finalizar la matrícula.</p>
          <Link to="/matricula" className="inline-block px-4 py-2 bg-primary text-white rounded text-sm hover:opacity-90">Continuar matrícula</Link>
        </div>
      </div>

      <div className="border rounded-md bg-white dark:bg-gray-800 p-4 shadow-sm">
        <h3 className="font-medium mb-3 text-sm text-gray-500 uppercase tracking-wide">Acciones Rápidas</h3>
        <div className="flex flex-wrap gap-3 text-sm">
          <Link to="/apoderado/encuesta" className="px-3 py-2 rounded bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600">Actualizar datos</Link>
          <Link to="/matricula" className="px-3 py-2 rounded bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600">Gestionar matrícula</Link>
          <Link to="/profile" className="px-3 py-2 rounded bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600">Mi perfil</Link>
          <Link to="/settings" className="px-3 py-2 rounded bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600">Configuración</Link>
          <Link to="/apoderado/portal" className="px-3 py-2 rounded bg-primary/10 text-primary hover:bg-primary/20">Ver estado de pagos</Link>
        </div>
      </div>
    </div>
  );
};

export default GuardianWelcomePage;
