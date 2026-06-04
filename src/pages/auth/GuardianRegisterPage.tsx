import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import { validateRun as validateRunLocal, formatRunDisplay } from '../../utils/rut';
import toast from 'react-hot-toast';
import { friendlyError } from '../../utils/friendlyError';

interface RegisterGuardianForm {
  email: string;
  password: string;
  confirmPassword: string;
  run: string;
}


export function GuardianRegisterPage() {
  const { signUp, refreshProfileRole } = useAuth();
  const navigate = useNavigate();
  const [showPassword, setShowPassword] = useState(false);
  const [runLocal, setRunLocal] = useState('');
  const [runValidity, setRunValidity] = useState<{ valid: boolean; clean?: string }>({ valid: false });
  const [claiming, setClaiming] = useState(false);

  const { register, handleSubmit, watch, formState: { errors, isSubmitting } } = useForm<RegisterGuardianForm>();
  const password = watch('password');

  useEffect(() => {
    // If redirected from claim page with a pending RUN stored
    try {
      const pending = sessionStorage.getItem('pending_guardian_run');
      if (pending) {
        setRunLocal(pending);
        const v = validateRunLocal(pending);
        setRunValidity(v);
        sessionStorage.removeItem('pending_guardian_run');
      }
    } catch {}
  }, []);

  const onRunChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    setRunLocal(value);
    setRunValidity(validateRunLocal(value));
  };
  const onRunBlur = () => {
    if (runLocal) setRunLocal(formatRunDisplay(runLocal));
  };

  const claimGuardian = async (normalized: string) => {
    setClaiming(true);
    try {
      const { data, error } = await supabase.rpc('claim_guardian_by_run', { input_run: normalized });
      if (error) {
        toast.error(friendlyError(error, 'Error vinculando apoderado.'));
        return;
      }
      switch (data?.status) {
        case 'CREATED_NEW':
          toast.success('Cuenta creada y apoderado registrado.');
          break;
        case 'CLAIMED_EXISTING':
          toast.success('Cuenta creada y apoderado reclamado.');
          break;
        case 'ALREADY_LINKED':
          toast('Apoderado ya vinculado.');
          break;
        case 'ALREADY_CLAIMED':
          toast.error('RUN ya reclamado por otro usuario.');
          break;
        case 'INVALID_RUN':
          toast.error('RUN inválido (DV incorrecto).');
          break;
        default:
          toast('Operación completada.');
      }
      // Asegurar que exista fila en profiles con rol GUARDIAN tras claim exitoso
      if (['CREATED_NEW','CLAIMED_EXISTING','ALREADY_LINKED'].includes(data?.status)) {
        try {
          const { error: rpcErr } = await supabase.rpc('ensure_profile_for_current_user', { p_role: 'GUARDIAN' });
          if (rpcErr) console.warn('RPC ensure_profile_for_current_user error', rpcErr);
        } catch (ensureErr) { console.warn('ensure guardian profile failed', ensureErr); }
        await refreshProfileRole();
        setTimeout(() => navigate('/matricula'), 1500);
      } else {
        await refreshProfileRole();
      }
    } finally {
      setClaiming(false);
    }
  };

  const onSubmit = async (data: RegisterGuardianForm) => {
    const v = validateRunLocal(runLocal);
    if (!v.valid) {
      toast.error('RUN inválido.');
      return;
    }
    try {
      await signUp(data.email, data.password);
      // signUp (AuthContext) puede dejar usuario sin sesión si requiere confirmación; asumimos login directo si identities > 0
      toast.success('Cuenta creada. Procesando apoderado...');
      await claimGuardian(v.clean!);
    } catch (error: any) {
      if (!error.message?.includes('Error al registrar')) {
        toast.error(friendlyError(error, 'Error creando la cuenta.'));
      }
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-dark-bg py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900 dark:text-white">
            Registro de Apoderado
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
            Crea tu cuenta y valida tu RUN para continuar con la matrícula.
          </p>
        </div>
        <form className="mt-8 space-y-6" onSubmit={handleSubmit(onSubmit)}>
          <div className="rounded-md shadow-sm space-y-4">
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 dark:text-gray-300">Correo Electrónico</label>
              <input
                id="email"
                type="email"
                {...register('email', { required: 'Requerido', pattern: { value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i, message: 'Correo inválido' } })}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary focus:border-primary dark:bg-dark-card dark:border-gray-600"
              />
              {errors.email && <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.email.message}</p>}
            </div>
            <div>
              <label htmlFor="run" className="block text-sm font-medium text-gray-700 dark:text-gray-300">RUN</label>
              <input
                id="run"
                type="text"
                value={runLocal}
                onChange={onRunChange}
                onBlur={onRunBlur}
                placeholder="12.345.678-K"
                className={`mt-1 block w-full px-3 py-2 border rounded-md shadow-sm focus:outline-none focus:ring-primary focus:border-primary dark:bg-dark-card dark:border-gray-600 ${runLocal && !runValidity.valid ? 'border-red-400' : 'border-gray-300'}`}
              />
              {runLocal && !runValidity.valid && <p className="mt-1 text-xs text-red-600">DV incorrecto.</p>}
            </div>
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 dark:text-gray-300">Contraseña</label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  {...register('password', { required: 'Requerido', minLength: { value: 8, message: 'Mínimo 8 caracteres' }, pattern: { value: /^(?=.*[A-Z])(?=.*\d)/, message: 'Debe contener mayúscula y número' } })}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary focus:border-primary dark:bg-dark-card dark:border-gray-600 pr-10"
                />
                <button
                  type="button"
                  tabIndex={-1}
                  className="absolute inset-y-0 right-0 px-3 flex items-center text-gray-400"
                  onClick={() => setShowPassword(v => !v)}
                  aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
                >
                  {showPassword ? (
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                    </svg>
                  ) : (
                    <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.542-7a9.956 9.956 0 012.293-3.95M6.873 6.873A9.956 9.956 0 0112 5c4.478 0 8.268 2.943 9.542 7a9.956 9.956 0 01-4.293 5.95M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 3l18 18" />
                    </svg>
                  )}
                </button>
              </div>
              {errors.password && <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.password.message}</p>}
            </div>
            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-700 dark:text-gray-300">Confirmar Contraseña</label>
              <input
                id="confirmPassword"
                type="password"
                {...register('confirmPassword', { required: 'Requerido', validate: value => value === password || 'No coincide' })}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary focus:border-primary dark:bg-dark-card dark:border-gray-600"
              />
              {errors.confirmPassword && <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.confirmPassword.message}</p>}
            </div>
          </div>
          <div>
            <button
              type="submit"
              disabled={isSubmitting || claiming || !runValidity.valid}
              className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary hover:bg-primary-light focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary disabled:opacity-50"
            >
              {isSubmitting || claiming ? 'Procesando...' : 'Crear cuenta y validar'}
            </button>
          </div>
        </form>
        <p className="mt-2 text-center text-sm text-gray-600 dark:text-gray-400">
          ¿Ya tienes una cuenta? <Link to="/login" className="font-medium text-primary hover:text-primary-light">Inicia sesión</Link>
        </p>
        <p className="mt-1 text-center text-xs text-gray-500 dark:text-gray-400">
          Si ya reclamaste tu RUN puedes ir directamente a <Link to="/matricula" className="text-primary hover:text-primary-light">Matrícula</Link>.
        </p>
      </div>
    </div>
  );
}

export default GuardianRegisterPage;
