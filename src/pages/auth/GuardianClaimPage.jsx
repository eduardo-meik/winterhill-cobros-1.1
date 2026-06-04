import React, { useState, useCallback, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Link } from 'react-router-dom';
import { normalizeRun, validateRun as validateRunLocal, formatRunDisplay } from '../../utils/rut';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';
import { friendlyError } from '../../utils/friendlyError';


export const GuardianClaimPage = () => {
  const { user, refreshProfileRole } = useAuth();
  const navigate = useNavigate();
  const [run, setRun] = useState(''); // user-facing (may contain dots/hyphen)
  const [claiming, setClaiming] = useState(false);
  const [result, setResult] = useState(null);
  const [localValidity, setLocalValidity] = useState({ valid: false });

  const onRunChange = (e) => {
    const value = e.target.value;
    setRun(value);
    const v = validateRunLocal(value);
    setLocalValidity(v);
  };

  const onRunBlur = () => {
    if (run) {
      setRun(formatRunDisplay(run));
    }
  };

  const debugLog = useCallback((msg, data) => {
    // eslint-disable-next-line no-console
    console.log(`[GuardianClaim] ${msg}`, data || '');
  }, []);

  const handleClaim = async (e) => {
    e.preventDefault();
    const { valid, clean, expected, dv } = validateRunLocal(run);
    if (!valid) {
      toast.error('RUN inválido o dígito verificador incorrecto.');
      debugLog('Local validation failed', { run, clean, expected, dv });
      return;
    }
    if (!user) {
      // Guardamos el RUN normalizado para reintentar después de login (opcional)
      try { sessionStorage.setItem('pending_guardian_run', clean); } catch {}
      toast('Inicia sesión para continuar.');
      navigate('/login', { state: { from: '/registro-apoderado' } });
      return;
    }
    setClaiming(true);
    setResult(null);
    try {
      debugLog('Calling RPC claim_guardian_by_run', { input_run: clean });
      const { data, error } = await supabase.rpc('claim_guardian_by_run', { input_run: clean });
      if (error) {
        toast.error(friendlyError(error, 'Error en la reclamación.'));
        debugLog('RPC error', error);
        return;
      }
      setResult(data);
      const status = data?.status;
      let success = false;
      switch (status) {
        case 'CLAIMED_EXISTING':
          toast.success('Apoderado reclamado exitosamente.');
          success = true;
          break;
        case 'CREATED_NEW':
          toast.success('Se creó tu registro de apoderado.');
          success = true;
          break;
        case 'ALREADY_LINKED':
          toast('Ya estabas vinculado como apoderado.');
          break;
        case 'ALREADY_CLAIMED':
          toast.error('Este RUN ya fue reclamado por otro usuario.');
          break;
        case 'INVALID_RUN':
          toast.error('RUN inválido. Verifica dígito verificador.');
          break;
        default:
          toast('Operación finalizada.');
      }
      // refresh role to reflect guardian role if assigned post-claim
      await refreshProfileRole();
      if (success) {
        // Redirect after short delay to matrícula
        setTimeout(() => navigate('/matricula'), 1800);
      }
      debugLog('Role refreshed');
    } catch (err) {
      toast.error(friendlyError(err, 'Error inesperado.'));
      debugLog('Unexpected error', err);
    } finally {
      setClaiming(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4">
      <div className="w-full max-w-md bg-white shadow rounded p-6 space-y-6">
        <div>
          <h1 className="text-xl font-semibold text-gray-800">Registro de Apoderado</h1>
          <p className="text-sm text-gray-600 mt-1">Ingresa tu RUN sin puntos y con el dígito verificador para vincularte como apoderado del Colegio Winterhill.</p>
        </div>
        {!user && (
          <div className="p-3 bg-yellow-50 border border-yellow-200 text-sm text-yellow-800 rounded space-y-2">
            <div>Debes iniciar sesión para continuar.</div>
            <div className="text-xs text-gray-700">
              ¿Aún no tienes cuenta? <Link to="/registro-apoderado/nuevo" className="underline font-medium">Créala aquí</Link>
            </div>
          </div>
        )}
        <form onSubmit={handleClaim} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">RUN</label>
            <input
              type="text"
              value={run}
              onChange={onRunChange}
              onBlur={onRunBlur}
              placeholder="12.345.678-K"
              className={`w-full border rounded px-3 py-2 focus:outline-none focus:ring focus:ring-indigo-200 ${run && !localValidity.valid ? 'border-red-400' : ''}`}
              disabled={claiming}
              autoComplete="off"
              inputMode="text"
            />
            {run && !localValidity.valid && (
              <p className="text-xs text-red-600 mt-1">Dígito verificador incorrecto.</p>
            )}
          </div>
          <button
            type="submit"
            disabled={claiming || !localValidity.valid}
            className="w-full bg-indigo-600 text-white py-2 rounded hover:bg-indigo-700 disabled:opacity-50"
          >
            {claiming ? 'Procesando...' : (user ? 'Iniciar' : 'Iniciar (requiere sesión)')}
          </button>
        </form>
        {result && (
          <div className="text-sm bg-gray-50 border border-gray-200 rounded p-4 space-y-2">
            <div className="flex items-center justify-between">
              <div><span className="font-medium">Estado:</span> {result.status}</div>
              {(result.status === 'CLAIMED_EXISTING' || result.status === 'CREATED_NEW') && (
                <span className="text-xs text-green-600">Redirigiendo...</span>
              )}
            </div>
            {result.message && <div className="text-gray-700 leading-snug">{result.message}</div>}
            {result.guardian_id && <div>Guardian ID: {result.guardian_id}</div>}
            {result.created && <div>Creado: {result.created ? 'Sí' : 'No'}</div>}
            <div className="pt-2 flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() => navigate('/matricula')}
                className="px-3 py-1.5 text-sm bg-indigo-600 text-white rounded hover:bg-indigo-700"
              >Ir a Matrícula ahora</button>
              <button
                type="button"
                onClick={() => navigate('/dashboard')}
                className="px-3 py-1.5 text-sm bg-gray-200 text-gray-800 rounded hover:bg-gray-300"
              >Ir al Inicio</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default GuardianClaimPage;