-- life_groups was missing a DELETE policy (only SELECT/INSERT/UPDATE existed),
-- so prior delete attempts on test rows silently affected 0 rows instead of
-- erroring — the row just kept reappearing. Adds the policy, then removes the
-- leftover "ZZZ TEST New Leader (delete me)" group left over from earlier testing.

CREATE POLICY "Authenticated can delete life_groups"
  ON public.life_groups FOR DELETE
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated can delete lg_attendance"
  ON public.lg_attendance FOR DELETE
  TO authenticated
  USING (true);

DELETE FROM public.lg_attendance WHERE life_group_id = 'f40ca9a7-0f0f-4b6b-b3a8-392d834d45a7';
UPDATE public.members SET life_group_id = NULL WHERE life_group_id = 'f40ca9a7-0f0f-4b6b-b3a8-392d834d45a7';
DELETE FROM public.life_groups WHERE id = 'f40ca9a7-0f0f-4b6b-b3a8-392d834d45a7';
