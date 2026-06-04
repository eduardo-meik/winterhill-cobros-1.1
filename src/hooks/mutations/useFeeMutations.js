import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../services/supabase';

/**
 * Shared React Query mutation hooks for fee (payment) operations.
 * Centralises cache invalidation and loading state.
 * Components handle toast messages (they vary per use case).
 * Use `mutateAsync` in components to await the result.
 */
export function useFeeMutations() {
  const queryClient = useQueryClient();

  const invalidateFees = () =>
    queryClient.invalidateQueries({ queryKey: ['fees'] });

  const updateFee = useMutation({
    mutationFn: async ({ id, data }) => {
      const { error } = await supabase
        .from('fee')
        .update(data)
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => invalidateFees(),
  });

  const deleteFee = useMutation({
    mutationFn: async (id) => {
      const { error } = await supabase
        .from('fee')
        .delete()
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => invalidateFees(),
  });

  return { updateFee, deleteFee };
}
