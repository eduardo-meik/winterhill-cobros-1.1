import { supabase } from './src/services/supabase'; async function listTables() { const { data, error } = await supabase.rpc('info_tables'); console.log(data); } listTables();
