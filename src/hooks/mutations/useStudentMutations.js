import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../services/supabase';

/**
 * Shared React Query mutation hooks for student operations.
 * Centralises cache invalidation and loading state.
 * Components handle toast messages (they vary per use case).
 * Use `mutateAsync` in components to await the result.
 */
export function useStudentMutations() {
  const queryClient = useQueryClient();

  const invalidateStudents = () =>
    queryClient.invalidateQueries({ queryKey: ['students'] });

  const updateStudent = useMutation({
    mutationFn: async ({ id, data }) => {
      const { error } = await supabase
        .from('students')
        .update(data)
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => invalidateStudents(),
  });

  const deleteStudent = useMutation({
    mutationFn: async (id) => {
      const { error } = await supabase
        .from('students')
        .delete()
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => invalidateStudents(),
  });

  return { updateStudent, deleteStudent };
}
