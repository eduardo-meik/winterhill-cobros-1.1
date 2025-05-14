import React, { useState, useEffect } from 'react';
import { Card, CardHeader, CardContent } from '../ui/Card';
import { Button } from '../ui/Button';
import { useForm } from 'react-hook-form';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../services/supabase';
import toast from 'react-hot-toast';
import { format } from 'date-fns';

export function ProfilePage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [profile, setProfile] = useState(null);
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isChangingPassword, setIsChangingPassword] = useState(false);

  const { register, handleSubmit, formState: { errors }, reset, watch } = useForm();
  const newPassword = watch('newPassword');

  useEffect(() => {
    if (user) {
      fetchProfile();
    }
  }, [user]);

  const fetchProfile = async () => {
    try {
      setLoading(true);
      
      // Use RPC function instead of direct query to bypass RLS policies
      const { data, error } = await supabase.rpc('get_user_profile', {
        user_id: user.id
      });

      if (error) throw error;
      setProfile(data || { first_name: '', last_name: '', email: user.email });
    } catch (error) {
      console.error('Error fetching profile:', error);
      toast.error('Error al cargar el perfil');
      // Set a default profile to prevent null errors
      setProfile({ first_name: '', last_name: '', email: user.email });
    } finally {
      setLoading(false);
    }
  };

  const onSubmit = async (data) => {
    try {
      setIsSaving(true);
      
      // Ensure all required fields are present
      const updateData = {
        id: user.id,
        first_name: data.first_name || '',
        last_name: data.last_name || '',
        phone: data.phone || '',
        email: user.email,
        updated_at: new Date().toISOString()
      };

      const { error } = await supabase
        .from('profiles')
        .upsert(updateData);

      if (error) throw error;

      setProfile(prev => ({
        ...prev,
        ...updateData
      }));

      toast.success('Perfil actualizado exitosamente');
      setIsEditing(false);
    } catch (error) {
      console.error('Error updating profile:', error);
      toast.error('Error al actualizar el perfil');
    } finally {
      setIsSaving(false);
    }
  };

  const handlePasswordChange = async (data) => {
    try {
      setIsSaving(true);

      const { error } = await supabase.auth.updateUser({
        password: data.newPassword
      });

      if (error) throw error;

      toast.success('Contraseña actualizada exitosamente');
      setIsChangingPassword(false);
      reset({ newPassword: '', confirmPassword: '' });
    } catch (error) {
      console.error('Error changing password:', error);
      toast.error('Error al cambiar la contraseña');
    } finally {
      setIsSaving(false);
    }
  };

  if (loading) {
    return (
      <main className="flex-1 min-w-0 overflow-auto">
        <div className="max-w-[1440px] mx-auto p-4">
          <div className="flex items-center justify-center h-[calc(100vh-8rem)]">
            <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary"></div>
          </div>
        </div>
      </main>
    );
  }

  if (!user) {
    return (
      <main className="flex-1 min-w-0 overflow-auto">
        <div className="max-w-[1440px] mx-auto p-4">
          <div className="flex items-center justify-center h-[calc(100vh-8rem)]">
            <p className="text-gray-500">Por favor inicia sesión para ver tu perfil</p>
          </div>
        </div>
      </main>
    );
  }

  const displayName = profile?.full_name || 
    `${profile?.first_name || ''} ${profile?.last_name || ''}`.trim() || 
    user?.email?.split('@')[0] || 
    'Usuario';

  return (
    <main className="flex-1 min-w-0 overflow-auto">
      <div className="max-w-[1440px] mx-auto animate-fade-in">
        <div className="flex flex-wrap justify-between gap-3 p-4">
          <h1 className="text-gray-900 dark:text-white text-2xl md:text-3xl font-bold">Mi Perfil</h1>
        </div>

        <div className="p-4">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            {/* Profile Overview Card */}
            <Card className="lg:col-span-2">
              <CardHeader>
                {/* Corrected header structure */}
                <div className="flex items-center"> {/* Removed w-full, it wasn't needed here */}
                  <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Información del Perfil</h2>
                  <Button
                    variant={isEditing ? 'secondary' : 'primary'}
                    onClick={() => {
                      if (isEditing) {
                        reset(profile); // Reset form to original profile data when cancelling
                      } else {
                        reset(profile); // Ensure form is populated with current data when starting edit
                      }
                      setIsEditing(!isEditing);
                    }}
                    className="ml-auto" // This pushes the button to the right
                  >
                    {isEditing ? 'Cancelar' : 'Editar Perfil'}
                  </Button>
                </div>
              </CardHeader>
              {/* Added CardContent for profile details/form */}
              <CardContent>
                {isEditing ? (
                  <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Nombre</label>
                        <input
                          type="text"
                          {...register('first_name')}
                          defaultValue={profile?.first_name || ''}
                          className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Apellido</label>
                        <input
                          type="text"
                          {...register('last_name')}
                          defaultValue={profile?.last_name || ''}
                          className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Teléfono</label>
                        <input
                          type="tel"
                          {...register('phone')}
                          defaultValue={profile?.phone || ''}
                          className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Email</label>
                        <input
                          type="email"
                          value={user?.email || ''}
                          disabled
                          className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-gray-100 dark:bg-dark-card text-gray-500 dark:text-gray-400 cursor-not-allowed"
                        />
                      </div>
                    </div>
                    <div className="flex justify-end gap-3 pt-4">
                      <Button type="submit" disabled={isSaving}>
                        {isSaving ? 'Guardando...' : 'Guardar Cambios'}
                      </Button>
                    </div>
                  </form>
                ) : (
                  <div className="space-y-3">
                    <p><span className="font-medium text-gray-700 dark:text-gray-300">Nombre:</span> {profile?.first_name || '-'}</p>
                    <p><span className="font-medium text-gray-700 dark:text-gray-300">Apellido:</span> {profile?.last_name || '-'}</p>
                    <p><span className="font-medium text-gray-700 dark:text-gray-300">Email:</span> {user?.email || '-'}</p>
                    <p><span className="font-medium text-gray-700 dark:text-gray-300">Teléfono:</span> {profile?.phone || '-'}</p>
                    <p><span className="font-medium text-gray-700 dark:text-gray-300">Miembro desde:</span> {user?.created_at ? format(new Date(user.created_at), 'dd/MM/yyyy') : '-'}</p>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Security Card */}
            <Card>
              <CardHeader>
                <h2 className="text-gray-900 dark:text-white text-lg font-semibold">Seguridad</h2>
              </CardHeader>
              <CardContent>
                {isChangingPassword ? (
                  <form onSubmit={handleSubmit(handlePasswordChange)} className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Nueva Contraseña
                      </label>
                      <input
                        type="password"
                        {...register('newPassword', {
                          required: 'Este campo es requerido',
                          minLength: {
                            value: 8,
                            message: 'La contraseña debe tener al menos 8 caracteres'
                          },
                          pattern: {
                            value: /^(?=.*[A-Z])(?=.*\d)/,
                            message: 'La contraseña debe contener al menos una mayúscula y un número'
                          }
                        })}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                      {errors.newPassword && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.newPassword.message}</p>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                        Confirmar Nueva Contraseña
                      </label>
                      <input
                        type="password"
                        {...register('confirmPassword', {
                          required: 'Este campo es requerido',
                          validate: value => value === newPassword || 'Las contraseñas no coinciden'
                        })}
                        className="w-full px-4 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-dark-hover text-gray-900 dark:text-white focus:ring-2 focus:ring-primary/20 focus:border-primary"
                      />
                      {errors.confirmPassword && (
                        <p className="mt-1 text-sm text-red-600 dark:text-red-400">{errors.confirmPassword.message}</p>
                      )}
                    </div>

                    <div className="flex justify-end gap-3 pt-4">
                      <Button
                        type="button"
                        variant="secondary"
                        onClick={() => setIsChangingPassword(false)}
                      >
                        Cancelar
                      </Button>
                      <Button type="submit" disabled={isSaving}>
                        {isSaving ? 'Guardando...' : 'Cambiar Contraseña'}
                      </Button>
                    </div>
                  </form>
                ) : (
                  <div className="space-y-4">
                    <p className="text-sm text-gray-500 dark:text-gray-400">
                      Gestiona tu contraseña y la seguridad de tu cuenta.
                    </p>
                    <Button
                      onClick={() => setIsChangingPassword(true)}
                      className="w-full"
                    >
                      Cambiar Contraseña
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </main>
  );
}