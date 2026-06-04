delete from public.fee
where year_academico = 2026
  and student_id = any(array[
    '195577c6-a45c-4e97-9de3-76ebc4af4f09'::uuid,
    '40812bca-c859-4aab-b744-e017cd94d974'::uuid,
    '5a907b42-8a3a-4742-9aa1-4b02b6884045'::uuid,
    '6812c399-a2ac-4f08-9a56-289848c655be'::uuid,
    '8100f568-89d1-4330-acb0-5ead711d631d'::uuid,
    '83ea7cec-45c4-4b60-b89e-f141671108ed'::uuid,
    'bf024ee2-4e96-4c70-97c3-584d5669ddb1'::uuid
  ]);