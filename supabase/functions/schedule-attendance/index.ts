import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "npm:zod@3.23.8";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const rutDocenteSchema = z
  .string()
  .trim()
  .regex(/^[0-9]{7,8}-[0-9kK]$/, "RUT docente invalido");

const createHorarioSchema = z
  .object({
    owner_id: z.string().uuid(),
    rut_docente: rutDocenteSchema,
    bloque_fecha: z.string().date(),
    hora_inicio: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
    hora_fin: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/),
    sala_id: z.string().uuid().nullable().optional(),
    curso_id: z.string().uuid().nullable().optional(),
    asignatura: z.string().trim().min(1).max(120).optional(),
  })
  .superRefine((value, ctx) => {
    if (value.hora_inicio >= value.hora_fin) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["hora_fin"],
        message: "hora_fin debe ser mayor a hora_inicio",
      });
    }
  });

const createMarcaSchema = z.object({
  owner_id: z.string().uuid(),
  rut_docente: rutDocenteSchema,
  tipo_marca: z.enum(["entrada", "salida"]),
  archivo_origen: z.string().trim().min(1).max(255).optional(),
  fuente: z.string().trim().min(1).max(100).default("reloj_control"),
  fecha_hora_marca: z.coerce.date().optional(),
  excel_serial: z.number().finite().optional(),
});

const reconcileDaySchema = z.object({
  owner_id: z.string().uuid(),
  rut_docente: rutDocenteSchema,
  fecha: z.string().date(),
  tolerancia_minutos: z.number().int().min(0).default(1),
});

const requestSchema = z.discriminatedUnion("action", [
  z.object({ action: z.literal("create_horario"), payload: createHorarioSchema }),
  z.object({ action: z.literal("create_marca"), payload: createMarcaSchema }),
  z.object({ action: z.literal("reconcile_day"), payload: reconcileDaySchema }),
]);

function excelSerialToDate(serial: number): Date {
  const excelEpochUtcMs = Date.UTC(1899, 11, 30);
  const msPerDay = 24 * 60 * 60 * 1000;
  return new Date(excelEpochUtcMs + Math.round(serial * msPerDay));
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function minutesBetween(start: Date, end: Date): number {
  return Math.max(0, Math.floor((end.getTime() - start.getTime()) / 60000));
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method Not Allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !anonKey || !serviceKey) {
    return jsonResponse({ error: "Configuracion incompleta de Supabase" }, 500);
  }

  const authClient = createClient(supabaseUrl, anonKey, {
    global: {
      headers: {
        Authorization: req.headers.get("Authorization") ?? "",
      },
    },
  });

  const { data: userData, error: authError } = await authClient.auth.getUser();
  if (authError || !userData?.user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let requestBody: unknown;
  try {
    requestBody = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const parsed = requestSchema.safeParse(requestBody);
  if (!parsed.success) {
    return jsonResponse({ error: "Payload invalido", details: parsed.error.flatten() }, 422);
  }

  const adminClient = createClient(supabaseUrl, serviceKey);

  try {
    if (parsed.data.action === "create_horario") {
      const payload = parsed.data.payload;
      const { data, error } = await adminClient
        .from("docentes_horarios")
        .insert(payload)
        .select("id, owner_id, rut_docente, bloque_fecha, hora_inicio, hora_fin, sala_id, curso_id")
        .single();

      if (error) {
        if (error.code === "23P01") {
          return jsonResponse({ error: "Colision de horario detectada", details: error.message }, 409);
        }
        return jsonResponse({ error: "No se pudo crear el bloque horario", details: error.message }, 500);
      }

      return jsonResponse({ data }, 201);
    }

    if (parsed.data.action === "create_marca") {
      const payload = parsed.data.payload;
      const fechaHoraMarca = payload.fecha_hora_marca
        ? payload.fecha_hora_marca
        : payload.excel_serial !== undefined
        ? excelSerialToDate(payload.excel_serial)
        : null;

      if (!fechaHoraMarca) {
        return jsonResponse(
          {
            error: "Debe enviar fecha_hora_marca o excel_serial",
          },
          422,
        );
      }

      const insertPayload = {
        owner_id: payload.owner_id,
        rut_docente: payload.rut_docente,
        tipo_marca: payload.tipo_marca,
        fecha_hora_marca: fechaHoraMarca.toISOString(),
        archivo_origen: payload.archivo_origen,
        fuente: payload.fuente,
      };

      const { data, error } = await adminClient
        .from("asistencia_marcas")
        .insert(insertPayload)
        .select("id, owner_id, rut_docente, tipo_marca, fecha_hora_marca")
        .single();

      if (error) {
        if (error.code === "23505") {
          return jsonResponse({ error: "Marca duplicada", details: error.message }, 409);
        }
        return jsonResponse({ error: "No se pudo registrar la marca", details: error.message }, 500);
      }

      return jsonResponse({ data }, 201);
    }

    const { owner_id, rut_docente, fecha, tolerancia_minutos } = parsed.data.payload;
    const dayStart = `${fecha}T00:00:00.000Z`;
    const dayEnd = `${fecha}T23:59:59.999Z`;

    const [{ data: horarios, error: horariosError }, { data: marcas, error: marcasError }] = await Promise.all([
      adminClient
        .from("docentes_horarios")
        .select("id, bloque_fecha, hora_inicio, hora_fin")
        .eq("owner_id", owner_id)
        .eq("rut_docente", rut_docente)
        .eq("bloque_fecha", fecha)
        .order("hora_inicio", { ascending: true }),
      adminClient
        .from("asistencia_marcas")
        .select("id, tipo_marca, fecha_hora_marca")
        .eq("owner_id", owner_id)
        .eq("rut_docente", rut_docente)
        .gte("fecha_hora_marca", dayStart)
        .lte("fecha_hora_marca", dayEnd)
        .order("fecha_hora_marca", { ascending: true }),
    ]);

    if (horariosError || marcasError) {
      return jsonResponse(
        {
          error: "No se pudo leer data para conciliacion",
          details: horariosError?.message ?? marcasError?.message,
        },
        500,
      );
    }

    const primerHorario = horarios?.[0] ?? null;
    const primeraEntrada = marcas?.find((m) => m.tipo_marca === "entrada") ?? null;
    const ultimaSalida = [...(marcas ?? [])].reverse().find((m) => m.tipo_marca === "salida") ?? null;

    let minutosPlanificados = 0;
    let minutosEfectivos = 0;
    let minutosAtraso = 0;
    let minutosSalidaAnticipada = 0;
    let estado: "cumplimiento" | "atraso" | "salida_anticipada" | "incompleto" | "sin_horario" = "sin_horario";

    if (primerHorario) {
      const inicioPlanificado = new Date(`${fecha}T${primerHorario.hora_inicio}Z`);
      const finPlanificado = new Date(`${fecha}T${primerHorario.hora_fin}Z`);
      minutosPlanificados = minutesBetween(inicioPlanificado, finPlanificado);

      if (!primeraEntrada || !ultimaSalida) {
        estado = "incompleto";
      } else {
        const entrada = new Date(primeraEntrada.fecha_hora_marca);
        const salida = new Date(ultimaSalida.fecha_hora_marca);

        minutosEfectivos = minutesBetween(entrada, salida);
        minutosAtraso = Math.max(0, minutesBetween(inicioPlanificado, entrada) - tolerancia_minutos);
        minutosSalidaAnticipada = Math.max(0, minutesBetween(salida, finPlanificado) - tolerancia_minutos);

        estado =
          minutosAtraso > 0
            ? "atraso"
            : minutosSalidaAnticipada > 0
            ? "salida_anticipada"
            : "cumplimiento";
      }
    }

    const conciliacionPayload = {
      owner_id,
      rut_docente,
      fecha,
      minutos_planificados: minutosPlanificados,
      minutos_efectivos: minutosEfectivos,
      minutos_atraso: minutosAtraso,
      minutos_salida_anticipada: minutosSalidaAnticipada,
      tolerancia_minutos,
      estado,
      detalle: {
        total_horarios: horarios?.length ?? 0,
        total_marcas: marcas?.length ?? 0,
      },
      calculado_en: new Date().toISOString(),
    };

    const { data: conciliacionData, error: conciliacionError } = await adminClient
      .from("asistencia_conciliacion")
      .upsert(conciliacionPayload, {
        onConflict: "owner_id,rut_docente,fecha",
      })
      .select("id, owner_id, rut_docente, fecha, estado, minutos_planificados, minutos_efectivos")
      .single();

    if (conciliacionError || !conciliacionData) {
      return jsonResponse(
        { error: "No se pudo guardar la conciliacion", details: conciliacionError?.message ?? null },
        500,
      );
    }

    await adminClient
      .from("asistencia_discrepancias")
      .delete()
      .eq("owner_id", owner_id)
      .eq("conciliacion_id", conciliacionData.id);

    const discrepancias: Array<{ tipo: string; severidad: string; descripcion: string }> = [];

    if (estado === "sin_horario") {
      discrepancias.push({
        tipo: "sin_horario",
        severidad: "alta",
        descripcion: "No existe bloque planificado para el docente en la fecha indicada.",
      });
    }
    if (estado === "incompleto") {
      discrepancias.push({
        tipo: "marca_faltante",
        severidad: "alta",
        descripcion: "Falta marca de entrada o salida para la fecha indicada.",
      });
    }
    if (minutosAtraso > 0) {
      discrepancias.push({
        tipo: "atraso",
        severidad: "media",
        descripcion: `Se detecta atraso efectivo de ${minutosAtraso} minuto(s).`,
      });
    }
    if (minutosSalidaAnticipada > 0) {
      discrepancias.push({
        tipo: "salida_anticipada",
        severidad: "media",
        descripcion: `Se detecta salida anticipada efectiva de ${minutosSalidaAnticipada} minuto(s).`,
      });
    }

    if (discrepancias.length > 0) {
      await adminClient.from("asistencia_discrepancias").insert(
        discrepancias.map((discrepancia) => ({
          owner_id,
          conciliacion_id: conciliacionData.id,
          tipo: discrepancia.tipo,
          severidad: discrepancia.severidad,
          descripcion: discrepancia.descripcion,
          metadata: {},
        })),
      );
    }

    return jsonResponse({ data: conciliacionData, discrepancias }, 200);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unexpected error";
    return jsonResponse({ error: message }, 500);
  }
});
