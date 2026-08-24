-- Adds the Life Group feature: a new "lg_leader" profile role and a bible-study
-- attendance table. Run this in the Supabase SQL Editor (no migration tooling in
-- this repo — same manual pattern as the earlier Attendees/category changes).
--
-- Before running: check what role values are actually in use right now, since the
-- checked-in copy of the schema has drifted from the live DB before:
--   select distinct role from profiles;
-- If that returns anything besides regular/admin/superadmin/deactivated, add it to
-- the ARRAY below too, or this ALTER will fail.

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check
  CHECK (role = ANY (ARRAY[
    'regular'::text,
    'admin'::text,
    'superadmin'::text,
    'deactivated'::text,
    'lg_leader'::text
  ]));

CREATE TABLE IF NOT EXISTS public.lg_attendance (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id uuid NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  life_group_leader text NOT NULL,
  session_date date NOT NULL,
  present boolean DEFAULT true,
  recorded_by uuid,
  note text,
  created_at timestamptz DEFAULT now(),
  UNIQUE (member_id, session_date)
);

-- This project enforces RLS by default, and a new table gets no policy (= all access
-- denied) until one is added — mirror whatever the existing "attendance" table allows
-- for logged-in app users.
ALTER TABLE public.lg_attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read lg_attendance"
  ON public.lg_attendance FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated can insert lg_attendance"
  ON public.lg_attendance FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated can update lg_attendance"
  ON public.lg_attendance FOR UPDATE
  TO authenticated
  USING (true) WITH CHECK (true);
