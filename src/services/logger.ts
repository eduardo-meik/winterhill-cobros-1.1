import { LogEntry, LogCode } from '../types/logging';
import { supabase } from './supabase';

class Logger {
  private static instance: Logger;
  private readonly MAX_RETRIES = 3;
  private readonly RETRY_DELAY = 1000;
  private readonly remoteLoggingEnabled: boolean;
  private remoteLoggingDisabled = false;

  private constructor() {
    this.remoteLoggingEnabled = Logger.resolveRemoteLoggingFlag();
  }

  public static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  private static resolveRemoteLoggingFlag(): boolean {
    // Remote persistence is opt-in via VITE_ENABLE_REMOTE_LOGGING to avoid unauthorized writes on client sessions.
    try {
      const flag = (typeof import.meta !== 'undefined' && (import.meta as any)?.env?.VITE_ENABLE_REMOTE_LOGGING) ?? undefined;
      if (flag !== undefined) {
        return String(flag).toLowerCase() === 'true';
      }
    } catch {/* ignore */}

    try {
      const flag = typeof process !== 'undefined' ? process.env?.VITE_ENABLE_REMOTE_LOGGING : undefined;
      if (flag !== undefined) {
        return String(flag).toLowerCase() === 'true';
      }
    } catch {/* ignore */}

    return false;
  }

  private shouldDisableRemoteLogging(error: unknown): boolean {
    if (!error) return false;
    const status = (error as any)?.status ?? (error as any)?.code;
    const message = typeof (error as any)?.message === 'string' ? (error as any).message.toLowerCase() : '';
    if (status === 401 || status === '401' || status === 'PGRST401') return true;
    if (status === '42501') return true;
    if (message.includes('permission denied') || message.includes('not authorized') || message.includes('unauthorized')) {
      return true;
    }
    return false;
  }

  private async persistLog(entry: LogEntry): Promise<void> {
    if (!this.remoteLoggingEnabled || this.remoteLoggingDisabled) {
      return;
    }

    try {
      const { error } = await supabase
        .from('auth_logs') 
        .insert([{
          code: entry.code,
          user_id: entry.userId,
          message: entry.message,
          action: entry.action,
          metadata: entry.metadata
        }]);

      if (error) {
        if (this.shouldDisableRemoteLogging(error)) {
          this.remoteLoggingDisabled = true;
          return;
        }
        throw error;
      }
    } catch (error) {
      if (this.shouldDisableRemoteLogging(error)) {
        this.remoteLoggingDisabled = true;
        return;
      }
      console.error('Failed to persist log:', error);
      // En producción, aquí podríamos enviar el error a un servicio de monitoreo
      throw error;
    }
  }

  private formatMessage(entry: LogEntry): string {
    return `${entry.timestamp} | ${entry.code} | ${entry.userId || 'ANONYMOUS'} | ${entry.message}${entry.action ? ` | ${entry.action}` : ''}`;
  }

  public async log(
    code: LogCode,
    message: string,
    userId?: string,
    action?: string,
    metadata?: Record<string, any>
  ): Promise<void> {
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      code,
      userId,
      message,
      action,
      metadata
    };

    // Log to console in development; guard for test environment where import.meta may not be defined
    if (typeof process !== 'undefined' ? process.env?.NODE_ENV !== 'production' : true) {
      try { console.log(this.formatMessage(entry)); } catch { /* ignore */ }
    }

    // Persist log with retry logic
    let retries = 0;
    while (retries < this.MAX_RETRIES) {
      try {
        await this.persistLog(entry);
        break;
      } catch (error) {
        retries++;
        if (retries === this.MAX_RETRIES) {
          console.error('Failed to persist log after maximum retries');
          break;
        }
        await new Promise(resolve => setTimeout(resolve, this.RETRY_DELAY));
      }
    }
  }

  public getActionableStep(code: LogCode): string {
    const actionableSteps: { [k: string]: string } = {
      [LogCode.AUTH_LOGIN_FAILED]: 'Verifica tus credenciales e intenta nuevamente',
      [LogCode.SECURITY_ACCOUNT_LOCKED]: 'Contacta a soporte para desbloquear tu cuenta',
      [LogCode.VALIDATION_PASSWORD]: 'La contraseña debe tener al menos 8 caracteres, una mayúscula y un número',
      [LogCode.SECURITY_RATE_LIMIT]: 'Espera unos minutos antes de intentar nuevamente',
      [LogCode.SECURITY_SESSION_EXPIRED]: 'Inicia sesión nuevamente',
      [LogCode.EMAIL_VERIFICATION_FAILED]: 'Solicita un nuevo enlace de verificación'
    };
    return actionableSteps[code] || 'Contacta a soporte si el problema persiste';
  }
}

export default Logger