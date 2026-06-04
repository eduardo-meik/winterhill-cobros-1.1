import React from 'react';
import { StatusCard } from './StatusCard';
import {
  AcademicCapIcon,
  CheckCircleIcon,
  ClockIcon,
} from '@heroicons/react/24/outline';

interface EnrollmentStatusCardProps {
  status: 'completed' | 'in_progress' | 'pending' | 'not_started';
  completionPercentage?: number;
  currentStep?: string;
  totalSteps?: number;
  completedSteps?: number;
  className?: string;
}

export const EnrollmentStatusCard: React.FC<EnrollmentStatusCardProps> = ({
  status,
  completionPercentage,
  currentStep,
  totalSteps = 0,
  completedSteps = 0,
  className,
}) => {
  const getStatusConfig = () => {
    switch (status) {
      case 'completed':
        return {
          status: 'completed' as const,
          icon: <CheckCircleIcon className="h-6 w-6" />,
          value: '✓ Completada',
          description: 'Matrícula finalizada exitosamente',
          actionLabel: 'Ver detalles',
          actionTo: '/matricula',
          progress: 100,
        };
      case 'in_progress':
        return {
          status: 'pending' as const,
          icon: <ClockIcon className="h-6 w-6" />,
          value: currentStep || 'En progreso',
          description: totalSteps > 0 
            ? `Paso ${completedSteps} de ${totalSteps}`
            : 'Matrícula en proceso',
          actionLabel: 'Continuar matrícula',
          actionTo: '/matricula',
          progress: completionPercentage || 
            (totalSteps > 0 ? (completedSteps / totalSteps) * 100 : 50),
        };
      case 'pending':
        return {
          status: 'warning' as const,
          icon: <AcademicCapIcon className="h-6 w-6" />,
          value: 'Pendiente',
          description: 'Por favor complete el proceso de matrícula',
          actionLabel: 'Iniciar matrícula',
          actionTo: '/matricula',
          progress: 0,
        };
      case 'not_started':
      default:
        return {
          status: 'warning' as const,
          icon: <AcademicCapIcon className="h-6 w-6" />,
          value: 'No iniciada',
          description: 'Aún no ha comenzado el proceso',
          actionLabel: 'Comenzar matrícula',
          actionTo: '/matricula',
          progress: 0,
        };
    }
  };

  const config = getStatusConfig();

  return (
    <StatusCard
      title="Estado de Matrícula"
      {...config}
      className={className}
    />
  );
};

export default EnrollmentStatusCard;
