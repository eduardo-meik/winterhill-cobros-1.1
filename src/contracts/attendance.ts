import { z } from 'zod';

export const rutDocenteSchema = z
  .string()
  .trim()
  .regex(/^[0-9]{7,8}-[0-9kK]$/, 'RUT docente invalido');

export const horarioBloqueSchema = z
  .object({
    owner_id: z.string().uuid(),
    rutDocente: rutDocenteSchema,
    bloqueFecha: z.string().date(),
    horaInicio: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Hora inicio invalida'),
    horaFin: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Hora fin invalida'),
    salaId: z.string().uuid().nullable().optional(),
    cursoId: z.string().uuid().nullable().optional(),
    asignatura: z.string().trim().min(1).max(120).optional(),
  })
  .superRefine((value, ctx) => {
    if (value.horaInicio >= value.horaFin) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['horaFin'],
        message: 'horaFin debe ser mayor a horaInicio',
      });
    }
  });

export const marcaAsistenciaSchema = z.object({
  owner_id: z.string().uuid(),
  rutDocente: rutDocenteSchema,
  fechaHoraMarca: z.coerce.date(),
  tipoMarca: z.enum(['entrada', 'salida']),
  fuente: z.string().trim().min(1).max(100).default('reloj_control'),
  archivoOrigen: z.string().trim().min(1).max(255).optional(),
});

export const conciliacionRequestSchema = z.object({
  owner_id: z.string().uuid(),
  rutDocente: rutDocenteSchema,
  fecha: z.string().date(),
  toleranciaMinutos: z.number().int().min(0).default(1),
});

export type HorarioBloqueInput = z.infer<typeof horarioBloqueSchema>;
export type MarcaAsistenciaInput = z.infer<typeof marcaAsistenciaSchema>;
export type ConciliacionRequestInput = z.infer<typeof conciliacionRequestSchema>;
