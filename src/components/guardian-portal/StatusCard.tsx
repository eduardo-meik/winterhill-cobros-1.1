import React from 'react';
import { Link } from 'react-router-dom';
import {
  CheckCircleIcon,
  ClockIcon,
  ExclamationTriangleIcon,
  ArrowRightIcon,
} from '@heroicons/react/24/outline';

interface StatusCardProps {
  title: string;
  status: 'completed' | 'pending' | 'warning' | 'error';
  icon?: React.ReactNode;
  description?: string;
  value?: string | number;
  progress?: number; // 0-100
  actionLabel?: string;
  actionTo?: string;
  onAction?: () => void;
  className?: string;
}

const statusStyles = {
  completed: {
    container: 'border-green-200 dark:border-green-800',
    header: 'bg-green-50 dark:bg-green-900/20',
    icon: 'text-green-600 dark:text-green-400',
    value: 'text-green-700 dark:text-green-300',
    progress: 'bg-green-600',
    badge: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
    DefaultIcon: CheckCircleIcon,
  },
  pending: {
    container: 'border-blue-200 dark:border-blue-800',
    header: 'bg-blue-50 dark:bg-blue-900/20',
    icon: 'text-blue-600 dark:text-blue-400',
    value: 'text-blue-700 dark:text-blue-300',
    progress: 'bg-blue-600',
    badge: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
    DefaultIcon: ClockIcon,
  },
  warning: {
    container: 'border-yellow-200 dark:border-yellow-800',
    header: 'bg-yellow-50 dark:bg-yellow-900/20',
    icon: 'text-yellow-600 dark:text-yellow-400',
    value: 'text-yellow-700 dark:text-yellow-300',
    progress: 'bg-yellow-600',
    badge: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300',
    DefaultIcon: ExclamationTriangleIcon,
  },
  error: {
    container: 'border-red-200 dark:border-red-800',
    header: 'bg-red-50 dark:bg-red-900/20',
    icon: 'text-red-600 dark:text-red-400',
    value: 'text-red-700 dark:text-red-300',
    progress: 'bg-red-600',
    badge: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300',
    DefaultIcon: ExclamationTriangleIcon,
  },
};

export const StatusCard: React.FC<StatusCardProps> = ({
  title,
  status,
  icon,
  description,
  value,
  progress,
  actionLabel,
  actionTo,
  onAction,
  className = '',
}) => {
  const styles = statusStyles[status];
  const IconComponent = icon || <styles.DefaultIcon className="h-6 w-6" />;

  return (
    <div
      className={`border rounded-lg overflow-hidden bg-white dark:bg-gray-800 ${styles.container} ${className}`}
    >
      {/* Header */}
      <div className={`px-4 py-3 ${styles.header}`}>
        <div className="flex items-center gap-3">
          <div className={styles.icon}>
            {React.isValidElement(IconComponent) ? IconComponent : IconComponent}
          </div>
          <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
            {title}
          </h3>
        </div>
      </div>

      {/* Content */}
      <div className="p-4">
        {/* Value/Metric */}
        {value !== undefined && (
          <div className={`text-3xl font-bold mb-2 ${styles.value}`}>
            {value}
          </div>
        )}

        {/* Description */}
        {description && (
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
            {description}
          </p>
        )}

        {/* Progress Bar */}
        {progress !== undefined && (
          <div className="mb-3">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs text-gray-500 dark:text-gray-400">
                Progreso
              </span>
              <span className="text-xs font-medium text-gray-700 dark:text-gray-300">
                {Math.round(progress)}%
              </span>
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className={`h-2 rounded-full transition-all duration-300 ${styles.progress}`}
                style={{ width: `${Math.min(100, Math.max(0, progress))}%` }}
              />
            </div>
          </div>
        )}

        {/* Action Button */}
        {(actionLabel && (actionTo || onAction)) && (
          <div className="mt-4">
            {actionTo ? (
              <Link
                to={actionTo}
                className="inline-flex items-center gap-2 text-sm font-medium text-primary hover:text-primary/80"
              >
                {actionLabel}
                <ArrowRightIcon className="h-4 w-4" />
              </Link>
            ) : (
              <button
                onClick={onAction}
                className="inline-flex items-center gap-2 text-sm font-medium text-primary hover:text-primary/80"
              >
                {actionLabel}
                <ArrowRightIcon className="h-4 w-4" />
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default StatusCard;
