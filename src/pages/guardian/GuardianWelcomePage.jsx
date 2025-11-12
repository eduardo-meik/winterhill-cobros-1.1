import React, { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useAuth } from '../../contexts/AuthContext';
import { useGuardianData } from '../../contexts/GuardianContext';
import { useGuardianIntakeGate } from '../../hooks/useGuardianIntakeGate';
import GuardianCompletionNotice from '../../components/guardian/GuardianCompletionNotice';
import { sendGuardianCompletionEmail } from '../../services/guardianNotifications';

// Simple status chips
const Chip = ({ children, color = 'bg-gray-200 text-gray-800' }) => (
  <span className={`inline-block px-2 py-0.5 text-xs rounded-full font-medium ${color}`}>{children}</span>
);

const formatCurrency = (value) => new Intl.NumberFormat('es-CL', { maximumFractionDigits: 0 }).format(Math.round(Number(value) || 0));

const buildGuardianSummary = (guardian, intake, fallbackEmail) => {
  const guardianLastNames = ((guardian?.last_name || '').trim().length ? guardian.last_name.split(/\s+/).filter(Boolean) : []);
  return {
    firstName: intake?.guardian_first_name || guardian?.guardian_first_name || guardian?.first_name || '',
    lastNameP: intake?.guardian_last_name_paterno || guardian?.guardian_last_name_paterno || guardianLastNames[0] || '',
    lastNameM: intake?.guardian_last_name_materno || guardian?.guardian_last_name_materno || guardianLastNames.slice(1).join(' '),
    relationship: intake?.guardian_relationship || guardian?.guardian_relationship || guardian?.family_tie || guardian?.relationship_type || '—',
    rut: intake?.guardian_rut || guardian?.guardian_rut || guardian?.run || '—',
    email: intake?.guardian_email || guardian?.guardian_email || guardian?.email || fallbackEmail,
    phone: intake?.guardian_phone || guardian?.guardian_phone || guardian?.phone || '—',
    address: intake?.guardian_address || guardian?.guardian_address || guardian?.address || '—',
    commune: intake?.guardian_commune || guardian?.guardian_commune || '—',
    education: intake?.guardian_education_level || guardian?.guardian_education_level || '—',
  };
};

const mapStudentsForDisplay = (students = []) => students.map((student) => {
  const displayName = student.whole_name || [student.first_name, student.last_name].filter(Boolean).join(' ').trim();
  return {
    id: student.id,
    displayName: displayName || 'Sin nombre',
    run: student.run || '',
    courseLabel: student.curso_label || 'Sin curso',
  };
});

export const GuardianWelcomePage = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { data, loading, refreshing, refresh, error } = useGuardianData();
  const { intakeNeeded, checking } = useGuardianIntakeGate();
  const [sendingCompletionEmail, setSendingCompletionEmail] = useState(false);

  useEffect(() => {
    if (!checking && intakeNeeded) {
      navigate('/apoderado/encuesta', { replace: true });
    }
  }, [checking, intakeNeeded, navigate]);

  const guardianSummary = useMemo(() => buildGuardianSummary(data?.guardian, data?.intake, user?.email), [data?.guardian, data?.intake, user?.email]);
  const displayStudents = useMemo(() => mapStudentsForDisplay(data?.students), [data?.students]);
  const enrollmentStatus = useMemo(() => String(data?.enrollment?.status || '').toLowerCase(), [data?.enrollment?.status]);
  const rawEnrollmentStatus = data?.enrollment?.status || 'sin_estado';
  const showCompletionNotice = ['completed', 'approved', 'finalized'].includes(enrollmentStatus);
  const currentYear = data?.enrollment?.year ?? new Date().getFullYear();

  const feeTotals = useMemo(() => {
    if (!data?.fees?.length) {
      return { totalPaid: 0, totalPending: 0, totalOverdue: 0 };
    }
    return data.fees.reduce((acc, fee) => {
      const amount = Number(fee.amount || 0);
      const status = String(fee.status || '').toLowerCase();
      if (status === 'paid') acc.totalPaid += amount;
      if (status === 'pending') acc.totalPending += amount;
      if (status === 'overdue') acc.totalOverdue += amount;
      return acc;
    }, { totalPaid: 0, totalPending: 0, totalOverdue: 0 });
  }, [data?.fees]);

  if (!user) {
    return <div className="p-6">No autenticado.</div>;
  }
  if (user.role !== 'guardian') {
    return <div className="p-6">Esta página es solo para apoderados.</div>;
  }

  if (checking || loading) {
    return (
      <div className="flex-1 flex items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary" />
      </div>
    );
  }

  const handleSendCompletionEmail = async () => {
    if (!data?.guardian?.email) {
      toast.error('Agrega un correo de contacto antes de reenviar la confirmación.');
      return;
    }
    try {
      setSendingCompletionEmail(true);
      const portalUrl = typeof window !== 'undefined' ? `${window.location.origin}/apoderado/matricula` : undefined;
      await sendGuardianCompletionEmail({
        guardian: data.guardian,
        students: data.students || [],
        enrollment: data.enrollment,
        documents: data.enrollmentDocuments || [],
        year: currentYear,
        portalUrl,
      });
      toast.success('Reenviamos la confirmación a tu correo.');
    } catch (error) {
      console.error('Error enviando confirmación', error);
      const message = error?.message || 'No pudimos enviar el correo de confirmación.';
      toast.error(message);
    } finally {
      setSendingCompletionEmail(false);
    }
  };

  const handleViewDocuments = () => {
    navigate('/apoderado/matricula');
  };

  const welcomeName = guardianSummary.firstName || data?.guardian?.first_name || '';

  return (
    <div className="w-full p-6 space-y-8 overflow-y-auto">
      {showCompletionNotice && (
        <GuardianCompletionNotice
          className="mb-4"
          guardianName={guardianSummary.firstName}
          email={guardianSummary.email}
          onViewDocuments={handleViewDocuments}
          onSendEmail={handleSendCompletionEmail}
          sendingEmail={sendingCompletionEmail}
        />
      )}
      <div className="flex items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold mb-2">Bienvenido{welcomeName ? `, ${welcomeName}` : ''}</h1>
          <p className="text-sm text-gray-600 dark:text-gray-400">Gestiona tu perfil, estudiantes y pagos desde un solo lugar.</p>
        </div>
        <button
          onClick={() => refresh({ force: true })}
          className="px-3 py-2 text-sm rounded bg-gray-100 hover:bg-gray-200"
        >
          {refreshing ? 'Actualizando…' : 'Actualizar'}
        </button>
      </div>

      {error && (
        <div className="border border-red-300 bg-red-50 dark:bg-red-900/30 text-sm text-red-700 rounded p-3">
          {error}
        </div>
      )}

      {data?.alerts?.length > 0 && (
        <div className="border border-amber-200 bg-amber-50 dark:bg-amber-900/30 rounded p-4 space-y-2">
          <div className="text-sm font-medium text-amber-800">Atención requerida</div>
          <ul className="list-disc pl-4 text-sm text-amber-800 space-y-1">
            {data.alerts.map((alert) => (
              <li key={alert.type}>{alert.message}</li>
            ))}
          </ul>
        </div>
      )}

      {!intakeNeeded && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-md border bg-white dark:bg-gray-800">
            <div className="text-xs text-gray-500 mb-1">Estudiantes asociados</div>
            <div className="text-2xl font-semibold">{displayStudents.length}</div>
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
          <ul className="text-sm space-y-1">
            <li><span className="font-medium">Nombre:</span> {guardianSummary.firstName || '—'} {guardianSummary.lastNameP} {guardianSummary.lastNameM}</li>
            <li><span className="font-medium">RUN/RUT:</span> {guardianSummary.rut}</li>
            <li><span className="font-medium">Relación:</span> {guardianSummary.relationship}</li>
            <li><span className="font-medium">Email:</span> {guardianSummary.email}</li>
            <li><span className="font-medium">Teléfono:</span> {guardianSummary.phone}</li>
            <li><span className="font-medium">Dirección:</span> {guardianSummary.address}</li>
            <li><span className="font-medium">Comuna:</span> {guardianSummary.commune}</li>
            <li><span className="font-medium">Nivel Educacional:</span> {guardianSummary.education}</li>
          </ul>
          <div className="mt-4">
            <Link to="/apoderado/encuesta" className="text-primary text-sm hover:underline">Ver / editar encuesta</Link>
          </div>
        </div>

        <div className="col-span-1 border rounded-md bg-white dark:bg-gray-800 p-4 shadow-sm">
          <h3 className="font-medium mb-3 text-sm text-gray-500 uppercase tracking-wide">Estudiantes Asociados</h3>
          {displayStudents.length ? (
            <ul className="text-sm divide-y divide-gray-200 dark:divide-gray-700">
              {displayStudents.map((student) => (
                <li key={student.id} className="py-2 flex items-center justify-between">
                  <div>
                    <div className="font-medium">{student.displayName}</div>
                    {student.run && <div className="text-xs text-gray-500">{student.run}</div>}
                  </div>
                  <Chip>{student.courseLabel}</Chip>
                </li>
              ))}
            </ul>
          ) : (
            <div className="text-sm text-gray-500">Aún no hay estudiantes vinculados.</div>
          )}
          <div className="mt-4">
            <Link to="/apoderado/matricula" className="text-primary text-sm hover:underline">Gestionar matrícula</Link>
          </div>
        </div>

        <div className="col-span-1 border rounded-md bg-white dark:bg-gray-800 p-4 shadow-sm">
          <h3 className="font-medium mb-3 text-sm text-gray-500 uppercase tracking-wide">Estado de Matrícula</h3>
          <div className="flex items-center gap-2 mb-2">
            <span className="font-medium">Estado:</span>
            <Chip color={showCompletionNotice ? 'bg-green-200 text-green-800' : 'bg-blue-200 text-blue-800'}>{rawEnrollmentStatus}</Chip>
          </div>
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">Revisa y completa los pasos necesarios para finalizar la matrícula.</p>
          <Link to="/apoderado/matricula" className="inline-block px-4 py-2 bg-primary text-white rounded text-sm hover:opacity-90">Continuar matrícula</Link>
        </div>
      </div>

      <div className="border rounded-md bg-white dark:bg-gray-800 p-4 shadow-sm">
        <h3 className="font-medium mb-3 text-sm text-gray-500 uppercase tracking-wide">Acciones Rápidas</h3>
        <div className="flex flex-wrap gap-3 text-sm">
          <Link to="/apoderado/encuesta" className="px-3 py-2 rounded bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600">Actualizar datos</Link>
          <Link to="/apoderado/matricula" className="px-3 py-2 rounded bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600">Gestionar matrícula</Link>
          <Link to="/profile" className="px-3 py-2 rounded bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600">Mi perfil</Link>
          <Link to="/settings" className="px-3 py-2 rounded bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600">Configuración</Link>
          <Link to="/apoderado/portal" className="px-3 py-2 rounded bg-primary/10 text-primary hover:bg-primary/20">Ver estado de pagos</Link>
        </div>
      </div>
    </div>
  );
};

export default GuardianWelcomePage;
