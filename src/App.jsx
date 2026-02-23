import React, { Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './contexts/AuthContext';
import { GuardianProvider } from './contexts/GuardianContext';
import { ProtectedRoute } from './components/auth/ProtectedRoute';
import { StaffRoute } from './components/auth/StaffRoute';
import { LoginPage } from './pages/auth/LoginPage';
import { RegisterPage } from './pages/auth/RegisterPage';
import { GuardianRegisterPage } from './pages/auth/GuardianRegisterPage';
import { ForgotPasswordPage } from './pages/auth/ForgotPasswordPage';
import { ResetPasswordPage } from './pages/auth/ResetPasswordPage';
import { GuardianClaimPage } from './pages/auth/GuardianClaimPage';
import { GuardianAcceptInvitePage } from './pages/auth/GuardianAcceptInvitePage';
import { AuthCallbackPage } from './pages/auth/AuthCallbackPage';
import { MainLayout } from './components/layouts/MainLayout';
import { useAuth } from './contexts/AuthContext';

// Lazy-loaded route components — each becomes its own chunk
const Dashboard = React.lazy(() => import('./components/Dashboard'));
const StudentsPage = React.lazy(() => import('./components/students/StudentsPage').then(m => ({ default: m.StudentsPage })));
const GuardiansPage = React.lazy(() => import('./components/guardians/GuardiansPage').then(m => ({ default: m.GuardiansPage })));
const PaymentsPage = React.lazy(() => import('./components/payments/PaymentsPage').then(m => ({ default: m.PaymentsPage })));
const ReportingPage = React.lazy(() => import('./components/reporting/ReportingPage.jsx').then(m => ({ default: m.ReportingPage })));
const AssistantPage = React.lazy(() => import('./components/assistant/AssistantPage').then(m => ({ default: m.AssistantPage })));
const ProfilePage = React.lazy(() => import('./components/profile/ProfilePage').then(m => ({ default: m.ProfilePage })));
const SettingsPage = React.lazy(() => import('./components/settings/SettingsPage').then(m => ({ default: m.SettingsPage })));
const MatriculaWizard = React.lazy(() => import('./components/matricula/MatriculaWizard').then(m => ({ default: m.MatriculaWizard })));
const GuardianIntakePage = React.lazy(() => import('./pages/guardian/GuardianIntakePage').then(m => ({ default: m.GuardianIntakePage })));
const RepactacionWizard = React.lazy(() => import('./components/repactacion/RepactacionWizard'));
const GuardianWelcomePage = React.lazy(() => import('./pages/guardian/GuardianWelcomePage').then(m => ({ default: m.GuardianWelcomePage })));
const GuardianPortalPage = React.lazy(() => import('./pages/guardian/GuardianPortalPage'));
const GuardianEnrollmentPage = React.lazy(() => import('./pages/guardian/GuardianEnrollmentPage'));

// Shared loading fallback
const PageSpinner = () => (
  <div className="flex h-full items-center justify-center py-20">
    <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary" />
  </div>
);

// Dynamic root redirect based on role
export function RootRedirect() {
  const { user, loading } = useAuth();
  if (loading) {
    return (
      <div className="flex h-full items-center justify-center py-20">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary" />
      </div>
    );
  }
  const role = (user?.role ?? 'guardian').toLowerCase();
  if (role === 'guardian') return <Navigate to="/apoderado/bienvenido" replace />;
  return <Navigate to="/dashboard" replace />;
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Public routes that do not require authentication */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/registro-apoderado" element={<GuardianClaimPage />} />
          <Route path="/registro-apoderado/nuevo" element={<GuardianRegisterPage />} />
          <Route path="/apoderado/aceptar" element={<GuardianAcceptInvitePage />} />
          <Route path="/forgot-password" element={<ForgotPasswordPage />} />
          <Route path="/reset-password" element={<ResetPasswordPage />} />
          <Route path="/auth/callback" element={<AuthCallbackPage />} />

          {/* Protected routes that require authentication */}
          <Route
            path="/"
            element={(
              <ProtectedRoute>
                <GuardianProvider>
                  <MainLayout />
                </GuardianProvider>
              </ProtectedRoute>
            )}
          >
            {/* Root redirect: guardian -> bienvenida, others -> dashboard */}
            <Route index element={<RootRedirect />} />

            {/* Main application routes — lazy loaded */}
            <Route
              path="dashboard"
              element={(
                <StaffRoute>
                  <Suspense fallback={<PageSpinner />}><Dashboard /></Suspense>
                </StaffRoute>
              )}
            />
            <Route
              path="students"
              element={(
                <StaffRoute>
                  <Suspense fallback={<PageSpinner />}><StudentsPage /></Suspense>
                </StaffRoute>
              )}
            />
            <Route
              path="guardians"
              element={(
                <StaffRoute>
                  <Suspense fallback={<PageSpinner />}><GuardiansPage /></Suspense>
                </StaffRoute>
              )}
            />
            <Route
              path="payments"
              element={(
                <StaffRoute>
                  <Suspense fallback={<PageSpinner />}><PaymentsPage /></Suspense>
                </StaffRoute>
              )}
            />
            <Route
              path="reporting"
              element={(
                <StaffRoute>
                  <Suspense fallback={<PageSpinner />}><ReportingPage /></Suspense>
                </StaffRoute>
              )}
            />
            <Route
              path="assistant"
              element={(
                <StaffRoute>
                  <Suspense fallback={<PageSpinner />}><AssistantPage /></Suspense>
                </StaffRoute>
              )}
            />
            <Route path="profile" element={<Suspense fallback={<PageSpinner />}><ProfilePage /></Suspense>} />
            <Route path="settings" element={<Suspense fallback={<PageSpinner />}><SettingsPage /></Suspense>} />
            <Route path="matricula" element={<StaffRoute><Suspense fallback={<PageSpinner />}><MatriculaWizard /></Suspense></StaffRoute>} />
            <Route path="repactacion" element={<StaffRoute><Suspense fallback={<PageSpinner />}><RepactacionWizard /></Suspense></StaffRoute>} />
            <Route path="apoderado/encuesta" element={<Suspense fallback={<PageSpinner />}><GuardianIntakePage /></Suspense>} />
            <Route path="apoderado/bienvenido" element={<Suspense fallback={<PageSpinner />}><GuardianWelcomePage /></Suspense>} />
            <Route path="apoderado/portal" element={<Suspense fallback={<PageSpinner />}><GuardianPortalPage /></Suspense>} />
            <Route path="apoderado/matricula" element={<Suspense fallback={<PageSpinner />}><GuardianEnrollmentPage /></Suspense>} />
          </Route>
        </Routes>
        <Toaster position="top-right" />
      </AuthProvider>
    </BrowserRouter>
  );
}