const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const { chromium } = require('@playwright/test');

function loadEnv() {
  const envPath = path.join(process.cwd(), '.env');
  const env = {};
  fs.readFileSync(envPath, 'utf8').replace(/\r/g, '').split('\n').forEach(line => {
    const match = line.match(/^([^#=]+)=(.*)$/);
    if (!match) return;
    env[match[1].trim()] = match[2].trim().replace(/^["']|["']$/g, '');
  });
  return env;
}

function computeRutDv(body) {
  const digits = String(body).split('').reverse().map(Number);
  let factor = 2;
  let total = 0;
  for (const digit of digits) {
    total += digit * factor;
    factor = factor === 7 ? 2 : factor + 1;
  }
  const remainder = 11 - (total % 11);
  if (remainder === 11) return '0';
  if (remainder === 10) return 'K';
  return String(remainder);
}

function formatRut(body) {
  const dv = computeRutDv(body);
  const reversed = String(body).split('').reverse();
  const parts = [];
  for (let i = 0; i < reversed.length; i += 3) {
    parts.push(reversed.slice(i, i + 3).reverse().join(''));
  }
  return `${parts.reverse().join('.')}-${dv}`;
}

async function ensureDir(dirPath) {
  await fs.promises.mkdir(dirPath, { recursive: true });
}

function getFlowArg() {
  const arg = process.argv.find(v => v.startsWith('--flow='));
  const flow = (arg ? arg.split('=')[1] : 'students').trim();
  if (!['students', 'matricula'].includes(flow)) {
    throw new Error(`Flow inválido: ${flow}. Usa --flow=students o --flow=matricula`);
  }
  return flow;
}

async function buildSerializedSession({ supabaseUrl, anonKey, adminClient, adminUserId, baseUrl }) {
  const { data: userData, error: userError } = await adminClient.auth.admin.getUserById(adminUserId);
  if (userError) throw userError;
  const email = userData?.user?.email;
  if (!email) throw new Error('No se encontró email del usuario admin');

  const { data: linkData, error: linkError } = await adminClient.auth.admin.generateLink({
    type: 'magiclink',
    email,
    options: { redirectTo: `${baseUrl}/auth/callback` },
  });
  if (linkError) throw linkError;

  const hashedToken = linkData?.properties?.hashed_token;
  if (!hashedToken) {
    throw new Error('Supabase no devolvió hashed_token para el magic link');
  }

  const { data: sessionData, error: sessionError } = await adminClient.auth.verifyOtp({
    token_hash: hashedToken,
    type: 'magiclink',
  });
  if (sessionError) throw sessionError;
  const session = sessionData?.session;
  if (!session?.access_token || !session?.refresh_token) {
    throw new Error('No se pudo obtener una sesión válida desde verifyOtp');
  }

  const capturedStorage = {};
  const storageAdapter = {
    getItem(key) {
      return Object.prototype.hasOwnProperty.call(capturedStorage, key) ? capturedStorage[key] : null;
    },
    setItem(key, value) {
      capturedStorage[key] = value;
    },
    removeItem(key) {
      delete capturedStorage[key];
    },
  };

  const browserStyleClient = createClient(supabaseUrl, anonKey, {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: false,
      storage: storageAdapter,
      storageKey: 'supabase.auth.token',
    },
  });

  const { error: setSessionError } = await browserStyleClient.auth.setSession({
    access_token: session.access_token,
    refresh_token: session.refresh_token,
  });
  if (setSessionError) throw setSessionError;

  const serializedSession = capturedStorage['supabase.auth.token'];
  if (!serializedSession) {
    throw new Error('No se pudo serializar la sesión de Supabase para localStorage');
  }

  return { serializedSession, email };
}

async function selectFirstCourse(page) {
  const courseSelect = page.locator('select[name="curso"]');
  await courseSelect.waitFor({ state: 'visible', timeout: 30000 });
  await page.waitForTimeout(750);
  const courseOptions = await courseSelect.locator('option').evaluateAll(options => options.map(option => ({
    value: option.value,
    text: (option.textContent || '').trim(),
    disabled: option.disabled,
  })));
  const firstCourse = courseOptions.find(option => option.value && !option.disabled);
  if (!firstCourse) {
    throw new Error('No hay cursos disponibles para el nivel seleccionado');
  }
  await courseSelect.selectOption(firstCourse.value);
  return firstCourse;
}

async function fillAndSubmitStudentModal(page, { studentName, studentRun }) {
  await page.waitForSelector('text=Registrar Estudiante', { timeout: 30000 });
  await page.locator('input[name="whole_name"]').fill(studentName);
  await page.locator('input[name="run"]').fill(studentRun);
  await page.locator('input[name="date_of_birth"]').fill('2015-03-15');
  await page.locator('select[name="nivel"]').selectOption('110');
  const selectedCourse = await selectFirstCourse(page);
  await page.locator('input[name="fecha_matricula"]').fill('2026-03-01');
  await page.locator('select[name="estado_std"]').selectOption('MATRICULADO');
  await page.getByRole('button', { name: 'Registrar Estudiante' }).click();
  await page.waitForSelector('text=Estudiante registrado exitosamente', { timeout: 30000 });
  return selectedCourse;
}

async function prepareTemporaryGuardian(adminClient, adminUserId, now) {
  const runBody = 25900000 + Number(String(Date.now()).slice(-5));
  const guardianRun = formatRut(runBody);
  const guardian = {
    owner_id: adminUserId,
    first_name: `E2E Guardian ${now.getHours()}${now.getMinutes()}`,
    last_name: `MTR ${now.getSeconds()}`,
    run: guardianRun,
    email: `e2e.guardian.${Date.now()}@example.local`,
    relationship_type: 'TUTOR',
  };

  const { data, error } = await adminClient
    .from('guardians')
    .insert(guardian)
    .select('id, first_name, last_name, run, email')
    .single();
  if (error) throw error;
  return data;
}

async function runFlowStudents(page, payload) {
  await page.goto(`${payload.baseUrl}/students`, { waitUntil: 'networkidle', timeout: 120000 });
  await page.waitForSelector('text=Estudiantes', { timeout: 30000 });
  await page.getByRole('button', { name: 'Agregar Estudiante' }).click();
  return fillAndSubmitStudentModal(page, payload);
}

async function runFlowMatricula(page, payload) {
  const guardian = await prepareTemporaryGuardian(payload.adminClient, payload.adminUserId, new Date());
  payload.tempGuardian = guardian;

  await page.goto(`${payload.baseUrl}/matricula`, { waitUntil: 'networkidle', timeout: 120000 });
  await page.waitForSelector('text=Modo asistido', { timeout: 30000 });

  const searchInput = page.locator('input[placeholder="Buscar por nombre, RUN o email..."]');
  await searchInput.fill(guardian.run);
  await page.getByRole('button', { name: 'Buscar' }).click();

  await page.getByRole('button', { name: new RegExp(`${guardian.first_name} ${guardian.last_name}`) }).click();
  await page.waitForSelector('text=Mis Matrículas', { timeout: 30000 });
  await page.getByRole('button', { name: '+ Iniciar Nueva Matrícula' }).click();
  await page.waitForSelector('text=Mis Alumnos Asociados', { timeout: 30000 });
  await page.getByRole('button', { name: 'Registrar estudiante' }).click();

  return fillAndSubmitStudentModal(page, payload);
}

async function main() {
  const flow = getFlowArg();
  const env = loadEnv();
  const baseUrl = 'http://localhost:5173';
  const supabaseUrl = env.VITE_SUPABASE_URL;
  const anonKey = env.VITE_SUPABASE_ANON_KEY;
  const serviceKey = env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !anonKey || !serviceKey) {
    throw new Error('Faltan VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY o SUPABASE_SERVICE_ROLE_KEY en .env');
  }

  const adminUserId = 'bd72b98b-e2e7-43a1-a225-21c0fbbbf918';
  const outputRoot = path.join(process.cwd(), 'tmp_playwright_artifacts');
  const videoDir = path.join(outputRoot, 'videos');
  const screenshotDir = path.join(outputRoot, 'screenshots');
  await ensureDir(videoDir);
  await ensureDir(screenshotDir);

  const adminClient = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const authInfo = await buildSerializedSession({
    supabaseUrl,
    anonKey,
    adminClient,
    adminUserId,
    baseUrl,
  });

  const now = new Date();
  const stamp = now.toISOString().replace(/[:.]/g, '-');
  const rutBody = 26000000 + Number(String(Date.now()).slice(-5));
  const studentName = `E2E Video ${flow.toUpperCase()} ${now.getFullYear()} ${String(now.getMonth() + 1).padStart(2, '0')} ${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`;
  const studentRun = formatRut(rutBody);
  const screenshotPath = path.join(screenshotDir, `create-student-${flow}-${stamp}.png`);
  const failureScreenshotPath = path.join(screenshotDir, `create-student-${flow}-${stamp}-failure.png`);
  const failureHtmlPath = path.join(outputRoot, `create-student-${flow}-${stamp}-failure.html`);
  const metadataPath = path.join(outputRoot, `create-student-${flow}-${stamp}.json`);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 1100 },
    recordVideo: { dir: videoDir, size: { width: 1440, height: 900 } },
  });
  const page = await context.newPage();
  const pageVideo = page.video();
  const payload = {
    flow,
    baseUrl,
    adminClient,
    adminUserId,
    studentName,
    studentRun,
    tempGuardian: null,
  };

  try {
    await page.addInitScript(([storageKey, storageValue]) => {
      window.localStorage.setItem(storageKey, storageValue);
    }, ['supabase.auth.token', authInfo.serializedSession]);

    const selectedCourse = flow === 'matricula'
      ? await runFlowMatricula(page, payload)
      : await runFlowStudents(page, payload);

    const { data: insertedStudent, error: insertedStudentError } = await adminClient
      .from('students')
      .select('id, whole_name, run, curso, nivel')
      .eq('run', studentRun)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (insertedStudentError) throw insertedStudentError;
    if (!insertedStudent?.id) {
      throw new Error(`No se encontró en BD el estudiante recién creado con RUN ${studentRun}`);
    }

    await page.screenshot({ path: screenshotPath, fullPage: true });

    const metadata = {
      executedAt: new Date().toISOString(),
      flow,
      baseUrl,
      email: authInfo.email,
      studentName,
      studentRun,
      selectedCourse,
      insertedStudent,
      temporaryGuardian: payload.tempGuardian,
      screenshotPath,
    };
    await fs.promises.writeFile(metadataPath, JSON.stringify(metadata, null, 2), 'utf8');
  } catch (error) {
    const html = await page.content().catch(() => '');
    await page.screenshot({ path: failureScreenshotPath, fullPage: true }).catch(() => {});
    await fs.promises.writeFile(failureHtmlPath, html, 'utf8').catch(() => {});
    console.error('[PLAYWRIGHT_DIAGNOSTIC]', JSON.stringify({
      flow,
      url: page.url(),
      failureScreenshotPath,
      failureHtmlPath,
    }, null, 2));
    throw error;
  } finally {
    await page.close();
    await context.close();
    await browser.close();
  }

  const videoPath = await pageVideo.path();
  const result = {
    success: true,
    flow,
    studentName,
    studentRun,
    videoPath,
    screenshotPath,
    metadataPath,
  };
  console.log(JSON.stringify(result, null, 2));
}

main().catch(error => {
  console.error('[PLAYWRIGHT_CREATE_STUDENT_ERROR]', error?.stack || error?.message || error);
  process.exit(1);
});