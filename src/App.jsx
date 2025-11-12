import React from 'react';
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
import Dashboard from './components/Dashboard';
import { StudentsPage } from './components/students/StudentsPage';
import { GuardiansPage } from './components/guardians/GuardiansPage';
import { PaymentsPage } from './components/payments/PaymentsPage';
import { ReportingPage } from './components/reporting/ReportingPage.jsx';
import { AssistantPage } from './components/assistant/AssistantPage';
import { ProfilePage } from './components/profile/ProfilePage';
import { SettingsPage } from './components/settings/SettingsPage';
import { MatriculaWizard } from './components/matricula/MatriculaWizard';
import { GuardianIntakePage } from './pages/guardian/GuardianIntakePage';
import RepactacionWizard from './components/repactacion/RepactacionWizard';
import { GuardianWelcomePage } from './pages/guardian/GuardianWelcomePage';
import GuardianPortalPage from './pages/guardian/GuardianPortalPage';
import GuardianEnrollmentPage from './pages/guardian/GuardianEnrollmentPage';
import { useAuth } from './contexts/AuthContext';

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

            {/* Main application routes */}
            <Route
              path="dashboard"
              element={(
                <StaffRoute>
                  <Dashboard />
                </StaffRoute>
              )}
            />
            <Route
              path="students"
              element={(
                <StaffRoute>
                  <StudentsPage />
                </StaffRoute>
              )}
            />
            <Route
              path="guardians"
              element={(
                <StaffRoute>
                  <GuardiansPage />
                </StaffRoute>
              )}
            />
            <Route
              path="payments"
              element={(
                <StaffRoute>
                  <PaymentsPage />
                </StaffRoute>
              )}
            />
            <Route
              path="reporting"
              element={(
                <StaffRoute>
                  <ReportingPage />
                </StaffRoute>
              )}
            />
            <Route
              path="assistant"
              element={(
                <StaffRoute>
                  <AssistantPage />
                </StaffRoute>
              )}
            />
            <Route path="profile" element={<ProfilePage />} />
            <Route path="settings" element={<SettingsPage />} />
            <Route path="matricula" element={<MatriculaWizard />} />
            <Route path="repactacion" element={<RepactacionWizard />} />
            <Route path="apoderado/encuesta" element={<GuardianIntakePage />} />
            <Route path="apoderado/bienvenido" element={<GuardianWelcomePage />} />
            <Route path="apoderado/portal" element={<GuardianPortalPage />} />
            <Route path="apoderado/matricula" element={<GuardianEnrollmentPage />} />
          </Route>
        </Routes>
        <Toaster position="top-right" />
      </AuthProvider>
    </BrowserRouter>
  );
}