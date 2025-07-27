import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './contexts/AuthContext';
import { ProtectedRoute } from './components/auth/ProtectedRoute';
import { LoginPage } from './pages/auth/LoginPage';
import { RegisterPage } from './pages/auth/RegisterPage';
import { ForgotPasswordPage } from './pages/auth/ForgotPasswordPage';
import { ResetPasswordPage } from './pages/auth/ResetPasswordPage';
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

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Public routes that do not require authentication */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />
          <Route path="/forgot-password" element={<ForgotPasswordPage />} />
          <Route path="/reset-password" element={<ResetPasswordPage />} />
          <Route path="/auth/callback" element={<AuthCallbackPage />} />

          {/* Protected routes that require authentication */}
          <Route path="/" element={<ProtectedRoute><MainLayout /></ProtectedRoute>}>
            {/* Redirect from root to dashboard */}
            <Route index element={<Navigate to="/dashboard" replace />} />

            {/* Main application routes */}
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="students" element={<StudentsPage />} />
            <Route path="guardians"Element={<GuardiansPage />} />
            <Route path="payments" element={<PaymentsPage />} />
            <Route path="reporting" element={<ReportingPage />} />
            <Route path="assistant" element={<AssistantPage />} />
            <Route path="profile" element={<ProfilePage />} />
            <Route path="settings" element={<SettingsPage />} />
          </Route>
        </Routes>
        <Toaster position="top-right" />
      </AuthProvider>
    </BrowserRouter>
  );
}