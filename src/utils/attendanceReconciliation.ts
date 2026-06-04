import { differenceInMinutes, max, min } from 'date-fns';

type TipoMarca = 'entrada' | 'salida';

export interface MarcaAsistencia {
  tipoMarca: TipoMarca;
  fechaHoraMarca: Date;
}

export interface BloquePlanificado {
  inicioPlanificado: Date;
  finPlanificado: Date;
}

export type EstadoConciliacion =
  | 'cumplimiento'
  | 'atraso'
  | 'salida_anticipada'
  | 'incompleto'
  | 'sin_horario';

export interface ResultadoConciliacion {
  minutosPlanificados: number;
  minutosEfectivos: number;
  minutosAtraso: number;
  minutosSalidaAnticipada: number;
  estado: EstadoConciliacion;
}

export function reconcileDayAttendance(
  bloque: BloquePlanificado | null,
  marcas: MarcaAsistencia[],
  toleranciaMinutos = 1,
): ResultadoConciliacion {
  if (!bloque) {
    return {
      minutosPlanificados: 0,
      minutosEfectivos: 0,
      minutosAtraso: 0,
      minutosSalidaAnticipada: 0,
      estado: 'sin_horario',
    };
  }

  const entradas = marcas
    .filter((marca) => marca.tipoMarca === 'entrada')
    .map((marca) => marca.fechaHoraMarca);
  const salidas = marcas
    .filter((marca) => marca.tipoMarca === 'salida')
    .map((marca) => marca.fechaHoraMarca);

  const minutosPlanificados = Math.max(0, differenceInMinutes(bloque.finPlanificado, bloque.inicioPlanificado));

  if (entradas.length === 0 || salidas.length === 0) {
    return {
      minutosPlanificados,
      minutosEfectivos: 0,
      minutosAtraso: 0,
      minutosSalidaAnticipada: 0,
      estado: 'incompleto',
    };
  }

  const primeraEntrada = min(entradas);
  const ultimaSalida = max(salidas);

  if (ultimaSalida <= primeraEntrada) {
    return {
      minutosPlanificados,
      minutosEfectivos: 0,
      minutosAtraso: 0,
      minutosSalidaAnticipada: 0,
      estado: 'incompleto',
    };
  }

  const minutosEfectivos = Math.max(0, differenceInMinutes(ultimaSalida, primeraEntrada));
  const atrasoRaw = Math.max(0, differenceInMinutes(primeraEntrada, bloque.inicioPlanificado));
  const salidaRaw = Math.max(0, differenceInMinutes(bloque.finPlanificado, ultimaSalida));

  const minutosAtraso = Math.max(0, atrasoRaw - toleranciaMinutos);
  const minutosSalidaAnticipada = Math.max(0, salidaRaw - toleranciaMinutos);

  const estado: EstadoConciliacion =
    minutosAtraso > 0
      ? 'atraso'
      : minutosSalidaAnticipada > 0
      ? 'salida_anticipada'
      : 'cumplimiento';

  return {
    minutosPlanificados,
    minutosEfectivos,
    minutosAtraso,
    minutosSalidaAnticipada,
    estado,
  };
}
