import React from 'react';
import { Link } from 'react-router-dom';
import { CheckCircleIcon } from '@heroicons/react/24/outline';

export interface GuardianCompletionNoticeProps {
  guardianName?: string | null;
  email?: string | null;
  onViewDocuments?: () => void;
  onSendEmail?: (() => void) | null;
  sendingEmail?: boolean;
  className?: string;
}

const GuardianCompletionNotice: React.FC<GuardianCompletionNoticeProps> = ({
  guardianName,
  email,
  onViewDocuments,
  onSendEmail,
  sendingEmail = false,
  className = '',
}) => {
  const displayName = guardianName || 'Apoderado';

  return (
    <div
      className={`border border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-900/20 rounded-lg p-4 shadow-sm ${className}`}
      role="status"
    >
      <div className="flex flex-col gap-3 md:flex-row md:items-start md:gap-4">
        <div className="flex-shrink-0">
          <CheckCircleIcon className="h-8 w-8 text-green-600 dark:text-green-400" />
        </div>
        <div className="flex-1 min-w-0 space-y-2">
          <div>
            <h2 className="text-sm font-semibold text-green-800 dark:text-green-200 uppercase tracking-wide">
              Matrícula finalizada
            </h2>
            <p className="text-sm text-green-700 dark:text-green-300">
              ¡Listo, {displayName}! Confirmamos que el proceso de matrícula está completado y tus documentos se encuentran disponibles en el portal.
              {email ? ` Te enviamos una copia a ${email}.` : ' Aún no tenemos un correo registrado; agrega uno para recibir los comprobantes.'}
            </p>
          </div>

          <div className="flex flex-wrap gap-2">
            <button
              type="button"
              onClick={onViewDocuments}
              className="inline-flex items-center gap-2 rounded-md bg-green-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
            >
              Ver documentos
            </button>

            {email ? (
              onSendEmail && (
                <button
                  type="button"
                  onClick={onSendEmail}
                  disabled={sendingEmail}
                  className="inline-flex items-center gap-2 rounded-md border border-green-500 px-4 py-2 text-sm font-medium text-green-700 transition hover:bg-green-100 disabled:opacity-70 dark:border-green-400 dark:text-green-300 dark:hover:bg-green-900/30"
                >
                  {sendingEmail ? 'Enviando…' : 'Reenviar confirmación'}
                </button>
              )
            ) : (
              <Link
                to="/profile"
                className="inline-flex items-center gap-2 rounded-md border border-green-500 px-4 py-2 text-sm font-medium text-green-700 transition hover:bg-green-100 dark:border-green-400 dark:text-green-300 dark:hover:bg-green-900/30"
              >
                Actualizar correo de contacto
              </Link>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default GuardianCompletionNotice;
