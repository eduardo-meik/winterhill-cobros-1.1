-- DIAGNOSTIC SCRIPT: Check for recent enrollments and user roles
-- Run this in the Supabase SQL Editor to verify if data exists.

-- 1. Check total enrollments count
SELECT 'Total Enrollments' as check_type, count(*) as count FROM public.enrollments;

-- 2. Check enrollments in the last 6 months (the dashboard filter)
SELECT 'Recent Enrollments (6 months)' as check_type, count(*) as count 
FROM public.enrollments 
WHERE created_at >= (now() - interval '6 months');

-- 3. List the 5 most recent enrollments to verify dates and status
SELECT id, created_at, status, year, guardian_id 
FROM public.enrollments 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. Check if there are users with ADMIN or ASIST roles
SELECT id, email, role, first_name, last_name 
FROM public.profiles 
WHERE role IN ('ADMIN', 'ASIST');

-- 5. Check if the current user (if running in context, otherwise this might be empty) has the role
-- Note: In SQL Editor, auth.uid() might be null, so this is just for reference if testing via RLS simulation.
-- SELECT * FROM public.profiles WHERE id = auth.uid();
