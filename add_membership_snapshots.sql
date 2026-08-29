-- Monthly membership-count history for the Reports > Growth tab.
-- One row per (month, category_group, member_type). The app upserts the
-- current month's counts every time the report loads, so history locks in
-- naturally as each calendar month passes — no cron job needed.

CREATE TABLE IF NOT EXISTS public.membership_snapshots (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  snapshot_month date NOT NULL,
  category_group text NOT NULL,
  member_type text NOT NULL,
  count integer NOT NULL DEFAULT 0,
  updated_at timestamptz DEFAULT now(),
  UNIQUE (snapshot_month, category_group, member_type)
);

ALTER TABLE public.membership_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated can read membership_snapshots"
  ON public.membership_snapshots FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated can insert membership_snapshots"
  ON public.membership_snapshots FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated can update membership_snapshots"
  ON public.membership_snapshots FOR UPDATE
  TO authenticated
  USING (true) WITH CHECK (true);
