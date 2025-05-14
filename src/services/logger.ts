import { LogEntry, LogCode } from '../types/logging';
import { supabase } from './supabase';

class Logger {
  private static instance: Logger;
  private readonly MAX_RETRIES = 3;
  private readonly RETRY_DELAY = 1000;

  private constructor() {}

  public static getInstance(): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger();
    }
    return Logger.instance;
  }

  private async persistLog(entry: LogEntry): Promise<void> {
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

      if (error) throw error;
    } catch (error) {
      console.error('Failed to persist log:', error);
      // En producción, aquí podríamos enviar el error a un servicio de monitoreo
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

    // Log to console in development
    if (import.meta.env.DEV) {
      console.log(this.formatMessage(entry));
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
    const actionableSteps: Record<LogCode, string> = {
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