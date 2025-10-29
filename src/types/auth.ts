export interface User {
  id: string;
  email: string;
  created_at: string;
  updated_at: string;
  role?: string; // role from profiles table (e.g., 'admin', 'guardian')
  profile?: 'ADMIN' | 'ASIST' | 'READONLY'; // new profile field for permissions
}

export interface AuthState {
  user: User | null;
  session: any | null;
  loading: boolean;
}

export interface AuthContextType extends AuthState {
  signUp: (email: string, password: string) => Promise<void>;
  signIn: (email: string, password: string, remember?: boolean) => Promise<void>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
  updatePassword: (password: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  refreshProfileRole: () => Promise<void>; // fetch role from profiles and update state
}