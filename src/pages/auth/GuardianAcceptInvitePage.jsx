import React, { useEffect, useMemo, useState } from 'react';
import { useLocation, useNavigate, Link } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { friendlyError } from '../../utils/friendlyError';

function useQuery() {
  const { search } = useLocation();
  return useMemo(() => new URLSearchParams(search), [search]);
}

export const GuardianAcceptInvitePage = () => {
  const query = useQuery();
  const token = query.get('token') || '';
  const navigate = useNavigate();
  const { user, loading, refreshProfileRole } = useAuth();
  const [submitting, setSubmitting] = useState(false);
  const [status, setStatus] = useState(null);

  useEffect(() => {
    let active = true;
    const run = async () => {
      if (!token) return; // show UI with instructions
      if (loading) return; // wait until auth loads
      if (!user) return; // require login
      setSubmitting(true);
      try {
        const { data, error } = await supabase.rpc('accept_guardian_invite', { p_token: token });
        if (error) {
          console.error('accept_guardian_invite error', error);
          toast.error(friendlyError(error, 'No se pudo aceptar la invitación.'));
          if (active) setStatus({ status: 'error', message: friendlyError(error, 'No se pudo aceptar la invitación.') });
          return;
        }
        if (active) setStatus(data);
        const state = data?.status;
        switch (state) {
          case 'linked':
            toast.success('Cuenta vinculada a tu registro de apoderado.');
            await refreshProfileRole();
            setTimeout(() => navigate('/apoderado/bienvenido', { replace: true }), 1200);
            break;
          case 'already_linked':
            toast('Ya estabas vinculado.');
            setTimeout(() => navigate('/apoderado/bienvenido', { replace: true }), 800);
            break;
          case 'invalid_token':
            toast.error('Invitación inválida.');
            break;
          case 'expired':
            toast.error('La invitación expiró. Solicita una nueva.');
            break;
          case 'claimed_by_other':
            toast.error('Esta invitación ya fue utilizada por otra cuenta.');
            break;
          case 'not_authenticated':
            // Shouldn’t happen here, but handle gracefully
            toast('Inicia sesión para continuar.');
            break;
          default:
            // Unknown, just report
            break;
        }
      } finally {
        if (active) setSubmitting(false);
      }
    };
    run();
    return () => { active = false; };
  }, [token, user, loading, navigate, refreshProfileRole]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-md bg-white shadow rounded p-6 space-y-4">
        <h1 className="text-xl font-semibold text-gray-800">Vincular cuenta de Apoderado</h1>
        {!token && (
          <div className="text-sm text-gray-700">Falta el parámetro token en el enlace. Revisa el email de invitación.</div>
        )}
        {token && !user && !loading && (
          <div className="space-y-2">
            <div className="p-3 bg-yellow-50 border border-yellow-200 text-sm text-yellow-800 rounded">
              Debes iniciar sesión para aceptar la invitación.
            </div>
            <div className="flex gap-2">
              <Link to={`/login?next=${encodeURIComponent(window.location.pathname + window.location.search)}`} className="px-3 py-2 rounded bg-indigo-600 text-white hover:bg-indigo-700">Iniciar sesión</Link>
              <Link to="/registro-apoderado/nuevo" className="px-3 py-2 rounded bg-gray-100 hover:bg-gray-200">Crear cuenta</Link>
            </div>
          </div>
        )}
        {token && user && (
          <div className="text-sm text-gray-700">
            {submitting ? 'Procesando invitación…' : (status ? JSON.stringify(status) : 'Listo para procesar.')}
          </div>
        )}
      </div>
    </div>
  );
};

export default GuardianAcceptInvitePage;
