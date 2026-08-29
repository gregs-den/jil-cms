-- Evolves Life Groups from "one row per leader" into real group entities:
-- a leader can now run multiple groups, each with its own name, demographic
-- type, address, and start date.

-- A leader can now have more than one group.
ALTER TABLE public.life_groups DROP CONSTRAINT IF EXISTS life_groups_leader_name_key;

ALTER TABLE public.life_groups
  ADD COLUMN IF NOT EXISTS name text,
  ADD COLUMN IF NOT EXISTS group_type text,
  ADD COLUMN IF NOT EXISTS address text,
  ADD COLUMN IF NOT EXISTS started_at date;

-- Backfill existing groups (currently one per leader): name after the leader,
-- start date from when the row was created. group_type is left NULL — an
-- admin needs to classify each existing group by hand (no source data for it).
UPDATE public.life_groups
SET name = leader_name || '''s Life Group'
WHERE name IS NULL;

UPDATE public.life_groups
SET started_at = created_at::date
WHERE started_at IS NULL;

ALTER TABLE public.life_groups
  ALTER COLUMN name SET NOT NULL;

ALTER TABLE public.life_groups DROP CONSTRAINT IF EXISTS life_groups_group_type_check;
ALTER TABLE public.life_groups ADD CONSTRAINT life_groups_group_type_check
  CHECK (group_type IS NULL OR group_type IN ('Men', 'Women', 'Young Adult', 'KKB', 'Children', 'Hetero'));

-- A member now belongs to a specific group (not just "whoever's leader name
-- matches their free-text field"), since one leader can run several groups.
ALTER TABLE public.members
  ADD COLUMN IF NOT EXISTS life_group_id uuid REFERENCES public.life_groups(id);

-- Backfill: existing data is unambiguous today (one group per leader), so this
-- mapping is exact.
UPDATE public.members m
SET life_group_id = lg.id
FROM public.life_groups lg
WHERE m.life_group_id IS NULL
  AND trim(m.lifegroup_leader) <> ''
  AND trim(m.lifegroup_leader) = lg.leader_name;

-- Same for attendance history, so past Bible-study records stay attributable
-- to the correct specific group.
ALTER TABLE public.lg_attendance
  ADD COLUMN IF NOT EXISTS life_group_id uuid REFERENCES public.life_groups(id);

UPDATE public.lg_attendance la
SET life_group_id = lg.id
FROM public.life_groups lg
WHERE la.life_group_id IS NULL
  AND trim(la.life_group_leader) = lg.leader_name;
