import React from 'react';
import { StatusCard } from './StatusCard';
import {
  CurrencyDollarIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
} from '@heroicons/react/24/outline';
import { formatCurrency } from '../../services/feeService';

interface PaymentStatusCardProps {
  totalAmount: number;
  paidAmount: number;
  pendingAmount: number;
  overdueAmount: number;
  overdueCount?: number;
  nextDueDate?: string;
  className?: string;
}

export const PaymentStatusCard: React.FC<PaymentStatusCardProps> = ({
  totalAmount,
  paidAmount,
  pendingAmount,
  overdueAmount,
  overdueCount = 0,
  nextDueDate,
  className,
}) => {
  const progress = totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;

  const getStatusConfig = () => {
    // Has overdue payments
    if (overdueAmount > 0) {
      return {
        status: 'error' as const,
        icon: <ExclamationTriangleIcon className="h-6 w-6" />,
        value: formatCurrency(overdueAmount),
        description: `${overdueCount} cuota${overdueCount !== 1 ? 's' : ''} vencida${overdueCount !== 1 ? 's' : ''}`,
        actionLabel: 'Ver cuotas',
        actionTo: '/apoderado/bienvenido#aranceles',
      };
    }

    // Has pending payments
    if (pendingAmount > 0) {
      const nextDue = nextDueDate
        ? `Próximo vencimiento: ${new Date(nextDueDate).toLocaleDateString('es-CL')}`
        : 'Tiene pagos pendientes';
      
      return {
        status: 'warning' as const,
        icon: <CurrencyDollarIcon className="h-6 w-6" />,
        value: formatCurrency(pendingAmount),
        description: nextDue,
        actionLabel: 'Ver cuotas',
        actionTo: '/apoderado/bienvenido#aranceles',
      };
    }

    // All paid
    return {
      status: 'completed' as const,
      icon: <CheckCircleIcon className="h-6 w-6" />,
      value: '✓ Al día',
      description: `Total pagado: ${formatCurrency(paidAmount)}`,
      actionLabel: 'Ver historial',
      actionTo: '/apoderado/bienvenido#aranceles',
    };
  };

  const config = getStatusConfig();

  return (
    <StatusCard
      title="Estado de Pagos"
      {...config}
      progress={progress}
      className={className}
    />
  );
};

export default PaymentStatusCard;
