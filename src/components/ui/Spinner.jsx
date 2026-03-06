import clsx from 'clsx';

const SIZES = {
  sm: 'h-5 w-5',
  md: 'h-8 w-8',
  lg: 'h-10 w-10',
};

export function Spinner({ size = 'md', className }) {
  return (
    <div
      className={clsx(
        'animate-spin rounded-full border-t-2 border-b-2 border-primary',
        SIZES[size] || SIZES.md,
        className
      )}
      role="status"
      aria-label="Cargando"
    />
  );
}

export function PageSpinner() {
  return (
    <div className="flex h-full items-center justify-center py-20">
      <Spinner size="lg" />
    </div>
  );
}
