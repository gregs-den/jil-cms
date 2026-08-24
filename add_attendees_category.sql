-- Run this once in the Supabase SQL Editor to allow "Attendees" as a member category.
-- (This repo has no migration tooling — schema changes are applied by hand against
-- the live database, same as the recent birthdate_updated_at column.)

ALTER TABLE public.members DROP CONSTRAINT IF EXISTS members_category_check;

ALTER TABLE public.members ADD CONSTRAINT members_category_check
  CHECK (category = ANY (ARRAY[
    'WSAM'::text,
    'LGAM'::text,
    'WSAM/LGAM'::text,
    'First Timer'::text,
    'Attendees'::text,
    'Guest'::text
  ]));
