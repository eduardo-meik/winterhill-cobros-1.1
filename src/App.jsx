import React, { Suspense } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './contexts/AuthContext';
import { GuardianProvider } from './contexts/GuardianContext';
import { AcademicYearProvider } from './contexts/AcademicYearContext';
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
import { PageSpinner } from './components/ui/Spinner';
import { ErrorBoundary } from './components/ui/ErrorBoundary';
import { isGuardianRole } from './constants/roles';
import { lazyWithRetry } from './utils/lazyWithRetry';

// Lazy-loaded route components — each becomes its own chunk
const Dashboard = lazyWithRetry(() => import('./components/Dashboard'), 'dashboard');
const StudentsPage = lazyWithRetry(() => import('./components/students/StudentsPage').then(m => ({ default: m.StudentsPage })), 'students');
const GuardiansPage = lazyWithRetry(() => import('./components/guardians/GuardiansPage').then(m => ({ default: m.GuardiansPage })), 'guardians');
const PaymentsPage = lazyWithRetry(() => import('./components/payments/PaymentsPage').then(m => ({ default: m.PaymentsPage })), 'payments');
const ReportingPage = lazyWithRetry(() => import('./components/reporting/ReportingPage.jsx').then(m => ({ default: m.ReportingPage })), 'reporting');
const AttendanceReportPage = lazyWithRetry(() => import('./components/reporting/AttendanceReportPage.jsx').then(m => ({ default: m.AttendanceReportPage })), 'attendance-report');
const SchedulingBoardPage = lazyWithRetry(() => import('./components/scheduling/SchedulingBoardPage.jsx').then(m => ({ default: m.SchedulingBoardPage })), 'scheduling-board');
const AssistantPage = lazyWithRetry(() => import('./components/assistant/AssistantPage').then(m => ({ default: m.AssistantPage })), 'assistant');
const ProfilePage = lazyWithRetry(() => import('./components/profile/ProfilePage').then(m => ({ default: m.ProfilePage })), 'profile');
const SettingsPage = lazyWithRetry(() => import('./components/settings/SettingsPage').then(m => ({ default: m.SettingsPage })), 'settings');
const MatriculaWizard = lazyWithRetry(() => import('./components/matricula/MatriculaWizard').then(m => ({ default: m.MatriculaWizard })), 'matricula');
const GuardianIntakePage = lazyWithRetry(() => import('./pages/guardian/GuardianIntakePage').then(m => ({ default: m.GuardianIntakePage })), 'guardian-intake');
const RepactacionWizard = lazyWithRetry(() => import('./components/repactacion/RepactacionWizard'), 'repactacion');
const PromotionTool = lazyWithRetry(() => import('./components/promotion/PromotionTool'), 'promocion');
const GuardianWelcomePage = lazyWithRetry(() => import('./pages/guardian/GuardianWelcomePage').then(m => ({ default: m.GuardianWelcomePage })), 'guardian-welcome');
const GuardianPortalPage = lazyWithRetry(() => import('./pages/guardian/GuardianPortalPage'), 'guardian-portal');
const GuardianEnrollmentPage = lazyWithRetry(() => import('./pages/guardian/GuardianEnrollmentPage'), 'guardian-enrollment');

// Dynamic root redirect based on role
export function RootRedirect() {
  const { user, loading } = useAuth();
  if (loading) {
    return <PageSpinner />;
  }
  if (isGuardianRole(user?.role)) return <Navigate to="/apoderado/bienvenido" replace />;
  return <Navigate to="/dashboard" replace />;
}

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 2 * 60 * 1000,  // 2 minutes before data is considered stale
      gcTime: 10 * 60 * 1000,    // 10 minutes before unused cache is garbage-collected
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

export default function App() {
  return (
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
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
                <AcademicYearProvider>
                  <GuardianProvider>
                    <MainLayout />
                  </GuardianProvider>
                </AcademicYearProvider>
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
                  <ErrorBoundary><Suspense fallback={<PageSpinner />}><Dashboard /></Suspense></ErrorBoundary>
                </StaffRoute>
              )}
            />
            <Route
              path="students"
              element={(
                <StaffRoute>
                  <ErrorBoundary><Suspense fallback={<PageSpinner />}><StudentsPage /></Suspense></ErrorBoundary>
                </StaffRoute>
              )}
            />
            <Route
              path="guardians"
              element={(
                <StaffRoute>
                  <ErrorBoundary><Suspense fallback={<PageSpinner />}><GuardiansPage /></Suspense></ErrorBoundary>
                </StaffRoute>
              )}
            />
            <Route
              path="payments"
              element={(
                <StaffRoute>
                  <ErrorBoundary><Suspense fallback={<PageSpinner />}><PaymentsPage /></Suspense></ErrorBoundary>
                </StaffRoute>
              )}
            />
            <Route
              path="reporting"
              element={(
                <StaffRoute>
                  <ErrorBoundary><Suspense fallback={<PageSpinner />}><ReportingPage /></Suspense></ErrorBoundary>
                </StaffRoute>
              )}
            />
            <Route
              path="attendance-report"
              element={(
                <StaffRoute>
                  <ErrorBoundary><Suspense fallback={<PageSpinner />}><AttendanceReportPage /></Suspense></ErrorBoundary>
                </StaffRoute>
              )}
            />
            <Route
              path="scheduling"
              element={(
                <StaffRoute>
                  <ErrorBoundary><Suspense fallback={<PageSpinner />}><SchedulingBoardPage /></Suspense></ErrorBoundary>
                </StaffRoute>
              )}
            />
            <Route
              path="assistant"
              element={(
                <StaffRoute>
                  <ErrorBoundary><Suspense fallback={<PageSpinner />}><AssistantPage /></Suspense></ErrorBoundary>
                </StaffRoute>
              )}
            />
            <Route path="profile" element={<ErrorBoundary><Suspense fallback={<PageSpinner />}><ProfilePage /></Suspense></ErrorBoundary>} />
            <Route path="settings" element={<ErrorBoundary><Suspense fallback={<PageSpinner />}><SettingsPage /></Suspense></ErrorBoundary>} />
            <Route path="matricula" element={<StaffRoute><ErrorBoundary><Suspense fallback={<PageSpinner />}><MatriculaWizard /></Suspense></ErrorBoundary></StaffRoute>} />
            <Route path="promocion" element={<StaffRoute><ErrorBoundary><Suspense fallback={<PageSpinner />}><PromotionTool /></Suspense></ErrorBoundary></StaffRoute>} />
            <Route path="repactacion" element={<StaffRoute><ErrorBoundary><Suspense fallback={<PageSpinner />}><RepactacionWizard /></Suspense></ErrorBoundary></StaffRoute>} />
            <Route path="apoderado/encuesta" element={<ErrorBoundary><Suspense fallback={<PageSpinner />}><GuardianIntakePage /></Suspense></ErrorBoundary>} />
            <Route path="apoderado/bienvenido" element={<ErrorBoundary><Suspense fallback={<PageSpinner />}><GuardianWelcomePage /></Suspense></ErrorBoundary>} />
            <Route path="apoderado/portal" element={<ErrorBoundary><Suspense fallback={<PageSpinner />}><GuardianPortalPage /></Suspense></ErrorBoundary>} />
            <Route path="apoderado/matricula" element={<ErrorBoundary><Suspense fallback={<PageSpinner />}><GuardianEnrollmentPage /></Suspense></ErrorBoundary>} />
          </Route>
        </Routes>
        <Toaster position="top-right" />
      </AuthProvider>
      </QueryClientProvider>
    </BrowserRouter>
  );
}