-- ============================================================================
-- COMPREHENSIVE ENROLLMENT DATA ANALYSIS
-- Identifies all types of enrollment issues in the dataset
-- Created: 2025-12-22
-- ============================================================================

-- ============================================================================
-- ISSUE 1: ENROLLMENT ID SHARING (Multiple students on same enrollment)
-- This is a DATA INTEGRITY ERROR - one enrollment should not have multiple students
-- ============================================================================
WITH enrollment_sharing AS (
    SELECT 
        id as enrollment_id,
        COUNT(DISTINCT student_id) as student_count,
        STRING_AGG(DISTINCT first_name, ', ') as students,
        year,
        created_at
    FROM (
        -- Your JSON data here - insert all records
        SELECT * FROM (VALUES
            ('2107a703-4075-49a0-918d-4040d5ea1b6a'::uuid, 2026, '2025-11-03 14:27:08.528171+00'::timestamptz, 'f42a98fd-f5f3-481f-ad1f-9d5e10d9935a'::uuid, 'VIOLETA CAROLINA'),
            ('2107a703-4075-49a0-918d-4040d5ea1b6a'::uuid, 2026, '2025-11-03 14:27:08.528171+00'::timestamptz, '604757cf-8b2e-4987-a1f9-5b8630e35eac'::uuid, 'SIMÓN MIJAHIL')
            -- Add all other records here...
        ) AS t(id, year, created_at, student_id, first_name)
    ) enrollments
    GROUP BY id, year, created_at
    HAVING COUNT(DISTINCT student_id) > 1
)
SELECT 
    '1. ENROLLMENT ID SHARING' as issue_type,
    COUNT(*) as affected_enrollments,
    SUM(student_count) as total_students_affected
FROM enrollment_sharing;

-- ============================================================================
-- ISSUE 2: DUPLICATE ENROLLMENTS FOR SAME STUDENT (Same year)
-- Student has multiple enrollments in the same academic year
-- ============================================================================
WITH student_year_duplicates AS (
    SELECT 
        student_id,
        first_name,
        year,
        COUNT(*) as enrollment_count,
        STRING_AGG(id::text, ', ') as enrollment_ids,
        MIN(created_at) as first_enrollment,
        MAX(created_at) as last_enrollment
    FROM (
        -- Your JSON data here
        SELECT * FROM (VALUES
            ('a2d5d4ee-7040-4110-b33d-820a8cf79b8e'::uuid, 2025, '2025-10-21 15:17:01.380968+00'::timestamptz, '5a85933a-3ff3-4451-9000-209072da1eaa'::uuid, 'VIOLETA ABRIL')
            -- Add all records...
        ) AS t(id, year, created_at, student_id, first_name)
    ) enrollments
    GROUP BY student_id, first_name, year
    HAVING COUNT(*) > 1
)
SELECT 
    '2. DUPLICATE ENROLLMENTS (SAME YEAR)' as issue_type,
    COUNT(*) as affected_students,
    SUM(enrollment_count) as total_duplicate_enrollments
FROM student_year_duplicates;

-- ============================================================================
-- ISSUE 3: TEST/PLACEHOLDER STUDENTS
-- Students with test names that should be removed
-- ============================================================================
WITH test_students AS (
    SELECT DISTINCT
        student_id,
        first_name
    FROM (
        -- Your JSON data here
        SELECT * FROM (VALUES
            ('52596939-d2f6-46e3-a962-175666597c0e'::uuid, 2025, '2025-11-01 15:56:43.234686+00'::timestamptz, '4dce9f5a-cd94-43d1-a4e5-12b9558bd921'::uuid, 'Test1')
            -- Add all records...
        ) AS t(id, year, created_at, student_id, first_name)
    ) enrollments
    WHERE 
        LOWER(first_name) LIKE '%test%'
        OR LOWER(first_name) LIKE '%estudiante%'
        OR LOWER(first_name) LIKE '%testing%'
        OR LOWER(first_name) LIKE '%junito%'
        OR LOWER(first_name) LIKE '%falso%'
)
SELECT 
    '3. TEST/PLACEHOLDER STUDENTS' as issue_type,
    COUNT(*) as test_students_count
FROM test_students;

-- ============================================================================
-- ISSUE 4: YEAR 2022 ENROLLMENTS (Likely legacy/test data)
-- Enrollments from 2022 when system started in 2025
-- ============================================================================
SELECT 
    '4. YEAR 2022 ENROLLMENTS (LEGACY)' as issue_type,
    COUNT(*) as enrollment_count_2022
FROM (
    -- Your JSON data here
    SELECT * FROM (VALUES
        ('c93c2e13-8579-4d14-aad4-f87997af2b6f'::uuid, 2022, '2025-12-16 11:46:40.442954+00'::timestamptz, '453a4353-fc3a-4682-87ac-815da1186d68'::uuid, 'SANTIAGO')
        -- Add all records...
    ) AS t(id, year, created_at, student_id, first_name)
) enrollments
WHERE year = 2022;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================
SELECT 
    'TOTAL ENROLLMENT RECORDS' as metric,
    COUNT(*) as count
FROM (
    -- Your JSON data here - count all
    SELECT 1
) enrollments;
