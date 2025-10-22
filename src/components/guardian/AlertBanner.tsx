import React from 'react';
import { Link } from 'react-router-dom';
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon,
  XCircleIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';

export type AlertVariant = 'success' | 'warning' | 'error' | 'info';

interface AlertBannerProps {
  variant: AlertVariant;
  title?: string;
  message: string;
  actionLabel?: string;
  actionTo?: string;
  onAction?: () => void;
  onDismiss?: () => void;
  dismissible?: boolean;
  className?: string;
}

const variantStyles = {
  success: {
    container: 'bg-green-50 border-green-200 dark:bg-green-900/20 dark:border-green-800',
    icon: 'text-green-600 dark:text-green-400',
    title: 'text-green-800 dark:text-green-200',
    message: 'text-green-700 dark:text-green-300',
    button: 'bg-green-600 hover:bg-green-700 text-white',
    Icon: CheckCircleIcon,
  },
  warning: {
    container: 'bg-yellow-50 border-yellow-200 dark:bg-yellow-900/20 dark:border-yellow-800',
    icon: 'text-yellow-600 dark:text-yellow-400',
    title: 'text-yellow-800 dark:text-yellow-200',
    message: 'text-yellow-700 dark:text-yellow-300',
    button: 'bg-yellow-600 hover:bg-yellow-700 text-white',
    Icon: ExclamationTriangleIcon,
  },
  error: {
    container: 'bg-red-50 border-red-200 dark:bg-red-900/20 dark:border-red-800',
    icon: 'text-red-600 dark:text-red-400',
    title: 'text-red-800 dark:text-red-200',
    message: 'text-red-700 dark:text-red-300',
    button: 'bg-red-600 hover:bg-red-700 text-white',
    Icon: XCircleIcon,
  },
  info: {
    container: 'bg-blue-50 border-blue-200 dark:bg-blue-900/20 dark:border-blue-800',
    icon: 'text-blue-600 dark:text-blue-400',
    title: 'text-blue-800 dark:text-blue-200',
    message: 'text-blue-700 dark:text-blue-300',
    button: 'bg-blue-600 hover:bg-blue-700 text-white',
    Icon: InformationCircleIcon,
  },
};

export const AlertBanner: React.FC<AlertBannerProps> = ({
  variant,
  title,
  message,
  actionLabel,
  actionTo,
  onAction,
  onDismiss,
  dismissible = false,
  className = '',
}) => {
  const styles = variantStyles[variant];
  const IconComponent = styles.Icon;

  const handleAction = () => {
    if (onAction) {
      onAction();
    }
  };

  return (
    <div
      className={`border rounded-lg p-4 ${styles.container} ${className}`}
      role="alert"
    >
      <div className="flex items-start gap-3">
        {/* Icon */}
        <div className="flex-shrink-0">
          <IconComponent className={`h-6 w-6 ${styles.icon}`} />
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0">
          {title && (
            <h3 className={`text-sm font-semibold mb-1 ${styles.title}`}>
              {title}
            </h3>
          )}
          <p className={`text-sm ${styles.message}`}>{message}</p>

          {/* Action Button */}
          {(actionLabel && (actionTo || onAction)) && (
            <div className="mt-3">
              {actionTo ? (
                <Link
                  to={actionTo}
                  className={`inline-block px-4 py-2 rounded text-sm font-medium ${styles.button}`}
                >
                  {actionLabel}
                </Link>
              ) : (
                <button
                  onClick={handleAction}
                  className={`inline-block px-4 py-2 rounded text-sm font-medium ${styles.button}`}
                >
                  {actionLabel}
                </button>
              )}
            </div>
          )}
        </div>

        {/* Dismiss Button */}
        {dismissible && onDismiss && (
          <button
            onClick={onDismiss}
            className={`flex-shrink-0 ${styles.icon} hover:opacity-70`}
            aria-label="Cerrar alerta"
          >
            <XMarkIcon className="h-5 w-5" />
          </button>
        )}
      </div>
    </div>
  );
};

export default AlertBanner;
