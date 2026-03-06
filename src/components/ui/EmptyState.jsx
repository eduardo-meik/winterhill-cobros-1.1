import clsx from 'clsx';

/**
 * Reusable empty-state placeholder for tables, lists, and search results.
 *
 * @param {string}  title       – Main heading (e.g. "Sin resultados")
 * @param {string}  description – Optional secondary text
 * @param {React.ReactNode} icon – Optional icon element
 * @param {React.ReactNode} action – Optional CTA button / link
 * @param {string}  className   – Extra wrapper classes
 */
export function EmptyState({ title = 'Sin datos', description, icon, action, className }) {
  return (
    <div className={clsx('flex flex-col items-center justify-center py-12 text-center', className)}>
      {icon && <div className="mb-3 text-gray-300 dark:text-gray-600">{icon}</div>}
      <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100">{title}</h3>
      {description && (
        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{description}</p>
      )}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}
