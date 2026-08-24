-- Tracks each Life Group's own status (separate from individual member categories):
-- new groups start "probationary" and need a manual admin approval to become
-- "official", with a minimum 3-month probation window.

CREATE TABLE IF NOT EXISTS public.life_groups (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  leader_name text NOT NULL UNIQUE,
  status text NOT NULL DEFAULT 'probationary' CHECK (status IN ('probationary', 'official')),
  created_at timestamptz DEFAULT now(),
  approved_at timestamptz,
  approved_by uuid
);

ALTER TABLE public.life_groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read life_groups"
  ON public.life_groups FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated can insert life_groups"
  ON public.life_groups FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated can update life_groups"
  ON public.life_groups FOR UPDATE
  TO authenticated
  USING (true) WITH CHECK (true);

-- Grandfather in every Life Group that already exists today (identified by the
-- distinct "lifegroup_leader" values already on members) as "official" — only
-- brand-new groups formed from here on should start in probation.
INSERT INTO public.life_groups (leader_name, status, created_at, approved_at)
SELECT DISTINCT trim(lifegroup_leader), 'official', now(), now()
FROM public.members
WHERE lifegroup_leader IS NOT NULL AND trim(lifegroup_leader) <> ''
ON CONFLICT (leader_name) DO NOTHING;
