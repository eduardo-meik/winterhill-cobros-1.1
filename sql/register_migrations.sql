-- Register all 49 manually-applied migrations in supabase_migrations.schema_migrations
-- Run this in the Supabase SQL Editor AFTER all batches have been applied successfully.
-- This keeps supabase_migrations.schema_migrations in sync with CLI.

INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250515000001', '20250515000001_add_guardian_student_functions', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250529000000', '20250529000000_add_role_to_student_guardian', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250529000001', '20250529000001_add_unique_constraint_to_student_guardian', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250726202500', '20250726202500_harden_security', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250805000001', '20250805000001_fix_security_definer_views', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250805000002', '20250805000002_fix_function_search_path', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250924000000', '20250924000000_matricula_base', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925000000', '20250925000000_ensure_profile_for_current_user', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925000001', '20250925000001_guardian_auto_onboarding', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925000002', '20250925000002_guardian_claim_flow', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20250925000003', '20250925000003_guardian_intake_survey', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251021000000', '20251021000000_guardian_invite_and_claim', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251022000000', '20251022000000_fix_guardian_intake_auto_create', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251023000000', '20251023000000_add_year_to_fee', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251023000001', '20251023000001_complete_architecture_implementation', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251027000000', '20251027000000_setup_enrollment_documents_bucket', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251030000000', '20251030000000_enrollment_assisted_mode_policies', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251031000000', '20251031000000_email_logs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251101000000', '20251101000000_create_cheques_table', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103000000', '20251103000000_alter_cheques_add_document_link', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103000001', '20251103000001_alter_cheques_add_numero_cuota', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251103000002', '20251103000002_fix_cheques_policies', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251108000000', '20251108000000_add_audit_logs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251108000001', '20251108000001_rate_limit', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251110000000', '20251110000000_extend_enrollment_documents_types', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251115000000', '20251115000000_finalize_enrollment_rpc', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251115000001', '20251115000001_staff_intake_rpcs', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251116000000', '20251116000000_add_matriculado_estado', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251118000000', '20251118000000_enrollment_document_receipts', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251119000000', '20251119000000_guardian_identity_fields', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251120120000', '20251120120000_guardian_intake_course_id', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251202000000', '20251202000000_fix_security_issues', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251203000000', '20251203000000_matricula_p1_p2', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251203000001', '20251203000001_matricula_p3_p4', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251217000000', '20251217000000_add_cheques_missing_columns', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219000000', '20251219000000_add_guardian_fields_libro_matricula', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219000001', '20251219000001_add_pre_matriculado_estado', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219000002', '20251219000002_add_student_apellidos_separated', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219000003', '20251219000003_create_libro_matricula_rpc', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20251219000004', '20251219000004_fix_libro_matricula_report', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260222000000', '20260222000000_security_hardening', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302000000', '20260302000000_annual_transition_academic_records', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302000001', '20260302000001_fix_fee_on_conflict_and_clone_cursos', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260302000002', '20260302000002_promote_and_enroll_batch', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305000000', '20260305000000_backfill_academic_records', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305000001', '20260305000001_finalize_enrollment_per_student_plans', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305000002', '20260305000002_folio_unification', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305000003', '20260305000003_performance_indexes', '{}') ON CONFLICT DO NOTHING;
INSERT INTO supabase_migrations.schema_migrations (version, name, statements) VALUES ('20260305000004', '20260305000004_security_hardening_supplement', '{}') ON CONFLICT DO NOTHING;

-- Verify
SELECT count(*) AS total_registered FROM supabase_migrations.schema_migrations;
