create or replace function public.guardian_portal_bootstrap(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_guardian guardians%rowtype;
  v_enrollment enrollments%rowtype;
  v_current_enrollment enrollments%rowtype;
  v_next_enrollment enrollments%rowtype;
  v_payload jsonb := '{}'::jsonb;
  v_enrollments jsonb := '{}'::jsonb;
  v_available_years jsonb := '[]'::jsonb;
  v_current_year int := extract(year from now());
  v_next_year int := extract(year from now()) + 1;
  v_guardian_id uuid;
begin
  if p_user_id is null then
    return jsonb_build_object('guardian', null);
  end if;

  select *
    into v_guardian
    from guardians
   where owner_id = p_user_id
   order by updated_at desc nulls last
   limit 1;

  if found then
    v_payload := v_payload || jsonb_build_object('guardian', to_jsonb(v_guardian));
  else
    begin
      v_guardian_id := public.ensure_guardian_for_user(p_user_id);
    exception
      when undefined_function then
        v_guardian_id := null;
      when others then
        v_guardian_id := null;
    end;

    if v_guardian_id is not null then
      select *
        into v_guardian
        from guardians
       where id = v_guardian_id
       limit 1;
    else
      select *
        into v_guardian
        from guardians
       where owner_id = p_user_id
       order by updated_at desc nulls last
       limit 1;
    end if;

    if found then
      v_payload := v_payload || jsonb_build_object('guardian', to_jsonb(v_guardian));
    else
      return jsonb_build_object('guardian', null);
    end if;
  end if;

  -- Ensure we have enrollment records for the current cycle and the upcoming year
  select *
    into v_current_enrollment
    from enrollments e
   where e.guardian_id = v_guardian.id
     and e.year = v_current_year
   order by e.updated_at desc nulls last
   limit 1;

  select *
    into v_next_enrollment
    from enrollments e
   where e.guardian_id = v_guardian.id
     and e.year = v_next_year
   order by e.updated_at desc nulls last
   limit 1;

  if v_next_enrollment.id is null then
    begin
      insert into enrollments (guardian_id, year, status, meta)
      values (v_guardian.id, v_next_year, 'draft', '{}'::jsonb)
      returning * into v_next_enrollment;
    exception
      when unique_violation then
        select *
          into v_next_enrollment
          from enrollments e
         where e.guardian_id = v_guardian.id
           and e.year = v_next_year
         order by e.updated_at desc nulls last
         limit 1;
    end;
  end if;

  -- Build a map of enrollments keyed by academic year
  select coalesce(jsonb_object_agg(enr.year::text, jsonb_build_object(
           'enrollment', to_jsonb(enr),
           'student_ids', coalesce((
             select jsonb_agg(es.student_id)
               from enrollment_students es
              where es.enrollment_id = enr.id
           ), '[]'::jsonb),
           'documents', coalesce((
             select jsonb_agg(row_to_json(ed.*))
               from enrollment_documents ed
              where ed.enrollment_id = enr.id
           ), '[]'::jsonb),
           'fees', coalesce((
             select jsonb_agg(row_to_json(f.*))
               from fee f
              where f.student_id in (
                      select es2.student_id
                        from enrollment_students es2
                       where es2.enrollment_id = enr.id)
                and coalesce(f.year_academico, cast(extract(year from f.due_date) as int), v_current_year) between enr.year - 1 and enr.year + 1
           ), '[]'::jsonb)
         )), '{}'::jsonb)
    into v_enrollments
    from enrollments enr
   where enr.guardian_id = v_guardian.id
     and enr.year between v_current_year - 1 and v_next_year;

  select coalesce(jsonb_agg(en.year order by en.year), '[]'::jsonb)
    into v_available_years
    from (
          select distinct year
            from enrollments
           where guardian_id = v_guardian.id
             and year between v_current_year - 1 and v_next_year
         ) en;

  -- Refresh canonical enrollment selection preferring the upcoming cycle
  select *
    into v_enrollment
    from enrollments e
   where e.guardian_id = v_guardian.id
   order by e.year desc, e.updated_at desc nulls last
   limit 1;

  v_payload := v_payload || jsonb_build_object(
    'students',
    coalesce(
      (
        select jsonb_agg(row_to_json(s.*))
        from (
          select
            sg.student_id as id,
            st.whole_name,
            st.first_name,
            concat_ws(' ', st.apellido_paterno, st.apellido_materno) as last_name,
            st.run,
            st.date_of_birth,
            st.genero,
            st.nombre_social,
            st.nacionalidad,
            st.direccion,
            st.comuna,
            NULL::text AS convive_con,
            st.curso as curso_id,
            coalesce(c.nom_curso, st.curso::text) as curso_label
          from student_guardian sg
          join students st on st.id = sg.student_id
          left join cursos c on c.id = st.curso
          where sg.guardian_id = v_guardian.id
        ) as s
      ),
      '[]'::jsonb
    )
  );

  v_payload := v_payload || jsonb_build_object(
    'intake',
    (
      select to_jsonb(gi)
      from guardian_intake_surveys gi
      where gi.guardian_id = v_guardian.id
      order by gi.updated_at desc nulls last
      limit 1
    )
  );

  if v_enrollment.id is not null then
    v_payload := v_payload || jsonb_build_object('enrollment', to_jsonb(v_enrollment));
    v_payload := v_payload || jsonb_build_object(
      'enrollment_student_ids',
      coalesce(
        (
          select jsonb_agg(es.student_id)
            from enrollment_students es
           where es.enrollment_id = v_enrollment.id
        ),
        '[]'::jsonb
      )
    );
    v_payload := v_payload || jsonb_build_object(
      'enrollment_documents',
      coalesce(
        (
          select jsonb_agg(row_to_json(ed.*))
            from enrollment_documents ed
           where ed.enrollment_id = v_enrollment.id
        ),
        '[]'::jsonb
      )
    );
  else
    v_payload := v_payload || jsonb_build_object('enrollment', null, 'enrollment_student_ids', '[]'::jsonb, 'enrollment_documents', '[]'::jsonb);
  end if;

  v_payload := v_payload || jsonb_build_object(
    'fees',
    coalesce(
      (
        select jsonb_agg(row_to_json(f.*))
        from fee f
        where f.student_id in (
          select sg.student_id
          from student_guardian sg
          where sg.guardian_id = v_guardian.id
        )
          and coalesce(
            f.year_academico,
            cast(extract(year from f.due_date) as int),
            v_current_year
          ) >= v_current_year - 2
      ),
      '[]'::jsonb
    )
  );

  v_payload := v_payload || jsonb_build_object('enrollments', v_enrollments);
  v_payload := v_payload || jsonb_build_object('available_enrollment_years', v_available_years);

  if v_current_enrollment.id is not null then
    v_payload := v_payload || jsonb_build_object('current_enrollment_year', v_current_enrollment.year);
  end if;
  if v_next_enrollment.id is not null then
    v_payload := v_payload || jsonb_build_object('upcoming_enrollment_year', v_next_enrollment.year);
  end if;

  return v_payload;
end;
$$;
