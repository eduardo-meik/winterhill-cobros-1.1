-- Matrícula Base Schema Migration
-- Date: 2025-09-24
-- Purpose: Create enrollment (matrícula) core tables, strict RLS, triggers, and seed Pagaré template

-- Safety: wrap in transaction
BEGIN;

-- 1) Helper: enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- for gen_random_uuid

-- 2) Tables
-- 2.1 enrollments (one per guardian per academic year, may include multiple students)
CREATE TABLE IF NOT EXISTS public.enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guardian_id uuid NOT NULL REFERENCES public.guardians(id) ON DELETE RESTRICT,
  year integer NOT NULL CHECK (year BETWEEN 2000 AND 2100),
  status text NOT NULL CHECK (status IN ('draft','pending','completed','rejected')) DEFAULT 'draft',
  meta jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (guardian_id, year)
);

-- 2.2 enrollment_students (N students per enrollment)
CREATE TABLE IF NOT EXISTS public.enrollment_students (
  enrollment_id uuid NOT NULL REFERENCES public.enrollments(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (enrollment_id, student_id)
);

-- 2.3 document_templates (admin-editable legal templates)
CREATE TABLE IF NOT EXISTS public.document_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type IN ('PAGARE','DECLARACION','OTRO')),
  version int NOT NULL,
  title text,
  content text NOT NULL, -- raw template with {{placeholders}}
  placeholders jsonb DEFAULT '[]'::jsonb,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (type, version)
);

-- 2.4 enrollment_documents (generated per enrollment: pagaré, declaraciones, etc.)
CREATE TABLE IF NOT EXISTS public.enrollment_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid NOT NULL REFERENCES public.enrollments(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('PAGARE','DECLARACION','OTRO')),
  template_version int NOT NULL,
  status text NOT NULL CHECK (status IN ('draft','generated','signed')) DEFAULT 'draft',
  pdf_url text, -- storage public URL or signed path
  storage_path text, -- storage object path
  generated_payload jsonb DEFAULT '{}'::jsonb, -- rendered variables snapshot
  signed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 2.5 signatures (audit of acceptances / signatures)
CREATE TABLE IF NOT EXISTS public.signatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_document_id uuid NOT NULL REFERENCES public.enrollment_documents(id) ON DELETE CASCADE,
  signer_type text NOT NULL CHECK (signer_type IN ('GUARDIAN','ADMIN')),
  signer_user_id uuid, -- auth.users.id when applicable
  method text NOT NULL CHECK (method IN ('checkbox','drawn','upload')),
  ip inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 2.6 Optional: pre_receipts (pre-invoice/receipt before SII)
CREATE TABLE IF NOT EXISTS public.pre_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL,
  student_id uuid REFERENCES public.students(id) ON DELETE SET NULL,
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  status text NOT NULL CHECK (status IN ('draft','issued','void')) DEFAULT 'draft',
  issued_at timestamptz,
  meta jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 3) Indexes
CREATE INDEX IF NOT EXISTS idx_enrollments_guardian_year ON public.enrollments (guardian_id, year);
CREATE INDEX IF NOT EXISTS idx_enrollment_students_enrollment ON public.enrollment_students (enrollment_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_students_student ON public.enrollment_students (student_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_documents_enrollment ON public.enrollment_documents (enrollment_id);
CREATE INDEX IF NOT EXISTS idx_enrollment_documents_type ON public.enrollment_documents (type);
CREATE INDEX IF NOT EXISTS idx_pre_receipts_student ON public.pre_receipts (student_id);

-- 4) RLS enablement
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollment_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollment_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.signatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pre_receipts ENABLE ROW LEVEL SECURITY;

-- 5) RLS Policies
-- Helper policy approach: link access to guardians.owner_id = auth.uid()

-- enrollments: guardian who owns guardian_id can read/write their own enrollments
DROP POLICY IF EXISTS enrollments_guardian_access ON public.enrollments;
CREATE POLICY enrollments_guardian_access ON public.enrollments
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = enrollments.guardian_id
      AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.id = enrollments.guardian_id
      AND g.owner_id = auth.uid()
    )
  );

-- enrollment_students: access via parent enrollment
DROP POLICY IF EXISTS enrollment_students_guardian_access ON public.enrollment_students;
CREATE POLICY enrollment_students_guardian_access ON public.enrollment_students
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE e.id = enrollment_students.enrollment_id
      AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE e.id = enrollment_students.enrollment_id
      AND g.owner_id = auth.uid()
    )
  );

-- document_templates: readable by all authenticated; write restricted later to ADMIN
DROP POLICY IF EXISTS document_templates_read ON public.document_templates;
CREATE POLICY document_templates_read ON public.document_templates
  FOR SELECT TO authenticated
  USING (true);

-- Admin write access (align with profiles.role = 'ADMIN')
DROP POLICY IF EXISTS document_templates_admin_write ON public.document_templates;
CREATE POLICY document_templates_admin_write ON public.document_templates
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'ADMIN'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.role = 'ADMIN'
    )
  );

-- enrollment_documents: access via parent enrollment
DROP POLICY IF EXISTS enrollment_documents_guardian_access ON public.enrollment_documents;
CREATE POLICY enrollment_documents_guardian_access ON public.enrollment_documents
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE e.id = enrollment_documents.enrollment_id
      AND g.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollments e
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE e.id = enrollment_documents.enrollment_id
      AND g.owner_id = auth.uid()
    )
  );

-- signatures: access via parent enrollment_document
DROP POLICY IF EXISTS signatures_guardian_access ON public.signatures;
CREATE POLICY signatures_guardian_access ON public.signatures
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.enrollment_documents d
      JOIN public.enrollments e ON e.id = d.enrollment_id
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE d.id = signatures.enrollment_document_id
      AND g.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS signatures_insert_guardian ON public.signatures;
CREATE POLICY signatures_insert_guardian ON public.signatures
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.enrollment_documents d
      JOIN public.enrollments e ON e.id = d.enrollment_id
      JOIN public.guardians g ON g.id = e.guardian_id
      WHERE d.id = signatures.enrollment_document_id
      AND g.owner_id = auth.uid()
    )
  );

-- pre_receipts: guardian can read their own; admin can manage
DROP POLICY IF EXISTS pre_receipts_guardian_read ON public.pre_receipts;
CREATE POLICY pre_receipts_guardian_read ON public.pre_receipts
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.guardians g
      WHERE g.owner_id = auth.uid()
      AND (
        (pre_receipts.enrollment_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.enrollments e WHERE e.id = pre_receipts.enrollment_id AND e.guardian_id = g.id
        ))
        OR
        (pre_receipts.student_id IS NOT NULL AND EXISTS (
          SELECT 1 FROM public.student_guardian sg WHERE sg.student_id = pre_receipts.student_id AND sg.guardian_id = g.id
        ))
      )
    )
  );

DROP POLICY IF EXISTS pre_receipts_admin_all ON public.pre_receipts;
CREATE POLICY pre_receipts_admin_all ON public.pre_receipts
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('ADMIN','FINANCE_MANAGER')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('ADMIN','FINANCE_MANAGER')
    )
  );

-- 6) Triggers for updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_enrollments_updated_at ON public.enrollments;
CREATE TRIGGER trg_enrollments_updated_at BEFORE UPDATE ON public.enrollments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_document_templates_updated_at ON public.document_templates;
CREATE TRIGGER trg_document_templates_updated_at BEFORE UPDATE ON public.document_templates FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_enrollment_documents_updated_at ON public.enrollment_documents;
CREATE TRIGGER trg_enrollment_documents_updated_at BEFORE UPDATE ON public.enrollment_documents FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_pre_receipts_updated_at ON public.pre_receipts;
CREATE TRIGGER trg_pre_receipts_updated_at BEFORE UPDATE ON public.pre_receipts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 7) Grants (keep least privilege; RLS will gate data)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT SELECT ON public.document_templates TO authenticated;

-- 8) Seed initial Pagaré template (v1) from contratos/pagare.txt
-- Note: placeholders will be progressively integrated in rendering layer
INSERT INTO public.document_templates (type, version, title, content, placeholders, active)
VALUES (
  'PAGARE',
  1,
  'Pagaré Winterhill v1',
  $$CONTRATO DE PRESTACIÓN DE SERVICIOS EDUCACIONALES 

En Viña del Mar, a _____ de _____ del 202__ entre la CORPORACIÓN EDUCACIONAL WINTERHILL. RUT 65.152.884-4, representada legalmente por doña Orlando Borquéz Domingo, cédula de Identidad N° 7.269.437-6 ambos domiciliadas en Pasaje Anwandter N° 31. Viña del Mar, en adelante, "LA CORPORACIÓN" y Don(a), _____ (nacionalidad) _____ (profesión u oficio). fano _____ (estado civil) _____ cédula de identidad N° _____ domiciliado/a en: _____ 




En adelante "EL/LA APODERADO/A", se ha celebrado el sigulente Contrato de Prestación de Servicios Educacionales: 


Primero: La Corporación Educacional Winterhill se encuentra reconocida oficialmente como tal y es sostenedora del Establecimiento Educacional denominado "Colegio Winterhill", en adelante "EL ESTABLECIMIENTO", ubicado en Pasaje Andwanter N° 31, Comuna de Viña del Mar, 


Segundo: Para todos los efectos de este contrato, se entiende por APODERADO/A la persona que, como responsable dellos) hijo(s) suscribe el presente instrumento, quien asume la totalidad de las obligaciones, deberes y compromisos que en este instrumento se consignan. 

EI/LA APODERADO/A ha solicitado a LA CORPORACIÓN -quien lo ha aceptado-matricular y prestar servicios educacionales en el Establecimiento Educacional Colegio Winterhill, ubicado en Pasaje Andwanter N 31. Comuna de Viña del Mar, par el año académico 2025, en calidad de alumnos(s) a su(s) pupilo a) que se individualizan a continuación, en adelante, Indistinta y anónimamente "EL/LA ESTUDIANTE": 

Númer	Nombre	RUT	Curso año 2025
O			
2			
3			
A			
5			



Export to Sheets
Tercero: LA CORPORACIÓN, en su calidad de sostenedora del ESTABLECIMIENTO, como entidad educacional y formativa, se compromete a lo siguiente:

Entregar, durante la vigencia del presente contrato, la atención necesaria para que EL/LA ESTUDIANTE desarrolle el proceso educativo dentro del nivel académico establecido por el colegio, comprometiendo un énfasis en su formación integral. 

Desarrollar el proceso de enseñanza-aprendizaje de conformidad con el Proyecto Educativo Institucional y los planes y programas de estudio del respectivo nivel, aprobados por el Ministerio de Educación de Chile, implementado por los docentes del colegio. 

Velar por el proceso formativo acorde a las normas reglamentarias del ESTABLECIMIENTO, basado en exigencias legales oficiales, vigentes en materias de evaluación y promoción. 

Difundir el contenido del Proyecto Educativo Institucional del Colegio, Manual de Convivencia Escolar y Reglamento de Evaluación y Promoción. 

Proporcionar al ESTUDIANTE. de acuerdo a las condiciones internas, la infraestructura del ESTABLECIMIENTO que se requiera para el desarrollo del programa curricular y extracurricular. 

Cuarto: EL/LA APODERADO/A se compromete a:
1 Aceptar y respetar los principios y objetivos del ESTABLECIMIENTO descritos en el Proyecto Educativo Institucional. Manual de Convivencia Escolar y Reglamento de Evaluación y Promoción. 


2 Favorecer las tareas educativas y formativas que, en beneficio del ESTUDIANTE, conciba y desarrolle EL ESTABLECIMIENTO. 


3. Pagar oportunamente, dentro de los plazos establecidos, la colegiatura y cumplir con el compromiso mensual correspondiente al Financiamiento Compartido. 


4. Asistir a las reuniones convocadas por el subcentro de madres, padres y apoderados. 


5. Asistir a las entrevistas personales citadas por los profesionales que se desempeñan en el Colegio. 

6 Mantener una actitud de respeta hacia cualquier miembro de la comunidad educativa. 


7. Informar por escrito el retiro de un estudiante. 

Quinto: EI/LA ESTUDIANTE, en virtud del presente contrato, adquiere los siguientes derechos:

A participar del proceso de enseñanza-aprendizaje acorde al Proyecto Educativo del Colegio y programas oficiales del Ministerio de Educación. 

A participar en todas las actividades académicas curriculares propias y demás de carácter extra programáticas que el Colegio promueva y ejecute. 

Utilizar la infraestructura del Colegio según las normas internas, para el normal desarrollo de su formación y del régimen curricular. 

Sexto: Serán obligaciones de EL/LA ALUMNO/A, en tanto beneficiario/a del presente contrato, las siguientes:

Cumplir con lo establecido en el Manual de Convivencia Escolar del Colegio. 

Asistir puntual y regularmente a las clases y actividades planificadas por el establecimiento. 

Respetar las normas de evaluación descritas en el Reglamento de Evaluación y Promoción vigente. 


Séptimo: EL APODERADO/A se obliga a pagar a LA CORPORACIÓN, por la prestación de los servicios educacionales encomendados, los siguientes valores, por los/as estudiantes individualizados en la Cláusula Segunda: 

Por concepto de matricula, al contado, la suma de $ _____ 

Por concepto de colegiatura anual, el monto correspondiente a 

_____−divididoen_____cuotasmensualesde _____ cada una para el dia _____ de cada mes. 

EL/LA APODERADO/A pagará la escolaridad anual del/los estudiantes señalados en este instrumento. en la siguiente forma (seleccionar): Cheques: _____ Transferencia Electrónica: _____ Pago en efectivo: _____ ☐ Tarjeta de Crédito: _____ 


Atendido que, LA CORPORACIÓN, se encuentra sujeta a la necesidad de financiar el funcionamiento del ESTABLECIMIENTO, por el periodo que corresponda a la totalidad del respectivo año académico, será obligatorio para el padre y/o apoderado/a efectuar el pago de la colegiatura anual, en la forma y fechas que se han establecido en esta cláusula. 

En el caso de el/la estudiante requiera, previo informe médico y/o psicológico, dar cierre anticipado del año escolar, la CORPORACIÓN exigirá el pago del año completo de conformidad con lo establecido en la cláusula séptima de este instrumento. 

Las partes contratantes convienen que, tanto el pago de la matrícula como la colegiatura anual antes referidas, constituyen obligaciones esenciales del presente contrato y su incumplimiento, por parte del APODERADO/A, habilitará a LA CORPORACIÓN para poner término a este contrato y perseguir las responsabilidades legales que de ello deriven. 

Igualmente, la CORPORACIÓN se reserva el derecho a renovar matricula en favor del/la estudiantes individualizados en la cláusula segunda para el evento que el/la apoderado/a incurra en incumplimiento de las obligaciones financieras que ha asumido en virtud de la presente cláusula. toda vez que -los ingresos que ellas deben reportar- resultan esenciales para el financiamiento y debido funcionamiento del Colegio Winterhill. 


Sin perjuicio de ello, las partes se comprometen a estudiar, en particular, la situación que pueda explicar dicho incumplimiento y, en el evento de ser ello plausible, establecer los mecanismos necesarios a fin de lograr, en definitiva, el pago de las referidas obligaciones y no afectar la situación educacional del alumno/a. 


Octavo: En el caso que el/la estudiante(s) tenga la calidad de "alumno prioritario" durante el presente año (2025). su apoderado/a. igualmente, deberá suscribir este contrato comprometiéndose a documentar el arancel en caso de que, eventualmente, pierda esta calidad para el año lectivo 2025. 


Noveno: En caso que el/la estudiante tenga que interrumpir el curso del respectivo año académico. cualquiera sea la causal de ello y habiendo dado aviso oportuno a la Dirección del ESTABLECIMIENTO Y al Departamento de Administración, se procederá a entregar al APODERADO/A la documentación académica que corresponda. 



Décimo: El presente contrato comenzará a regir desde la fecha de su suscripción y durará hasta el término del año lectivo correspondiente. Podrá ser renovado por el mutuo y expreso acuerdo de las partes que se manifestará en la suscripción de un nuevo contrato. 


Undécimo: El cumplimiento de las obligaciones financieras contraídas por el/la APODERADO/A, en el marco del presente contrato, será garantizado de la siguiente forma (seleccionar):
a) Cheques: nominativos a nombre de Corporación Educacional Winterhill, con vencimiento dentro de los primeros diez días de cada mes, por el periodo de marzo de 2025 a diciembre de 2025, 

b) Tarjeta de Crédito: a través del número de cuotas que le permita el banco. 

c) Pago efectivo: por el total de la colegiatura del año. 

d) Pago con transferencia bancaria comprometida a través de pagare notarial. 


Duodécimo: La CORPORACIÓN queda facultada para endosar o transferir, a cualquier título, los créditos constituidos por los cheques a fecha extendidos y/o aceptadas por el/la apoderado/a para garantizar las obligaciones financieras indicadas en la cláusula séptima, así como endosarios en cobranza o en garantía y disponer su protesto en caso de falta de pago oportuno. 

Por tanto, el/la apoderado/a autoriza expresamente al representante legal de la CORPORACIÓN para que, en caso de simple retardo, mora o incumplimiento de las obligaciones contraídas en documentos tales como contrato, facturas, órdenes de compra, solicitudes de compra, letras de cambio u otros, sus datos y las demás derivados de dichos documentos puedan ser ingresados, procesados, tratados y comunicados a terceros sin restricciones, en el registro o banco de datos SICOM (sistema de morosidades y Protestos DICOM). Esta autorización tiene el carácter de permanente, pudiendo ser revocada, sin efecto retroactivo y con fecha no anterior al último documento de pago emitido 



Décimo Tercero: La vigencia del presente Contrato de Prestación de Servicios Educacionales es exclusivamente por el período académico definido en la cláusula segunda de este instrumento. Su renovación por parte del Establecimiento Educacional estará sujeta al estricto cumplimiento por parte del alumno/a de lo establecido en los reglamentos institucionales y, especialmente, en lo relativo al cumplimiento de las obligaciones pecuniarias por parte del padre, madre o apoderado para con el Establecimiento Educacional. Para que el/la alumno/a pueda conservar su calidad de alumno regular del Colegio Winterhill, su padre y/o apoderado/a tendrá la obligación de suscribir, dentro de los plazos fijados por la CORPORACIÓN, el nuevo Contrato de Prestación de Servicios Educacionales. correspondiente al periodo académico siguiente. 




Décimo Cuarto: Tanto el/la estudiante como el apoderado/a declaran conocer y aceptar los principios que inspiran la misión y objetivos del Colegio Winterhill como, asimismo, las disposiciones reglamentarias del Reglamento General del Alumno y del Reglamento Interno del establecimiento. 


Décimo Quinto: En caso que el/la estudiante cause daños materiales al patrimonio de la CORPORACIÓN o del Colegio Winterhill, su padre y/o apoderado/a deberá pagar la reparación o reposición de los daños causados, sin perjuicio de las sanciones que puedan corresponder al alumno en conformidad a la reglamentación interna del Colegio. Será responsabilidad exclusiva del estudiante el cuidado de sus útiles y efectos personales que introduzca al recinto del Colegio, entendiéndose que éste, sus docentes y/o trabajadores, no asumen responsabilidad alguna por su eventual hurto, extravia o deterioro por cualquier causa. 



Décimo Sexto: EI/LA APODERADO/A declara que el estudiante individualizado en este contrato tiene salud compatible con el régimen de estudios del ESTABLECIMIENTO Colegio Winterhill. En caso de sufrir el/la estudiante algún accidente o problema de salud durante su permanencia en el Colegio, éste proporcionará todos los medios a su alcance para superar la emergencia y asegurar el pronto traslado del estudiante al establecimiento asistencial que corresponda, sin que ello implique asumir responsabilidad institucional ni económica por los hechos que motivaren la atención de emergencia. EI ESTABLECIMIENTO facilitará todos los trámites correspondientes al Seguro de Accidente Escolar al que tiene derecho todo alumno regular de instituciones reconocidas por el Ministerio de Educación. 




Décimo Séptimo: EL/LA APODERADO/A declara conocer el manual de convivencia escolar y los protocolos internos del Colegio Winterhill; asimismo, LA CORPORACIÓN da cuenta que éstos se encuentran disponibles en la página web 

http://colegiowinterhill.cl/Website/index.php/protocolos. Igualmente, las partes acuerdan que dichos documentos serán enviados por LA CORPORACIÓN al siguiente: correo electrónico que indica EL/LA APODERADO/ 



Décimo Octavo: Queda un ejemplar del presente contrato en poder de la CORPORACIÓN y otro en poder del apoderad/a quienes, por el hecho de suscribirlo, expresan su plena conformidad con el contenido del mismo. 

APODERADO/A
RUT: 

CORPORACIÓN EDUCACIONAL WINTERHILL
RUT: 65.152.884-4 $$,
  jsonb_build_array(
    'guardian_full_name','guardian_run','guardian_address','guardian_email','guardian_phone',
    'year','students_table','colegiatura_anual','cantidad_cuotas','monto_cuota','dia_vencimiento'
  ),
  true
)
ON CONFLICT (type, version) DO NOTHING;

COMMIT;
