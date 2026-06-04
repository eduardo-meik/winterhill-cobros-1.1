
const dotenv = require('dotenv');
dotenv.config();
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(process.env.VITE_SUPABASE_URL, process.env.VITE_SUPABASE_ANON_KEY);
async function test() {
  const res1 = await supabase.from('fee').select('id, student:students(id, cursos:curso(id))').limit(1);
  console.log('Error 1 (cursos:curso):', res1.error?.message || 'Success');
  
  const res2 = await supabase.from('fee').select('id, student:students(id, curso(id))').limit(1);
  console.log('Error 2 (curso):', res2.error?.message || 'Success');

  const res3 = await supabase.from('fee').select('id, student:students(id, cursos(id))').limit(1);
  console.log('Error 3 (cursos):', res3.error?.message || 'Success');
}
test();
