import React from 'react';
import { StatusCard } from './StatusCard';
import {
  DocumentCheckIcon,
  DocumentTextIcon,
  ClockIcon,
} from '@heroicons/react/24/outline';

interface IntakeStatusCardProps {
  status: 'submitted' | 'draft' | 'pending';
  submittedAt?: string;
  year?: number;
  className?: string;
}

export const IntakeStatusCard: React.FC<IntakeStatusCardProps> = ({
  status,
  submittedAt,
  year,
  className,
}) => {
  const currentYear = year || new Date().getFullYear();

  const getStatusConfig = () => {
    switch (status) {
      case 'submitted':
        return {
          status: 'completed' as const,
          icon: <DocumentCheckIcon className="h-6 w-6" />,
          value: '✓ Completada',
          description: submittedAt
            ? `Enviada el ${new Date(submittedAt).toLocaleDateString('es-CL')}`
            : 'Encuesta completada',
          actionLabel: 'Ver encuesta',
          actionTo: '/apoderado/encuesta',
          progress: 100,
        };
      case 'draft':
        return {
          status: 'warning' as const,
          icon: <DocumentTextIcon className="h-6 w-6" />,
          value: 'Borrador',
          description: 'Encuesta iniciada pero no enviada',
          actionLabel: 'Continuar encuesta',
          actionTo: '/apoderado/encuesta',
          progress: 50,
        };
      case 'pending':
      default:
        return {
          status: 'error' as const,
          icon: <ClockIcon className="h-6 w-6" />,
          value: 'Pendiente',
          description: `Por favor complete la Encuesta Anual de Ingreso ${currentYear}`,
          actionLabel: 'Completar ahora',
          actionTo: '/apoderado/encuesta',
          progress: 0,
        };
    }
  };

  const config = getStatusConfig();

  return (
    <StatusCard
      title={`Encuesta Anual ${currentYear}`}
      {...config}
      className={className}
    />
  );
};

export default IntakeStatusCard;
