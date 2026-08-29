-- Removes the duplicate "abdonn" profile that was accidentally created for
-- Abdon, Nolasco alongside his real lg_leader account "abdon.n". He was
-- logging in with abdonn (role: regular) while the leader promotion was
-- applied to abdon.n, which is why he saw "no access" on Life Group.
--
-- This only removes the profiles row — the underlying auth.users login for
-- abdonn will still exist afterward but won't resolve to a working account in
-- the app (username lookup fails), so it's effectively disabled. If you want
-- it fully gone, also delete it from Supabase Dashboard -> Authentication ->
-- Users after running this.

DELETE FROM public.profiles WHERE username = 'abdonn';
