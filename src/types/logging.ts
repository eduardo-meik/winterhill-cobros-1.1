export interface LogEntry {
  timestamp: string;
  code: string;
  userId?: string;
  message: string;
  action?: string;
  metadata?: Record<string, any>;
}

export enum LogCode {
  // Auth Events
  AUTH_SIGNUP_SUCCESS = 'AUTH001',
  AUTH_SIGNUP_FAILED = 'AUTH002',
  AUTH_LOGIN_SUCCESS = 'AUTH003',
  AUTH_LOGIN_FAILED = 'AUTH004',
  AUTH_LOGOUT = 'AUTH005',
  AUTH_PASSWORD_RESET_REQUEST = 'AUTH006',
  AUTH_PASSWORD_RESET_SUCCESS = 'AUTH007',
  AUTH_PASSWORD_RESET_FAILED = 'AUTH008',
  
  // Validation Errors
  VALIDATION_PASSWORD = 'VAL001',
  VALIDATION_EMAIL = 'VAL002',
  
  // Security Events
  SECURITY_ACCOUNT_LOCKED = 'SEC001',
  SECURITY_RATE_LIMIT = 'SEC002',
  SECURITY_SESSION_EXPIRED = 'SEC003',
  
  // Email Verification
  EMAIL_VERIFICATION_SENT = 'EMAIL001',
  EMAIL_VERIFICATION_SUCCESS = 'EMAIL002',
  EMAIL_VERIFICATION_FAILED = 'EMAIL003'
}