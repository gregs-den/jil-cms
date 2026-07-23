--
-- PostgreSQL database dump
--

\restrict tqHUTkIbScTtIG8RzyrYzv5m3j5SceGJFjZrl7aduqKTv8lKVLgHEBi59663ROF

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
  insert into public.profiles (id, name, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', new.email),
    'regular'
  );
  return new;
end;
$$;


ALTER FUNCTION public.handle_new_user() OWNER TO postgres;

--
-- Name: is_admin(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_admin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    AS $$
  select exists (
    select 1 from profiles
    where id = auth.uid() and role in ('admin', 'superadmin')
  );
$$;


ALTER FUNCTION public.is_admin() OWNER TO postgres;

--
-- Name: rls_auto_enable(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.rls_auto_enable() RETURNS event_trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION public.rls_auto_enable() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: announcement_reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.announcement_reactions (
    id bigint NOT NULL,
    announcement_id bigint,
    member_id uuid,
    emoji text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.announcement_reactions OWNER TO postgres;

--
-- Name: announcement_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.announcement_reactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.announcement_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.announcements (
    id bigint NOT NULL,
    title text NOT NULL,
    body text,
    tag text,
    date text,
    created_at timestamp with time zone DEFAULT now(),
    branch_id uuid
);


ALTER TABLE public.announcements OWNER TO postgres;

--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.announcements ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.app_settings (
    key text NOT NULL,
    value text
);


ALTER TABLE public.app_settings OWNER TO postgres;

--
-- Name: attendance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.attendance (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid,
    branch_id uuid,
    service_date date NOT NULL,
    present boolean DEFAULT true NOT NULL,
    recorded_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    event_id bigint,
    checked_in_at timestamp with time zone DEFAULT now(),
    note text
);


ALTER TABLE public.attendance OWNER TO postgres;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    user_name text,
    action text NOT NULL,
    entity text,
    entity_id text,
    details text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- Name: birthday_greetings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.birthday_greetings (
    id bigint NOT NULL,
    event_id bigint,
    member_id uuid,
    message text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.birthday_greetings OWNER TO postgres;

--
-- Name: birthday_greetings_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.birthday_greetings ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.birthday_greetings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: branches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.branches (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    address text,
    created_at timestamp with time zone DEFAULT now(),
    parent_id uuid
);


ALTER TABLE public.branches OWNER TO postgres;

--
-- Name: event_reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_reactions (
    id bigint NOT NULL,
    event_id bigint,
    member_id uuid,
    emoji text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.event_reactions OWNER TO postgres;

--
-- Name: event_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.event_reactions ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.event_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    id bigint NOT NULL,
    name text NOT NULL,
    type text DEFAULT 'event'::text,
    date text,
    branch text,
    created_at timestamp with time zone DEFAULT now(),
    branch_id uuid
);


ALTER TABLE public.events OWNER TO postgres;

--
-- Name: events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: finance_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.finance_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.finance_categories OWNER TO postgres;

--
-- Name: finance_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.finance_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid,
    branch_id uuid,
    type text,
    amount numeric(12,2) NOT NULL,
    record_date date DEFAULT CURRENT_DATE NOT NULL,
    recorded_by uuid,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT finance_records_type_check CHECK ((type = ANY (ARRAY['Tithes'::text, 'Offering'::text, 'Pledges'::text, 'Mission'::text, 'Support'::text, 'iCare'::text, 'First Fruit'::text])))
);


ALTER TABLE public.finance_records OWNER TO postgres;

--
-- Name: giving; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.giving (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid,
    type text,
    amount numeric,
    note text,
    date date DEFAULT CURRENT_DATE,
    branch text,
    created_at timestamp with time zone DEFAULT now(),
    branch_id uuid
);


ALTER TABLE public.giving OWNER TO postgres;

--
-- Name: members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_code text NOT NULL,
    name text NOT NULL,
    birthdate date,
    address text,
    category text,
    member_type text,
    lifegroup_leader text,
    branch_id uuid,
    points integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    type text,
    branch text,
    user_id uuid,
    is_active boolean DEFAULT true,
    gender text,
    status text DEFAULT 'Active'::text,
    CONSTRAINT members_category_check CHECK ((category = ANY (ARRAY['WSAM'::text, 'LGAM'::text, 'WSAM/LGAM'::text, 'First Timer'::text, 'Guest'::text]))),
    CONSTRAINT members_member_type_check CHECK ((member_type = ANY (ARRAY['Kids'::text, 'Youth'::text, 'Young Adult'::text, 'Men'::text, 'Women'::text, 'Senior'::text]))),
    CONSTRAINT valid_status CHECK ((status = ANY (ARRAY['Active'::text, 'Delisted'::text, 'Deceased'::text])))
);


ALTER TABLE public.members OWNER TO postgres;

--
-- Name: monthly_theme; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.monthly_theme (
    id integer DEFAULT 1 NOT NULL,
    image_url text,
    updated_at timestamp with time zone DEFAULT now(),
    color text DEFAULT '#1D4ED8'::text
);


ALTER TABLE public.monthly_theme OWNER TO postgres;

--
-- Name: prayer_prays; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prayer_prays (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    prayer_request_id uuid,
    member_id uuid,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.prayer_prays OWNER TO postgres;

--
-- Name: prayer_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prayer_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    member_id uuid,
    title text NOT NULL,
    description text NOT NULL,
    category text DEFAULT 'General'::text,
    is_anonymous boolean DEFAULT false,
    status text DEFAULT 'pending'::text,
    prayer_count integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    expires_at timestamp without time zone DEFAULT (now() + '30 days'::interval),
    updated_at timestamp without time zone DEFAULT now(),
    branch_id uuid
);


ALTER TABLE public.prayer_requests OWNER TO postgres;

--
-- Name: prayer_responses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prayer_responses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    prayer_request_id uuid,
    member_id uuid,
    message text NOT NULL,
    is_prayer boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.prayer_responses OWNER TO postgres;

--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    name text NOT NULL,
    role text DEFAULT 'regular'::text NOT NULL,
    branch_id uuid,
    member_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    username text,
    theme_color text DEFAULT 'blue'::text,
    CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['regular'::text, 'admin'::text, 'superadmin'::text])))
);


ALTER TABLE public.profiles OWNER TO postgres;

--
-- Name: service_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_events (
    id bigint NOT NULL,
    event text NOT NULL,
    date date NOT NULL,
    "time" time without time zone NOT NULL,
    branch text NOT NULL,
    expiry timestamp with time zone NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.service_events OWNER TO postgres;

--
-- Name: service_events_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.service_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.service_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: announcement_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.announcement_reactions (id, announcement_id, member_id, emoji, created_at) FROM stdin;
17	6	480cd97b-4cc6-45ce-b004-9f08bf8a4650	🙏	2026-06-29 13:46:27.116188+00
18	6	480cd97b-4cc6-45ce-b004-9f08bf8a4650	❤️	2026-06-29 13:46:29.241135+00
22	8	ceec8411-7036-45f9-8df9-f13db0601590	👏	2026-07-05 00:36:47.802853+00
24	8	0e97dc12-046f-4b6d-9883-8651dd436ce0	❤️	2026-07-06 14:05:54.503114+00
26	9	0e97dc12-046f-4b6d-9883-8651dd436ce0	🔥	2026-07-08 02:24:08.455091+00
27	9	0e97dc12-046f-4b6d-9883-8651dd436ce0	👏	2026-07-08 02:34:19.761501+00
\.


--
-- Data for Name: announcements; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.announcements (id, title, body, tag, date, created_at, branch_id) FROM stdin;
6	Sunday Service worship	join us	Worship	june 30, 2026	2026-06-29 13:32:31.948612+00	e319ab92-b31d-4512-9126-0a12a86b69bc
8	Sunday Worship Service	Join us with our Month's Theme: Breakthrough Patience That Sustains	Announcement	July 5 2026	2026-07-04 07:39:12.406415+00	\N
9	Sunday Service Worship	Breakthrough: Patience That Sustains - James 1:3-4	Announcement	July 30,2026	2026-07-08 02:23:12.292475+00	\N
11	Whole Month of July	Breakthrough: Patience That Sustains - James 1:3-4	Announcement	July 31, 2026	2026-07-08 03:20:03.864832+00	e319ab92-b31d-4512-9126-0a12a86b69bc
\.


--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.app_settings (key, value) FROM stdin;
church_name	JIL Pinamalayan
contact_phone	0934674658768
contact_email	jilpinamalayan@gmail.com
logo_url	https://xmqdtzlyrxeruagicple.supabase.co/storage/v1/object/public/theme/logo-1781795745379.png
address	Pinamalayan, Oriental Mindoro
bg_url	https://xmqdtzlyrxeruagicple.supabase.co/storage/v1/object/public/theme/bg-1781800135081.png
finance_bg_url	https://xmqdtzlyrxeruagicple.supabase.co/storage/v1/object/public/theme/finance-bg-1781800153690.png
announcement_bg_url	https://xmqdtzlyrxeruagicple.supabase.co/storage/v1/object/public/theme/ann-bg-1781800166829.png
theme	midnight
\.


--
-- Data for Name: attendance; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.attendance (id, member_id, branch_id, service_date, present, recorded_by, created_at, event_id, checked_in_at, note) FROM stdin;
a03e1cfd-10a0-438f-88df-6935a31e8588	cbe8fc96-165f-4b41-ab04-ed496f567496	\N	2026-06-16	t	\N	2026-06-16 05:09:05.232551+00	6	2026-06-16 05:09:05.232551+00	\N
0e1a3a6d-e3fb-4a37-9ceb-bc0d7a9b683b	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-16	t	\N	2026-06-16 09:04:21.030848+00	6	2026-06-16 09:04:21.030848+00	\N
31691a72-5d35-4e32-9682-3b463ff97bea	b69e0d20-e229-4210-807f-35119377abe6	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-16	t	\N	2026-06-16 14:06:48.54446+00	6	2026-06-16 14:06:48.54446+00	forgot cause he is the musician
237d29ab-4f34-48d4-9bbb-902d6067039c	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-15	t	\N	2026-06-16 14:16:59.232584+00	5	2026-06-16 14:16:59.232584+00	\N
868faaec-cecf-4bfa-a1fc-fe91aae6a71e	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-18	t	\N	2026-06-18 14:32:26.88161+00	8	2026-06-18 14:32:26.88161+00	\N
735d79ba-658f-43c0-966b-4f1bafc620e5	fc69a073-d6e9-41d7-986c-4d45447a4eba	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-18	t	\N	2026-06-18 14:34:21.961294+00	8	2026-06-18 14:34:21.961294+00	\N
dc206989-3725-43f4-9a30-98120c8c796c	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-20	t	\N	2026-06-20 10:37:19.152606+00	9	2026-06-20 10:37:19.152606+00	\N
f0effad6-c526-4ccd-b2d0-d8de70a14b2e	d9526726-1b9a-43ef-9186-811832e29197	\N	2026-06-20	t	\N	2026-06-20 10:43:46.367034+00	9	2026-06-20 10:43:46.367034+00	\N
8e36eab8-e645-48d9-b511-599b3e8a43fc	5996dedd-c7d5-4bd8-83c7-f297507355d1	\N	2026-06-21	t	\N	2026-06-21 00:41:49.226831+00	10	2026-06-21 00:41:49.226831+00	\N
63c90d1d-c29b-4ed8-9527-506ba73d41d6	02ef26bb-ae4e-4573-8ee9-6e3f8772afe2	\N	2026-06-21	t	\N	2026-06-21 00:45:33.132432+00	10	2026-06-21 00:45:33.132432+00	\N
5f6cd19f-01f6-45bc-a2f9-af3be3c70a50	12e0ef3b-eeaa-4873-990d-f99b893a758c	\N	2026-06-21	t	\N	2026-06-21 00:46:54.842496+00	10	2026-06-21 00:46:54.842496+00	\N
cb78e667-9c78-480d-9eb9-60958c513c47	cbe8fc96-165f-4b41-ab04-ed496f567496	\N	2026-06-21	t	\N	2026-06-21 00:48:47.060923+00	10	2026-06-21 00:48:47.060923+00	\N
4314d83c-b769-4ce2-ac97-6ee4b4ec7525	173629cc-3607-4df3-ac3b-7b20fb3c64db	\N	2026-06-21	t	\N	2026-06-21 00:49:01.296994+00	10	2026-06-21 00:49:01.296994+00	\N
8a017a59-2e1d-489f-93f9-123e4d0e9b6b	2b4402e5-72b0-4396-9556-fe0362179bb5	\N	2026-06-21	t	\N	2026-06-21 00:49:34.122837+00	10	2026-06-21 00:49:34.122837+00	\N
e2cb3050-9d58-42f7-8380-6dd8339b189d	f8bd29d9-d6ba-4d45-9738-de6b78066ba1	\N	2026-06-21	t	\N	2026-06-21 00:50:01.483441+00	10	2026-06-21 00:50:01.483441+00	\N
d5c27802-3ad7-4b2e-bb78-52eaf9ca92ce	566c3572-7f46-403c-900f-c8ee777efc37	\N	2026-06-21	t	\N	2026-06-21 00:50:25.703366+00	10	2026-06-21 00:50:25.703366+00	\N
daf44966-c134-411c-8311-f260b8f2c6c4	64cbb814-aea5-4a81-a9d4-1fa772dfc6c2	\N	2026-06-21	t	\N	2026-06-21 00:52:42.625725+00	10	2026-06-21 00:52:42.625725+00	\N
b78d3cfa-e248-4d6f-a4a9-167690397837	79843090-2b95-4228-82f4-2f2cb0e808da	\N	2026-06-21	t	\N	2026-06-21 00:53:21.606609+00	10	2026-06-21 00:53:21.606609+00	\N
6e8abc54-a9eb-4485-8c15-225dbb096ed4	52f8fce3-318b-4761-b71f-d354169e8aa3	\N	2026-06-21	t	\N	2026-06-21 00:53:45.325805+00	10	2026-06-21 00:53:45.325805+00	\N
caeaab3f-e45d-472e-b77f-383ab1a3b332	587d80e4-9544-4d0e-b4f6-8d70c4f94339	\N	2026-06-21	t	\N	2026-06-21 00:55:11.770353+00	10	2026-06-21 00:55:11.770353+00	\N
a38a7517-68eb-479c-8a4b-907efc76fc8a	c13c4cd0-9b1c-41dc-a586-c0bc45cd5981	\N	2026-06-21	t	\N	2026-06-21 00:55:31.411248+00	10	2026-06-21 00:55:31.411248+00	\N
d0a412b1-7377-47fc-8cf9-e31cdac41362	6369071b-a2fc-4cfc-a5ce-e255012a974e	\N	2026-06-21	t	\N	2026-06-21 00:55:55.745945+00	10	2026-06-21 00:55:55.745945+00	\N
84c87b38-7b8b-4577-9bac-c08ef67e21a8	02cb479d-680a-4087-952d-eae76bfe1bf1	\N	2026-06-21	t	\N	2026-06-21 00:56:21.303084+00	10	2026-06-21 00:56:21.303084+00	\N
5a02640a-1b51-48bd-86c6-06e308fa4944	82e44072-b750-4c63-9da4-3605604f8731	\N	2026-06-21	t	\N	2026-06-21 00:56:34.850954+00	10	2026-06-21 00:56:34.850954+00	\N
adfc5685-cb90-4b7f-a361-97675043dc0f	ca65ec58-3956-4d5a-8c62-d2fb531e76b2	\N	2026-06-21	t	\N	2026-06-21 00:56:49.160925+00	10	2026-06-21 00:56:49.160925+00	\N
d90f4d80-66ef-4736-9189-653ae1639a90	a1377609-e9be-4217-9b95-8514a51c84ec	\N	2026-06-21	t	\N	2026-06-21 00:57:54.852091+00	10	2026-06-21 00:57:54.852091+00	\N
86c5f506-a874-452a-bba6-bbd44e554759	9a1cdb26-a48d-4074-a40f-a36ebf8008f6	\N	2026-06-21	t	\N	2026-06-21 00:58:09.771895+00	10	2026-06-21 00:58:09.771895+00	\N
6007baf6-9353-4046-8d9e-2c74aa2de338	2623ed6d-71ab-431d-8a45-c74dab443a48	\N	2026-06-21	t	\N	2026-06-21 00:58:36.640629+00	10	2026-06-21 00:58:36.640629+00	\N
06443863-70e9-4cb4-9e7b-4810f9dba634	981fb578-7140-4e36-9780-12a4fb94a6b8	\N	2026-06-21	t	\N	2026-06-21 01:00:38.47632+00	10	2026-06-21 01:00:38.47632+00	\N
fbeaa4d0-22e1-4003-8bfa-0806041ec687	72a076f8-c919-4f30-8adc-19710568511d	\N	2026-06-21	t	\N	2026-06-21 01:01:18.727603+00	10	2026-06-21 01:01:18.727603+00	\N
366e77bd-6f0b-4f10-8d3a-898580610cde	cd2bfb39-f90a-419d-a24a-da3a98bcc336	\N	2026-06-21	t	\N	2026-06-21 01:01:37.082059+00	10	2026-06-21 01:01:37.082059+00	\N
7ea2b321-5554-4249-9a3f-b6be5da08e46	c14a7d27-197e-4bfc-92b3-64644dca20e2	\N	2026-06-21	t	\N	2026-06-21 01:01:46.135596+00	10	2026-06-21 01:01:46.135596+00	\N
d01201c9-508f-4082-94ce-46ade6ab33d9	37908ad3-6a80-47a2-8747-c71b70c0cc02	\N	2026-06-21	t	\N	2026-06-21 01:01:59.924656+00	10	2026-06-21 01:01:59.924656+00	\N
09d5fd1d-bd1c-4ebf-9b01-3f9755b73912	66803bd3-d447-42f3-89fa-87eaed56d6a4	\N	2026-06-21	t	\N	2026-06-21 01:02:17.881324+00	10	2026-06-21 01:02:17.881324+00	\N
7940d134-d300-40f4-8bf4-5cef6185a5d9	6ca43bf0-36dd-4aff-b0f6-d3197376644a	\N	2026-06-21	t	\N	2026-06-21 01:03:18.738804+00	10	2026-06-21 01:03:18.738804+00	\N
8983dcc6-f175-4986-8cee-a74f7572999f	1f8077c5-af7c-4350-8430-9f032722b8bd	\N	2026-06-21	t	\N	2026-06-21 01:03:38.779711+00	10	2026-06-21 01:03:38.779711+00	\N
5cfc9e98-322d-4623-8804-3cd1da246739	e61253d5-41ca-404b-ac3e-a2b01e6a8032	\N	2026-06-21	t	\N	2026-06-21 01:03:52.321079+00	10	2026-06-21 01:03:52.321079+00	\N
5926a2a5-234a-447c-93b3-5adbcb5c8741	1e31aa0e-86cd-407a-ab1d-b227a7f43fcc	\N	2026-06-21	t	\N	2026-06-21 01:04:20.121286+00	10	2026-06-21 01:04:20.121286+00	\N
2ff42271-84f2-45f0-9c45-f94d429122f9	b69e0d20-e229-4210-807f-35119377abe6	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-21	t	\N	2026-06-21 01:05:07.910317+00	10	2026-06-21 01:05:07.910317+00	\N
c9e24fe7-7fd0-4c25-81c5-e59a2c3ab5f3	285d9d80-cfc9-405b-8310-d84710d2e8b5	\N	2026-06-21	t	\N	2026-06-21 01:05:17.020948+00	10	2026-06-21 01:05:17.020948+00	\N
d21e098e-50b9-45d9-8697-f58d0eb1a390	270248b7-e849-47fe-a9fe-c2dbb8b9008d	\N	2026-06-21	t	\N	2026-06-21 01:06:14.681596+00	10	2026-06-21 01:06:14.681596+00	\N
5e90b14f-7b69-4265-b7fc-5db7b7a67525	e5c6c350-4b2f-4f28-9a98-011e513f1583	\N	2026-06-21	t	\N	2026-06-21 01:06:47.654499+00	10	2026-06-21 01:06:47.654499+00	\N
59b8426e-9179-4166-80c2-d71544a40f9b	e855a73b-e58b-41ed-819d-b95cea314837	\N	2026-06-21	t	\N	2026-06-21 01:07:11.919949+00	10	2026-06-21 01:07:11.919949+00	\N
2e2237fb-bc37-4415-8108-1c7235be928b	37a3403a-6d49-4703-b78f-416c732e7e1f	\N	2026-06-21	t	\N	2026-06-21 01:07:23.810981+00	10	2026-06-21 01:07:23.810981+00	\N
2c0ef372-9fb2-4f41-a428-8c9beca0906f	010165e9-2c36-4e06-aed6-3f7a548d93be	\N	2026-06-21	t	\N	2026-06-21 01:07:42.146398+00	10	2026-06-21 01:07:42.146398+00	\N
7339f9f8-10cf-4b18-9f0a-afd78f57e416	92a0a1ea-976c-403d-bf2b-eda30baaae6b	\N	2026-06-21	t	\N	2026-06-21 01:08:48.381283+00	10	2026-06-21 01:08:48.381283+00	\N
98ea7610-7fad-4d96-9e75-35c88fe53ab0	ec18ecea-d03a-43ad-9a55-9d46704d2869	\N	2026-06-21	t	\N	2026-06-21 01:09:20.738107+00	10	2026-06-21 01:09:20.738107+00	\N
64c4d85d-e069-4e39-b03b-e099f1b4c913	7124a3ab-dee2-4949-856a-6606e9cb3fe5	\N	2026-06-21	t	\N	2026-06-21 01:09:41.725516+00	10	2026-06-21 01:09:41.725516+00	\N
5a314596-9c40-427c-87b5-b0828a2bc031	08b62f39-de02-4f1c-ad4c-65516384a75c	\N	2026-06-21	t	\N	2026-06-21 01:22:36.240328+00	10	2026-06-21 01:22:36.240328+00	\N
8280e8e8-0593-4eca-8571-84b1a2b6dba3	a7449003-7672-457c-853d-2b391dc7a37f	\N	2026-06-21	t	\N	2026-06-21 01:23:13.632295+00	10	2026-06-21 01:23:13.632295+00	\N
abd3b8e2-0011-4a52-bb38-b81d766e8e88	7293eb16-166e-41eb-b939-fba5192332e8	\N	2026-06-21	t	\N	2026-06-21 01:23:52.862462+00	10	2026-06-21 01:23:52.862462+00	\N
424bcee9-f08f-414a-8e11-cb1f9d4fbf8b	6338b1d6-f55e-4e6e-a3c6-758256a45e6d	\N	2026-06-21	t	\N	2026-06-21 01:24:21.472974+00	10	2026-06-21 01:24:21.472974+00	\N
5b58f3c2-cde9-45c7-a0c6-9b9c406d399b	638160ab-dcb6-43d7-a417-3ecfcabbacd4	\N	2026-06-21	t	\N	2026-06-21 01:24:33.564037+00	10	2026-06-21 01:24:33.564037+00	\N
355d9166-f9ae-4473-b644-45313e0072bb	958c65fd-c4d5-4394-8d62-e9d72bb1b3ea	\N	2026-06-21	t	\N	2026-06-21 01:24:54.221953+00	10	2026-06-21 01:24:54.221953+00	\N
2d24fdc6-ea42-49d0-ba5f-977c8a80c7a4	7d050ab6-9019-4425-bc0c-552dc0eff256	\N	2026-06-21	t	\N	2026-06-21 01:25:09.592574+00	10	2026-06-21 01:25:09.592574+00	\N
841ddd1c-565e-4c45-b6e0-e3a299351bbc	ac35dd23-d860-4905-ab8f-0fde81f5ce88	\N	2026-06-21	t	\N	2026-06-21 01:25:29.165743+00	10	2026-06-21 01:25:29.165743+00	\N
dc246549-3b3b-44ed-ba6e-02fb882b25d3	6f69e8b5-4f73-4ebc-a3bd-0a4462870bbc	\N	2026-06-21	t	\N	2026-06-21 01:25:46.00729+00	10	2026-06-21 01:25:46.00729+00	\N
5e56378d-37c7-4b42-b904-332af72114a1	4266ec51-58e4-4486-afbe-f13d24ff2210	\N	2026-06-21	t	\N	2026-06-21 01:26:17.373688+00	10	2026-06-21 01:26:17.373688+00	\N
91142e85-2b07-4443-99c7-01c45c6f806d	4319944f-03e5-4a57-9722-180364fad573	\N	2026-06-21	t	\N	2026-06-21 01:27:43.341923+00	10	2026-06-21 01:27:43.341923+00	\N
6e4fabd0-81a5-4371-907e-d5affa1e5e61	257d7932-c151-4929-b4db-344374438de8	\N	2026-06-21	t	\N	2026-06-21 01:28:44.486415+00	10	2026-06-21 01:28:44.486415+00	\N
183376c4-05b2-4b92-99b4-4ee1eb0f1269	a8a9c3b1-e52c-4789-a093-0c5a94381d13	\N	2026-06-21	t	\N	2026-06-21 01:29:30.654868+00	10	2026-06-21 01:29:30.654868+00	\N
e440ab9c-9913-4ec0-a398-d6677c1fa53b	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-21	t	\N	2026-06-21 01:30:49.448165+00	10	2026-06-21 01:30:49.448165+00	\N
c56d7b53-ec86-415b-baa7-f575b50ab0d3	a651b2a0-d8a4-4369-8825-dd0ebee15871	\N	2026-06-21	t	\N	2026-06-21 01:31:10.188193+00	10	2026-06-21 01:31:10.188193+00	\N
b843c768-d365-4280-bd04-752732259714	a52004f2-2bc7-409a-b09d-6b9f66550648	\N	2026-06-21	t	\N	2026-06-21 02:27:18.173044+00	10	2026-06-21 02:27:18.173044+00	\N
594493c3-b350-4531-9f61-d7fd7e8bbbe7	6caf31bd-d0fa-4167-a332-fa43d1ed44ca	\N	2026-06-21	t	\N	2026-06-21 02:28:32.335366+00	10	2026-06-21 02:28:32.335366+00	\N
ea589653-81f9-4a11-ad5d-b5bf54002e81	6ef7bee6-7cba-46a7-ad34-cce842e3eeff	\N	2026-06-21	t	\N	2026-06-21 02:31:17.275966+00	10	2026-06-21 02:31:17.275966+00	\N
071e934b-d963-4681-b6df-ca67287faec4	16eaf18a-e99c-4530-aaec-8a6e96b99cdb	\N	2026-06-21	t	\N	2026-06-21 02:31:34.157739+00	10	2026-06-21 02:31:34.157739+00	\N
59389612-e62c-4b65-b37b-a9640fee7929	4d648f7d-4745-457e-b0d8-0e8a0dff331d	\N	2026-06-21	t	\N	2026-06-21 02:32:23.205777+00	10	2026-06-21 02:32:23.205777+00	\N
75ac98aa-5325-4554-a407-cd64ab5bce76	25729cc6-db38-4342-9bda-2fe1fd5d5279	\N	2026-06-21	t	\N	2026-06-21 02:33:18.077134+00	10	2026-06-21 02:33:18.077134+00	\N
fae72d21-3c30-41ab-9512-c0019e507000	08496ade-6c10-4623-b70d-c67d531c5f4a	\N	2026-06-21	t	\N	2026-06-21 02:34:04.013039+00	10	2026-06-21 02:34:04.013039+00	\N
3f822585-2bd3-47ac-94f0-625ebc393d2c	0e6428b9-396e-4936-9d84-cac17f8241f8	\N	2026-06-21	t	\N	2026-06-21 02:34:18.103113+00	10	2026-06-21 02:34:18.103113+00	\N
4e536459-4820-4385-ada1-581797063ab8	7cf9e15a-42d8-473d-884f-a3fe10bb64b9	\N	2026-06-21	t	\N	2026-06-21 02:35:26.803721+00	10	2026-06-21 02:35:26.803721+00	\N
f7aa96ea-8697-4ea0-8cd1-f8add89bc615	d715cd09-5d06-442d-bd17-ff0c47ee9071	\N	2026-06-21	t	\N	2026-06-21 02:35:52.709468+00	10	2026-06-21 02:35:52.709468+00	\N
f0d35e76-c8bb-4bed-a645-32ccbf59c9b0	34b2a69d-8173-4da5-a053-bf6dc5db01f0	\N	2026-06-21	t	\N	2026-06-21 02:36:22.562543+00	10	2026-06-21 02:36:22.562543+00	\N
0c1bc2da-f1dc-4e98-9868-d8d94b21cb53	e25732ca-6445-46ab-a726-94bceb349e7f	\N	2026-06-21	t	\N	2026-06-21 02:36:55.646709+00	10	2026-06-21 02:36:55.646709+00	\N
e1bd6c26-390c-4b0b-8567-8b42313ba0eb	2b14e5c3-9164-4794-a4a1-037446d22488	\N	2026-06-21	t	\N	2026-06-21 02:37:25.334801+00	10	2026-06-21 02:37:25.334801+00	\N
6c7010e5-daff-4418-8fa6-30830130028a	5d79d53d-be89-42c7-a8b9-c86523207d29	\N	2026-06-21	t	\N	2026-06-21 02:38:34.240683+00	10	2026-06-21 02:38:34.240683+00	\N
9b14980f-2ec0-4b85-ae21-05b8a915889d	17c66a47-97ba-466a-966b-fe4d96d369a0	\N	2026-06-21	t	\N	2026-06-21 02:38:47.574947+00	10	2026-06-21 02:38:47.574947+00	\N
50d725ff-5e56-4b3e-b384-53fd34aaa6c3	90c2cf00-edc1-408d-a89c-9c28e4697f8d	\N	2026-06-21	t	\N	2026-06-21 02:39:14.677641+00	10	2026-06-21 02:39:14.677641+00	\N
14138cf6-9ac6-4f9a-bedd-08b8c60b7e35	9bacb1d4-162d-47f1-9b89-36b637c2331e	\N	2026-06-21	t	\N	2026-06-21 02:39:32.862825+00	10	2026-06-21 02:39:32.862825+00	\N
81ab1dec-7ec3-4d1c-bce3-28ca632a4901	a4ae75e8-b8fb-4f40-b30b-2365d8324fd2	\N	2026-06-21	t	\N	2026-06-21 02:39:56.395067+00	10	2026-06-21 02:39:56.395067+00	\N
ddf554bb-3455-45b9-ad9b-c9b3d91a3766	480cd97b-4cc6-45ce-b004-9f08bf8a4650	\N	2026-06-21	t	\N	2026-06-21 02:41:58.57198+00	10	2026-06-21 02:41:58.57198+00	\N
68decddd-577b-485a-9c1b-eccc5318a31a	355fd0db-83cd-4e20-9d44-7efe8e9ac2cd	\N	2026-06-21	t	\N	2026-06-21 02:44:25.352989+00	10	2026-06-21 02:44:25.352989+00	\N
c8c7c74f-af65-4080-8d4a-c2288c58fb09	e4333720-3c25-427b-92a8-b6d3a7eb6a9d	\N	2026-06-21	t	\N	2026-06-21 02:40:20.921281+00	10	2026-06-21 02:40:20.921281+00	\N
18d65ec0-85b6-4a80-a43b-1c77f2d71bdb	1d3bc4c0-0e4f-4fdc-955b-31382fd3d120	\N	2026-06-21	t	\N	2026-06-21 02:41:37.299217+00	10	2026-06-21 02:41:37.299217+00	\N
4ed167b1-5bd5-462b-80e3-395686d1677a	22d7b909-c937-437a-8423-cda727b9e299	\N	2026-06-21	t	\N	2026-06-21 02:42:16.214775+00	10	2026-06-21 02:42:16.214775+00	\N
d67627e8-ec1c-4739-a375-1905306dbe00	41750d34-8220-4b8a-a052-7942aed874a4	\N	2026-06-21	t	\N	2026-06-21 02:42:45.745961+00	10	2026-06-21 02:42:45.745961+00	\N
99d57b57-4bd6-493e-891a-baf36704f606	671ca314-2d76-46fe-8d9f-c9c4e6e451bd	\N	2026-06-21	t	\N	2026-06-21 02:43:00.577319+00	10	2026-06-21 02:43:00.577319+00	\N
adf8d0f8-fb20-4880-b069-e28c56b8a0d6	c0461e9f-7877-4f78-9340-6dec1c7bb900	\N	2026-06-21	t	\N	2026-06-21 02:43:42.29254+00	10	2026-06-21 02:43:42.29254+00	\N
0cab59bb-7fa8-409d-9d94-1bc17502c6e0	15473380-816d-42a3-a058-e876140357ad	\N	2026-06-21	t	\N	2026-06-21 02:47:47.80226+00	10	2026-06-21 02:47:47.80226+00	\N
691b71aa-cd97-45a4-a3f9-6b6bee886cdb	814624a8-bbb4-477b-a3b3-160286cbecad	\N	2026-06-21	t	\N	2026-06-21 02:49:41.663052+00	10	2026-06-21 02:49:41.663052+00	\N
44f4991b-715a-4972-97fe-dbd81fc79038	869a19cd-f071-4034-9142-3e6d122e2409	\N	2026-06-21	t	\N	2026-06-21 02:50:00.265006+00	10	2026-06-21 02:50:00.265006+00	\N
31406a67-f573-4c7c-9920-7878222ff332	6466176a-45c5-48ef-a6d4-c1bcf68023b5	\N	2026-06-21	t	\N	2026-06-21 02:50:44.353606+00	10	2026-06-21 02:50:44.353606+00	\N
bfad64f3-96c8-42c5-830a-7a74825d6267	fb7a935c-276d-4a4f-9727-f6a6ae708e8d	\N	2026-06-21	t	\N	2026-06-21 02:52:41.457027+00	10	2026-06-21 02:52:41.457027+00	\N
70677759-c5f3-4a1a-83a1-56da5867101b	99785ae3-8d0e-45f7-aa2e-a5cf9628adca	\N	2026-06-21	t	\N	2026-06-21 02:52:57.095555+00	10	2026-06-21 02:52:57.095555+00	\N
2e8d1c6c-3005-4ea7-8735-a4d5e9917019	3db467e0-9e46-4b17-99d2-3eb1bf00526a	\N	2026-06-21	t	\N	2026-06-21 02:57:20.993922+00	10	2026-06-21 02:57:20.993922+00	\N
7126e72d-128a-4b63-ac68-6964ae937b53	9785feec-4480-42af-baf8-8a9233610652	\N	2026-06-21	t	\N	2026-06-21 02:59:17.99903+00	10	2026-06-21 02:59:17.99903+00	\N
caacd0dd-3bec-4695-baf2-da0b83e59926	59539988-c0cf-4119-978c-976b6a4bce9c	\N	2026-06-21	t	\N	2026-06-21 03:02:17.411741+00	10	2026-06-21 03:02:17.411741+00	\N
bf34a747-ff59-47c4-bb4a-63341b1ac896	1c800bfb-5bc1-4f0e-93f8-d6cc75411182	\N	2026-06-21	t	\N	2026-06-21 03:03:36.980156+00	10	2026-06-21 03:03:36.980156+00	\N
a0b40be6-a7ca-4f93-9821-2d0f2f5f6d2d	f6259078-04af-442c-b1b0-5f95aa2c26da	\N	2026-06-21	t	\N	2026-06-21 03:05:40.687994+00	10	2026-06-21 03:05:40.687994+00	\N
7d93128b-b274-403e-ab14-b596cc309f85	10e98a1d-539c-40e6-ac71-4bf4ab0bb029	\N	2026-06-21	t	\N	2026-06-21 03:06:16.588149+00	10	2026-06-21 03:06:16.588149+00	\N
745b93a7-4380-4797-b95f-e843a950f227	2af9861a-ae3f-4b2d-b672-f0b5f95d350a	\N	2026-06-21	t	\N	2026-06-21 03:07:42.253146+00	10	2026-06-21 03:07:42.253146+00	\N
81516e18-904d-4f45-b7fc-28678a7359c1	48a80a3f-1a4f-4260-839e-25008b15a463	\N	2026-06-21	t	\N	2026-06-21 03:07:47.403261+00	10	2026-06-21 03:07:47.403261+00	\N
13430881-6b7a-4f60-b254-4861ada004c6	a0bbb937-07ac-4235-b0ce-ca9d38e6b9e7	\N	2026-06-21	t	\N	2026-06-21 03:08:20.017933+00	10	2026-06-21 03:08:20.017933+00	\N
cb698aa1-380c-4566-95ee-2b768dec82c9	f0e50ead-69b0-41ba-9bd2-f4800fea7072	\N	2026-06-21	t	\N	2026-06-21 03:09:12.152959+00	10	2026-06-21 03:09:12.152959+00	\N
d563f3ea-bdb7-4e09-b3e8-62c6723dc864	7d723030-17ae-4b51-ae87-2bc434d9f685	\N	2026-06-21	t	\N	2026-06-21 03:09:41.821082+00	10	2026-06-21 03:09:41.821082+00	\N
9f6b47a1-3e29-4ce8-89ee-611f1cc92a5d	20eee381-1cde-474b-9d46-2a38571b0bed	\N	2026-06-21	t	\N	2026-06-21 03:09:50.401042+00	10	2026-06-21 03:09:50.401042+00	\N
80fcac41-dc62-40eb-b0ce-1f7a6e040336	fcce3ece-fb6c-498a-b95b-e883bcc44935	\N	2026-06-21	t	\N	2026-06-21 03:10:33.912657+00	10	2026-06-21 03:10:33.912657+00	\N
1033869e-7129-4239-9cc3-4ada9f460433	ec7fde3e-b530-4199-87ed-6d6f64359301	\N	2026-06-21	t	\N	2026-06-21 03:11:42.640337+00	10	2026-06-21 03:11:42.640337+00	\N
4f72283b-e317-4563-a62f-67822436bfc2	5f1f6df6-587f-4cca-bc20-8d73ed28cd48	\N	2026-06-21	t	\N	2026-06-21 03:13:33.022001+00	10	2026-06-21 03:13:33.022001+00	\N
31838540-9cc5-4aff-b949-753b78f41588	b53621c9-2b60-4fb8-ba67-26dee55d5956	\N	2026-06-21	t	\N	2026-06-21 03:14:26.436957+00	10	2026-06-21 03:14:26.436957+00	\N
ba59ba8d-a674-42a7-90f3-005b17eea636	15543fd3-3bd4-4d88-9d30-2b2b4420cb2f	\N	2026-06-21	t	\N	2026-06-21 03:15:18.557247+00	10	2026-06-21 03:15:18.557247+00	\N
d29dd171-7f23-4693-84f7-d374fa885e23	ee192999-176b-42c7-b3d6-c2c616dd9ec2	\N	2026-06-21	t	\N	2026-06-21 03:16:19.254641+00	10	2026-06-21 03:16:19.254641+00	\N
318f3ca7-f676-4f3a-88e8-76ca82d988bc	f43be6e8-0ab7-4d33-8a36-66a4037daa00	\N	2026-06-21	t	\N	2026-06-21 03:18:51.29068+00	10	2026-06-21 03:18:51.29068+00	\N
d5c641ed-e451-4df7-a765-9e239d3a9120	2306de94-3fb2-4f6c-b94d-be835e7f2c35	\N	2026-06-21	t	\N	2026-06-21 03:20:41.444483+00	10	2026-06-21 03:20:41.444483+00	\N
72847089-65ac-4ccd-aec5-52865bde5d1d	229b6adb-6b77-43ff-aaa9-a611efb86e51	\N	2026-06-21	t	\N	2026-06-21 03:21:17.617694+00	10	2026-06-21 03:21:17.617694+00	\N
1ef857cf-e6a0-4003-b27c-2e67547cd82c	22402836-8c15-48de-99a7-ce61781c7c8a	\N	2026-06-21	t	\N	2026-06-21 03:39:19.67971+00	10	2026-06-21 03:39:19.67971+00	\N
9358cdc9-a238-4510-9a96-6fcd9c88b1f0	6300819d-e78b-405b-87ee-d43207e6eb81	\N	2026-06-21	t	\N	2026-06-21 03:43:46.144259+00	10	2026-06-21 03:43:46.144259+00	\N
d7b87265-56f9-4162-8907-c1298de9b6b2	a1c43c09-51ba-408e-84c5-63491da2139e	\N	2026-06-21	t	\N	2026-06-21 03:43:53.569146+00	10	2026-06-21 03:43:53.569146+00	\N
e5fe19e5-3b48-4848-b652-02ebd5a77780	82e491b7-deca-4a63-8204-66368e7fbb01	\N	2026-06-21	t	\N	2026-06-21 03:48:15.133972+00	10	2026-06-21 03:48:15.133972+00	\N
e392b431-2f0d-4160-bc6e-d313d0164912	b69e0d20-e229-4210-807f-35119377abe6	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-28	t	\N	2026-06-28 00:44:56.996953+00	17	2026-06-28 00:44:56.996953+00	\N
92ee214e-90f8-46db-8882-9f39bd9be8b9	270248b7-e849-47fe-a9fe-c2dbb8b9008d	\N	2026-06-28	t	\N	2026-06-28 00:48:35.598798+00	17	2026-06-28 00:48:35.598798+00	\N
73e80c6c-147d-405c-8204-065206a62c09	08b62f39-de02-4f1c-ad4c-65516384a75c	\N	2026-06-28	t	\N	2026-06-28 00:49:38.821291+00	17	2026-06-28 00:49:38.821291+00	\N
2b20c7a5-653b-4466-918b-c9bf41b19045	e5c6c350-4b2f-4f28-9a98-011e513f1583	\N	2026-06-28	t	\N	2026-06-28 00:51:19.763514+00	17	2026-06-28 00:51:19.763514+00	\N
e0d5b360-bca7-4caf-bafc-7091aa8f3d4a	e855a73b-e58b-41ed-819d-b95cea314837	\N	2026-06-28	t	\N	2026-06-28 00:53:34.293064+00	17	2026-06-28 00:53:34.293064+00	\N
d74eee9b-dd9e-4d1b-8b53-ca734f50d1f3	37a3403a-6d49-4703-b78f-416c732e7e1f	\N	2026-06-28	t	\N	2026-06-28 00:53:57.318351+00	17	2026-06-28 00:53:57.318351+00	\N
cc3ba75b-a905-4898-a3da-c9050e9b8e21	ec18ecea-d03a-43ad-9a55-9d46704d2869	\N	2026-06-28	t	\N	2026-06-28 00:54:27.813261+00	17	2026-06-28 00:54:27.813261+00	\N
14278a56-7c28-42e6-b03b-174a571f2de3	7124a3ab-dee2-4949-856a-6606e9cb3fe5	\N	2026-06-28	t	\N	2026-06-28 00:54:48.876141+00	17	2026-06-28 00:54:48.876141+00	\N
dec048ae-7c4c-4278-9107-bf431fb8ab23	6338b1d6-f55e-4e6e-a3c6-758256a45e6d	\N	2026-06-28	t	\N	2026-06-28 00:55:06.7004+00	17	2026-06-28 00:55:06.7004+00	\N
17402725-7dd8-46a6-93a4-4be48ad87dc7	638160ab-dcb6-43d7-a417-3ecfcabbacd4	\N	2026-06-28	t	\N	2026-06-28 00:55:19.820946+00	17	2026-06-28 00:55:19.820946+00	\N
7df48bff-e103-4978-be6b-e11da361db47	38e7a7c8-1d38-4a24-aecb-a96173ff1aec	\N	2026-06-28	t	\N	2026-06-28 00:55:35.740401+00	17	2026-06-28 00:55:35.740401+00	\N
fd0e81f6-abb4-46f5-8eaf-b12daa261761	6300819d-e78b-405b-87ee-d43207e6eb81	\N	2026-06-28	t	\N	2026-06-28 00:55:51.355678+00	17	2026-06-28 00:55:51.355678+00	\N
38ea378c-4b9c-4c69-bee9-d92a807e5e81	a7449003-7672-457c-853d-2b391dc7a37f	\N	2026-06-28	t	\N	2026-06-28 00:56:03.180609+00	17	2026-06-28 00:56:03.180609+00	\N
74e23cc6-9340-4624-a7e0-2a33e6850eb1	958c65fd-c4d5-4394-8d62-e9d72bb1b3ea	\N	2026-06-28	t	\N	2026-06-28 00:56:46.975101+00	17	2026-06-28 00:56:46.975101+00	\N
3e284381-4689-4ed6-a741-92e33df8ef52	86b584c5-8474-4fd8-98b9-e96bd5a44543	\N	2026-06-28	t	\N	2026-06-28 00:57:06.738849+00	17	2026-06-28 00:57:06.738849+00	\N
d3182ff1-60af-48f1-8776-e3238e4535a1	ac8a0995-9fc5-4bcb-a365-d3787e610bc4	\N	2026-06-28	t	\N	2026-06-28 00:59:11.645648+00	17	2026-06-28 00:59:11.645648+00	\N
eecbc1b2-7225-47b1-b63a-bc0c7af96d85	7d050ab6-9019-4425-bc0c-552dc0eff256	\N	2026-06-28	t	\N	2026-06-28 00:59:36.238585+00	17	2026-06-28 00:59:36.238585+00	\N
0f41a4c5-d8b6-4897-b8c0-5b7c71f8d31b	ac35dd23-d860-4905-ab8f-0fde81f5ce88	\N	2026-06-28	t	\N	2026-06-28 00:59:49.836387+00	17	2026-06-28 00:59:49.836387+00	\N
c78ee501-9204-4025-ac9b-f9c791844505	4319944f-03e5-4a57-9722-180364fad573	\N	2026-06-28	t	\N	2026-06-28 01:00:04.844324+00	17	2026-06-28 01:00:04.844324+00	\N
d64719ee-185e-49bd-a73e-3acfe23066e0	b5e26c10-d004-4806-9085-ac4278d6a155	\N	2026-06-28	t	\N	2026-06-28 01:01:24.060918+00	17	2026-06-28 01:01:24.060918+00	\N
799e9a9a-612f-4d6d-91cc-998175c94c47	257d7932-c151-4929-b4db-344374438de8	\N	2026-06-28	t	\N	2026-06-28 01:01:41.063151+00	17	2026-06-28 01:01:41.063151+00	\N
73716cdd-4b26-471e-b303-d9716bd35b16	a8a9c3b1-e52c-4789-a093-0c5a94381d13	\N	2026-06-28	t	\N	2026-06-28 01:01:53.255192+00	17	2026-06-28 01:01:53.255192+00	\N
49d5b632-a1cc-41e6-b0a9-b8b752e0bf5d	6caf31bd-d0fa-4167-a332-fa43d1ed44ca	\N	2026-06-28	t	\N	2026-06-28 01:02:09.31147+00	17	2026-06-28 01:02:09.31147+00	\N
e0186a7e-7abc-4e73-9a09-4ee255712034	cbe8fc96-165f-4b41-ab04-ed496f567496	\N	2026-06-28	t	\N	2026-06-28 01:02:58.990785+00	17	2026-06-28 01:02:58.990785+00	\N
67e16340-d36f-4462-8ae4-ab938f9321b0	173629cc-3607-4df3-ac3b-7b20fb3c64db	\N	2026-06-28	t	\N	2026-06-28 01:03:13.20295+00	17	2026-06-28 01:03:13.20295+00	\N
7f1411e8-ed7c-4d79-b22f-dc5a364db2b1	8b893f20-a053-4e4a-ab93-c5f957565cd7	\N	2026-06-28	t	\N	2026-06-28 01:03:34.22245+00	17	2026-06-28 01:03:34.22245+00	\N
853eeafa-bef4-4384-83e7-ba9cafcab95b	f30d5945-7b43-43a0-a49a-21df3fd98b43	\N	2026-06-28	t	\N	2026-06-28 01:03:48.816901+00	17	2026-06-28 01:03:48.816901+00	\N
cb0e3083-27f7-4be7-a327-4e559abfba83	5c07e6b3-9180-41e0-a075-67e89ab316f6	\N	2026-06-28	t	\N	2026-06-28 01:04:04.247839+00	17	2026-06-28 01:04:04.247839+00	\N
b92dbda4-b093-455f-b18e-45e0a25d4df3	79843090-2b95-4228-82f4-2f2cb0e808da	\N	2026-06-28	t	\N	2026-06-28 01:05:05.496357+00	17	2026-06-28 01:05:05.496357+00	\N
ce180829-cd6e-417a-8d83-8e1147e0dd0f	52f8fce3-318b-4761-b71f-d354169e8aa3	\N	2026-06-28	t	\N	2026-06-28 01:05:15.323001+00	17	2026-06-28 01:05:15.323001+00	\N
2a306f6e-622f-43c9-99ba-029118c37b72	587d80e4-9544-4d0e-b4f6-8d70c4f94339	\N	2026-06-28	t	\N	2026-06-28 01:05:35.875156+00	17	2026-06-28 01:05:35.875156+00	\N
178023b8-98d8-4f4c-be72-b56d22606a59	c13c4cd0-9b1c-41dc-a586-c0bc45cd5981	\N	2026-06-28	t	\N	2026-06-28 01:05:51.366037+00	17	2026-06-28 01:05:51.366037+00	\N
81429f04-3ab3-4ba4-9259-1ffc17e013de	6369071b-a2fc-4cfc-a5ce-e255012a974e	\N	2026-06-28	t	\N	2026-06-28 01:06:12.939272+00	17	2026-06-28 01:06:12.939272+00	\N
8226d153-7d31-41fd-aa75-9b92475d4eaa	82e44072-b750-4c63-9da4-3605604f8731	\N	2026-06-28	t	\N	2026-06-28 01:06:29.456208+00	17	2026-06-28 01:06:29.456208+00	\N
caddb567-38d4-439c-8953-87b143339fcc	ca65ec58-3956-4d5a-8c62-d2fb531e76b2	\N	2026-06-28	t	\N	2026-06-28 01:06:45.56636+00	17	2026-06-28 01:06:45.56636+00	\N
c80c821c-5858-4aa1-b317-aeaf826fac94	a1377609-e9be-4217-9b95-8514a51c84ec	\N	2026-06-28	t	\N	2026-06-28 01:07:06.431434+00	17	2026-06-28 01:07:06.431434+00	\N
da2d3ef9-b703-4c3d-8952-15a67148e681	2623ed6d-71ab-431d-8a45-c74dab443a48	\N	2026-06-28	t	\N	2026-06-28 01:07:21.495936+00	17	2026-06-28 01:07:21.495936+00	\N
572855e4-0d44-49c2-aeb9-c19d5680f985	ff41e45b-6dbb-4995-b5b7-816c9f3b9e5e	\N	2026-06-28	t	\N	2026-06-28 01:07:37.102069+00	17	2026-06-28 01:07:37.102069+00	\N
1fb9be88-3b86-4be2-8c67-28fcbe9a2cf2	72a076f8-c919-4f30-8adc-19710568511d	\N	2026-06-28	t	\N	2026-06-28 01:08:18.427146+00	17	2026-06-28 01:08:18.427146+00	\N
0980b4a0-96cd-4428-8e5a-b225ef3bcebd	cd2bfb39-f90a-419d-a24a-da3a98bcc336	\N	2026-06-28	t	\N	2026-06-28 01:08:43.381957+00	17	2026-06-28 01:08:43.381957+00	\N
51e06bcd-9433-4339-989d-0130011c487d	37908ad3-6a80-47a2-8747-c71b70c0cc02	\N	2026-06-28	t	\N	2026-06-28 01:08:55.296343+00	17	2026-06-28 01:08:55.296343+00	\N
14dce273-3387-4cf4-8af1-689764752c14	66803bd3-d447-42f3-89fa-87eaed56d6a4	\N	2026-06-28	t	\N	2026-06-28 01:09:11.760985+00	17	2026-06-28 01:09:11.760985+00	\N
8bf74e9c-8c3f-435c-979f-7feb3f6e9965	dfdc25f1-4496-4c0b-9914-3b05ae6d575c	\N	2026-06-28	t	\N	2026-06-28 01:10:26.389844+00	17	2026-06-28 01:10:26.389844+00	\N
bd25ecd2-2e95-4ca8-8d4f-a192e2fcac64	c9586dfd-1ff1-40a0-8048-1454a66478c6	\N	2026-06-28	t	\N	2026-06-28 01:11:19.976203+00	17	2026-06-28 01:11:19.976203+00	\N
c470240b-9d43-4c8e-87c4-8dd80fa4be9e	597f5873-299e-4d3c-ab38-bf98ca4bfcfb	\N	2026-06-28	t	\N	2026-06-28 01:12:07.77391+00	17	2026-06-28 01:12:07.77391+00	\N
e3813538-85dc-4f13-a75e-d06a12680dbe	1d3bc4c0-0e4f-4fdc-955b-31382fd3d120	\N	2026-06-28	t	\N	2026-06-28 01:12:34.765734+00	17	2026-06-28 01:12:34.765734+00	\N
9e67479d-d7be-4464-aefd-611a96693e8e	e7519785-a169-436d-8bcc-07ddaa90769a	\N	2026-06-28	t	\N	2026-06-28 01:12:47.975864+00	17	2026-06-28 01:12:47.975864+00	\N
5ba3162b-a7f3-42c6-8165-8df1537cc29f	67069c95-9dcf-4da2-8076-fdfa84564ae5	\N	2026-06-28	t	\N	2026-06-28 01:14:11.9636+00	17	2026-06-28 01:14:11.9636+00	\N
8a77fc32-2cf2-4129-aeb3-6010a71318f3	22d7b909-c937-437a-8423-cda727b9e299	\N	2026-06-28	t	\N	2026-06-28 01:14:35.601063+00	17	2026-06-28 01:14:35.601063+00	\N
379001c8-f3db-4492-94e1-341decf1e8a8	480cd97b-4cc6-45ce-b004-9f08bf8a4650	\N	2026-06-28	t	\N	2026-06-28 01:15:03.804338+00	17	2026-06-28 01:15:03.804338+00	\N
7edd2328-2d73-401c-b826-d095450c6966	41750d34-8220-4b8a-a052-7942aed874a4	\N	2026-06-28	t	\N	2026-06-28 01:15:31.751462+00	17	2026-06-28 01:15:31.751462+00	\N
620ebd08-59a8-4bc8-9a08-0412be552ef3	a974878e-ee1c-4c6b-816e-4073e32f7d14	\N	2026-06-28	t	\N	2026-06-28 01:15:48.960354+00	17	2026-06-28 01:15:48.960354+00	\N
e49aece8-7544-4dc9-88b6-af85bd916e91	c0461e9f-7877-4f78-9340-6dec1c7bb900	\N	2026-06-28	t	\N	2026-06-28 01:16:03.304083+00	17	2026-06-28 01:16:03.304083+00	\N
bea581a5-7d8f-4712-8dce-d85597d2f53b	355fd0db-83cd-4e20-9d44-7efe8e9ac2cd	\N	2026-06-28	t	\N	2026-06-28 01:16:25.097539+00	17	2026-06-28 01:16:25.097539+00	\N
4ed88d8e-6783-4d16-8cde-dd7a836f2d7e	814624a8-bbb4-477b-a3b3-160286cbecad	\N	2026-06-28	t	\N	2026-06-28 01:16:40.855844+00	17	2026-06-28 01:16:40.855844+00	\N
45dba8e7-7cce-40c4-a500-95674b128354	869a19cd-f071-4034-9142-3e6d122e2409	\N	2026-06-28	t	\N	2026-06-28 01:16:52.2464+00	17	2026-06-28 01:16:52.2464+00	\N
6a50d744-e8cc-49e4-8052-42c09e5ee7d8	99785ae3-8d0e-45f7-aa2e-a5cf9628adca	\N	2026-06-28	t	\N	2026-06-28 01:17:05.548059+00	17	2026-06-28 01:17:05.548059+00	\N
1d1bb065-cd38-484d-90c1-9f36450e318e	fb7a935c-276d-4a4f-9727-f6a6ae708e8d	\N	2026-06-28	t	\N	2026-06-28 01:17:18.166778+00	17	2026-06-28 01:17:18.166778+00	\N
a79783da-db79-4898-bfd5-0cb720315d78	59539988-c0cf-4119-978c-976b6a4bce9c	\N	2026-06-28	t	\N	2026-06-28 01:17:38.230862+00	17	2026-06-28 01:17:38.230862+00	\N
3c525c47-ac0c-4615-af4a-8a77bb9d6fd6	69146716-cc6d-456c-b8fa-91c99adbad75	\N	2026-06-28	t	\N	2026-06-28 01:20:08.041795+00	17	2026-06-28 01:20:08.041795+00	\N
63e940e7-b2fc-4f89-b025-bcf3f9780a48	5f7dad6a-e648-4010-83cb-e01c3b2aa8bb	\N	2026-06-28	t	\N	2026-06-28 01:20:45.635383+00	17	2026-06-28 01:20:45.635383+00	\N
4acf59c3-dbf8-440e-8566-2d7a5ff6c963	63a62e01-2145-4beb-a3a0-1ba81785b030	\N	2026-06-28	t	\N	2026-06-28 01:21:18.353241+00	17	2026-06-28 01:21:18.353241+00	\N
744d09c6-26dc-4b07-ab8e-c3d827b46b59	0e97dc12-046f-4b6d-9883-8651dd436ce0	\N	2026-06-28	t	\N	2026-06-28 01:21:33.575284+00	17	2026-06-28 01:21:33.575284+00	\N
b2bbc176-ac7a-43ea-a18b-85bda59b5952	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	e319ab92-b31d-4512-9126-0a12a86b69bc	2026-06-28	t	\N	2026-06-28 01:22:00.2084+00	17	2026-06-28 01:22:00.2084+00	\N
8a14416e-f308-417a-9bd8-83f7351bd253	6ef7bee6-7cba-46a7-ad34-cce842e3eeff	\N	2026-06-28	t	\N	2026-06-28 01:22:18.451063+00	17	2026-06-28 01:22:18.451063+00	\N
1de261f9-fb48-43f3-b6f1-1f48abe8b2c6	0e6428b9-396e-4936-9d84-cac17f8241f8	\N	2026-06-28	t	\N	2026-06-28 01:22:32.573059+00	17	2026-06-28 01:22:32.573059+00	\N
c47313e0-9403-4e87-a771-6c88505ab19a	5d79d53d-be89-42c7-a8b9-c86523207d29	\N	2026-06-28	t	\N	2026-06-28 01:22:47.730947+00	17	2026-06-28 01:22:47.730947+00	\N
599422f0-275c-408c-a3db-38d86cd9973c	cc623c4d-cde9-499d-85a0-e70039bf8039	\N	2026-06-28	t	\N	2026-06-28 01:24:13.307311+00	17	2026-06-28 01:24:13.307311+00	\N
39d4f690-5d05-444f-a660-777e45cd0e6d	90c2cf00-edc1-408d-a89c-9c28e4697f8d	\N	2026-06-28	t	\N	2026-06-28 01:24:31.796056+00	17	2026-06-28 01:24:31.796056+00	\N
ecfc905b-b0e5-4c02-aa40-beb6212200ee	9bacb1d4-162d-47f1-9b89-36b637c2331e	\N	2026-06-28	t	\N	2026-06-28 01:24:47.29317+00	17	2026-06-28 01:24:47.29317+00	\N
4179111d-f243-4c79-8a8a-b6a757bc01c9	a4ae75e8-b8fb-4f40-b30b-2365d8324fd2	\N	2026-06-28	t	\N	2026-06-28 01:25:02.25898+00	17	2026-06-28 01:25:02.25898+00	\N
43ce0a45-20dc-4d1b-a30d-60c1b590fe50	e4333720-3c25-427b-92a8-b6d3a7eb6a9d	\N	2026-06-28	t	\N	2026-06-28 01:25:15.051898+00	17	2026-06-28 01:25:15.051898+00	\N
6f6f88ab-ef9a-412c-8f7f-e6732c81dc34	5f1f6df6-587f-4cca-bc20-8d73ed28cd48	\N	2026-06-28	t	\N	2026-06-28 01:25:34.51313+00	17	2026-06-28 01:25:34.51313+00	\N
01eab3aa-ddcf-4f11-9274-525029a9ee05	9785feec-4480-42af-baf8-8a9233610652	\N	2026-06-28	t	\N	2026-06-28 01:25:53.297716+00	17	2026-06-28 01:25:53.297716+00	\N
9c3b4b34-6f06-43b7-aac9-06c8ca7298ce	ceec8411-7036-45f9-8df9-f13db0601590	\N	2026-06-28	t	\N	2026-06-28 01:26:13.039814+00	17	2026-06-28 01:26:13.039814+00	\N
6efee3d1-357b-416c-bcf6-760bd4837830	af9fc6f6-94ed-4fb3-bd1b-0bc321d02592	\N	2026-06-28	t	\N	2026-06-28 01:27:03.638501+00	17	2026-06-28 01:27:03.638501+00	\N
2744799f-e9dc-4cbe-92d7-9e95971170ee	732d3b71-0b1e-4bae-aafd-d586d35b0f32	\N	2026-06-28	t	\N	2026-06-28 01:29:12.662456+00	17	2026-06-28 01:29:12.662456+00	\N
3a10de6f-791f-4ed8-b495-b4f3d83182c9	c0e6de1a-ceef-43f0-9bf2-4861b047aace	\N	2026-06-28	t	\N	2026-06-28 01:29:25.400992+00	17	2026-06-28 01:29:25.400992+00	\N
f026ccef-e93f-4446-b209-1e0f27ebc03d	24729a64-82e6-4707-b848-e52828d5d0cf	\N	2026-06-28	t	\N	2026-06-28 01:29:37.645104+00	17	2026-06-28 01:29:37.645104+00	\N
f2176aee-05b4-4d36-9bea-2989131a6d2d	17c66a47-97ba-466a-966b-fe4d96d369a0	\N	2026-06-28	t	\N	2026-06-28 01:29:56.975491+00	17	2026-06-28 01:29:56.975491+00	\N
4812f803-dd7f-4549-af38-20dbc380098d	5996dedd-c7d5-4bd8-83c7-f297507355d1	\N	2026-07-05	t	\N	2026-07-05 00:37:14.054824+00	18	2026-07-05 00:37:14.054824+00	\N
f1f98a4c-cd9e-4ad6-bda5-75fed53c588b	ceec8411-7036-45f9-8df9-f13db0601590	\N	2026-07-05	t	\N	2026-07-05 00:37:39.197336+00	19	2026-07-05 00:37:39.197336+00	\N
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, user_name, action, entity, entity_id, details, created_at) FROM stdin;
eae4fdd1-fda3-49a4-9cd4-e803e63f46b3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	finance_submitted	giving	37e142aa-9c21-4a9a-8bb5-03b14d09a007	₱10000 Tithes	2026-06-18 02:12:03.607314+00
62fb2fbd-a0b3-4bf2-a7ce-09fca11d416f	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 02:29:31.241663+00
f8ea2298-9dd4-478e-b59b-b511af76db9b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 02:29:42.087413+00
39a947ce-e37b-49b4-b5b3-b15afb4681e9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 02:30:31.337471+00
336eb6b4-c846-4fb3-bf21-ffc6b100bb1a	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 02:30:42.889799+00
249d6e2f-140e-410a-8a38-3980a9a51c21	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-18 02:46:09.589668+00
540b38ba-2ccd-4954-8725-1db95be42258	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 02:46:22.325134+00
bd835179-b76f-40d4-8016-4fc166ba3cd9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 02:58:22.04803+00
006d934c-6c32-4783-8703-7a9688e67327	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 03:01:49.886211+00
5bd447c6-f7af-4b0e-ade2-78d2e5ef40c0	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-18 03:02:00.424987+00
b4eb8ded-2a92-4be4-a26e-af2e503007e3	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-18 03:02:15.997283+00
2da96f28-72bc-43fe-ae43-ae1db8ed592a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 03:03:28.808271+00
0b3c6a2d-9e83-49b9-8faa-49185321efd7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 03:03:44.094332+00
a956742f-915d-4c2f-bbd6-5d9f93aacb8a	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-18 03:03:57.9326+00
c978ac37-e8e9-4747-9044-d1efd1142f01	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-18 03:12:39.933981+00
aeea27e0-8f0e-44e0-865b-9b549bb2c759	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 03:13:05.161174+00
fc556342-8c37-4ff8-a7af-ea0b2e58ae26	\N	Test	attendance_recorded	attendance	\N	Test entry	2026-06-18 03:14:22.125968+00
c22e0f0e-25f2-4297-b58d-590352ad76ac	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 03:22:59.064052+00
69ff7572-2de5-4a64-85f7-c06b8e2e05ef	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-18 03:23:10.941229+00
caf4d07b-61f1-4448-935c-ea2fae5c0a2c	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-18 03:31:46.001296+00
2d7b9c86-4ab7-4e76-8612-60e6e644d96f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 03:31:59.345136+00
ff1c2497-8325-41f7-ad14-3ffc57224b55	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 03:40:11.533722+00
6d33bf30-f6b3-4ce0-912c-4caeaaa46c14	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-18 03:40:21.122732+00
0aff4dec-c218-4ffb-b45a-a7cefc59a321	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-18 13:28:37.255556+00
e4bbf302-31d6-434f-8faa-7fa4a22bb613	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 13:28:48.163789+00
6ccc5c35-0ec0-4c28-bf10-7bd6f5d68701	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 13:42:38.967917+00
06909169-eb71-4399-934e-75581577e716	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-18 13:42:46.320511+00
ee143c71-42c9-4bf2-bd36-084259d1df27	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-18 14:05:21.913248+00
76558c65-fa31-40b8-b7f1-1200b14ca679	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-18 14:05:32.663419+00
5c586211-18ac-4311-bcb9-4ed92206f507	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 14:05:40.230664+00
378cb0c4-33a9-41e7-b09c-86d5fe31a570	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 14:11:59.634043+00
fd1262a5-8994-4371-95d2-f490c6737f82	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-06-18 14:12:15.390775+00
de47a9bb-1582-4601-9252-ac991eb35056	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 14:20:06.46379+00
02af962f-7448-462f-988d-6531580ec542	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 14:25:24.686847+00
d47973ed-1c4e-4766-866b-1b48a98a8f97	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Abdon, Prince Kerel Zebedee checked in for Sunday Worship Service	2026-06-18 14:25:41.174085+00
b8944d44-490d-447d-9350-d06b1d3b7bf8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 14:30:24.872767+00
eb6bf07e-2875-4b8b-9724-e465056dbfa5	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-18 14:30:33.732353+00
5e4f86e4-0682-4b23-b948-4b3892a86acc	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	attendance_recorded	attendance	b69e0d20-e229-4210-807f-35119377abe6	Abdon, Noli checked in for Sunday Worship Service	2026-06-18 14:30:44.379194+00
bb241f31-d44f-48d2-9754-9f517bcd6c00	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 14:32:18.800077+00
b27b1001-6219-4756-b0c0-fa6ee7d195a4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Abdon, Prince Kerel Zebedee checked in for Sunday Worship Service	2026-06-18 14:32:29.869703+00
cb6c15eb-3eac-4d06-8575-dbfb0715bef0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 14:34:02.776836+00
2475b0dd-94c6-4c08-9296-1baadf626eca	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 14:34:14.878835+00
8dc0e1ff-eee2-44fe-a6b3-bff872ea01b8	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	fc69a073-d6e9-41d7-986c-4d45447a4eba	Adoyo, Cesar checked in	2026-06-18 14:34:22.796061+00
8184afa8-57ba-4e56-b733-28393c7ee7bd	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	category_added	finance_category	3a2164ad-1313-4271-87bc-bf2f0705aa3a	Added "Adding category"	2026-06-18 14:36:37.717335+00
49f245bc-c9d9-49cd-b28e-bb4a5f939ec3	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	category_deleted	finance_category	3a2164ad-1313-4271-87bc-bf2f0705aa3a	Deleted "Adding category"	2026-06-18 14:36:55.470666+00
8f195cad-cb74-409b-b46b-a9514ac92549	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	branch_added	branch	50e7a6e8-7bb3-4f69-b792-46a8e7b5b94a	Added "jan lang"	2026-06-18 14:37:21.835873+00
7032e939-8277-4050-848c-82d4b1444663	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	branch_deleted	branch	50e7a6e8-7bb3-4f69-b792-46a8e7b5b94a	Deleted "jan lang"	2026-06-18 14:37:32.771257+00
f256fc1c-70cf-45b8-a8f3-c0a2d2c0d426	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_role_changed	user	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com → regular	2026-06-18 14:37:54.082855+00
3b1ecf3c-dc7d-42be-9f0d-617ed8d002d9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_role_changed	user	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com → admin	2026-06-18 14:38:30.480722+00
502bdc41-6cb2-4dc1-a488-fe7740210599	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_updated	user	2a81452d-3ab7-4578-9438-bed90045ff84	Updated malabayathan@gmail.com	2026-06-18 14:38:43.662632+00
40e85d72-3b1d-4d89-b938-cc1a51074d7c	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 14:45:25.705647+00
7dfe9576-0f48-4965-b147-f16de147b0d4	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 14:45:33.476427+00
ea5edb48-2a0b-4cad-a550-e95822c476ed	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 14:46:54.931505+00
2dfe2415-a306-4ff2-8605-565bf0bf12fe	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_role_changed	user	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com → admin	2026-06-18 14:47:04.721065+00
df78f332-7606-4de5-be7d-95f9c166b15d	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_deleted	user	2a81452d-3ab7-4578-9438-bed90045ff84	Deleted malabayathan@gmail.com	2026-06-18 14:54:09.020396+00
cd8b580a-2f44-459e-b633-19298b24ac7a	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:14:54.195393+00
4270bf21-47c1-4e39-a173-4e527684e783	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:21:26.678903+00
bbe5ca21-73b7-4509-8c1f-13a831b2fcf7	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 15:21:41.762062+00
fe87d65c-27f3-4682-a8bb-4471c19adeb7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 15:21:50.835403+00
7acf7701-2831-469e-87f6-e907e56f1725	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 15:22:21.847102+00
92eb7e20-d36e-4ca4-918b-9bb5752ebfe8	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:30:06.354785+00
ae0d6a89-8e06-4551-b0d0-492515c24dcc	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 15:31:43.986523+00
ae9cb057-2392-4843-8dfb-b47c6b18c433	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:31:56.760521+00
c5b76339-e8c0-4a0e-9bb7-d97b2b199185	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 15:32:17.745749+00
7bfc11a9-5003-4172-a63c-2aef917ecfae	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:32:49.117259+00
38a02f42-a240-4185-98f7-303367691830	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 15:43:34.657159+00
cc4b1c80-ec5a-4b7c-b243-15fa6aea3512	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:43:45.823326+00
b6422af4-4513-4a49-ab12-f755ae373517	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 15:44:10.791384+00
f2790d89-3a4f-4c64-bef0-699802ba164c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 15:44:18.398851+00
f1a83af4-4294-419e-8194-2d1acf2a6312	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 15:44:26.279748+00
de54f9c4-8623-4e08-91ff-6bad3beb49d5	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:44:34.486278+00
64e30edb-f133-4586-b2ff-9a807451dd25	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 15:46:56.636069+00
bfad3015-1d08-4403-ba47-2f835bdd7af2	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:47:31.125965+00
f9d8e656-29ab-402c-9b29-cd0cb65988d1	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:55:17.996393+00
b4ad6b26-8e67-46a3-a7c6-afd561bba5b1	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 15:55:24.125052+00
b72e8127-2fa8-4c71-8d70-b22f86006479	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-18 15:55:29.816796+00
333bcf98-004c-4d64-bfad-2f47004f05c2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-18 15:56:01.522483+00
be5e9c84-df2f-4ca3-a507-f9ef7de7d834	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 15:56:10.501503+00
cf0ccc84-f379-4708-b463-13216f04baab	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 16:27:37.824257+00
f2d4b726-f404-4c60-a434-8829e08f7437	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 16:30:25.986081+00
581c2557-73f5-4337-ae4f-e7f61f1e7ae1	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 16:31:15.817917+00
e5b1da5a-98cb-424c-93ff-b3dc86e882f9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-18 17:01:21.085259+00
55be9f03-b0f8-4915-96f9-b37ac517522c	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-18 17:02:19.651833+00
9cd31aba-b3e9-4f01-9fbd-56f38430759e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 10:26:26.852289+00
8524b9a1-c24a-4f7d-b18b-f7bed41236e5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-20 10:27:15.621861+00
99bb58ac-e1c6-4847-969d-7cd385595b18	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 10:27:28.363607+00
055a7415-6a2f-46d6-81ab-522922aecd60	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-20 10:28:45.146728+00
8033d8bd-93d3-4c39-8397-5859548da46e	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-20 10:29:14.875692+00
abd548c5-852c-43d9-9e65-cb973192053d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 10:35:25.189576+00
88ef3d1b-d25f-422c-9cde-970731330cd8	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Abdon, Prince Kerel Zebedee checked in	2026-06-20 10:35:56.814295+00
b631aae0-f478-4d5c-ad23-36ef6dafed03	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Abdon, Prince Kerel Zebedee checked in	2026-06-20 10:37:24.957472+00
e870aaca-58b0-4ace-be5f-1cdd5329c9c8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-20 10:43:06.477483+00
65090cda-1723-4c0d-b6ec-7ca0ea1955a6	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-20 10:43:20.606751+00
dba7a630-06c6-4c72-aba5-22f569a5b397	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	d9526726-1b9a-43ef-9186-811832e29197	Abel, Princess Collyn checked in	2026-06-20 10:43:46.978371+00
f0269c83-89b9-4de7-b08d-6d2b0340963e	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-20 10:59:23.85389+00
4c00045f-7ff3-40e4-8946-8ba2e8934cb8	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	10e98a1d-539c-40e6-ac71-4bf4ab0bb029	Updated member: Calidguid, Dave	2026-06-20 11:03:27.723156+00
e193e219-61f2-4f53-a316-f43003f949f8	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_created	member	12e0ef3b-eeaa-4873-990d-f99b893a758c	Created member: Malachi Villanueva	2026-06-20 11:05:00.861593+00
3131c611-991f-4b00-8192-6a6cdf6d2a4e	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	20eee381-1cde-474b-9d46-2a38571b0bed	Updated member: Maano, Adam Qiji Lei	2026-06-20 11:05:28.740157+00
e9b9aa7b-4ad3-4b45-a730-62bfac061c76	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_created	member	2267c58f-384a-4c9a-8480-ba5a66f44664	Created member: Wyl Amram Villanueva	2026-06-20 11:06:30.25834+00
33bd8ca5-e50f-4fac-b5ce-062839bdb84b	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_created	member	0e6428b9-396e-4936-9d84-cac17f8241f8	Created member: Caleb Joshua Falculan	2026-06-20 11:07:10.211238+00
0d60fd60-4bf2-46fd-bd4e-33a18f9466cb	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_created	member	2af9861a-ae3f-4b2d-b672-f0b5f95d350a	Created member: Jester Carl Daniel Caringal	2026-06-20 11:08:19.853801+00
0f2172d3-c119-4ea4-b786-e3983712f023	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	90c2cf00-edc1-408d-a89c-9c28e4697f8d	Updated member: Lumague, Marielle Danielle	2026-06-20 11:08:46.51078+00
5fcf68b3-fa48-47f4-8739-27adb3f1dae4	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	05b2d95a-e2dd-48fb-b44a-0c84b8f4ad01	Updated member: David, Jarence	2026-06-20 11:09:10.788643+00
14e52aa6-6f8a-490d-834f-c18b8e301f87	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	48a80a3f-1a4f-4260-839e-25008b15a463	Updated member: Caringal, Jethro	2026-06-20 11:09:54.013977+00
4bf757c7-d5bd-43d1-a303-b14d9d4e94c2	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	6ae59089-32a5-4145-bfb3-b1ad463bf22b	Updated member: Jarabe, Trisha Gail	2026-06-20 11:10:18.050074+00
99001693-6786-4c6b-90a4-65997f83a7d3	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_created	member	6fa7b76c-2566-4e21-901d-10ce5d2d31a3	Created member: Mary Dane Yray	2026-06-20 11:11:11.780249+00
bbfc350d-6a20-497f-8ee7-85aa8512aafb	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	e4333720-3c25-427b-92a8-b6d3a7eb6a9d	Updated member: Palmero, Jasper	2026-06-20 11:11:37.872685+00
3c7993b1-2d0a-45d1-a9c7-bb98850d6b2e	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-20 13:10:30.173079+00
89f5eb9f-b48b-40ed-b8d9-c6b88c6f82b0	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-20 13:20:55.602721+00
5302bf46-3063-4876-a93c-9c09e1edef77	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_role_changed	user	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com → admin	2026-06-20 13:30:37.904479+00
41ed945f-c7ea-4261-b75d-5538ead65b87	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 13:30:58.838243+00
1f990404-a674-453c-b081-1c4a063ac6f4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0abac385-1ba2-4706-a584-9e856f745018	Updated member: Abarientos, Elma May	2026-06-20 13:35:03.628735+00
c6d45bf6-20cb-41a9-9de1-4c02abdb1fe5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	05b2d95a-e2dd-48fb-b44a-0c84b8f4ad01	Updated member: Zabdiel Kent Jarence M. David	2026-06-20 13:37:00.177229+00
a2bbbc9a-1b9a-4b8f-98d2-1e28de56ad2c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	10e98a1d-539c-40e6-ac71-4bf4ab0bb029	Updated member: Dave C. Calidguid	2026-06-20 13:37:24.527185+00
cb495a98-9361-4908-94b7-b5ff49a488d8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0abac385-1ba2-4706-a584-9e856f745018	Updated member: Elma May Abarientos	2026-06-20 13:43:16.89217+00
187b89c1-403b-4aaa-a356-fe87426312c6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0abac385-1ba2-4706-a584-9e856f745018	Updated member: Abarientos, Elma May	2026-06-20 13:44:17.672242+00
90bfb9b0-3c04-4470-a09b-171382f70f37	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	10e98a1d-539c-40e6-ac71-4bf4ab0bb029	Updated member: Calidguid, Dave C.	2026-06-20 13:44:44.159789+00
62a34754-19aa-4aea-9c51-e412c690628c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	2af9861a-ae3f-4b2d-b672-f0b5f95d350a	Updated member: Caringal, Jester Carl Daniel	2026-06-20 13:45:22.818149+00
6e6d6926-457f-4590-bda4-e44eede95a9b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	48a80a3f-1a4f-4260-839e-25008b15a463	Updated member: Caringal, Jethro Carl Daniel	2026-06-20 13:47:14.315671+00
273c161e-0214-4e68-a12d-070ea20a40df	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	20eee381-1cde-474b-9d46-2a38571b0bed	Updated member: Maaño, Adam Qiji Lei	2026-06-20 13:47:35.290279+00
972d4fcc-a4e1-4c57-b460-a5cbd77df7b5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	12e0ef3b-eeaa-4873-990d-f99b893a758c	Updated member: Villanueva, Wyl Malachi	2026-06-20 13:48:06.971285+00
de8f4aa9-d68c-49a1-a0ff-5ad65d02d432	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Updated member: Abdon, Prince Kerel Zebedee	2026-06-20 13:49:19.654611+00
f595b5c2-924a-4890-b4ab-1541900af5e1	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	5996dedd-c7d5-4bd8-83c7-f297507355d1	Created member: David, Zabdiel Kent Jarence M.	2026-06-20 14:02:07.690497+00
70fb82a2-3559-472f-8879-41b1b7e0a462	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-20 14:10:31.082338+00
08a0b72c-2263-456b-a4b9-ef8bab675ae7	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_role_changed	user	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com → superadmin	2026-06-20 14:10:52.505423+00
d846f679-a4fd-4077-9d35-2c5df1d9f3f2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 14:10:58.091518+00
2b98ab4c-94c4-46c2-938b-68435c47f888	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	9a90503d-2cfd-4dfd-bb93-b49ac5a3b020	Updated member: Adriano, Erica	2026-06-20 14:25:47.856536+00
9aa6bebe-b74e-4720-8801-155676c7f200	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	466481c7-b1dd-405b-9fb6-2772cc535b0c	Updated member: Adoyo, Ma. Amor	2026-06-20 14:26:57.968774+00
f87317fc-1f34-4e37-af4b-bbe5cd8db470	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	803aa85a-5bcd-4aa0-802c-e59bfd4a6c41	Updated member: Adoyo, Jenilyn	2026-06-20 14:27:54.047635+00
150c531c-c2b4-4dbc-b82d-48bc767c7681	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	1e3f5d9d-212c-40f2-9d46-a61a3434f57f	Updated member: Adoyo, Bianca	2026-06-20 14:29:11.188003+00
14a2e300-3dec-48d2-904f-9b7a20ddca19	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	eb4ddded-37d1-4d11-a6f7-2d9c3e1e3014	Updated member: Adoyo, Angelita	2026-06-20 14:29:57.935383+00
c8380fff-ac45-4d39-92c4-4939010e4ea2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	da0466b1-3893-4d09-9ade-84eb9b772635	Updated member: Adonay, John Emman	2026-06-20 14:32:36.599495+00
f83ef465-d5f2-46e8-8d76-d6afaef90144	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	d92cd0b6-fc32-4c68-8d04-6ba88b242e38	Updated member: Adonay, Emily	2026-06-20 14:33:22.869045+00
fd58c3bb-430b-4795-a11f-3506f7a1a78a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	d92cd0b6-fc32-4c68-8d04-6ba88b242e38	Updated member: Adonay, Emily	2026-06-20 14:33:28.093069+00
e29ddb4a-7ed9-47f6-9507-1a346225443c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	9a90503d-2cfd-4dfd-bb93-b49ac5a3b020	Updated member: Adriano, Erica	2026-06-20 14:34:09.874735+00
8b5cfc25-6b71-481d-854a-eea55ea1b87a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f6df0b9f-00b0-45d2-8f96-d89cb67e1fbf	Updated member: Almo, Jhon Carlo	2026-06-20 14:35:51.575135+00
09ad0de9-fe2c-411a-8644-7b3273784680	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	c1339944-72f6-4b7b-ade9-8f518408fb94	Updated member: Arellano, Jeffrey	2026-06-20 14:36:58.25844+00
a2af7aba-25c7-4026-9712-fefd3706a9bf	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	952ddc83-8eee-420c-96b3-75f5b9de1311	Updated member: Aseron, Grace	2026-06-20 14:37:45.298464+00
55319ef2-e4f7-402d-aed6-793a68d813aa	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	154edee8-ab39-4868-a441-abb2eabb6cdc	Updated member: Bajeta, Marites	2026-06-20 14:39:03.536551+00
afafe217-bf9d-4713-80f7-aaa85a09de2a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	61aacebf-0632-484a-973d-6ca60db76b8b	Updated member: Bajeta, Melody	2026-06-20 14:39:35.895038+00
721a2263-9656-4662-80a9-665f9432703f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	61aacebf-0632-484a-973d-6ca60db76b8b	Updated member: Bajeta, Melody	2026-06-20 14:40:15.878961+00
bef40fdd-e7eb-4b32-b7f0-ef11031151f6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	60f7248c-e234-4d20-ba54-9ba5324f7edd	Updated member: Barrameda, Liza	2026-06-20 14:41:35.871994+00
312563f6-5104-4216-8da3-66ab17b72f08	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0cf0133a-773d-4692-8857-188e348523bd	Updated member: Barrameda, Lloyd	2026-06-20 14:42:05.320488+00
282d073f-3d10-45d0-b062-7acc27d4aea3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	1d3bc4c0-0e4f-4fdc-955b-31382fd3d120	Updated member: Bolaños, Grace Anne	2026-06-20 14:43:52.29006+00
b4340606-b8fd-46ee-b57f-d22b408e7795	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e7519785-a169-436d-8bcc-07ddaa90769a	Updated member: Bolanos, Mark Leo	2026-06-20 14:44:31.069898+00
50bfab8b-3f70-4481-a5a1-08f8099c5d2d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	31750972-21d4-4d47-a497-81a0f82fabb2	Updated member: Brucal, Jenny	2026-06-20 14:45:16.698539+00
dfe5c3e4-243d-4de3-a5fe-a67274507fb9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	6cc8e30b-beaf-47c7-b6b6-dad17d5ff745	Updated member: Brucal, Jham Paul	2026-06-20 14:45:57.672818+00
c0bdd9e2-fd39-4ff5-ab8d-1fb97055e651	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	173629cc-3607-4df3-ac3b-7b20fb3c64db	Updated member: Calangi, Dorlie	2026-06-20 14:46:42.531315+00
ff54d152-cbc2-4242-bf64-677924a4c2fe	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	285d9d80-cfc9-405b-8310-d84710d2e8b5	Updated member: Calidguid, George Victor	2026-06-20 14:47:18.623644+00
442b82bc-f408-4f60-8b8a-64ae9fe09b7d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7913742e-1132-4f39-90a9-9a456e53df8f	Updated member: Calidguid, Shiela	2026-06-20 14:48:19.098833+00
ed9ada8d-f7a5-4705-a522-7f63134e50c7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a651b2a0-d8a4-4369-8825-dd0ebee15871	Updated member: Calidguid, Christia Faith	2026-06-20 14:49:00.471828+00
81feafd8-0e5f-4346-a5d2-f0e4f95729dd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	26fd6e9f-352a-49c4-a7fa-c7c619fdbe8b	Updated member: Calzada, Jericho	2026-06-20 14:49:51.307239+00
fec4c57f-9de9-4185-9d31-ce008eb2df5f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a974878e-ee1c-4c6b-816e-4073e32f7d14	Updated member: Camacho, Donavel	2026-06-20 14:50:54.356573+00
81a8813d-a458-4fcc-812b-4923590f19fb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	6ef7bee6-7cba-46a7-ad34-cce842e3eeff	Updated member: Camacho, Daniel	2026-06-20 14:51:04.530003+00
48f2f333-f698-43df-83e2-90bbefffddb3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	16eaf18a-e99c-4530-aaec-8a6e96b99cdb	Updated member: Camacho, Danreb	2026-06-20 14:51:14.536654+00
4eee0975-adf5-4ce6-8401-f185f1b935cd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	16eaf18a-e99c-4530-aaec-8a6e96b99cdb	Updated member: Camacho, Danreb	2026-06-20 14:53:50.07547+00
8e548341-2cc1-4a96-8420-328a9591fb2d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	32f49f26-b956-4087-9659-b3ece5075548	Updated member: Carpio, Nancy	2026-06-20 14:55:20.210328+00
c268ad1c-90ba-4526-9849-f87f142fa7c5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	08b62f39-de02-4f1c-ad4c-65516384a75c	Updated member: Carpio, Noel	2026-06-20 14:55:33.546625+00
7965b724-9e9a-46ba-b194-b413fbe7a34f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e33e8a0e-0c35-4df9-b7a2-62d4514ec8f6	Updated member: Castillo, Jo	2026-06-20 14:56:21.652056+00
a65d9d6b-dec8-4fe8-885f-a15049213a37	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7fd04be2-f9af-488b-abcf-d060e43363ea	Updated member: Castillo, Zeny	2026-06-20 14:56:46.316412+00
6d3e4d0e-aa3f-49e1-95ac-f845be83aa9c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e5c6c350-4b2f-4f28-9a98-011e513f1583	Updated member: Causapin, Daniel	2026-06-20 14:59:49.988519+00
59bff335-b834-42d4-9012-123b5fabcf01	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	b4c128f0-2908-4aba-a807-45206c6bdfdb	Updated member: Cay, Arvin	2026-06-20 15:00:32.006223+00
d2ab4dc8-f8b7-4c7b-8cfd-732a5e0cd51b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	ac40e33a-a9cc-4d04-9380-84b396b91354	Updated member: Constantino, Sherly	2026-06-20 15:01:41.042838+00
10ddc71e-b8c2-4aa5-9e90-36049ea05a0a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	108a7e75-0dce-4d88-a6da-b4992f378e68	Updated member: Constantino, Winiefredo	2026-06-20 15:02:06.723986+00
e4c77bab-ffe8-41f6-bd62-64e17a5bc334	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	566c3572-7f46-403c-900f-c8ee777efc37	Updated member: David, Ana Florence	2026-06-20 15:03:07.307225+00
cf3fc4fa-fa5b-478b-9a91-f74321834ba0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e855a73b-e58b-41ed-819d-b95cea314837	Updated member: David, Jeffrey	2026-06-20 15:03:23.260051+00
c7f4fab6-bd46-4125-9c58-5c03b43af00c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	920c3e54-d15a-4bc9-b473-b418808970e7	Updated member: Del Prado, Daryl	2026-06-20 15:04:42.233388+00
f9ef9955-cada-4d8c-8e35-be9a25a9c52a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7f8f5ed4-68d2-460c-8ffc-de4eff4fecc6	Updated member: Del Prado, Merlinda	2026-06-20 15:05:14.89177+00
20ae1783-80c9-421e-9391-906ddc697799	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7f7d07b9-0f3b-4fdf-89ed-c6f236500468	Updated member: Delorzo, Edralyn	2026-06-20 15:05:49.344968+00
0b72e481-b36d-4fa1-932d-95a652e2594b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	2a9e5964-f1f8-415f-bc2a-5291262ab442	Updated member: Delos Santos, Carlo	2026-06-20 15:06:14.385567+00
2b65f4a6-873d-4b2c-9e07-bd1e4ee07fad	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	03e02e2e-198a-4d63-8078-b07623487502	Updated member: Entrina, Laurence	2026-06-20 15:06:54.552362+00
bae735f7-faba-4e5f-b656-250da022a523	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	587d1563-e974-4da8-8767-e8d351fa1912	Updated member: Espiritu, John Lloyd	2026-06-20 15:07:21.901211+00
bac5994d-8411-4d3d-ab4b-af77eaf65525	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	1c014f38-d865-4c35-b2b5-7d6b0710485d	Updated member: Fallorna, Mary Joy	2026-06-20 15:08:08.26739+00
27e610a0-e8d3-4763-82e6-62ec7dbfea7d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	80c5224d-3cf8-439f-bfba-12eca2943b9c	Updated member: Faminial, Maria France Princes	2026-06-20 15:08:40.986639+00
e603aa8a-9c96-41c3-bd1d-0d0ac1657579	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	d715cd09-5d06-442d-bd17-ff0c47ee9071	Updated member: Fegal, Ghiezyl	2026-06-20 15:09:23.415565+00
2d620149-0e1d-48b3-8f72-86b9ddd0a7e4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f8bd29d9-d6ba-4d45-9738-de6b78066ba1	Updated member: Fiedalan, Estelita	2026-06-20 15:11:37.409727+00
f5633c06-6ded-4377-aad5-b119bc090daa	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	22d7b909-c937-437a-8423-cda727b9e299	Updated member: Fiedalan, Jemimah	2026-06-20 15:12:00.351778+00
51838f7a-e5c6-4ae3-a5d3-519ab56c8acb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e2fa528f-63fd-4af2-9c3c-67c855b4cda1	Updated member: Frias, Justine	2026-06-20 15:12:34.16293+00
63926bc5-000b-43a0-9d27-779ea06309ea	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-20 15:12:54.399894+00
cb81fe3f-f105-437b-a964-1803913d66ac	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 15:13:06.246001+00
caf1a08a-f5e0-4680-bd01-51a92b88c426	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e40529d9-26c1-4d3d-8502-287af9e77254	Updated member: Gamolao, Renza	2026-06-20 15:14:29.160836+00
a33cc1ff-83da-49a4-b559-0d3534b40356	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e96f6ebc-c12f-4358-8745-9569bbf2831f	Updated member: Ganibo, Rosechel	2026-06-20 15:15:11.815637+00
4310c801-f2d9-4ac8-9b7c-60eb66b94a4a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	765816e4-5a88-4577-b048-17c0dec000df	Updated member: Gonzales, Princess	2026-06-20 15:16:15.240135+00
c16aa88b-5349-4b8b-ad83-6c815e50c0b8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	768d6ccb-43e3-4b23-86b4-d5b072908fed	Updated member: Gonzales, Rosalie	2026-06-20 15:17:25.631853+00
bb563491-d925-4bac-87f6-9fa9df6d4ed6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7df0317a-fc89-437f-a756-252b03f66a40	Updated member: Guerra, Erica	2026-06-20 15:17:59.41307+00
f1472eee-fdde-4892-b143-4c6b031daeb4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e31f23fe-e77d-42dc-9255-da743aba39f4	Updated member: Hernandez, Prudencio Jr	2026-06-20 15:21:10.782376+00
af607544-75b0-4cae-b048-26faf3e39be3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f2fbf001-fa01-4173-ae6a-9cb686f648c0	Updated member: Hernandez, Rona Jane	2026-06-20 15:21:36.865144+00
135c7dda-ae1f-4391-83a7-eea354af1db0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0491f4c9-6f70-4f24-874d-3b266f267f3f	Updated member: Honorica, Bennelyn	2026-06-20 15:22:14.051253+00
5db550f3-f0a7-416f-b806-414b058d311f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	be8d321a-1253-4d96-b353-b5c06f3b60b9	Updated member: Honorica, Nicole	2026-06-20 15:22:44.948071+00
20045a51-720f-4e97-b97b-3f343d4aee1a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	5d79d53d-be89-42c7-a8b9-c86523207d29	Updated member: Ilao, Angelica	2026-06-20 15:23:24.946663+00
dca6e877-83a9-42b5-9197-97190f1b5e90	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	5c07e6b3-9180-41e0-a075-67e89ab316f6	Updated member: Ilao, Emily	2026-06-20 15:23:46.949431+00
0c105078-5363-4760-8d4f-2b6cf20942c5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	010165e9-2c36-4e06-aed6-3f7a548d93be	Updated member: Jimenez, Erwin	2026-06-20 15:24:08.50532+00
1649e8ed-3927-4a8b-acd1-c70e20d72a8d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	17c66a47-97ba-466a-966b-fe4d96d369a0	Updated member: Jimenez, Efraim	2026-06-20 15:24:42.62433+00
cbf843b1-5ab5-4da3-ab46-54ae541f8b64	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	fcb78431-8436-4d1d-8011-7a1d8946a266	Updated member: Jimenez, Keila	2026-06-20 15:25:10.352798+00
ca5a2102-c72a-4727-befa-4d30c51d154c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	1a6867e6-a5ed-43a5-9c03-632d93316182	Updated member: Jimenez, Perla	2026-06-20 15:26:14.705309+00
a7eda67c-2e89-45c3-b3bd-fb6a18160f0d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	751c3478-196d-4580-93c1-d13b683503d9	Updated member: Lamonte, Rochelle Allen	2026-06-20 15:27:42.724061+00
635ecc31-f8ee-4c32-9e74-bf35e19f36e1	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	cbf1df44-43eb-443e-8f5b-c670a5519a46	Updated member: Lampayan, Jomar	2026-06-20 15:28:53.234698+00
6fad0014-2060-41bb-a45c-852eddee12d5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	30d46d69-91fb-4925-8fcc-e850d62e0c2a	Updated member: Landoy, Lowel	2026-06-20 15:29:31.0358+00
3df69fc2-e52d-4642-a34e-5bbc2740d8cc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f3658219-0cfb-4ac3-8031-34cfe7bc2bba	Updated member: Landoy, Michael	2026-06-20 15:30:16.608958+00
ce40a6c6-a9d6-4d11-bca4-3b921d26d9ed	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a37031bd-1e26-484c-b552-f264ab874e0b	Updated member: Landoy, Nelman	2026-06-20 15:31:03.600457+00
063666e7-1a10-48d5-90f6-d7e9a357807b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	81622d73-2f5f-440a-9ee5-cf41686189d9	Updated member: Landoy, Ressie	2026-06-20 15:31:32.894191+00
8b8c9329-e781-41e7-9edb-ad0ea0861891	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	c4ab2391-87d2-43bc-ae94-b22c525a600e	Updated member: Landoy, Richelda	2026-06-20 15:32:10.312793+00
b0a2545a-9ad0-4616-a6e9-3625a95e10e6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	de26ed83-276a-4541-afdb-432cc15e0b50	Updated member: Lanot, Aidan	2026-06-20 15:32:44.977635+00
65655bcc-9abb-4480-915e-aeefc9526975	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	4fc8a981-74ee-4efa-978a-feafab2e7017	Updated member: Lanot, Alicia	2026-06-20 15:33:07.535631+00
6f7b813a-c834-47e9-bdaf-8ded5d8a9e1d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	79843090-2b95-4228-82f4-2f2cb0e808da	Updated member: Lanot, Evelyn	2026-06-20 15:33:30.04906+00
93557527-6121-4090-a255-0fa6b1a08532	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0b0295ca-db43-4278-a8f0-ddbac125752d	Updated member: Lanot, Ronalyn	2026-06-20 15:35:02.169197+00
8d102274-0da1-4ab4-81a2-095db362944f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	4d520fc8-43c2-483e-9d89-d75d92a93adf	Updated member: Largo, Chona	2026-06-20 15:35:33.962679+00
cd2b6d71-f0b7-43c2-9069-2a74dfc14acb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	41750d34-8220-4b8a-a052-7942aed874a4	Updated member: La Rosa, Jenny Rose	2026-06-20 15:36:19.022388+00
6ce5b506-182d-42e9-b41d-688a706c2c6c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	65358194-525d-491c-8f8a-3a586e402aed	Updated member: Lawig, Sheena May	2026-06-20 15:36:52.518138+00
9db4385e-e51c-426e-9ab1-a024f1c5323e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	1d3bc4c0-0e4f-4fdc-955b-31382fd3d120	Updated member: Bolaños, Grace Anne	2026-06-20 15:37:05.13587+00
426e4ed0-788e-4e7b-812f-c0f0fe8af109	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e7519785-a169-436d-8bcc-07ddaa90769a	Updated member: Bolanos, Mark Leo	2026-06-20 15:37:10.634899+00
c8163703-029e-4c86-86ea-d8674769eb3b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	ceec8411-7036-45f9-8df9-f13db0601590	Created member: Sigue, Charisse Joselle S.	2026-06-20 15:38:58.468965+00
d9535252-2a3d-4b8b-b883-efbb7eaddf90	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	02ef26bb-ae4e-4573-8ee9-6e3f8772afe2	Created member: Villanueva, Wyl Amram T.	2026-06-20 15:40:25.985389+00
2ac4bb23-6742-497b-b34b-f473b2aa1732	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	e8dac4e2-58d9-40ee-99c9-c96c239d0484	Created member: Villanueva, Wyl Malachi	2026-06-20 15:41:02.643139+00
5f326988-d7ba-4981-a018-34137cf89462	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-20 15:41:13.235279+00
c940a8f6-ecc2-4dbf-a69d-f59a2e1544ce	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 15:41:21.36561+00
48407466-999d-4558-8600-ba25882510bc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-20 15:41:56.466186+00
e821a6ee-5002-4772-80dc-b9d0a1980857	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-20 15:42:13.431429+00
a94ff7da-f28e-4152-af75-a9f9b6a5d3b6	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_created	member	6175bbad-8302-463c-b1ae-40c6e10c8524	Created member: Villanueva, Wyl Amram T.	2026-06-20 15:43:03.661395+00
fa99df02-c30d-492e-ba72-04be10b7c29a	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-20 15:43:50.975694+00
4cb36b72-d0b1-48b1-90a3-c9202bb78c5e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 15:44:03.754195+00
b50f500c-8775-4f3b-8813-333ba75f2a61	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	19a9cfb4-b85e-408c-83d8-10fc49907de8	Created member: Sigue, Charisse Joselle S.	2026-06-20 15:47:23.696082+00
e751df94-189b-42bd-9243-654afda74243	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-20 15:47:59.170708+00
e1e5891f-dd6e-4b1c-86bd-c068c801c241	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 15:48:08.253996+00
9a953dc7-58e9-42db-b9ee-356514ebe57b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	b69e0d20-e229-4210-807f-35119377abe6	Updated member: Abdon, Nolasco	2026-06-20 15:50:13.382829+00
c750f1dd-f2e1-451f-9dc3-28d163fa7636	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-20 15:50:59.398503+00
1bb82adb-ea48-4060-a6fa-0846ffb7f0ee	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-20 15:51:42.560277+00
94f181cc-0329-4216-8012-83b652750435	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-20 16:16:37.851845+00
173602f8-5962-48b3-bc80-e6caf9dc14ca	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-21 00:39:04.092473+00
36a76362-58f5-4c04-959a-f6eda1ce6f91	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	5996dedd-c7d5-4bd8-83c7-f297507355d1	David, Zabdiel Kent Jarence M. checked in	2026-06-21 00:41:49.807043+00
82a72d04-e06d-4638-894f-17dc0b021cea	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	2dd48827-99a9-48a8-90cb-587d45be839d	Created member: Villanueva, Wyl Amram T.	2026-06-21 00:43:27.749045+00
2ab30af2-2480-4a69-8015-f797c3eb943b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	02ef26bb-ae4e-4573-8ee9-6e3f8772afe2	Villanueva, Wyl Amram T. checked in	2026-06-21 00:45:33.804828+00
82633fad-4da2-4a9a-9e86-88c38315c3b7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	12e0ef3b-eeaa-4873-990d-f99b893a758c	Villanueva, Wyl Malachi checked in	2026-06-21 00:46:55.339406+00
2efd0d65-e884-42fa-9f89-2e4333161517	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	cbe8fc96-165f-4b41-ab04-ed496f567496	Abdon, Analiza checked in	2026-06-21 00:48:47.604191+00
cdd1ad22-3065-44ef-a2c9-fb6f5d36e932	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	173629cc-3607-4df3-ac3b-7b20fb3c64db	Calangi, Dorlie checked in	2026-06-21 00:49:02.001805+00
a2e760d4-b512-4701-aabf-5ced0cd637d2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	2b4402e5-72b0-4396-9556-fe0362179bb5	Cantre, Princess checked in	2026-06-21 00:49:34.558749+00
13ab2d6d-9dff-4953-8526-ee2c3bfa55e7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	f8bd29d9-d6ba-4d45-9738-de6b78066ba1	Fiedalan, Estelita checked in	2026-06-21 00:50:02.370546+00
ed2b82eb-024d-47bd-9198-8a07f026c131	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	566c3572-7f46-403c-900f-c8ee777efc37	David, Ana Florence checked in	2026-06-21 00:50:26.214693+00
1ad53378-b96c-4eab-8ce6-c6fe73d7af69	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	64cbb814-aea5-4a81-a9d4-1fa772dfc6c2	Created member: Fiedalan, Liberty	2026-06-21 00:52:28.626509+00
564fb913-5a7c-49b1-8292-3274c1d5cc03	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	64cbb814-aea5-4a81-a9d4-1fa772dfc6c2	Fiedalan, Liberty checked in	2026-06-21 00:52:43.203346+00
52c0bb4b-732a-404e-a050-6a3bd4bfd591	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	79843090-2b95-4228-82f4-2f2cb0e808da	Lanot, Evelyn checked in	2026-06-21 00:53:22.264703+00
af43dc54-63de-4a64-87d1-df0c9fc25699	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	52f8fce3-318b-4761-b71f-d354169e8aa3	Lanot, Germilyn checked in	2026-06-21 00:53:46.028087+00
bc2db5d3-eb1e-4f22-9857-86a0073b9304	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	587d80e4-9544-4d0e-b4f6-8d70c4f94339	Maano, Ava Marie checked in	2026-06-21 00:55:12.453486+00
32b901d2-1afb-4587-9d25-3041f01e4bde	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	c13c4cd0-9b1c-41dc-a586-c0bc45cd5981	Magcamit, Glenda checked in	2026-06-21 00:55:32.265599+00
41a27152-99fa-4147-8dbb-734c8a9b01bc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	6369071b-a2fc-4cfc-a5ce-e255012a974e	Magpantay, Joselyn checked in	2026-06-21 00:55:56.436435+00
b5e49650-46f0-42b3-b292-bf29dab3f5c9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	02cb479d-680a-4087-952d-eae76bfe1bf1	Mahaguay, Leonisa checked in	2026-06-21 00:56:21.935208+00
9b9fff4c-ca99-4616-9881-81365d18b12b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	82e44072-b750-4c63-9da4-3605604f8731	Malabay, Teresita checked in	2026-06-21 00:56:35.621843+00
0423b21b-b001-4e71-ab73-06475bfeb94a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ca65ec58-3956-4d5a-8c62-d2fb531e76b2	Mangubat, Linda checked in	2026-06-21 00:56:49.810742+00
7b7df34f-1084-419a-8b5b-f25370327e69	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	a1377609-e9be-4217-9b95-8514a51c84ec	Created member: Manjares, Carmensita	2026-06-21 00:57:49.179382+00
d1516f12-bff8-442f-bbf7-52366b3afe06	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	a1377609-e9be-4217-9b95-8514a51c84ec	Manjares, Carmensita checked in	2026-06-21 00:57:55.557316+00
1ab98894-448e-4937-8468-d3db54e9764e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	9a1cdb26-a48d-4074-a40f-a36ebf8008f6	Marinay, Marites checked in	2026-06-21 00:58:10.572402+00
2ee0facd-5d8f-49a6-821a-f6f6727f471d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	2623ed6d-71ab-431d-8a45-c74dab443a48	Mascarinas, Coreta checked in	2026-06-21 00:58:37.543074+00
b2a6161f-e9de-483f-b515-e46319800577	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	303136e7-9583-4e37-9ffb-f749cda18e6a	Created member: Mascarinas, Rosalie	2026-06-21 01:00:19.041505+00
ba2d72c8-d786-4ca2-bef9-7c3ced1518ab	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	981fb578-7140-4e36-9780-12a4fb94a6b8	Mascarinas, Zenaida checked in	2026-06-21 01:00:38.957121+00
28d24eca-687a-41d8-883e-4f77024565c6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	981fb578-7140-4e36-9780-12a4fb94a6b8	Updated member: Mascarinas, Zenaida	2026-06-21 01:01:06.246691+00
4672f0b2-5a68-4d64-a908-2136084d2034	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	72a076f8-c919-4f30-8adc-19710568511d	Mendez, Daisy checked in	2026-06-21 01:01:19.431216+00
a7d19583-222e-452d-b9e2-677407f54806	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	cd2bfb39-f90a-419d-a24a-da3a98bcc336	Morente, Jocelyn checked in	2026-06-21 01:01:37.73712+00
6be5243c-e5f7-4cc9-b654-80f3b2d1a986	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	c14a7d27-197e-4bfc-92b3-64644dca20e2	Morente, Mila checked in	2026-06-21 01:01:46.630301+00
0eb3707b-6980-4a41-a21e-39c017c86f12	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	37908ad3-6a80-47a2-8747-c71b70c0cc02	Muje, Emma checked in	2026-06-21 01:02:00.43607+00
829bce40-1d32-4668-92a3-952e76a6c832	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	66803bd3-d447-42f3-89fa-87eaed56d6a4	Regencia, Jeaneth checked in	2026-06-21 01:02:18.581141+00
6c442c7b-f28c-49d0-989c-c0c6fc75730d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	66803bd3-d447-42f3-89fa-87eaed56d6a4	Updated member: Regencia, Jeanitha	2026-06-21 01:02:59.374988+00
5b0a9c21-cc5f-4441-9de5-0781eddbe918	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	6ca43bf0-36dd-4aff-b0f6-d3197376644a	Salazar, Genevieve checked in	2026-06-21 01:03:19.381372+00
eb0afcaa-45d5-4f8a-a89c-67bfa856b5f0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	1f8077c5-af7c-4350-8430-9f032722b8bd	Tuerto, Pacencia checked in	2026-06-21 01:03:39.493412+00
c2ad221b-e86d-4139-9ac6-d9a8578767c4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	e61253d5-41ca-404b-ac3e-a2b01e6a8032	Villaluna, Mary Grace checked in	2026-06-21 01:03:53.090894+00
20ce4b1e-3f0e-4728-913f-f0c909587cd3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e61253d5-41ca-404b-ac3e-a2b01e6a8032	Updated member: Villaluna, Mary Grace	2026-06-21 01:04:11.583809+00
122d2efd-3f81-4676-b4b7-9438ca40dde0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	1e31aa0e-86cd-407a-ab1d-b227a7f43fcc	Villanueva, Ullypa checked in	2026-06-21 01:04:20.801235+00
247e0c2e-6d5e-4210-91e6-d207c71e2559	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	1e31aa0e-86cd-407a-ab1d-b227a7f43fcc	Updated member: Villanueva, Ullypa	2026-06-21 01:04:39.252646+00
a757f036-9320-466c-b789-6850e619da23	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	b69e0d20-e229-4210-807f-35119377abe6	Abdon, Nolasco checked in	2026-06-21 01:05:08.617169+00
7a0774d9-70ef-49f1-8a4f-9fac100c1a41	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	285d9d80-cfc9-405b-8310-d84710d2e8b5	Calidguid, George Victor checked in	2026-06-21 01:05:17.527174+00
80c3f52b-0fde-4685-b30a-28d9d452ec99	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	270248b7-e849-47fe-a9fe-c2dbb8b9008d	Created member: Cantre, Cristituto	2026-06-21 01:06:00.208865+00
cb0cd3b3-b5b1-4fd2-ba6e-27c87d85b8a2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	270248b7-e849-47fe-a9fe-c2dbb8b9008d	Cantre, Cristituto checked in	2026-06-21 01:06:15.321391+00
80be8de4-61bb-43f1-87b5-8a35654672d8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	e5c6c350-4b2f-4f28-9a98-011e513f1583	Causapin, Daniel checked in	2026-06-21 01:06:48.347292+00
1acd6b8f-e98d-48c4-9ea7-8897d588ae2b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	e855a73b-e58b-41ed-819d-b95cea314837	David, Jeffrey checked in	2026-06-21 01:07:12.562394+00
593e06af-8cea-4277-be91-a176c34db496	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	37a3403a-6d49-4703-b78f-416c732e7e1f	Espiritu, Arnel checked in	2026-06-21 01:07:24.56265+00
473558d7-c31d-46ec-8742-2090722874cc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	010165e9-2c36-4e06-aed6-3f7a548d93be	Jimenez, Erwin checked in	2026-06-21 01:07:42.881613+00
e44d84cd-c29f-4a48-9b3f-9b09e7f3274c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	92a0a1ea-976c-403d-bf2b-eda30baaae6b	Created member: Embate, Jimmy	2026-06-21 01:08:34.458446+00
9dfa9807-6793-4211-828c-17debf1ea88b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	92a0a1ea-976c-403d-bf2b-eda30baaae6b	Embate, Jimmy checked in	2026-06-21 01:08:49.106724+00
baa967b5-95d2-4379-ae76-5fab4665616a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ec18ecea-d03a-43ad-9a55-9d46704d2869	Lanot, Manuel checked in	2026-06-21 01:09:21.436294+00
ec7ad0da-f54b-4bcd-8c46-c6a89fe86a63	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	7124a3ab-dee2-4949-856a-6606e9cb3fe5	Maano, Leonar checked in	2026-06-21 01:09:42.342165+00
65fe40b2-2c8b-4591-9899-f2e4abed6e83	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	08b62f39-de02-4f1c-ad4c-65516384a75c	Carpio, Noel checked in	2026-06-21 01:22:36.806208+00
bba63553-be1d-4b14-93b3-9919b00d7a37	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	a7449003-7672-457c-853d-2b391dc7a37f	Mascarinas, Edwin checked in	2026-06-21 01:23:14.22356+00
f15db707-d221-423b-abaf-a072d57307fe	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	7293eb16-166e-41eb-b939-fba5192332e8	Mascarinas, Silvestre checked in	2026-06-21 01:23:53.444602+00
7d15b7d2-b356-47a1-b99e-050391c1a831	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	6338b1d6-f55e-4e6e-a3c6-758256a45e6d	Magcamit, Diomedes checked in	2026-06-21 01:24:21.99482+00
d585649c-b90d-4689-b46e-0d8b7c437d4c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	638160ab-dcb6-43d7-a417-3ecfcabbacd4	Malangis, Ricardo checked in	2026-06-21 01:24:34.033513+00
6dff568d-52f0-40b5-8be9-20d8999140ca	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	958c65fd-c4d5-4394-8d62-e9d72bb1b3ea	Mascarinas, Vivencio checked in	2026-06-21 01:24:54.92285+00
e227acf7-1e4d-42db-8d8b-e31ba7b0c005	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	7d050ab6-9019-4425-bc0c-552dc0eff256	Morente, Bienvenido checked in	2026-06-21 01:25:10.21026+00
d240c12f-d675-4d52-9deb-9876818984af	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ac35dd23-d860-4905-ab8f-0fde81f5ce88	Morente, Gilbert Sr. checked in	2026-06-21 01:25:29.968165+00
c6e27b20-f55e-41a7-8790-8fb27f3e9053	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	6f69e8b5-4f73-4ebc-a3bd-0a4462870bbc	Regencia, Henry checked in	2026-06-21 01:25:46.743463+00
a457ee96-c549-4759-b28d-cc7ef0340263	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	4266ec51-58e4-4486-afbe-f13d24ff2210	Salazar, Pablo Jr checked in	2026-06-21 01:26:17.913977+00
b7d81a83-d165-41f8-86de-fc1a3a924a7d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	4266ec51-58e4-4486-afbe-f13d24ff2210	Updated member: Salazar, Pablo Jr	2026-06-21 01:27:29.150978+00
1fae927b-e11f-4b5a-9896-4ed2cb8b1350	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	4319944f-03e5-4a57-9722-180364fad573	Sapul, Luisito checked in	2026-06-21 01:27:44.261873+00
8c7a1dcd-eb04-4e4c-ba5a-1543f52e7b28	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	4319944f-03e5-4a57-9722-180364fad573	Updated member: Sapul, Luisito	2026-06-21 01:28:28.952368+00
0531f582-0495-4aa2-8145-5e9e158af997	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	257d7932-c151-4929-b4db-344374438de8	Tuerto, Ian checked in	2026-06-21 01:28:45.51756+00
bf7a9e08-f5a2-4ee0-8b23-eb2d15c6a229	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	257d7932-c151-4929-b4db-344374438de8	Updated member: Tuerto, Ian	2026-06-21 01:29:00.392728+00
b993e0c5-1256-45c6-a093-6493861d48ad	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	a8a9c3b1-e52c-4789-a093-0c5a94381d13	Villanueva, Willy checked in	2026-06-21 01:29:31.28286+00
c7d301e4-8e8b-43b2-b088-35c6b1b9be19	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a8a9c3b1-e52c-4789-a093-0c5a94381d13	Updated member: Villanueva, Willy	2026-06-21 01:30:20.239456+00
7b972794-7405-48e3-be4d-0dbd15921055	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Abdon, Prince Kerel Zebedee checked in	2026-06-21 01:30:50.112754+00
cfca3cbb-0dfe-41fa-953b-38bcc547534f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	a651b2a0-d8a4-4369-8825-dd0ebee15871	Calidguid, Christia Faith checked in	2026-06-21 01:31:10.896143+00
3242bf54-f06a-443b-a7e6-60638deea8a7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a651b2a0-d8a4-4369-8825-dd0ebee15871	Updated member: Calidguid, Christia Faith	2026-06-21 01:32:33.38717+00
da5c4e4a-e40e-43e6-b1d1-b4de694ec069	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	587d80e4-9544-4d0e-b4f6-8d70c4f94339	Updated member: Maaño, Ava Marie	2026-06-21 02:25:20.155615+00
37758de3-968a-4a9d-916b-7c237c492bee	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7d723030-17ae-4b51-ae87-2bc434d9f685	Updated member: Maaño, Haggai	2026-06-21 02:25:27.973374+00
36b3e8d6-c942-46c7-82de-3140e3de6700	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	9bacb1d4-162d-47f1-9b89-36b637c2331e	Updated member: Maaño, Jaica Jane	2026-06-21 02:25:36.829621+00
8f924afb-bdaf-4964-bc83-ba7ef6782155	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7124a3ab-dee2-4949-856a-6606e9cb3fe5	Updated member: Maaño, Leonar	2026-06-21 02:25:43.381211+00
ce0d9014-de88-4f4e-ba93-0c882baeb851	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7d723030-17ae-4b51-ae87-2bc434d9f685	Updated member: Maaño, Haggai	2026-06-21 02:26:01.770401+00
ac601306-8850-44aa-873d-221094e78f27	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7d723030-17ae-4b51-ae87-2bc434d9f685	Updated member: Maaño, Haggai	2026-06-21 02:26:11.992963+00
5520d2d0-cf98-4b21-9108-a01df8148b62	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	a52004f2-2bc7-409a-b09d-6b9f66550648	Created member: Lozada, Richard	2026-06-21 02:27:06.136165+00
08a9f47c-05f3-4375-983d-7e9ba7762da8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	a52004f2-2bc7-409a-b09d-6b9f66550648	Lozada, Richard checked in	2026-06-21 02:27:19.065558+00
7871b8f6-727b-41c8-9175-897f0880cb93	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	6caf31bd-d0fa-4167-a332-fa43d1ed44ca	Created member: Maaño, Emilio	2026-06-21 02:28:20.409177+00
5479c5a4-c38b-418f-9d14-3f0d67bbd0e8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	6caf31bd-d0fa-4167-a332-fa43d1ed44ca	Maaño, Emilio checked in	2026-06-21 02:28:32.894766+00
94f21566-a51c-4cac-a26d-edb3af5ac4cc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	79542bc2-be15-4f02-8096-65f058b2c148	Created member: Selda, Edward	2026-06-21 02:30:14.247914+00
61b767df-5559-4905-97e2-ff891c744f8e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	6ef7bee6-7cba-46a7-ad34-cce842e3eeff	Camacho, Daniel checked in	2026-06-21 02:31:18.069911+00
f5bb53f5-acf8-449c-ba3f-20752da293cb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	16eaf18a-e99c-4530-aaec-8a6e96b99cdb	Camacho, Danreb checked in	2026-06-21 02:31:34.944637+00
255139f5-30c4-4e16-94cc-088c32baaa8f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	4d648f7d-4745-457e-b0d8-0e8a0dff331d	Created member: Dela Cruz, Ayessa	2026-06-21 02:32:12.899387+00
5444c318-d1d3-486f-9e0e-78700d900ab4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	4d648f7d-4745-457e-b0d8-0e8a0dff331d	Dela Cruz, Ayessa checked in	2026-06-21 02:32:23.825482+00
fe5d1d54-056b-47b6-8c65-e1c988566d0f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	25729cc6-db38-4342-9bda-2fe1fd5d5279	Created member: Fajutagna, Aira	2026-06-21 02:32:58.909713+00
4ecd2c08-757e-478c-ab82-f277db08d28e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	25729cc6-db38-4342-9bda-2fe1fd5d5279	Fajutagna, Aira checked in	2026-06-21 02:33:18.897275+00
f6740b25-8d70-40ce-9d9a-4a8d41aac268	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	08496ade-6c10-4623-b70d-c67d531c5f4a	Created member: Fajutagana, Ierene	2026-06-21 02:33:57.48415+00
238e57c1-cb0f-4af4-a1a9-295967a693f2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	08496ade-6c10-4623-b70d-c67d531c5f4a	Fajutagana, Ierene checked in	2026-06-21 02:34:04.653555+00
1d9db2d3-8452-4e62-b1bf-ea2c9d48a29c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	0e6428b9-396e-4936-9d84-cac17f8241f8	Caleb Joshua Falculan checked in	2026-06-21 02:34:18.758649+00
a7671a05-f3f4-4810-afa9-5a12de28f99a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0e6428b9-396e-4936-9d84-cac17f8241f8	Updated member: Falculan, Caleb Joshua	2026-06-21 02:34:36.125361+00
4a34f2ae-9aa5-4aa6-ac40-800bc1688229	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	7cf9e15a-42d8-473d-884f-a3fe10bb64b9	Created member: Falculan, Trisha Mae	2026-06-21 02:35:11.634502+00
4f9e198c-de52-43d0-acf0-1ef79f0ea3e4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7cf9e15a-42d8-473d-884f-a3fe10bb64b9	Updated member: Falculan, Trisha Mae	2026-06-21 02:35:20.927344+00
48676e07-78c3-4349-9c4a-ddeb2aa5d96d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	7cf9e15a-42d8-473d-884f-a3fe10bb64b9	Falculan, Trisha Mae checked in	2026-06-21 02:35:27.563499+00
b76577ad-6404-4e0f-8ff5-7da4ca20f020	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	d715cd09-5d06-442d-bd17-ff0c47ee9071	Fegal, Ghiezyl checked in	2026-06-21 02:35:53.341218+00
15b6a888-97f2-4708-900b-ac922ee99efa	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	34b2a69d-8173-4da5-a053-bf6dc5db01f0	Created member: Fegal, Maria Elena	2026-06-21 02:36:16.641001+00
6d3c8cd1-1abb-4468-ac97-cdbf4f613cf9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	34b2a69d-8173-4da5-a053-bf6dc5db01f0	Fegal, Maria Elena checked in	2026-06-21 02:36:23.233988+00
405353c6-6dc6-4651-9c58-6a550d95b299	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	e25732ca-6445-46ab-a726-94bceb349e7f	Created member: Galang, Edlyn	2026-06-21 02:36:50.786457+00
0bba9035-2469-44b2-ad98-77fccaf1f545	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	e25732ca-6445-46ab-a726-94bceb349e7f	Galang, Edlyn checked in	2026-06-21 02:36:56.353053+00
215bd8ed-b0f6-4509-845f-58fa20842a12	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	2b14e5c3-9164-4794-a4a1-037446d22488	Created member: Guerra, Edralyn	2026-06-21 02:37:19.61578+00
a9e99275-e765-45f8-9acf-98a8e26432a8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	2b14e5c3-9164-4794-a4a1-037446d22488	Guerra, Edralyn checked in	2026-06-21 02:37:25.897419+00
103b2e5f-765d-4c6c-81f5-007944c19015	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	5d79d53d-be89-42c7-a8b9-c86523207d29	Ilao, Angelica checked in	2026-06-21 02:38:35.145568+00
b401b722-81b6-4758-862f-77de5c1e9bda	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	17c66a47-97ba-466a-966b-fe4d96d369a0	Jimenez, Efraim checked in	2026-06-21 02:38:48.56448+00
33ee1787-8b2e-4ab5-8c5f-14ed0542cbf6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	90c2cf00-edc1-408d-a89c-9c28e4697f8d	Lumague, Marielle Danielle checked in	2026-06-21 02:39:15.433163+00
3b859eee-b30c-495b-ba20-e3edc79b816f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	9bacb1d4-162d-47f1-9b89-36b637c2331e	Maaño, Jaica Jane checked in	2026-06-21 02:39:33.522325+00
9133dce0-c431-4709-8122-99a1dcaf122c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	a4ae75e8-b8fb-4f40-b30b-2365d8324fd2	Morente, Angel checked in	2026-06-21 02:39:56.983667+00
938f49b3-a4e4-4901-bc10-70bfe98ae54e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	e4333720-3c25-427b-92a8-b6d3a7eb6a9d	Palmero, Jasper checked in	2026-06-21 02:40:21.48035+00
f380df17-1213-452f-a624-0b7dc6a92018	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	0ea3de17-fac4-444b-af39-37a68c7e17e5	Created member: Sapallo, Phil	2026-06-21 02:40:51.358715+00
5015c2aa-4f6c-4ada-bd18-c88dba20e802	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0ea3de17-fac4-444b-af39-37a68c7e17e5	Updated member: Sapallo, Phil	2026-06-21 02:41:10.633202+00
3b9f3a93-4b89-4829-8bab-0791644e0daa	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	1d3bc4c0-0e4f-4fdc-955b-31382fd3d120	Bolaños, Grace Anne checked in	2026-06-21 02:41:38.033495+00
0cebc0d6-bcd5-489f-a93a-1fde401bff75	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	480cd97b-4cc6-45ce-b004-9f08bf8a4650	Lafuente, Daniel checked in	2026-06-21 02:41:59.13631+00
5d7a5947-b670-4766-bc73-6302f04d0884	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	22d7b909-c937-437a-8423-cda727b9e299	Fiedalan, Jemimah checked in	2026-06-21 02:42:16.853656+00
9bec2832-b347-4454-a464-57d0f8837ec8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	22d7b909-c937-437a-8423-cda727b9e299	Updated member: Lafuente, Jemimah F.	2026-06-21 02:42:32.662446+00
c52d2062-5316-4c5d-a8d9-a634de5d834d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	41750d34-8220-4b8a-a052-7942aed874a4	La Rosa, Jenny Rose checked in	2026-06-21 02:42:46.358215+00
ebefc34c-b4a9-4beb-88d3-5f8930d97527	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	671ca314-2d76-46fe-8d9f-c9c4e6e451bd	Magcamit, Neslyn checked in	2026-06-21 02:43:01.162984+00
4d9cda66-8dcb-4eaa-981c-c6d2b7aea863	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	671ca314-2d76-46fe-8d9f-c9c4e6e451bd	Updated member: Magcamit, Neslyn	2026-06-21 02:43:19.615489+00
a2ef847b-562e-43c0-ae59-031fe9872e74	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	c0461e9f-7877-4f78-9340-6dec1c7bb900	Mahaguay, Kriz Ann checked in	2026-06-21 02:43:42.873834+00
b79d0cbc-0ab5-45a5-9705-01cd7a1423ae	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	c0461e9f-7877-4f78-9340-6dec1c7bb900	Updated member: Mahaguay, Kriz Ann	2026-06-21 02:43:53.215996+00
8367a215-b546-4a89-9544-dca52b9d09fa	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	c0461e9f-7877-4f78-9340-6dec1c7bb900	Updated member: Mahaguay, Kriz Ann	2026-06-21 02:44:06.083059+00
0ea5933f-87c7-4331-a7d7-dbe921a39be7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	355fd0db-83cd-4e20-9d44-7efe8e9ac2cd	Morente, Gilbert Jr. checked in	2026-06-21 02:44:25.884815+00
efeaf331-33bc-4fb1-aac9-35b1515165ab	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	814624a8-bbb4-477b-a3b3-160286cbecad	Created member: Morente, Marimar	2026-06-21 02:45:13.065892+00
9ae28b4c-da82-423a-82f0-bba2c463ea72	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	355fd0db-83cd-4e20-9d44-7efe8e9ac2cd	Updated member: Morente, Gilbert Jr.	2026-06-21 02:45:56.265397+00
4c57e673-e466-4227-8c8c-bce35ef9b7d9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	814624a8-bbb4-477b-a3b3-160286cbecad	Updated member: Morente, Marimar	2026-06-21 02:46:10.976264+00
9e43d72a-b3e1-4d3b-a0d3-2a6fd31fbea7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	869a19cd-f071-4034-9142-3e6d122e2409	Created member: Morente, Sheena	2026-06-21 02:47:15.123268+00
24fa1747-6d7e-4c67-9b91-6ef19bf7b26a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	15473380-816d-42a3-a058-e876140357ad	Regencia, Jerwel checked in	2026-06-21 02:47:48.605124+00
37454a2b-6778-48ab-aeb2-79bc9c36b2b3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	814624a8-bbb4-477b-a3b3-160286cbecad	Morente, Marimar checked in	2026-06-21 02:49:42.294223+00
fac1a9d6-6a92-4002-87ba-a28f73f4b1e2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	869a19cd-f071-4034-9142-3e6d122e2409	Morente, Sheena checked in	2026-06-21 02:50:00.921845+00
cc8f724d-dbbe-4d33-90a0-8a9438051433	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	6466176a-45c5-48ef-a6d4-c1bcf68023b5	Updated member: Regencia, Keith Venice M.	2026-06-21 02:50:38.193473+00
472fa657-5d79-4fdc-8376-008cd85c0d79	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 01:24:33.624157+00
b2a1b71d-a197-4377-b22c-1aeaa91b1994	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	6466176a-45c5-48ef-a6d4-c1bcf68023b5	Regencia, Keith Venice M. checked in	2026-06-21 02:50:45.123617+00
2b970140-66b2-434a-84ed-deaf728cd9e9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	99785ae3-8d0e-45f7-aa2e-a5cf9628adca	Created member: Sapallo, Nhielross	2026-06-21 02:51:51.673252+00
578e3cfd-46b7-4a62-83bf-2e4973573214	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-06-24 05:34:29.963615+00
85187189-15a2-41be-a952-b6512701a4f0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	fb7a935c-276d-4a4f-9727-f6a6ae708e8d	Updated member: Villanueva, Aibeth	2026-06-21 02:52:29.393848+00
584e0df9-c102-4bf9-aff7-a562fd242092	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	fb7a935c-276d-4a4f-9727-f6a6ae708e8d	Villanueva, Aibeth checked in	2026-06-21 02:52:42.486574+00
bc7e90f3-84a2-4cb3-af9f-0b438afb347e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	99785ae3-8d0e-45f7-aa2e-a5cf9628adca	Sapallo, Nhielross checked in	2026-06-21 02:52:57.829951+00
4d7915b0-d2cf-4294-8d0c-bddd1447ae62	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	3db467e0-9e46-4b17-99d2-3eb1bf00526a	Updated member: Morente, Hannah Kate	2026-06-21 02:57:08.816299+00
e7b9ea95-3fd8-4907-8258-46f0238719aa	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	3db467e0-9e46-4b17-99d2-3eb1bf00526a	Morente, Hannah Kate checked in	2026-06-21 02:57:21.650239+00
99836f54-8fd4-4de4-9105-35c83564dc76	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	9785feec-4480-42af-baf8-8a9233610652	Created member: Magcamit, Kenneth	2026-06-21 02:58:46.322299+00
43f42fb7-7ea6-4a69-b37b-4127118d8108	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	9785feec-4480-42af-baf8-8a9233610652	Magcamit, Kenneth checked in	2026-06-21 02:59:18.799371+00
f834be1b-5590-462c-ab17-d5a700d3c651	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	59539988-c0cf-4119-978c-976b6a4bce9c	Created member: Embate, Charmaine	2026-06-21 03:02:00.930926+00
802ef13b-9c31-4544-bde9-dda20f327958	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	59539988-c0cf-4119-978c-976b6a4bce9c	Embate, Charmaine checked in	2026-06-21 03:02:18.379504+00
5bbfcfa6-1f8e-44ad-8781-9f5f2a046a90	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	1c800bfb-5bc1-4f0e-93f8-d6cc75411182	Created member: Abdon, Precious Keren Zshauna	2026-06-21 03:03:22.475331+00
ece790d6-ba37-4fbd-a49f-f916bb45e240	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	1c800bfb-5bc1-4f0e-93f8-d6cc75411182	Abdon, Precious Keren Zshauna checked in	2026-06-21 03:03:37.823456+00
3123bc47-25e3-45df-8c6c-c8f7b6d21389	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	f6259078-04af-442c-b1b0-5f95aa2c26da	Created member: Bolaños, Marianne Elyana Zephany	2026-06-21 03:05:32.082954+00
d454cf90-fb6b-4dd5-aaa1-3d21874ee146	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	f6259078-04af-442c-b1b0-5f95aa2c26da	Bolaños, Marianne Elyana Zephany checked in	2026-06-21 03:05:41.588824+00
e6194c00-8a34-40ec-ab14-f09629edcaa5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	10e98a1d-539c-40e6-ac71-4bf4ab0bb029	Calidguid, Dave C. checked in	2026-06-21 03:06:17.443851+00
a27c2d06-7cab-4b3b-b1ac-2ea15b6649e8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	49c2aa15-4a1f-4f25-9421-455436d3880c	Created member: Calidgud, Heart C.	2026-06-21 03:06:59.692819+00
890c21f7-3929-4d4f-aa66-3cedd77b80d3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	2af9861a-ae3f-4b2d-b672-f0b5f95d350a	Caringal, Jester Carl Daniel checked in	2026-06-21 03:07:43.229712+00
14e733f0-d546-438a-b1e1-4a2602d4b5c8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	48a80a3f-1a4f-4260-839e-25008b15a463	Caringal, Jethro Carl Daniel checked in	2026-06-21 03:07:48.198637+00
da56a0c3-0391-4f48-8b60-a99d3737b9d5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	a0bbb937-07ac-4235-b0ce-ca9d38e6b9e7	Created member: Caringal, Charles	2026-06-21 03:08:14.388347+00
f1346a1a-2f7b-4eec-96ae-46112ecaf4e0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	a0bbb937-07ac-4235-b0ce-ca9d38e6b9e7	Caringal, Charles checked in	2026-06-21 03:08:20.809326+00
3c41fce3-0a90-4199-b915-f1eb5d3b3ea4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	f0e50ead-69b0-41ba-9bd2-f4800fea7072	Created member: Espiritu, Alfrey	2026-06-21 03:09:03.90518+00
adbda24f-9f91-44a2-9439-eb80eb246128	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	f0e50ead-69b0-41ba-9bd2-f4800fea7072	Espiritu, Alfrey checked in	2026-06-21 03:09:13.009006+00
67e575df-fcf8-408a-8e7c-2b3746436c7a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	7d723030-17ae-4b51-ae87-2bc434d9f685	Maaño, Haggai checked in	2026-06-21 03:09:42.633581+00
48c13d18-9841-42c6-9be7-c08d694ef06b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	20eee381-1cde-474b-9d46-2a38571b0bed	Maaño, Adam Qiji Lei checked in	2026-06-21 03:09:51.19806+00
d5fb7e68-d4af-42fb-8ce9-d3d3e054eb5f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	fcce3ece-fb6c-498a-b95b-e883bcc44935	Created member: Magcamit, Deolinda	2026-06-21 03:10:22.525654+00
ccea6773-1b30-41ad-8a12-adf869fe6700	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	fcce3ece-fb6c-498a-b95b-e883bcc44935	Magcamit, Deolinda checked in	2026-06-21 03:10:34.7895+00
6d129c0b-5ebe-4494-b484-072637532f6e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	ec7fde3e-b530-4199-87ed-6d6f64359301	Created member: Morente, Genesis	2026-06-21 03:11:35.329747+00
3fcadf04-98b5-4e26-bf5c-b34ec2b5a48f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ec7fde3e-b530-4199-87ed-6d6f64359301	Morente, Genesis checked in	2026-06-21 03:11:43.512605+00
9db51dbf-c11b-43de-ac95-a71f54537674	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	ec7fde3e-b530-4199-87ed-6d6f64359301	Updated member: Morente, Genesis	2026-06-21 03:12:04.348179+00
6bcce3b8-439c-4874-a1fa-1b2e645ab9f8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	5f1f6df6-587f-4cca-bc20-8d73ed28cd48	Regencia, Ruth checked in	2026-06-21 03:13:33.994522+00
d9f4e795-43fa-4b67-8573-9936fea5ce81	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	b53621c9-2b60-4fb8-ba67-26dee55d5956	Created member: Regencia, Viera	2026-06-21 03:14:09.050239+00
39d1088b-12a7-4f17-893d-665f6f9afb96	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	b53621c9-2b60-4fb8-ba67-26dee55d5956	Regencia, Viera checked in	2026-06-21 03:14:27.558123+00
33bc165b-758a-4bfe-a64f-cc2035f728cd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	15543fd3-3bd4-4d88-9d30-2b2b4420cb2f	Created member: Regencia, Zaiden Keoon	2026-06-21 03:14:58.658549+00
6e4f4989-dd9e-4b77-a1a9-a7d0933043c6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	15543fd3-3bd4-4d88-9d30-2b2b4420cb2f	Regencia, Zaiden Keoon checked in	2026-06-21 03:15:19.352066+00
2feaea1f-0251-47a3-b433-35ece00e1329	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	ee192999-176b-42c7-b3d6-c2c616dd9ec2	Created member: Sosa, Alexa Mia	2026-06-21 03:16:09.962344+00
b5da9f3c-0f74-4c57-8672-e75daf3f1196	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ee192999-176b-42c7-b3d6-c2c616dd9ec2	Sosa, Alexa Mia checked in	2026-06-21 03:16:19.961756+00
bffb0c9d-6bf6-4d05-8b62-178ff7498b2a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	99785ae3-8d0e-45f7-aa2e-a5cf9628adca	Updated member: Sapallo, Nhielross	2026-06-21 03:16:59.338485+00
022a6f52-4b7d-4783-8da8-fd8e1fb278fb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	1e917538-2d2f-4f4d-b201-3de7ba736d54	Villanueva, Wyl Amram checked in	2026-06-21 03:17:25.011157+00
e0c92dfe-9809-4e7c-a4b9-3a978817b73f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	f43be6e8-0ab7-4d33-8a36-66a4037daa00	Created member: Villanueva, Wyl Elijah	2026-06-21 03:18:39.85324+00
e185ba40-c727-4542-ad52-292ac511f384	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	f43be6e8-0ab7-4d33-8a36-66a4037daa00	Villanueva, Wyl Elijah checked in	2026-06-21 03:18:51.970559+00
477b383f-fe51-4f28-9c87-c764fd1c01a2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	2306de94-3fb2-4f6c-b94d-be835e7f2c35	Created member: Linga, Bernadeth	2026-06-21 03:20:27.76019+00
c0f98339-83e4-4b62-8b19-d4d980b94c9f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	2306de94-3fb2-4f6c-b94d-be835e7f2c35	Linga, Bernadeth checked in	2026-06-21 03:20:42.332025+00
0ba67064-b194-4616-ba53-f623b7907f07	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	229b6adb-6b77-43ff-aaa9-a611efb86e51	Created member: Metin, Kristian	2026-06-21 03:21:03.224111+00
6b2f6f48-bb3f-4d1e-a07e-c20e343ee05e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	229b6adb-6b77-43ff-aaa9-a611efb86e51	Metin, Kristian checked in	2026-06-21 03:21:18.435719+00
42e9eb34-ba75-4d8a-bd56-2053919ca452	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	22402836-8c15-48de-99a7-ce61781c7c8a	Marinay, Prince Ethan checked in	2026-06-21 03:39:36.040339+00
512d3bb9-358c-4b2a-a6cd-76b8b4942368	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	9a1cdb26-a48d-4074-a40f-a36ebf8008f6	Updated member: Marinay, Marites	2026-06-21 03:40:00.844512+00
8e87385c-0b05-4d70-b955-32d68d11d3b0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	22402836-8c15-48de-99a7-ce61781c7c8a	Updated member: Marinay, Prince Ethan	2026-06-21 03:41:02.98068+00
7c723cc2-31a6-4d35-a057-1dd260338236	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a1c43c09-51ba-408e-84c5-63491da2139e	Updated member: Marinay, Prince Nate	2026-06-21 03:41:18.796117+00
f05d13e9-da4d-424d-aaee-5a28c6ba64de	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	81715602-1f4e-4bf2-8843-193354a719c0	Updated member: Marinay, Princess Yhessa	2026-06-21 03:41:43.844745+00
c7cbdfb1-d133-4469-8876-102e8ac301a6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	d08248db-ffac-4fc7-8f97-5dd314cf949e	Updated member: Marinay, Princess Mhonezz	2026-06-21 03:42:15.011636+00
acfef9b9-81e2-4d46-b0de-51dc5524b76b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	6300819d-e78b-405b-87ee-d43207e6eb81	Updated member: Marinay, Renato	2026-06-21 03:42:38.308177+00
a0a8ae03-b04a-4031-a437-3d93c324418d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	d08248db-ffac-4fc7-8f97-5dd314cf949e	Updated member: Escal, Princess Mhonezz M.	2026-06-21 03:43:21.46177+00
44dab908-be09-441e-89fb-575f905a89a8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	6300819d-e78b-405b-87ee-d43207e6eb81	Marinay, Renato checked in	2026-06-21 03:43:47.203391+00
35538878-17e6-4cf2-b058-18af92c1517a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	a1c43c09-51ba-408e-84c5-63491da2139e	Marinay, Prince Nate checked in	2026-06-21 03:43:54.363787+00
1cdefe4b-9649-4479-95c8-bfc59899a35e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	82e491b7-deca-4a63-8204-66368e7fbb01	Villaluna, Irish Faith checked in	2026-06-21 03:48:16.101713+00
54239047-ffa2-4ff0-bd0b-3ca19558b168	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e61253d5-41ca-404b-ac3e-a2b01e6a8032	Updated member: Villaluna, Mary Grace	2026-06-21 03:52:05.410266+00
b30b64e8-8884-4daa-89be-17f4017b474c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-21 14:32:13.001227+00
31b48b69-6adf-4654-a0e2-d269445c2d72	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-22 05:52:47.34055+00
84499817-8463-45a3-9c5e-119545c051ef	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-22 05:52:47.893513+00
a24340b5-23a6-44f3-b12f-68266eef3494	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-22 05:53:00.778029+00
dfc56cec-f9e3-4370-8047-0cc8b38309b0	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-22 05:56:07.371613+00
4003bd4d-ea0d-4d2f-8789-b5915fd40bda	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-22 05:56:39.663258+00
069b849d-bc63-4819-900f-ca7f06c2836d	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-23 10:21:12.381857+00
6e270f33-7674-42f9-b6a7-8c08e417fc6a	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-24 02:05:38.756062+00
98e87cf2-740d-49b2-a5b8-b94d19bc8833	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-24 02:05:57.159255+00
752f3ee4-edf9-4de9-9411-569dffdf3f17	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-24 02:06:06.610361+00
b11b1ea4-0a59-4c64-aba9-6ca1747f125d	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-24 03:55:26.147147+00
1da97e34-4e34-49ed-b221-050c1de1d1d6	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-24 03:55:33.872825+00
62cfe056-7134-41ee-978b-b7a3b5fa218e	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-24 03:55:43.489242+00
5dcd858e-c2df-4482-babf-b98949c313bd	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-24 03:55:53.455597+00
f7150f0b-8f70-4df3-a2ef-63cd35f2090a	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-24 04:11:51.443771+00
1c958f72-7e0c-4105-ad58-f09b6b2b3ac4	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-24 04:44:00.064248+00
f95b76ac-2a79-48ff-88dc-15d95ff9a90a	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-24 04:44:12.898166+00
d09b922c-949e-495c-b4aa-96f7f77ac611	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-24 04:46:41.030903+00
c9a44b5d-db12-41c5-8677-d0b03d7a5108	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-24 04:46:48.201912+00
2033e6a8-5552-461c-a0e1-73564d160bde	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-24 04:47:02.277144+00
49214ad3-1868-4434-a2ff-834d946ba145	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-24 04:47:10.742549+00
e980029a-72e7-4e16-a564-65c7a504ca08	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-24 04:55:41.577337+00
0ac1af21-7d86-40c1-a577-7dc875243bbb	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-24 04:55:49.060727+00
c5d6ae5e-e9c8-468b-a72e-556690e3e88c	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-24 04:55:54.950576+00
5ebe4446-f9b9-4e99-81c5-78306b501f27	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-24 04:56:00.725402+00
d59fc4e4-6a94-4c85-8e5e-5c8b3f9ebe3d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-24 04:56:10.835481+00
34f2cd92-28cf-447c-847f-0c07e3f97baa	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-24 04:56:18.229529+00
5773941c-9da2-4961-8bfd-9342a6789b30	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-24 04:56:25.009058+00
3b960fde-070a-4cc0-bd4f-cc86041c5989	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-24 04:56:33.142456+00
e41239b6-faa9-46e9-895a-c36287bedde9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-24 05:08:53.37244+00
625e3a35-5adf-4386-9efe-4d134b8be269	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-24 05:08:58.614454+00
05434371-4481-44cd-ad20-a789a547298e	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-24 05:09:31.976292+00
5210be03-1ab7-40af-9d74-30b3557def30	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-24 05:09:44.157852+00
70163adb-580d-4d2d-9de4-448f83f9200d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-24 05:32:05.256273+00
644259ed-b8b8-4500-9473-920ffa50e7fd	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-24 05:32:12.501861+00
9a820767-e7bd-4bec-bd38-e845f79a1209	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-24 05:34:01.963117+00
68489a3f-db65-4160-aebe-63cc18958921	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	logout	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed out	2026-06-24 05:38:49.289501+00
4f12cf91-bf27-4018-8091-f21f6156f116	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-24 05:38:59.061895+00
3375ede1-b75d-4502-9ebb-457af45c5daf	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-24 06:35:51.816108+00
253dca1e-bb75-4fac-803e-7529ca8f14b1	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-24 06:36:14.260492+00
bfe1bed5-dbab-4414-8244-125014cca5fd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-24 06:36:26.086263+00
7b75d2cb-df9c-4274-bd7f-8718f31c9689	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-25 01:53:08.810676+00
de9cf826-4d65-470b-a7f3-eba45256340e	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-25 01:53:14.999231+00
8ddd555c-832c-4e22-b440-922604ec8459	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-25 02:07:43.984303+00
8ab93a54-7b4c-44da-93ae-b0430e160fd1	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-25 02:07:49.339631+00
58bc9d64-d0f1-4ae3-ab72-acf1ed28d35d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-25 02:07:56.334044+00
41dc61f9-aae1-4afe-8317-15d5e0b6abc3	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-25 03:11:12.530457+00
17517ae3-c56e-4855-9d8c-d8a02d4f059e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-25 11:53:34.369374+00
5fb446c1-a7da-4222-9cb5-4d488c14f298	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-25 11:53:41.347364+00
3be10b16-0316-4112-800a-3d080095324a	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-25 11:57:46.993648+00
192a9355-b9df-47a1-8f7e-d033c5ba0710	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-25 11:57:53.20314+00
13fe16e6-dc59-4c00-97b5-697dca45b5e5	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-25 11:59:10.004452+00
2c6621a3-46ed-4993-ade1-d37bee7e7f05	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-25 11:59:16.89448+00
c7721053-9617-413a-ac3e-d50b6f036999	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-25 12:00:43.918302+00
6438cf66-b46a-4379-b4c8-b08289be5547	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-25 12:00:53.839494+00
5303ee00-8f82-46a9-98de-1becee3764e9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-25 12:01:10.609103+00
0e77e944-514a-4ddc-8c09-4c23642bad77	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-25 12:01:18.302593+00
d7ad7b87-2f10-44c9-b8ec-283164d7f29d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-25 12:01:24.81831+00
12c328ab-ee7f-4a09-9021-596559b19cff	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-25 12:01:31.109928+00
7bb23b6d-0eac-4010-9cf9-254ea1ac915e	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-25 12:04:37.903922+00
6e81b607-6d5c-448c-8521-d8e86a28b3b0	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-06-25 12:04:53.727984+00
b2ea4768-5282-48ad-8d68-247bd1950323	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	logout	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed out	2026-06-25 12:05:35.057245+00
13584fbd-da90-4b98-9905-6c56c18779f0	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-25 12:05:42.646584+00
9aa2fa63-603d-4b37-aecb-c7a46b7c1fe3	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-06-25 12:11:54.773764+00
e3491f6d-4a6b-465b-92cd-c49af94c7fab	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	logout	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed out	2026-06-25 12:12:23.182055+00
3ff9be88-86ce-4b61-ab68-52fe0f6d6cb8	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-25 12:12:28.598259+00
c3a49cb4-3a96-4cff-9ca4-9cd16572cc3c	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-25 12:36:50.382389+00
d9882a1b-79e4-40c4-a99d-0963d58389a1	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-25 12:36:56.223494+00
60197d66-67cb-421f-8369-1d796e31b6af	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-25 12:37:17.690435+00
269216bb-9f2e-4ee1-afdc-583daf524e36	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-25 12:37:22.702535+00
2a2c2f34-f952-4142-a18e-916c86c25461	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-06-25 16:31:51.878071+00
15445623-1c20-4efb-8846-4d9f2426f3e5	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-25 17:03:05.891717+00
d2b6a840-2007-4a46-acb4-32ec3d319c8d	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-25 17:03:15.743426+00
814abc8d-f1bb-47d6-b331-864896506b43	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-25 23:41:01.307495+00
c1ad00ac-16b2-44a7-99fb-23f95d4acb5a	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-26 01:28:02.701567+00
432173fc-c9e6-49e5-b7de-3a515df50e0e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-26 01:28:10.482801+00
252e9f29-465c-46b6-a1a1-c12168fc5176	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-26 01:29:39.09846+00
b94d5c4a-f644-43f9-99d8-61a18ba0a2cf	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-26 01:29:44.441315+00
6db26c85-0475-4c9a-8b85-8e6311f5bb27	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-26 01:30:36.250427+00
da64fb0d-101b-49dd-83b6-e002211e28a4	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-06-26 01:30:58.613434+00
aa5691bf-6a25-44d5-b708-e3e78ae3c989	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-06-26 01:39:51.132608+00
4a453060-312c-4861-abdd-6903be63e749	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	logout	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed out	2026-06-26 01:42:43.470367+00
ebe89f08-cd2f-4d71-946e-a48a111ed4c7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-26 01:42:48.902265+00
2bfa8b75-18df-4367-a18c-07dee6d3a43f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0abac385-1ba2-4706-a584-9e856f745018	Updated member: Abarientos, Elma May	2026-06-26 02:38:27.695975+00
3b9d39ba-0c3a-4038-8497-f0b348884c3c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-26 02:48:42.7856+00
6a148eb7-6805-4872-bca2-0d4697bbd783	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-26 02:48:55.878963+00
aad6e4bd-8681-46ae-8a9b-912da0ee5e80	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	0abac385-1ba2-4706-a584-9e856f745018	Updated member: Abarientos, Elma May	2026-06-26 02:49:08.678442+00
e44f24f1-d757-4976-978d-48915c52eeed	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	0e97dc12-046f-4b6d-9883-8651dd436ce0	Updated member: Salvilla, Harold Greg	2026-06-26 02:58:02.760172+00
63464ef2-1104-4247-ac15-8c8a8fed3d65	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-26 03:04:33.851241+00
5474e49f-b0f5-4bad-b33d-f8d2fc26bfa7	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	0e97dc12-046f-4b6d-9883-8651dd436ce0	Updated member: Salvilla, Harold Greg	2026-06-26 03:05:28.275712+00
5377f6d5-4eb9-4373-a57f-6cb695bb0ae0	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-26 03:08:38.250857+00
4cd798cb-8bbd-493b-89fb-c8a43fc59c79	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-26 03:41:39.945224+00
7fe059ae-1cca-40e3-bd80-686032e0649f	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-26 03:41:45.344044+00
869dd11a-8d2e-4d45-b116-15263e65a11d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-26 03:53:32.102833+00
a8b4a4cc-4adc-48df-97f6-2635c45134d9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-26 03:56:58.456878+00
86c5dfff-33e5-40af-bcc4-a48d582995f5	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-26 04:12:27.862373+00
d7f340f0-c8d0-4139-b357-fab89cc6cdcc	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-26 04:12:36.203859+00
58d04b70-53c8-424d-b532-aefca596cfb6	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	member_updated	member	0abac385-1ba2-4706-a584-9e856f745018	Updated member: Abarientos, Elma May	2026-06-26 04:12:50.750222+00
7c77096c-7262-448e-a0ef-3f33c84798ee	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	c4f53bf9-d840-4f43-a1b3-aa31dbf39123	Updated member: Abel, John Mark	2026-06-26 04:25:23.062512+00
c7c2629f-c011-4b60-b77b-ba7f0256468b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	5e92f942-00c9-4694-a992-f6f8493ad06d	Created Bajande, Coreen Joy (bajandecoreenjoy@gmail.com)	2026-06-26 10:34:34.261899+00
d199ff3b-8b50-4f27-898a-0e26505faf6d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-27 01:16:41.427935+00
6413bbb1-8680-4539-bc15-5d2ac2e8f45d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-27 01:28:58.901622+00
6e671152-a381-4489-ac80-012a874e951a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-27 02:55:09.597619+00
06d26c4b-d5e0-42eb-bf55-1d907902c551	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-27 02:55:19.749663+00
f5d9b372-5cb3-4196-8d3a-68b03ead1a51	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-27 03:02:22.531892+00
8ce4cca9-3e1a-4fc8-8928-bdfb234c788c	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-06-27 04:37:58.746351+00
1b9f2693-ccb1-4871-b2cd-8ecd9c8c4ae3	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-27 04:38:04.215141+00
14418cde-8e15-4461-93f2-33853db763c1	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	3	"Mendoza, Apolonia"	2026-06-27 05:33:50.326147+00
0c5d05b6-db1a-4028-b032-173b4de40cdd	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-27 05:37:57.328989+00
701cb3c1-552a-4d9a-8730-0434d3bfd984	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-27 05:40:21.789551+00
e58cb19a-6a06-45ef-9dda-36b3378b7c0b	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-27 05:52:52.411245+00
4d02243f-d0a5-4cd1-a91c-15b4ae9652ac	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-27 05:58:12.605703+00
38750324-3ea7-4ad3-992f-9186bd59fc14	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-27 06:05:56.668408+00
a65380e9-82b5-475a-84b4-a78d81f588e0	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-06-27 06:06:01.791672+00
366a5ca1-25c0-4903-b4a5-6dec2d451ba5	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-28 00:36:08.816422+00
d096d540-c582-4c14-bd9b-1d0ebcdbad93	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-28 00:36:18.443949+00
e4757225-6950-4a5d-94ef-90943cc98615	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-28 00:38:01.088564+00
cf5c43fa-b9ec-4727-b765-b149a699717d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-28 00:38:09.321832+00
643cf0f0-6f02-4321-bb53-85cde0d74ed2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-28 00:44:37.701285+00
90bb2e8a-f24d-44cb-b8fe-038f75243703	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	b69e0d20-e229-4210-807f-35119377abe6	Abdon, Nolasco checked in	2026-06-28 00:44:57.67343+00
f47f22fd-56a5-4dea-b6f4-727265117d94	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-06-28 00:47:09.959155+00
0fe7c11d-5951-4193-a7bc-bf31137924e3	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	270248b7-e849-47fe-a9fe-c2dbb8b9008d	Cantre, Cristituto checked in	2026-06-28 00:48:36.499779+00
b2150dc3-711c-483f-aa91-935f8408e21b	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	08b62f39-de02-4f1c-ad4c-65516384a75c	Carpio, Noel checked in	2026-06-28 00:49:39.593979+00
1a14391e-cb69-4daf-9eb1-46a220236aba	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	e5c6c350-4b2f-4f28-9a98-011e513f1583	Causapin, Daniel checked in	2026-06-28 00:51:20.573855+00
6abe7361-ccc8-4860-b97e-b9635eef6b0d	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	e855a73b-e58b-41ed-819d-b95cea314837	David, Jeffrey checked in	2026-06-28 00:53:35.197592+00
a8cf70f3-ed4e-413d-9a1a-1cba3537e497	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	37a3403a-6d49-4703-b78f-416c732e7e1f	Espiritu, Arnel checked in	2026-06-28 00:53:58.297277+00
0ca417d1-9b4c-4d5c-8b51-e4a55ef913f5	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ec18ecea-d03a-43ad-9a55-9d46704d2869	Lanot, Manuel checked in	2026-06-28 00:54:28.593135+00
60184e90-d98d-4fde-b837-6847689ce5a7	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	7124a3ab-dee2-4949-856a-6606e9cb3fe5	Maaño, Leonar checked in	2026-06-28 00:54:49.656938+00
bacab908-9e5b-44b1-a3b5-dc36c2ae0712	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	6338b1d6-f55e-4e6e-a3c6-758256a45e6d	Magcamit, Diomedes checked in	2026-06-28 00:55:07.501069+00
04565347-467e-472a-850b-0451c7aa72a5	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	638160ab-dcb6-43d7-a417-3ecfcabbacd4	Malangis, Ricardo checked in	2026-06-28 00:55:20.536381+00
4707451a-96f0-4b90-aff0-a4ef928eb164	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	38e7a7c8-1d38-4a24-aecb-a96173ff1aec	Malabay, Rodolfo checked in	2026-06-28 00:55:36.607764+00
77ff5582-867c-42df-92f1-d8024f45a18f	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	6300819d-e78b-405b-87ee-d43207e6eb81	Marinay, Renato checked in	2026-06-28 00:55:52.092267+00
8a455ee0-2768-4015-bfba-a8f411b6b889	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	a7449003-7672-457c-853d-2b391dc7a37f	Mascarinas, Edwin checked in	2026-06-28 00:56:04.007755+00
108d4951-e2b8-48ec-8296-ad93bb9b5651	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	958c65fd-c4d5-4394-8d62-e9d72bb1b3ea	Mascarinas, Vivencio checked in	2026-06-28 00:56:47.782975+00
62d9dce1-224b-416e-b824-75989081fb06	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	86b584c5-8474-4fd8-98b9-e96bd5a44543	Mendez, Renante checked in	2026-06-28 00:57:07.541002+00
34efb39e-ef9b-40f7-8cb9-25c0c9888d2f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	ac8a0995-9fc5-4bcb-a365-d3787e610bc4	Created member: Montaril, Wilson	2026-06-28 00:59:00.102695+00
9709b14d-1905-4774-b8f2-90f87114c93c	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ac8a0995-9fc5-4bcb-a365-d3787e610bc4	Montaril, Wilson checked in	2026-06-28 00:59:12.552853+00
44c8292f-44c1-4820-bd34-1d814dafb24a	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	7d050ab6-9019-4425-bc0c-552dc0eff256	Morente, Bienvenido checked in	2026-06-28 00:59:37.018044+00
b82f70f5-52da-4059-ba6f-3ff00eebaf9e	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ac35dd23-d860-4905-ab8f-0fde81f5ce88	Morente, Gilbert Sr. checked in	2026-06-28 00:59:50.522764+00
4bf94b08-c429-42e7-bad8-ac7d8ecdecca	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	4319944f-03e5-4a57-9722-180364fad573	Sapul, Luisito checked in	2026-06-28 01:00:05.611744+00
29bfb977-6c1d-45ee-8997-ba495e550622	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	b5e26c10-d004-4806-9085-ac4278d6a155	Created member: Sosa, Mario	2026-06-28 01:01:11.861824+00
a8fa261b-21e9-4263-97e0-7caf97541507	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	b5e26c10-d004-4806-9085-ac4278d6a155	Sosa, Mario checked in	2026-06-28 01:01:24.903754+00
9f96c26d-0ee1-4e76-b2a1-cfa439c51a3b	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	257d7932-c151-4929-b4db-344374438de8	Tuerto, Ian checked in	2026-06-28 01:01:41.878053+00
06da01d2-959b-4b2f-a909-f41ca47c77a9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	a8a9c3b1-e52c-4789-a093-0c5a94381d13	Villanueva, Willy checked in	2026-06-28 01:01:54.090462+00
e0be78d7-9413-42d3-91f4-b9bfb5f27fcf	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	6caf31bd-d0fa-4167-a332-fa43d1ed44ca	Maaño, Emilio checked in	2026-06-28 01:02:10.161705+00
b9d4dea0-cfd8-4552-b3d9-d48ea477ad21	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	cbe8fc96-165f-4b41-ab04-ed496f567496	Abdon, Analiza checked in	2026-06-28 01:02:59.849256+00
bd1204c6-841e-4b31-9c13-dad8c0f05551	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	173629cc-3607-4df3-ac3b-7b20fb3c64db	Calangi, Dorlie checked in	2026-06-28 01:03:13.99745+00
48596e4b-427f-48a0-86af-52643bf33080	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	8b893f20-a053-4e4a-ab93-c5f957565cd7	De Leon, Mildorena checked in	2026-06-28 01:03:35.047952+00
3a9a1cdb-7c85-4806-803e-992490970fc9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	f30d5945-7b43-43a0-a49a-21df3fd98b43	Espiritu, Judith checked in	2026-06-28 01:03:49.677145+00
365028d2-5bcd-424a-929d-b7801d1e9023	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	5c07e6b3-9180-41e0-a075-67e89ab316f6	Ilao, Emily checked in	2026-06-28 01:04:05.058636+00
9331499b-7260-4d33-adcc-297296b78a4f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	79843090-2b95-4228-82f4-2f2cb0e808da	Updated member: Lanot, Evelyn	2026-06-28 01:04:57.333535+00
e4060ebb-5fc1-416a-9a45-0ea90f1c2bc6	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	79843090-2b95-4228-82f4-2f2cb0e808da	Lanot, Evelyn checked in	2026-06-28 01:05:06.281182+00
0f9b513d-66a7-44ef-9ee7-b17b39a13511	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	52f8fce3-318b-4761-b71f-d354169e8aa3	Lanot, Germilyn checked in	2026-06-28 01:05:16.115986+00
c30e0636-42c3-4531-858f-8b85ec1a2c09	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	587d80e4-9544-4d0e-b4f6-8d70c4f94339	Maaño, Ava Marie checked in	2026-06-28 01:05:36.716963+00
56e11fdd-aaa9-42c0-90c1-1c5128608f00	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	c13c4cd0-9b1c-41dc-a586-c0bc45cd5981	Magcamit, Glenda checked in	2026-06-28 01:05:52.182119+00
a867a28b-a583-4a63-962d-1b444d75e137	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	6369071b-a2fc-4cfc-a5ce-e255012a974e	Magpantay, Joselyn checked in	2026-06-28 01:06:13.777466+00
ef5c9c1e-3218-4bf1-8772-e25feae23627	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	82e44072-b750-4c63-9da4-3605604f8731	Malabay, Teresita checked in	2026-06-28 01:06:30.19676+00
6e1b6a58-caac-46a2-8cb8-8b3b517c0e6c	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ca65ec58-3956-4d5a-8c62-d2fb531e76b2	Mangubat, Linda checked in	2026-06-28 01:06:46.326448+00
cd6ad769-b808-446a-bb9e-a4119bd688b5	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	a1377609-e9be-4217-9b95-8514a51c84ec	Manjares, Carmensita checked in	2026-06-28 01:07:07.225374+00
5c4f5754-d3b2-4d94-93b6-f3627e64189a	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	2623ed6d-71ab-431d-8a45-c74dab443a48	Mascarinas, Coreta checked in	2026-06-28 01:07:22.375854+00
9118f650-4507-433d-b6bc-3009b3756716	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ff41e45b-6dbb-4995-b5b7-816c9f3b9e5e	Mascarinas, Lagrimas checked in	2026-06-28 01:07:37.840799+00
3c4ff817-65dd-4de3-9a25-9e67772d8c4c	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	72a076f8-c919-4f30-8adc-19710568511d	Mendez, Daisy checked in	2026-06-28 01:08:19.24186+00
40d69cce-2d98-46d2-92eb-ab5d96bbdd82	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	cd2bfb39-f90a-419d-a24a-da3a98bcc336	Morente, Jocelyn checked in	2026-06-28 01:08:44.295731+00
43108b4e-7e36-46ee-8335-8c84ac84694f	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	37908ad3-6a80-47a2-8747-c71b70c0cc02	Muje, Emma checked in	2026-06-28 01:08:56.09756+00
c949916e-6e63-4353-8916-69cf84c888ea	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	66803bd3-d447-42f3-89fa-87eaed56d6a4	Regencia, Jeanitha checked in	2026-06-28 01:09:12.541385+00
60f0e403-8e2b-48c1-837a-3d92d4a2a3fd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	dfdc25f1-4496-4c0b-9914-3b05ae6d575c	Created member: Sosa, Agnes	2026-06-28 01:10:15.690784+00
64355734-ea69-4ff3-aa3c-f12ee0e2d6d9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	dfdc25f1-4496-4c0b-9914-3b05ae6d575c	Sosa, Agnes checked in	2026-06-28 01:10:27.169845+00
e275daf9-6bf0-47bd-a442-02cdc584f8aa	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	c9586dfd-1ff1-40a0-8048-1454a66478c6	Created member: Montaril, Adelaida	2026-06-28 01:11:12.612785+00
5b730f68-df31-424c-8548-b3b779cca119	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	c9586dfd-1ff1-40a0-8048-1454a66478c6	Montaril, Adelaida checked in	2026-06-28 01:11:20.716795+00
88c1de13-340b-4faf-9445-6a31595626ea	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	597f5873-299e-4d3c-ab38-bf98ca4bfcfb	Created member: Maaño, Charity	2026-06-28 01:12:01.558547+00
98e4eca9-1236-4b57-931f-4cb845ccf7c1	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	597f5873-299e-4d3c-ab38-bf98ca4bfcfb	Maaño, Charity checked in	2026-06-28 01:12:08.577126+00
de8a8066-0f65-4a77-b0ae-0cf14895b051	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	1d3bc4c0-0e4f-4fdc-955b-31382fd3d120	Bolaños, Grace Anne checked in	2026-06-28 01:12:35.590774+00
770fd505-29bc-42d6-bab3-82922f87088e	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	e7519785-a169-436d-8bcc-07ddaa90769a	Bolanos, Mark Leo checked in	2026-06-28 01:12:48.800637+00
e1e24fec-aab6-4614-8cbf-16792c60a659	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	67069c95-9dcf-4da2-8076-fdfa84564ae5	Created member: Monton, Avegail	2026-06-28 01:14:03.48208+00
a9cdc222-d918-419a-84ec-7c05e7d67ece	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 01:31:16.727823+00
3e630f98-c4b9-48ed-8a0b-232900ef0992	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	67069c95-9dcf-4da2-8076-fdfa84564ae5	Monton, Avegail checked in	2026-06-28 01:14:12.860216+00
4af9e0e6-905b-43de-bf34-523a114b02bf	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	22d7b909-c937-437a-8423-cda727b9e299	Lafuente, Jemimah F. checked in	2026-06-28 01:14:36.412384+00
b25db86d-a5c1-4db1-8013-96e858d2e4bd	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 04:54:01.3436+00
3a082ede-6d97-426f-9c9e-7984a4baffcf	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	480cd97b-4cc6-45ce-b004-9f08bf8a4650	Lafuente, Daniel checked in	2026-06-28 01:15:04.706658+00
cfe7aded-eb4b-46c3-803c-11611c393edd	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	c0461e9f-7877-4f78-9340-6dec1c7bb900	Mahaguay, Kriz Ann checked in	2026-06-28 01:16:04.12098+00
13e71f0c-5cd5-4b3d-92a2-df40624d6ea3	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	869a19cd-f071-4034-9142-3e6d122e2409	Morente, Sheena checked in	2026-06-28 01:16:53.06092+00
2ba24b26-d0a6-4f61-a345-b7c98ef51093	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	59539988-c0cf-4119-978c-976b6a4bce9c	Embate, Charmaine checked in	2026-06-28 01:17:39.045437+00
a8892708-d5f6-4b07-bacf-7c3263719299	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	41750d34-8220-4b8a-a052-7942aed874a4	La Rosa, Jenny Rose checked in	2026-06-28 01:15:32.511509+00
05d73450-2889-450b-ab8c-aac1f112b539	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	355fd0db-83cd-4e20-9d44-7efe8e9ac2cd	Morente, Gilbert Jr. checked in	2026-06-28 01:16:25.885857+00
36433950-01a8-4a3a-958d-49f3fc57dd24	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	99785ae3-8d0e-45f7-aa2e-a5cf9628adca	Sapallo, Nhielross checked in	2026-06-28 01:17:06.416345+00
8678355b-bc7d-4ddb-bdc1-670cb556110c	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	a974878e-ee1c-4c6b-816e-4073e32f7d14	Camacho, Donavel checked in	2026-06-28 01:15:49.801305+00
52761624-187a-439f-8951-e09a60d807a7	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	814624a8-bbb4-477b-a3b3-160286cbecad	Morente, Marimar checked in	2026-06-28 01:16:41.666837+00
59379392-3e55-45e6-8cea-500c8ea4e1d5	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	fb7a935c-276d-4a4f-9727-f6a6ae708e8d	Villanueva, Aibeth checked in	2026-06-28 01:17:18.952495+00
84012654-4b37-4475-ad52-b6370cca4b06	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	5f7dad6a-e648-4010-83cb-e01c3b2aa8bb	Created member: Flavier, Shiryl	2026-06-28 01:19:25.331799+00
936fde84-cb1e-4755-b5f1-19a9e442334e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	69146716-cc6d-456c-b8fa-91c99adbad75	Created member: Flavier, Ralph Vincent	2026-06-28 01:19:57.546824+00
88ac39a2-f5e8-4184-a676-a56e61b1d6a2	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	69146716-cc6d-456c-b8fa-91c99adbad75	Flavier, Ralph Vincent checked in	2026-06-28 01:20:08.883167+00
91f2f8ae-609f-4f15-aee4-926cc80473fc	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	5f7dad6a-e648-4010-83cb-e01c3b2aa8bb	Flavier, Shiryl checked in	2026-06-28 01:20:46.496074+00
72d27068-68a0-4b9f-ac82-50f276399e4b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	63a62e01-2145-4beb-a3a0-1ba81785b030	Created member: Salvilla, Mark	2026-06-28 01:21:12.180197+00
80b460bb-f4c8-4fbd-8428-f4166a4ff2cd	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	63a62e01-2145-4beb-a3a0-1ba81785b030	Salvilla, Mark checked in	2026-06-28 01:21:19.137649+00
7cecac80-3b99-4c8d-8275-26e3a66da144	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	0e97dc12-046f-4b6d-9883-8651dd436ce0	Salvilla, Harold Greg checked in	2026-06-28 01:21:34.343227+00
97cd8eb3-f059-4ace-b5bc-551fb370e1e8	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Abdon, Prince Kerel Zebedee checked in	2026-06-28 01:22:00.886874+00
f60503f9-73ef-4574-9af5-355873ea2027	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	6ef7bee6-7cba-46a7-ad34-cce842e3eeff	Camacho, Daniel checked in	2026-06-28 01:22:19.181402+00
e7a714a8-3c77-4a55-aaec-bd80b0148b84	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	0e6428b9-396e-4936-9d84-cac17f8241f8	Falculan, Caleb Joshua checked in	2026-06-28 01:22:33.296291+00
b32001cc-ebb1-41f8-b7de-18f94434e6d5	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	5d79d53d-be89-42c7-a8b9-c86523207d29	Ilao, Angelica checked in	2026-06-28 01:22:48.480856+00
606c70d2-bc9e-48cb-9aae-0215db37f354	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	cc623c4d-cde9-499d-85a0-e70039bf8039	Created member: Lumaban, Junevalyn	2026-06-28 01:24:03.918221+00
25f5f034-4e76-4f6b-942d-a46f58c94b4b	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	cc623c4d-cde9-499d-85a0-e70039bf8039	Lumaban, Junevalyn checked in	2026-06-28 01:24:14.088091+00
d9f790c6-16a2-454f-a07a-8f4f6ffe763b	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	90c2cf00-edc1-408d-a89c-9c28e4697f8d	Lumague, Marielle Danielle checked in	2026-06-28 01:24:33.337043+00
181fa4e8-d0fd-40b7-80f5-338e990db312	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	9bacb1d4-162d-47f1-9b89-36b637c2331e	Maaño, Jaica Jane checked in	2026-06-28 01:24:48.137998+00
c545a6e8-7e32-4d42-bcdb-9583b2ff864b	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	a4ae75e8-b8fb-4f40-b30b-2365d8324fd2	Morente, Angel checked in	2026-06-28 01:25:03.046638+00
5e411edc-4517-40d5-bda8-444f3cf89f8d	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	e4333720-3c25-427b-92a8-b6d3a7eb6a9d	Palmero, Jasper checked in	2026-06-28 01:25:15.875354+00
6cb0487e-1c2d-49f0-add0-4654dce39f14	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	5f1f6df6-587f-4cca-bc20-8d73ed28cd48	Regencia, Ruth checked in	2026-06-28 01:25:35.246746+00
3108583e-71e8-482f-b607-b6c503e20203	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	9785feec-4480-42af-baf8-8a9233610652	Magcamit, Kenneth checked in	2026-06-28 01:25:54.082948+00
ac379d86-0386-4a2a-8517-2088178a6fcf	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	ceec8411-7036-45f9-8df9-f13db0601590	Sigue, Charisse Joselle S. checked in	2026-06-28 01:26:13.783971+00
b6c7d60d-239d-4e38-8f98-5acf0fdeea0d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	af9fc6f6-94ed-4fb3-bd1b-0bc321d02592	Created member: Embate, Ruth	2026-06-28 01:26:53.111859+00
17b67117-4144-4846-92e7-cbac0fd7a655	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	af9fc6f6-94ed-4fb3-bd1b-0bc321d02592	Embate, Ruth checked in	2026-06-28 01:27:04.398621+00
ced2ea9d-982e-40cb-8373-2a755e8c0bbd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	732d3b71-0b1e-4bae-aafd-d586d35b0f32	Created member: Mameng, John Kith	2026-06-28 01:29:00.895867+00
b441ea24-7b22-4a58-9c67-388bbe08e1b9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	732d3b71-0b1e-4bae-aafd-d586d35b0f32	Mameng, John Kith checked in	2026-06-28 01:29:13.481491+00
d8a2cec8-aa81-46c8-9eb6-03b8c698ba02	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	c0e6de1a-ceef-43f0-9bf2-4861b047aace	Salazar, Jireeh checked in	2026-06-28 01:29:26.161079+00
bc094e60-b964-4bc4-87c7-104b80e15136	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	24729a64-82e6-4707-b848-e52828d5d0cf	Salazar, Zion Reign checked in	2026-06-28 01:29:38.460358+00
1e801cd1-ea5e-4f64-a2de-9bc451a48a9b	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	attendance_recorded	attendance	17c66a47-97ba-466a-966b-fe4d96d369a0	Jimenez, Efraim checked in	2026-06-28 01:29:57.746293+00
950fad7f-301b-4fb1-bea4-c993076ce997	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-28 02:23:22.036921+00
09289312-1737-4856-9f32-4102db482840	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-28 08:30:41.032264+00
4133a689-fbcf-4884-a591-e32a9df34d92	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 01:31:30.184392+00
d9e746b2-66af-4deb-83fc-94938eb8d05c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	d43a30df-92b6-42c2-ab80-ea060627c64d	Updated member: Malabay, Jonathan	2026-06-29 01:31:51.754151+00
bc49eab9-ef32-402a-8313-fc1c9efe2e74	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 01:31:54.820191+00
fc4152ea-8cd3-45e1-a7c7-f2da46b946f3	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 01:32:03.826499+00
f298e10a-a4f2-40a1-98a8-804ab7fb6bcd	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 01:44:08.607629+00
6bda5a57-3659-4447-acd7-04a0d7021ee4	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 01:44:16.128176+00
82a76966-091d-40c2-8476-f26e026a0c2a	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 01:44:41.313177+00
460c8c2e-56d2-4a7c-b05c-a811ebf96708	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 01:44:47.209601+00
388676e9-de99-4306-8291-ce77591d7690	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 04:53:14.16187+00
e7ca702c-61be-46d4-a03b-16c4bfd9891c	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 04:53:20.610749+00
6be12957-cd4a-459b-99cf-4762f373b405	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 04:54:07.312863+00
48605d14-d717-4842-8f2e-ca8a4516319b	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 04:59:59.58777+00
e66b2391-cdca-42be-bc40-999a9f269aa6	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 05:00:06.954789+00
250bee8f-e80d-49bf-b912-30e7861df917	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 05:09:22.403528+00
09c18cc6-c99f-460e-9935-7cf704af3eda	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 05:09:30.743384+00
7feafe7a-99ed-48e0-864d-f7752b0c9ac3	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 05:11:11.18208+00
82fae294-3b61-4de6-9f3d-c80f05c1ad17	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 05:11:16.95427+00
ff7afa27-0084-49ab-9f64-16117b7482f9	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	member_updated	member	29f8dee5-33dc-45a1-835f-827c01e936f4	Updated member: Bernadit, Adam Jay	2026-06-29 05:21:19.903643+00
daf3ca77-e6d1-414c-9fb6-7a627481a070	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	member_updated	member	558b94c5-3219-4302-b897-f85b3bf5a8f2	Updated member: Adriano, Edgar	2026-06-29 05:21:30.176336+00
74050cc8-3088-4291-afbf-c594b3f27af0	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	member_updated	member	ce8203b0-9b65-45a2-accc-3b98b57d439e	Updated member: Bernadit, Corazon	2026-06-29 05:21:43.583586+00
4de46839-e6d3-45da-bf0a-7f4ac6f9ec16	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 05:22:22.474049+00
9dd6c4fd-c3e8-4d17-b0ad-eb09648a8030	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 05:22:27.977449+00
963e0271-5652-482c-bb23-eb7863827fcb	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	member_updated	member	99785ae3-8d0e-45f7-aa2e-a5cf9628adca	Updated member: Sapallo, Nhielross	2026-06-29 05:23:14.926678+00
05d9a4bd-14fd-4518-ad48-24a5cc590e08	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	member_updated	member	a8a9c3b1-e52c-4789-a093-0c5a94381d13	Updated member: Villanueva, Willy	2026-06-29 05:23:32.08476+00
86e0d752-4c44-49f7-b61d-b8ce5bf52305	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 05:24:56.780095+00
93719e7a-cfae-410b-b7fc-25fdfd995d60	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 05:25:04.827303+00
ee9bb5fa-e3bd-4b76-adae-e95d34b40a66	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	420573f1-b8f6-4342-9669-6ccdd7ab7456	Updated member: Malabay, Jedediah	2026-06-29 05:25:34.622382+00
f36569b9-ce83-4e07-8948-9e8449c7f559	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0fcdc907-3411-4a6f-85d3-047029f3c1f2	Updated member: Malabay, Estrelita	2026-06-29 05:25:46.746206+00
b56a6c43-1cb9-4f18-87b1-aee3a2ca48bc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 05:25:49.052793+00
2117b2bc-a4a0-4509-b7a7-22947a96ceee	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 05:25:57.861463+00
d5ed28b7-6819-4826-b272-38c914ee3805	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 05:27:33.5466+00
9c31987d-7b7c-4974-a1be-ca546b735ad5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 05:27:41.547412+00
905b7cbe-09b5-4c5a-bf23-08ed315e47a5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	fb52810a-3ef3-4aac-a1c3-a4642a06c566	Updated member: Malangis, Julie Anne	2026-06-29 05:28:35.386727+00
dfd3e2fd-1f10-4970-b1c0-6d23996f9b2b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	8f62c753-b403-4752-adab-53a98479c448	Updated member: Malabay, Lloyd	2026-06-29 05:31:58.070887+00
a23cb4d0-71ad-4c73-8489-bf16451886bd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	38e7a7c8-1d38-4a24-aecb-a96173ff1aec	Updated member: Malabay, Rodolfo	2026-06-29 05:33:52.613271+00
fef63d89-7eeb-4980-9ee1-1dd69b3dfe83	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	38e7a7c8-1d38-4a24-aecb-a96173ff1aec	Updated member: Malabay, Rodolfo	2026-06-29 05:44:25.672237+00
02e0f825-a526-475d-ab6f-5ea9a43242c9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	38e7a7c8-1d38-4a24-aecb-a96173ff1aec	Updated member: Malabay, Rodolfo	2026-06-29 05:45:48.152641+00
1ccd6e47-0467-4d72-95d4-62254699141d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	38e7a7c8-1d38-4a24-aecb-a96173ff1aec	Updated member: Malabay, Rodolfo	2026-06-29 05:47:40.962631+00
50c0dd05-7cbf-47dc-9431-b1ce3a532fca	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0abac385-1ba2-4706-a584-9e856f745018	Updated member: Abarientos, Elma May	2026-06-29 05:49:36.55619+00
8dd72fd9-c90d-42a0-b4f7-49df440e6ebf	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Updated member: Abdon, Prince Kerel Zebedee	2026-06-29 05:49:45.688692+00
cb4c5cc6-0a01-4cb4-9949-76ae62b9d0c8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	d92cd0b6-fc32-4c68-8d04-6ba88b242e38	Updated member: Adonay, Emily	2026-06-29 05:50:01.052552+00
b86ee07b-c48e-414c-b33c-80a2d8f1520e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 05:50:11.500748+00
1a851e7b-c5d5-4670-b879-7df2bfce4d44	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 05:50:18.057477+00
1b7ace31-60c2-40b7-adbe-4e736e2eb42f	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	member_updated	member	c67166b0-db30-4310-b177-9f94d0b36696	Updated member: Atienza, Harold	2026-06-29 05:51:44.608362+00
5b880601-ae98-41ee-a5ae-ba0b33e25fc1	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	member_updated	member	1cf7e4fe-d4be-4d96-bc9a-96da56038a87	Updated member: Adriano, Marlyn	2026-06-29 05:53:18.41474+00
10e50d93-3da0-4944-b65a-606e1e5fc4c5	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 05:53:20.908916+00
bfe6e530-3475-4d9c-bcfe-098b06fd5011	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 05:53:28.474528+00
f8cddae7-8daa-40d9-9e79-3db7f048d13b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 05:53:44.137578+00
ea10138d-f761-4d1f-a91b-feb0d65d46cc	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 05:53:54.636708+00
5ec258c1-f9fd-4460-9e99-0d8c1b0a9069	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 05:54:16.660138+00
c4a11549-5dd2-4dd3-9ec2-6ceecb203a80	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 05:54:26.139437+00
1b5383a4-7abd-4492-b04c-8c10d883c742	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 05:54:42.055968+00
1653c485-9549-4296-9eb3-fe1066bd15cd	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 05:54:48.866549+00
a3bd3b27-124e-47eb-96bd-47b050290f3f	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	member_updated	member	8f62c753-b403-4752-adab-53a98479c448	Updated member: Malabay, Lloyd	2026-06-29 05:55:15.004667+00
dca5bc78-e608-4afb-9cd0-e8155d228e53	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	member_updated	member	0fcdc907-3411-4a6f-85d3-047029f3c1f2	Updated member: Malabay, Estrelita	2026-06-29 05:55:58.413375+00
e1acc09b-5579-4e7a-9450-ecc6284e37b9	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 05:56:08.466328+00
c31f96e6-6011-4c57-bab2-df3c713c74d4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 05:56:16.005965+00
30a50a2a-e8c6-4ba3-bba4-4f7cd4bf488c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 05:59:50.363808+00
4743dc34-7722-4166-a079-821f93dcd1e2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 05:59:56.982911+00
85815bbf-b527-4c52-bf04-dc20e0a9dc37	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 06:00:09.997557+00
95a1085d-1674-472d-b7ba-4fe32abfaa4b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 06:00:04.511661+00
9d874425-dbab-4ea0-aca8-59e905aa8597	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 06:03:39.506269+00
392323e9-baa1-47df-9a21-6ba440ab325d	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 06:03:46.850113+00
8e1d53e9-8f10-47ae-a140-4f1b93c1419b	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 06:30:39.701245+00
049ffdb4-42ca-49d4-954e-b9e7e03715df	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 06:30:55.573358+00
2f08882e-3c9e-4c59-9b0b-8ab2bc2120df	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	member_updated	member	17c66a47-97ba-466a-966b-fe4d96d369a0	Updated member: Jimenez, Efraim	2026-06-29 06:31:33.257819+00
84109ebe-abf0-4fd2-b716-5c8902bc31c6	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 07:01:45.895838+00
d105f9c4-3b04-489b-b54b-a8dd5a2880da	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 07:01:52.491161+00
6fdd8b35-6379-4fa7-9460-3f698e9eb8f0	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 07:07:39.214263+00
05b3489a-83a1-4eb2-ba37-5263654ae178	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 07:07:44.798791+00
2f6994cb-e20a-45e0-8280-915125d9625d	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 09:43:16.526407+00
3afb1832-af83-4f2d-b11b-3c66c297da55	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 09:43:24.19083+00
3245f011-8067-459b-bb2c-8943792ab4ae	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	24729a64-82e6-4707-b848-e52828d5d0cf	Updated member: Salazar, Zion Reign	2026-06-29 09:44:42.602343+00
9c059938-00cd-4a10-b5f9-9c0a9560f398	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	c0e6de1a-ceef-43f0-9bf2-4861b047aace	Updated member: Salazar, Jireeh	2026-06-29 09:45:04.459225+00
0edc7a24-0b2b-4f19-a69d-48037f2726b0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	5f1f6df6-587f-4cca-bc20-8d73ed28cd48	Updated member: Regencia, Ruth	2026-06-29 09:45:35.414662+00
29390d31-2f73-4286-9d0f-195875809ebb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	9bacb1d4-162d-47f1-9b89-36b637c2331e	Updated member: Maaño, Jaica Jane	2026-06-29 09:45:55.947534+00
62df29d8-a343-40b9-87a8-696174c24aa3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	480cd97b-4cc6-45ce-b004-9f08bf8a4650	Updated member: Lafuente, Daniel	2026-06-29 09:46:22.645732+00
52050d52-ace7-4f8d-8656-e42b6f12655d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	22d7b909-c937-437a-8423-cda727b9e299	Updated member: Lafuente, Jemimah F.	2026-06-29 09:46:33.021597+00
cbaf0649-0275-4066-8158-acf1feb9d938	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	37908ad3-6a80-47a2-8747-c71b70c0cc02	Updated member: Muje, Emma	2026-06-29 09:46:57.973186+00
160930d6-5217-4897-977a-e7027317a778	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	72a076f8-c919-4f30-8adc-19710568511d	Updated member: Mendez, Daisy	2026-06-29 09:47:18.111757+00
1dbb8192-4aff-403d-992d-5e5b43b12d11	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	ff41e45b-6dbb-4995-b5b7-816c9f3b9e5e	Updated member: Mascarinas, Lagrimas	2026-06-29 09:47:42.870907+00
8e60c1fb-1b32-42be-9f0a-01c06856fd7e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	2623ed6d-71ab-431d-8a45-c74dab443a48	Updated member: Mascarinas, Coreta	2026-06-29 09:47:59.179126+00
2ff9dadb-e7c8-438f-8298-7a7b40c6070a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	ca65ec58-3956-4d5a-8c62-d2fb531e76b2	Updated member: Mangubat, Linda	2026-06-29 09:48:24.217555+00
f3dc8478-5795-4ba0-91c3-5bd54dcd4bb8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	82e44072-b750-4c63-9da4-3605604f8731	Updated member: Malabay, Teresita	2026-06-29 09:48:39.355768+00
593bf062-f80f-46e7-a2cd-69400fab6681	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	6369071b-a2fc-4cfc-a5ce-e255012a974e	Updated member: Magpantay, Joselyn	2026-06-29 09:49:01.665362+00
39fa71b8-1ca2-45a4-b660-40a9ae5dfa2e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	52f8fce3-318b-4761-b71f-d354169e8aa3	Updated member: Lanot, Germilyn	2026-06-29 09:49:23.894574+00
be6f85ce-b2ec-4af4-a015-90b78d8b7e3a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f30d5945-7b43-43a0-a49a-21df3fd98b43	Updated member: Espiritu, Judith	2026-06-29 09:49:35.729813+00
379de656-527e-4af4-85f9-2ba76c53a4b3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	8b893f20-a053-4e4a-ab93-c5f957565cd7	Updated member: De Leon, Mildorena	2026-06-29 09:49:54.225293+00
384ac06e-4659-4038-b0bb-034a724d5a68	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	cbe8fc96-165f-4b41-ab04-ed496f567496	Updated member: Abdon, Analiza	2026-06-29 09:50:09.096357+00
29af51ab-61c8-462d-a304-dee3f5abc431	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7d050ab6-9019-4425-bc0c-552dc0eff256	Updated member: Morente, Bienvenido	2026-06-29 09:50:34.372914+00
89366005-5672-4141-acc2-b2a971a10e9f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	ac35dd23-d860-4905-ab8f-0fde81f5ce88	Updated member: Morente, Gilbert Sr.	2026-06-29 09:50:50.004606+00
16421ce9-f617-453d-aec2-90a7adbbbca6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	86b584c5-8474-4fd8-98b9-e96bd5a44543	Updated member: Mendez, Renante	2026-06-29 09:51:08.437115+00
0c994eec-44ec-463b-adc8-df6ce6271921	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	958c65fd-c4d5-4394-8d62-e9d72bb1b3ea	Updated member: Mascarinas, Vivencio	2026-06-29 09:51:21.202226+00
b279b74d-348f-4f3a-bc26-da5a4e23d9fd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a7449003-7672-457c-853d-2b391dc7a37f	Updated member: Mascarinas, Edwin	2026-06-29 09:51:43.503929+00
3bbc11ac-86b7-437d-b3d5-9fdcdcda9e4c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	638160ab-dcb6-43d7-a417-3ecfcabbacd4	Updated member: Malangis, Ricardo	2026-06-29 09:52:10.539817+00
5d23fdf8-8824-4a55-95b0-ef41b1449d8e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	6338b1d6-f55e-4e6e-a3c6-758256a45e6d	Updated member: Magcamit, Diomedes	2026-06-29 09:52:22.129383+00
14f4afc7-e0c0-4b49-ae1f-3bb862b3b784	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7124a3ab-dee2-4949-856a-6606e9cb3fe5	Updated member: Maaño, Leonar	2026-06-29 09:52:54.338446+00
b1ec1865-0013-493b-b84a-63134a1c2610	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	ec18ecea-d03a-43ad-9a55-9d46704d2869	Updated member: Lanot, Manuel	2026-06-29 09:53:15.508371+00
c81427cb-04ef-4a58-ba34-a2794b8c2195	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	37a3403a-6d49-4703-b78f-416c732e7e1f	Updated member: Espiritu, Arnel	2026-06-29 09:53:40.381577+00
e0e27488-7d27-411f-98b4-c63864184064	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e855a73b-e58b-41ed-819d-b95cea314837	Updated member: David, Jeffrey	2026-06-29 09:53:55.413452+00
e73c66a6-70b8-474a-bb66-a3bda50d5fbe	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	566c3572-7f46-403c-900f-c8ee777efc37	Updated member: David, Ana Florence	2026-06-29 09:54:02.738729+00
097bf51b-a230-4a6e-8805-0e15aa611476	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a4ae75e8-b8fb-4f40-b30b-2365d8324fd2	Updated member: Morente, Angel	2026-06-29 09:55:23.631509+00
df24fb78-caa7-480d-bfb9-619037d49710	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	cd2bfb39-f90a-419d-a24a-da3a98bcc336	Updated member: Morente, Jocelyn	2026-06-29 09:55:52.027065+00
bd9811ec-6093-4745-bdbe-d443061241d3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	c13c4cd0-9b1c-41dc-a586-c0bc45cd5981	Updated member: Magcamit, Glenda	2026-06-29 09:56:16.309337+00
26e3b3f2-9e17-4df5-96f2-6407fb4fb300	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 10:02:12.459265+00
afe7c036-d870-4c3e-a35f-73dd94a00470	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 10:02:19.019767+00
f6777dc4-1832-4989-afdd-0ad8dc4d3cc7	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 10:05:26.652686+00
299af128-ac4e-4bda-ba46-b27c72ef399a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 10:05:33.01122+00
980e5ad8-3e00-4f4b-a399-59db153c5e76	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 10:05:42.596595+00
3fe98f26-3bf5-4df5-a2e1-91202f7736b7	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 10:05:47.553104+00
ff05a5ff-87f8-4e1e-b661-9f102da3a60a	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 11:30:35.928651+00
40268456-78b0-42f4-a78f-25f089bef928	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 11:30:42.234368+00
4a13a7e3-2dad-4087-9acc-e785d2c091b2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	d43a30df-92b6-42c2-ab80-ea060627c64d	Updated member: Malabay, Jonathan	2026-06-29 11:30:55.982103+00
17ae6d63-fc5f-469b-a71c-dc653a83e823	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 11:30:59.468077+00
c2b064d6-2ec6-40f6-a1f3-84b79f3f15ad	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 11:31:12.329846+00
ac67a32d-6e4e-4889-802f-e6bc0cfefe4d	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 11:31:46.004877+00
3762d7a9-5163-4756-b944-991b4eb419c8	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 11:31:54.567333+00
c0176151-a622-4965-bed0-d87ede170dd5	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 11:32:09.016107+00
b9a5adf9-028a-48e6-ab5f-ec7e4db22363	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 11:32:15.00774+00
54f0d0a9-dbf2-4276-ae6a-0db867b39e53	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 11:45:42.797912+00
32ed71a8-85fb-44f3-a1b5-383daebe5a6e	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 11:45:50.83915+00
b7dbaba0-41fd-46f7-a2b3-3ce093f1f74a	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 11:46:05.559107+00
d5a9231c-1f58-4057-9a89-3abdc15e30f9	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 11:46:12.979193+00
9e72e30c-6c9b-4d13-a496-5d6ba336a7e6	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 11:51:41.550037+00
7e70fb4e-3082-4a70-be49-e67065bbe0bb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 11:51:51.608126+00
52fe9360-b59d-4fa1-b4dc-84c6a1eb22ea	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_updated	user	2a81452d-3ab7-4578-9438-bed90045ff84	Updated malabayathan@gmail.com	2026-06-29 11:52:12.764364+00
ff0a2a2f-ef26-4143-97ab-300ac514712c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 11:52:48.330863+00
695e1c79-1c06-435b-a620-a7c3588ae8c6	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 11:52:54.923894+00
4f352ea9-ceff-4620-95a4-48a575b76fa9	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 12:02:12.465116+00
8e555785-57ff-4f5a-8618-cc12d4f30c71	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 12:02:18.772519+00
61ebc099-1181-4dae-965f-54f8290412c7	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 12:02:36.345848+00
93323ab9-3d8f-4867-bfbc-ba65348adce8	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 12:02:42.301815+00
78a35011-ec55-42b3-85e0-ce423061758e	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 12:54:26.79271+00
d6370404-511e-45d1-b893-b4bdb49d149e	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 12:54:32.777959+00
0f10f288-b482-458c-9bea-1aed5c461bfc	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 12:54:44.483042+00
df81db3d-b013-42a1-b1e7-9aabf3571f8c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 12:54:49.649895+00
858ecc3b-0e9d-45bd-8f45-4a055e05fb72	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 12:58:13.634114+00
b0a1c5be-0fa0-477f-abff-608a78df6a5c	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-29 12:58:19.75452+00
73a362b5-af2e-46b3-b05d-4ab58e360b14	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-06-29 13:13:07.848223+00
24a3ed2b-4854-4509-b1aa-1e7314b87649	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 13:13:17.97141+00
84660920-aef7-4c07-835f-7cbe2419deb6	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 13:13:23.242108+00
8e0f52b3-027a-44b5-b1aa-5133efd03154	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 13:13:29.176362+00
7c564d4c-6dca-4157-ab91-b64386b04f07	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 13:13:42.408524+00
496b04e2-ec5f-4982-b793-db2179276f46	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 13:13:48.646323+00
fee9bbfa-3a78-4b38-bf66-88e66f6d323a	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 13:14:30.765378+00
dfe39954-9ca0-4a3a-b08c-c522a06161ab	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 13:14:37.855367+00
47273f34-e4ba-4d8c-ae82-5e1d3a5f6726	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 13:14:40.710633+00
910d0785-a758-4e8b-b941-28723db1add5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 13:14:45.974895+00
641943b4-c516-45d4-8821-1faac62c76b3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 13:18:51.045668+00
9e230bc4-6247-46dc-b77c-e19895bfb212	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 13:18:56.236948+00
2faea9fb-d0a0-425e-be60-27ce214ac11c	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	announcement_posted	announcement	6	"Sunday Service worship"	2026-06-29 13:32:32.460927+00
a2da36d2-18be-4e57-bfdc-22e38e8cf3b0	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-29 13:32:55.472046+00
611d9300-5fad-41db-9eef-fed66eb4c93f	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-29 13:33:06.674235+00
1d265472-8034-4e3d-b435-acd088a54cb6	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	announcement_posted	announcement	7	"sunday service worship"	2026-06-29 13:36:46.212474+00
22a44441-72ea-4a92-a3f1-e7d56f389f27	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	member_updated	member	dfdc25f1-4496-4c0b-9914-3b05ae6d575c	Updated member: Sosa, Agnes	2026-06-29 13:37:30.349622+00
d731f9ad-67f1-4b02-bc49-6f7af7f5ab16	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	member_updated	member	466481c7-b1dd-405b-9fb6-2772cc535b0c	Updated member: Adoyo, Ma. Amor	2026-06-29 13:37:42.605977+00
242bcf85-09d7-45ef-9476-82df0db36f3c	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-29 13:37:57.1401+00
c99022aa-7202-4edb-ab5d-0ee0ec622c60	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-29 13:38:03.912415+00
8225f305-f405-436f-a7d7-7f5e2ddfb244	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	c6ce9dda-3c52-4f7b-9876-f3b113a0a441	Created Adoyo, Ma. Amor (adoyomaamor@gmail.com)	2026-06-29 13:38:53.109166+00
bd896250-0d8f-4564-bc7a-cc4bbd1d9760	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-29 13:40:55.65525+00
a869f6af-7c8e-4be8-995b-7858fd1aa1b8	c6ce9dda-3c52-4f7b-9876-f3b113a0a441	adoyomaamor@gmail.com	login	user	c6ce9dda-3c52-4f7b-9876-f3b113a0a441	Signed in	2026-06-29 13:41:07.603236+00
cfef2605-2543-4f1c-98ef-f4211480c4e7	c6ce9dda-3c52-4f7b-9876-f3b113a0a441	adoyomaamor@gmail.com	logout	user	c6ce9dda-3c52-4f7b-9876-f3b113a0a441	Signed out	2026-06-29 13:43:50.368518+00
4c61ab91-58a2-4c94-aefe-27badd4a2ebd	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-29 13:43:55.948745+00
c4814f6c-c896-40dd-8d8b-1793d5876215	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	4	"Salazar, Jireeh"	2026-06-29 13:45:18.961916+00
4942976d-c976-489c-90bb-4232d5559f4f	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	5	"Lanot, Germilyn"	2026-06-29 13:45:39.267133+00
a419f934-6274-48dc-a27f-9514f41bc1c2	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	6	"Morente, Angel"	2026-06-29 13:45:48.776657+00
eb6da671-3587-48d0-bf93-2cf258f5c757	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-30 02:25:13.45034+00
417544d6-b159-4b6e-9089-e1dcf9f5d4cb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-30 02:25:18.345091+00
7c17c9ef-0b34-4cf0-94b4-0a10b8ecca05	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-30 02:25:36.282597+00
bdcd7bef-a78b-42df-83cb-79fe4192222d	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-30 02:25:47.028818+00
cc3a03bd-77cf-42d3-9947-e884e55c25d3	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-30 02:25:51.645586+00
7ee41713-6681-4287-8c7b-8c72eb0a170b	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-30 02:25:58.107593+00
8c9ca523-c9c5-48d9-9f71-886cbfcdbd46	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	7	"Salazar, Jireeh"	2026-06-30 02:57:19.323351+00
8a9de62f-3e67-4162-94ec-095485273bfe	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	8	"Lanot, Germilyn"	2026-06-30 02:57:22.376751+00
35aeb518-eaac-4314-af27-8c9dd2d14a92	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	9	"Morente, Angel"	2026-06-30 02:57:25.216952+00
7ace1ce6-7623-4451-81ec-05449488b84e	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-30 02:58:35.223225+00
0c531e3d-b572-4be2-abac-abc87651566b	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-30 02:58:43.23866+00
2fcf0dbf-0b2d-4723-86b7-5c92de736341	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-30 02:58:55.738644+00
e3ad68e9-ff1f-44df-aa34-1e008df7fd2a	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-30 02:59:02.143543+00
2b610c60-a96b-4806-8ece-dc865f04612d	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-30 03:11:32.684515+00
bd8049b7-00ac-46ac-8399-324962faf847	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-30 03:11:38.909883+00
6ce86c46-d929-431f-a18b-ed45e434346e	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-30 03:11:44.445303+00
08888555-604c-4a9e-9d73-d3b6d1844aae	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	login	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed in	2026-06-30 03:11:49.499936+00
b12c70ca-15ff-46ac-97d5-3bf000450bb2	2a81452d-3ab7-4578-9438-bed90045ff84	malabayathan@gmail.com	logout	user	2a81452d-3ab7-4578-9438-bed90045ff84	Signed out	2026-06-30 03:11:54.204458+00
2d4cfb27-3092-4815-b614-a79e27a0b540	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-30 03:11:59.8958+00
7bc92b11-cac8-4589-b7ef-ef799f06426c	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-30 03:12:42.917962+00
d65b783e-1530-4468-8658-7c8639813ffb	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-30 03:12:52.783384+00
0b51c800-52c1-4a70-bbe3-7d28ad39b83d	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-30 03:26:06.393777+00
539ffc18-f2c9-42fe-af66-8513cfd38e22	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-06-30 03:26:19.946327+00
e6057dac-362c-40cd-b0c4-c22fd309549f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-06-30 03:27:27.550203+00
d6be7624-c105-4ee4-8a7a-bc20163b779d	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-30 03:27:32.428353+00
9c30f5e4-52d1-4bb5-9d37-0f35d5543030	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	10	"Salazar, Jireeh"	2026-06-30 03:27:45.423203+00
9d73a104-d32f-41cf-bcc9-d1ee9c1791b2	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	11	"Lanot, Germilyn"	2026-06-30 03:27:47.959299+00
188b39ab-834c-4c72-98bb-ab7687c752f5	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	12	"Morente, Angel"	2026-06-30 03:27:51.402705+00
e5ba79b5-bf40-43b6-953d-1c04d6d2c83b	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-06-30 03:27:56.166136+00
abb22ebe-5bdd-46ca-8845-22c9bad27fe9	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-06-30 03:28:03.045675+00
a594e703-780b-478f-ba30-c180b0d22150	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	13	"praise night"	2026-06-30 03:28:35.580488+00
b2e343ff-391d-4f73-a439-f559370e5799	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-06-30 10:26:12.086781+00
332bb427-84dc-4a3d-a894-dbe3f177d394	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-07-01 02:45:28.14142+00
9a1bed68-4219-4352-9d9b-e89e7365869b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-01 02:45:33.893835+00
61c46928-776b-4bb7-bc24-2d42ddefe881	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-01 03:18:21.995114+00
bcb27189-068b-456a-91da-b242755d9fea	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-07-01 04:42:56.090749+00
3628555c-6562-4156-bff7-9be9d6e45db3	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	14	"Malabay, Estrelita"	2026-07-01 15:05:05.528822+00
a1c10983-20b3-4286-a32b-0eea603e4b4f	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	event_added	event	15	"Maaño, Leonar"	2026-07-01 15:05:07.845507+00
f4c247e1-afc3-4d01-b8ef-fda72fbe70a1	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-07-02 07:05:44.947944+00
da129cfe-446b-40bd-9ad9-9b1569665c8a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-03 04:04:21.677754+00
d924e1f0-c67d-487b-a976-bf16a6e39625	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_deleted	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Deleted abdonnoli@gmail.com	2026-07-03 04:15:16.560064+00
99a12546-7271-4d65-8e3a-9127ba0e44f0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	1801f3bc-0a0b-43d9-94b1-e0514f27d38a	Created Abdon, Nolasco (nholliea006@gmail.com)	2026-07-03 04:16:45.972865+00
685718b3-0e08-4111-9c9b-d215a8330c32	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_deleted	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Deleted abdonnoli@gmail.com	2026-07-04 07:27:14.163578+00
bd6fbd8f-f8a7-4d73-9759-0ebc3d491436	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-07-04 07:29:19.70115+00
b27eba3d-f23e-4172-a057-98d2964600bd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	b69e0d20-e229-4210-807f-35119377abe6	Updated member: Abdon, Nolasco	2026-07-04 07:30:33.46882+00
ceaf4eee-64a0-48a1-837a-c121c260c125	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-07-04 07:32:56.108306+00
2280c034-f51d-4a73-94dc-e26e581bd4f5	1801f3bc-0a0b-43d9-94b1-e0514f27d38a	nholliea006@gmail.com	login	user	1801f3bc-0a0b-43d9-94b1-e0514f27d38a	Signed in	2026-07-04 07:33:22.033317+00
038719e2-e911-464d-be17-f2cd06049509	1801f3bc-0a0b-43d9-94b1-e0514f27d38a	nholliea006@gmail.com	logout	user	1801f3bc-0a0b-43d9-94b1-e0514f27d38a	Signed out	2026-07-04 07:33:47.48233+00
76ea1936-cc62-4fad-9278-073bf9f4399d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_deleted	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Deleted abdonnoli@gmail.com	2026-07-04 07:34:16.629368+00
15779870-6d85-47bc-a557-2a941efd980e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-04 07:33:55.623924+00
aee0e1f0-4a12-47c3-8be7-c88f615e5448	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-07-04 07:35:55.074263+00
3add01a6-eecd-430a-9486-48d9015744d0	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-07-04 07:36:08.729761+00
1a7fd6ce-34bf-44f3-9c84-8626990793e4	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-07-04 07:36:12.963952+00
f8b7c5fe-2f25-4a55-b66f-63bd5bc66de4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-04 07:36:21.480007+00
e6e2179c-d5f1-40e1-a77d-9aaf307975b6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	announcement_posted	announcement	8	"Sunday Worship Service"	2026-07-04 07:39:13.138603+00
58de822d-b7f1-4aeb-9ab4-b0d1c5d82f21	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-04 13:01:49.221339+00
784cca73-b771-4bae-b864-c4ed573d7541	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	6c3c168f-ee29-4acb-9760-4cb802db727e	Created Abdon, Analiza (jinkykay006@gmail.com)	2026-07-04 13:06:41.126299+00
cf291b1f-8143-4b2e-89fd-6964a8b9ceb2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	341f3b46-8f81-4db4-9e83-c6c77c23abbc	Created Bolaños, Grace Anne (gracezephbolanos@gmail.com)	2026-07-04 13:10:17.49175+00
39ea252c-45fa-46fd-9a7c-40888d1fa99c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	a4d291ad-9480-4d62-ad61-ad95d1fe5f26	Created David, Zabdiel Kent Jarence M. (zabdiel.david14@gmail.com)	2026-07-05 00:24:00.59519+00
26d982c2-f399-47c3-a0a9-1bbe6bf194ee	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-07-05 00:31:37.245429+00
61882100-f5f6-49b2-b0f5-0ababa0a1299	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-05 00:31:50.205084+00
40047f15-105b-42de-ae71-a9fe7d9c4ee2	a4d291ad-9480-4d62-ad61-ad95d1fe5f26	zabdiel.david14@gmail.com	login	user	a4d291ad-9480-4d62-ad61-ad95d1fe5f26	Signed in	2026-07-05 00:33:04.355207+00
cae8c840-20d4-4a8e-bc52-4dd9d6067ab4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	7209d01b-1cec-4de4-bf98-517b3405d68e	Created Sigue, Charisse Joselle S. (charissejosellesg@gmail.com)	2026-07-05 00:34:57.262642+00
fddeb0c0-9b0a-4102-9ca4-e228f48593ba	7209d01b-1cec-4de4-bf98-517b3405d68e	charissejosellesg@gmail.com	login	user	7209d01b-1cec-4de4-bf98-517b3405d68e	Signed in	2026-07-05 00:36:24.61388+00
b79df63f-bb94-4764-92ab-c6d994be280b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	5996dedd-c7d5-4bd8-83c7-f297507355d1	David, Zabdiel Kent Jarence M. checked in	2026-07-05 00:37:15.022934+00
8d2f66d4-3f33-47dc-83de-51ee0dab9fdc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	attendance_recorded	attendance	ceec8411-7036-45f9-8df9-f13db0601590	Sigue, Charisse Joselle S. checked in	2026-07-05 00:37:40.016165+00
e732305c-4539-42cc-8d79-987811405c7f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	2fc913ba-e354-4f8b-8c97-1b6c988d241e	Updated member: Magcamit, Gwyneth Dorothy	2026-07-05 07:12:59.469959+00
c5aa5bdd-954f-4854-bb8e-598d9d88cbd0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	6ef7bee6-7cba-46a7-ad34-cce842e3eeff	Updated member: Camacho, Daniel Paul M.	2026-07-05 07:34:37.242169+00
ccefff46-6561-423f-8704-faee1a4ee288	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	10e98a1d-539c-40e6-ac71-4bf4ab0bb029	Updated member: Calidguid, David James C.	2026-07-05 07:35:33.860342+00
a7c694a2-efd3-4b16-9c02-ae13656abfc2	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	10e98a1d-539c-40e6-ac71-4bf4ab0bb029	Updated member: Calidguid, David James C.	2026-07-05 07:39:02.145846+00
5d2c4815-99b6-4a63-81b8-cf8e43637194	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	02ef26bb-ae4e-4573-8ee9-6e3f8772afe2	Updated member: Villanueva, Wyl Amram T.	2026-07-05 07:39:47.517541+00
2d05cee2-4b5b-4b49-b3a7-44edf707a51b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	92294503-c4b3-4871-bee7-bbc92f8c5dc3	Updated member: Bernadit, Ezekiel James	2026-07-05 07:41:43.560511+00
cca2c183-06e6-433e-97b7-19bb0178c877	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f9809ab5-2414-45c5-91b4-71b1c99675b1	Updated member: Peñaverde, Haven	2026-07-05 07:49:46.481391+00
7cbcd1e3-5f14-49e8-80c4-3af4bffa71da	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	235b7af6-39ae-43f0-8211-9d1ee26d14e2	Updated member: Peñaverde, Cherished Jewel	2026-07-05 07:49:56.877566+00
345a75b5-a273-4d86-b90a-802c4691fa5a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	eafb16ea-73a6-459d-a296-7a816fc42224	Updated member: Peñaverde, Marissa	2026-07-05 07:50:05.62815+00
b39a9e04-2986-43b7-be3e-806e2e08dda4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	010fd11f-1068-4b72-9f47-333dfb4f8459	Updated member: Peñaverde, Nicanor	2026-07-05 07:50:16.382714+00
6c64e9ce-4b64-45e1-ac5d-d7d870d0ae81	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f70d6460-84d6-4dcb-83aa-eb26e1d5a478	Updated member: Peñaverde, Precious Angel	2026-07-05 07:50:25.650554+00
99793ed6-44a1-4e34-8876-99a3dfb7b216	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0b03aa83-217a-41ab-b2a2-b5b82a14cf2c	Updated member: Peñaverde, Psalm	2026-07-05 07:50:36.644387+00
49efd489-b54e-4477-881d-ba6fa6282bc0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-23 03:13:10.178604+00
c6d02686-5c0a-4c09-8a23-2257f0e198af	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	235b7af6-39ae-43f0-8211-9d1ee26d14e2	Updated member: Peñaverde, Cherished Jewel	2026-07-05 07:51:00.155478+00
1604035f-2f0e-4aac-9284-7757eea41677	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	eafb16ea-73a6-459d-a296-7a816fc42224	Updated member: Peñaverde, Marissa	2026-07-05 07:51:18.334624+00
90507fcd-e80f-4e2d-be6e-ebafd90504f8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f70d6460-84d6-4dcb-83aa-eb26e1d5a478	Updated member: Peñaverde, Precious Angel	2026-07-05 07:51:40.377047+00
44c0210d-c559-43af-b38f-35c89e32b287	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0b03aa83-217a-41ab-b2a2-b5b82a14cf2c	Updated member: Peñaverde, Psalm Josh	2026-07-05 07:52:16.216338+00
37ccad97-d5bb-4c1e-bb38-1748e249cd94	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	0e220e0b-794c-4a15-bee2-23d04d8300f1	Created member: Ilao, Reanne	2026-07-05 07:53:20.334193+00
575d20cb-b0a9-4d84-8d1c-30c4ec7e0393	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	969f2aec-7a06-444b-a590-26ea15cd998c	Updated member: Reyes, Tristan R.	2026-07-05 07:55:01.29603+00
c4bd3786-bcbe-442a-aa33-cc13ee0675d4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	eafb16ea-73a6-459d-a296-7a816fc42224	Updated member: Peñaverde, Marissa	2026-07-05 07:55:54.520385+00
85183ffc-08c9-42c1-8dc1-229a5315c4be	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f9809ab5-2414-45c5-91b4-71b1c99675b1	Updated member: Peñaverde, Haven Josh	2026-07-05 07:56:54.253086+00
ef394195-07e3-4a88-843d-0aad90cc9f95	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	1e31aa0e-86cd-407a-ab1d-b227a7f43fcc	Updated member: Villanueva, Ullypa	2026-07-05 07:57:31.555067+00
39134670-9018-4da5-a30f-127a03e5ba55	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a8a9c3b1-e52c-4789-a093-0c5a94381d13	Updated member: Villanueva, Willy	2026-07-05 07:58:06.532009+00
d21a79e5-3454-4731-83f7-285562f2f598	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	638160ab-dcb6-43d7-a417-3ecfcabbacd4	Updated member: Malangis, Ricardo	2026-07-05 07:59:21.251183+00
e6d5105c-fb12-4eb5-9179-de16d3ebd6b3	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	4319944f-03e5-4a57-9722-180364fad573	Updated member: Sapul, Luisito	2026-07-05 07:59:51.660681+00
6bc4d79f-9e26-4ec2-bd78-4ad977af442b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	7913742e-1132-4f39-90a9-9a456e53df8f	Updated member: Calidguid, Shiela	2026-07-05 08:00:31.59158+00
f36814d3-1704-46f6-a445-4fd193677433	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	566c3572-7f46-403c-900f-c8ee777efc37	Updated member: David, Ana Florence	2026-07-05 08:01:08.370186+00
a5e9cd0b-a6db-42fd-a388-ccf2ddd1ee6d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e855a73b-e58b-41ed-819d-b95cea314837	Updated member: David, Jeffrey	2026-07-05 08:01:24.02336+00
b151f52d-4736-4997-b395-ab1af13e87a1	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a7449003-7672-457c-853d-2b391dc7a37f	Updated member: Mascarinas, Edwin	2026-07-05 08:02:09.329429+00
1c49026f-ab22-4076-bd3a-93671287d24f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	e9b2a1fd-bf6c-4bbb-ba75-414932663b5d	Created Mascarinas, Edwin (gideonmasc@gmail.com)	2026-07-05 08:03:48.228707+00
f412e56b-042b-4823-b82b-3120edb65d1f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	991ecb04-59f0-4ea0-b653-4de004b572b2	Created Magcamit, Gwyneth Dorothy (gwynethdorothymagcamit3@gmail.com)	2026-07-05 08:14:41.426958+00
1c17f235-2d5d-4383-bd18-1962813b962a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	704ffd7e-85cc-4121-ab38-13a124b29aa5	Created Camacho, Daniel Paul M. (dan094232@gmail.com)	2026-07-05 08:18:19.208963+00
275c467f-ada4-46d2-810d-9e4821ae4177	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	a470f357-9ae7-4655-b675-2b463e0b1374	Created Caringal, Jester Carl Daniel (jesthercaringal@gmail.com)	2026-07-05 08:22:13.308809+00
4956d6af-3bc0-4b99-b454-ef9d56271301	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	2af9861a-ae3f-4b2d-b672-f0b5f95d350a	Updated member: Caringal, Jesther Carl Daniel	2026-07-05 08:23:42.925842+00
2c9911a4-e819-41ed-9870-9209b0604bd6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	d9b5a9d8-a21d-4b0d-bedd-cd13de3d8816	Created Caringal, Jethro Carl Daniel (jethrocaringal@gmail.com)	2026-07-05 08:24:30.414725+00
85638739-5842-4fb8-b23b-d5bd85189622	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	27f4313b-a23d-4ab9-8705-16ddbb3d33a2	Created Calidguid, David James C. (calidguiddavid@gmail.com)	2026-07-05 08:26:22.773802+00
b68550c9-3ae8-4234-8632-fc1f1f8fb21e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	08679fae-f4ea-46e4-877c-4fc509bce66e	Created Villanueva, Wyl Amram T. (amramvillanueva@gmail.com)	2026-07-05 09:22:42.839117+00
135cd3e5-41f9-4b60-b0e0-a42b843e4e7e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	bdfd68c9-fd9a-43d2-89e5-2541674350b9	Created member: Baknong, Ian Ros	2026-07-05 09:27:15.056499+00
158f8fc0-a315-4954-9d47-8df7696a08e4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	08b84fab-3d1f-478b-8cc3-58584746f8d3	Created Peñaverde, Psalm Josh (penaverdepsalmjosh@gmail.com)	2026-07-05 09:30:42.178033+00
80299272-fea8-4329-b92e-b6913661e11e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	f697573a-9cd9-44be-a3ca-9c8de8c86377	Created Ilao, Reanne (reanneilao@gmail.com)	2026-07-05 09:32:36.536874+00
6af60d45-67c4-4381-b982-f2959379dafc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	b04bf73c-6ae9-408d-a8e7-b783d4efc1a7	Created Reyes, Tristan R. (regenciatristan87@gmail.com)	2026-07-05 09:34:23.002243+00
0a4631e6-ece2-431f-a153-520e354696a6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	834c21d2-c954-4d25-967d-ea608f36cda0	Created Peñaverde, Haven Josh (penaverdehavenjosh@gmail.com)	2026-07-05 09:35:53.062255+00
95abe4c6-427e-494b-8e07-247031ab236f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	9858c180-9eac-4c23-9a66-21593301c142	Created Palmero, Jasper (palmerojaspher@gmail.com)	2026-07-05 09:40:23.778943+00
d5b8d35c-59b8-402f-b53e-54d367946a42	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e4333720-3c25-427b-92a8-b6d3a7eb6a9d	Updated member: Palmero, Jaspher	2026-07-05 09:40:58.195749+00
6ae9d414-728d-4365-9135-5c996aabea5a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	16571d05-3777-45e1-819a-20bbd9358f48	Created Morente, Angel (angelmorentep@gmail.com)	2026-07-05 09:43:21.861063+00
d9635924-367a-4e0d-8d6a-89123f71e640	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	056957bc-47ac-461a-9a73-7b8a1863d0b5	Created Salazar, Jireeh (jireeh0306@gmail.com)	2026-07-05 09:45:33.360805+00
36cbdcbf-5564-4886-b78c-f0788d2d9e97	e9b2a1fd-bf6c-4bbb-ba75-414932663b5d	gideonmasc@gmail.com	login	user	e9b2a1fd-bf6c-4bbb-ba75-414932663b5d	Signed in	2026-07-05 09:47:22.66653+00
86afb0d0-d003-47d0-b407-8645485e90cb	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f2c66819-74a2-4288-8512-8935a069c4fe	Updated member: Mangante, Glezybelle	2026-07-05 09:48:09.878398+00
4f71f279-c915-4a01-99e3-308b6c0da6a8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	c0e6de1a-ceef-43f0-9bf2-4861b047aace	Updated member: Salazar, Jireeh	2026-07-05 09:48:35.861508+00
a349d488-8075-4c3f-aac1-5becb406a8a7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	443daf66-0c24-42a3-8a00-12ee4538d1b8	Updated member: Magturo, Princess Rosebelle	2026-07-05 09:50:12.79807+00
82b316a0-6e51-4359-96a0-3da2ace3c062	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	31faae60-b91d-4bae-99a8-51edf6c939a8	Created Mangante, Glezybelle (gilbertmangante@gmail.com)	2026-07-05 13:16:20.041702+00
9604fe2a-d051-40ae-9cfa-f876ed90059c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	3da69563-ecc2-457b-b608-c2b16b4fb712	Created Magturo, Princess Rosebelle (rosebellemagturo@gmail.com)	2026-07-05 13:19:35.057475+00
f322c3ed-91e0-4057-911b-e03778a68e8d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	443daf66-0c24-42a3-8a00-12ee4538d1b8	Updated member: Magturo, Princess Rosebelle	2026-07-05 13:21:24.148832+00
2d2eb804-4a79-411b-89c8-327cb96d75f8	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	f05f56f8-93d7-4af3-9c67-d33cac2f3a75	Created Lumague, Marielle Danielle (mlumague566@gmail.com)	2026-07-05 13:24:07.837476+00
bf770f5e-6787-4558-859e-85d77546a66d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	90c2cf00-edc1-408d-a89c-9c28e4697f8d	Updated member: Lumague, Marielle Danielle	2026-07-05 13:24:42.633575+00
3618b582-fc01-4fe0-bf25-e49623672cf4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	99d25b56-8054-4cc7-9000-ed0b3a01a359	Created Magcamit, Gaddiel (magcamitgaddiel@gmail.com)	2026-07-05 13:27:59.800282+00
00ca9982-ec8e-4c69-a7a0-a416fb54577c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	0b70a942-3407-4808-9e0c-31751812a11b	Updated member: Magcamit, Gaddiel Love N.	2026-07-05 13:28:45.216888+00
5ade5f6d-9bac-4173-81f9-bc949f1751f4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	aeacc657-6e9b-444b-b52a-10b4f9a62715	Created Jarabe, Trisha Gail (rhitsaresya@gmail.com)	2026-07-05 13:31:30.61977+00
2c034aff-45c4-49a9-8b7c-d3c2fe271909	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	6ae59089-32a5-4145-bfb3-b1ad463bf22b	Updated member: Jarabe, Trisha Gail	2026-07-05 13:31:55.858418+00
387e32ac-9027-4440-92a1-f36c58a76d2f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	4863bb41-c8a8-4c16-af1c-5aead378ddc1	Created Villanueva, Wyl Malachi (wylmalakhiv@gmail.com)	2026-07-05 13:34:12.258885+00
8a784efd-e97b-4488-bf27-cea8e4fea33d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	12e0ef3b-eeaa-4873-990d-f99b893a758c	Updated member: Villanueva, Wyl Malakhi	2026-07-05 13:34:46.605521+00
d0d7fdb8-9562-4d21-9196-43fe5fc7d883	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	12e0ef3b-eeaa-4873-990d-f99b893a758c	Updated member: Villanueva, Wyl Malakhi	2026-07-05 13:34:58.097765+00
543f29f5-3610-4df2-83ad-669dedba5b6e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	d8b86085-f8ac-4315-b05b-83aa26a1cce6	Created member: Rodil, Cristoffer Ivan S.	2026-07-05 13:37:34.268215+00
beb85076-b78c-49ed-ab06-70083eecafa9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	922a40c0-b382-4e86-8871-26611aa68b0c	Created Rodil, Cristoffer Ivan S. (ivanrodil308@gmail.com)	2026-07-05 13:38:37.216732+00
bef35711-afb9-4018-972c-3126106c3725	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	289c35fb-751e-4ac8-8060-22be4d001ccc	Created Salazar, Genevieve (genevievesalazar@gmail.com)	2026-07-05 14:02:17.49004+00
77280246-b644-4a1a-b5ed-fa3b104c8f4f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	6d75a29b-b271-4af3-b658-449fc06a2169	Created Mascarinas, Zenaida (zenfavor2018@gmail.com)	2026-07-05 14:04:28.238794+00
4f6ec74b-bbf7-491a-8d3e-22bcdfb70afe	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	981fb578-7140-4e36-9780-12a4fb94a6b8	Updated member: Mascariñas, Zenaida	2026-07-05 14:04:55.904102+00
59d894fc-999f-4f17-ad96-a12b4e85b7ef	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	981fb578-7140-4e36-9780-12a4fb94a6b8	Updated member: Mascariñas, Zenaida	2026-07-05 14:05:04.088598+00
08e74384-5d85-47af-b0ea-d62403981f5b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	a68dd28d-eb11-4fa7-a1a2-469dacb1e88c	Updated member: Bernadit, Jezreel	2026-07-07 04:25:51.958529+00
33e745f3-420a-4f91-a4ce-6877256670be	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	16184f27-1940-4d9e-b0c6-7f8a7f340897	Created Magcamit, Glenda (glendamagcamit@gmail.com)	2026-07-05 14:07:58.468343+00
6681f8b7-daa3-48ea-ad64-faa6737a91aa	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	e4010c82-5c16-4584-a288-8c33c382c78d	Created Peñaverde, Precious Angel (angelleprecious.penaverde@gmail.com)	2026-07-05 14:10:50.788997+00
04866d95-850c-458e-bd04-71f4f0a23b3f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	f70d6460-84d6-4dcb-83aa-eb26e1d5a478	Updated member: Peñaverde, Precious Angelle	2026-07-05 14:12:23.764598+00
f982acb6-e3b7-4b14-9bda-192f1be7705e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	f1c79b67-86b5-48dc-a6f6-38100bf6aaf2	Created Peñaverde, Marissa (marissapenaverde@gmail.com)	2026-07-05 14:15:32.969624+00
5995c2e6-ca17-4b64-a76c-428e02f1f8e9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	94f26f23-2e6b-418b-851a-34c651e5f24b	Created Villanueva, Ullypa (ullypavillanueva@gmail.com)	2026-07-05 14:16:43.669675+00
c4c4d237-4f83-41ac-98dc-5b0bc11e950b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_deleted	user	9acdd0f1-06b0-4b19-9620-f59a4f2bca30	Deleted villanuevaullypa@gmail.com	2026-07-05 14:17:36.494171+00
94c74952-9dde-4155-a202-76285a7a0150	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_deleted	user	94f26f23-2e6b-418b-851a-34c651e5f24b	Deleted ullypavillanueva@gmail.com	2026-07-05 14:17:53.878965+00
11c44488-5f1f-473d-89ed-28a403b4d4f6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	3fa4e9d8-f744-47ae-bb5b-e2f69135cd26	Created Villanueva, Willy (pulis_villa16@yahoo.com)	2026-07-05 14:19:48.196039+00
3766bd7a-38d9-471c-bea9-761bcebdb37e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	638160ab-dcb6-43d7-a417-3ecfcabbacd4	Updated member: Malangis, Ricardo	2026-07-05 14:21:39.462049+00
14065df3-5d3e-4347-be4c-8b72f4f1548f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	34bbfe8b-37f9-437d-aa1a-74bdd6870433	Created Malangis, Ricardo (ricky111585@gmail.com)	2026-07-05 14:22:46.032534+00
cab1c688-f272-49e4-b2c5-054ac84bfcdc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	8fc730c3-044d-48c9-b542-22c23753e989	Created Sapul, Luisito (luissapul@gmail.com)	2026-07-05 14:29:45.347352+00
d5ac5f2a-e3c7-4c04-8e3f-8665638c19c9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	b5f12c36-b5d2-48fd-9dbc-d3e51e1ee93c	Created Calidguid, Shiela (shezkynicole@gmail.com)	2026-07-05 14:32:14.734099+00
7b4c3cac-4d6d-4cf6-be7e-06a0d8b7ad95	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	6ef45081-88a6-4713-92f9-5bf033668d06	Created David, Jeffrey (jeffrey.david06pirates@gmail.com)	2026-07-05 14:33:52.513519+00
7c5f6505-c7e8-4eb1-ac29-486ff016fbbd	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	0da9d57e-0e51-48f0-bd1c-a9ccbde207c2	Created David, Ana Florence (anaflorence@gmail.com)	2026-07-05 14:35:10.112071+00
7c9e7099-75a0-4251-b693-ef891b288e68	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	a1f44ce3-e752-4be4-8f0e-a7c45bffcc17	Created member: Laderas, Antonette	2026-07-05 14:46:28.389751+00
174021a9-a019-4c6b-9805-03eb876a9c5b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_created	member	d64d1327-555b-4e79-9ff6-162f0298ae38	Created member: Asuncion, Jienel	2026-07-05 14:50:19.641732+00
e175022f-eb59-43f9-8288-4047cb9b521b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	fafc7719-006b-4ba4-816a-e7dee6f52401	Created Regencia, Amielyn (amielynregencia@gmil.com)	2026-07-05 14:52:26.007214+00
f2e3d423-241d-453c-8bd6-dd9d642e5f7c	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	5d1b41a2-c4cd-4e03-94e8-b18c36f20c21	Created Laderas, Antonette (antonetteladeras@gmail.com)	2026-07-05 14:53:16.812843+00
00c1d854-45ab-48e4-afe6-12ef43d4e977	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	f05dc39a-27e3-4358-bffe-df2d3306e39d	Created Maaño, Ava Marie (avamarie@gmail.com)	2026-07-05 14:53:57.38657+00
01bd0c84-1061-4e71-ad82-aa23d99626c7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	51c278c7-985f-43ad-b1a1-6511d4774d2d	Created Camacho, Danreb (danreb@gmail.com)	2026-07-05 14:54:37.424997+00
99f6b182-454a-48dd-a15b-a84fc35f5b42	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	a8fb11be-ee5e-4bfa-9363-bbe391bf7ab6	Created Jimenez, Efraim (efraimjimenez821@gmail.com)	2026-07-05 14:55:37.559406+00
16ce0a17-c838-4112-abbc-bc509be4f9d9	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	7eb706a0-bf7a-4398-b7df-b0857cec9668	Created Morente, Gilbert Jr. (jrmorente@gmail.com)	2026-07-05 14:56:15.54956+00
bc40b75b-ec86-4e1e-9b0d-52fe3ccc0554	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	92927591-a31a-4d9b-a828-67f78a367005	Created Villaluna, Mary Grace (gracev@gmail.com)	2026-07-05 14:56:52.843586+00
190576e8-9783-4be2-9e78-755cd1d388b7	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	b5d78d9c-162c-46f6-9479-9a3359d65f56	Created Regencia, Jeanitha (jeanethr@gmail.com)	2026-07-05 14:57:56.067963+00
ebb399e9-c79f-4da0-ab13-3fd33f9a8e0b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	2798911c-e175-4b2a-8d9a-7ca4cdae816b	Created Asuncion, Jienel (jienela@gmail.com)	2026-07-05 14:58:33.912676+00
11e2d609-d69c-4789-ad0d-ef7f582fb5a0	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	b6f736c7-1275-4edf-847f-dbae85526ba9	Created Malabay, Teresita (thessmalabay@gmail.com)	2026-07-05 14:59:37.187366+00
cbb9a45f-3d6c-4d06-8796-440fc84d987b	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	user_created	user	18f725da-689b-4512-ae57-0e7996e3b930	Created Salazar, Zion Reign (zions@gmail.com)	2026-07-05 15:00:17.478179+00
3cf27380-ce72-4ac8-9253-a77140b10808	5d1b41a2-c4cd-4e03-94e8-b18c36f20c21	antonetteladeras@gmail.com	login	user	5d1b41a2-c4cd-4e03-94e8-b18c36f20c21	Signed in	2026-07-06 02:00:15.200218+00
a7c094b9-147f-44e2-90b8-b1e04325b170	991ecb04-59f0-4ea0-b653-4de004b572b2	gwynethdorothymagcamit3@gmail.com	login	user	991ecb04-59f0-4ea0-b653-4de004b572b2	Signed in	2026-07-06 02:01:35.250106+00
2cf31d44-3e44-4089-8743-8eca21dbe64b	5d1b41a2-c4cd-4e03-94e8-b18c36f20c21	antonetteladeras@gmail.com	login	user	5d1b41a2-c4cd-4e03-94e8-b18c36f20c21	Signed in	2026-07-06 02:06:07.175696+00
f2bd0ed6-2a03-4fd2-bccc-b1825fe2361a	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-06 14:00:06.946993+00
52e1ceac-e9c1-4c55-bf6c-c08da31ed952	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e7902f31-5450-4483-8a1f-be8ff7b2a30c	Updated member: Aborquez, Jemmichah	2026-07-06 15:19:29.331651+00
88e71d3b-5d31-4f19-902b-5951d0e2bc7d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	4942304c-0292-435c-bd3d-6801d67e4011	Updated member: Aborquez, Sandara	2026-07-06 15:19:54.507074+00
81e67fd7-cfef-494a-a748-e3e92af46910	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	599dfe68-1645-4d46-8262-ad35d836afde	Updated member: Aborquez, Israel	2026-07-06 15:20:19.712127+00
2dde96d7-6147-4d8a-8276-a80f12d55550	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	4942304c-0292-435c-bd3d-6801d67e4011	Updated member: Aborquez, Sandara	2026-07-06 15:20:51.831331+00
97e2dad5-7a56-455e-9979-66efb3f2ed3a	6c3c168f-ee29-4acb-9760-4cb802db727e	jinkykay006@gmail.com	login	user	6c3c168f-ee29-4acb-9760-4cb802db727e	Signed in	2026-07-07 04:01:12.894425+00
215983e2-6a89-4cd9-8302-5841a5ea0586	6c3c168f-ee29-4acb-9760-4cb802db727e	jinkykay006@gmail.com	logout	user	6c3c168f-ee29-4acb-9760-4cb802db727e	Signed out	2026-07-07 04:01:50.580793+00
2d8cc9ef-ff03-470a-835b-1b940bca652c	6c3c168f-ee29-4acb-9760-4cb802db727e	jinkykay006@gmail.com	login	user	6c3c168f-ee29-4acb-9760-4cb802db727e	Signed in	2026-07-07 04:02:16.170507+00
33baf1da-aa65-4c81-ad88-f81a4c527d2e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	38113d30-6468-4cf9-8f0e-71345e38d4bf	Updated member: Muyco, Keziah Esther Mae	2026-07-07 04:20:37.672179+00
ee3118d0-f790-426c-a319-c414bbe2393d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	4e7df2f5-14cd-492a-8bf1-210313fea10e	Updated member: Asi, Jenny Rose	2026-07-07 04:20:52.23961+00
cec0ead8-8940-492d-ba30-1a8aa5806b2f	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	41750d34-8220-4b8a-a052-7942aed874a4	Updated member: La Rosa, Jenny Rose	2026-07-07 04:21:16.96076+00
736b77af-adb5-4bfd-88dc-8b2ed7f4a61a	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	e5b22d55-9380-43aa-8476-25e4c65fed7d	Updated member: Bernadit, Mary Jay	2026-07-07 04:23:29.242522+00
5581d175-1e54-4472-bf40-80f8589d8e14	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	member_updated	member	12589065-2014-4ff8-b222-a31bdc364bcb	Updated member: Bernadit, Jason	2026-07-07 04:24:18.816632+00
ed21e987-bcd8-4819-8d3a-282f19aced75	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-07 10:39:07.008799+00
1977cfc1-1dcb-4e7a-b368-3f5cd7e3ffaf	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-07-07 11:04:30.438484+00
7df2aaa8-06f9-4ff5-b9c6-450955247e6d	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-07 11:04:38.175625+00
b4075d5a-8892-4ec1-b90f-ee5d7e04922e	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-07-07 11:06:57.021947+00
cefb8228-2482-4ff8-827e-59770d49ce06	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-07-07 11:07:04.942922+00
3cd39208-ac60-4a3b-8532-c4514a6ad5fc	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-07 11:07:15.024763+00
8ca944f1-e1c3-4565-a506-01470d70b872	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-07-07 11:24:02.753654+00
2457534b-bfe7-4c02-8b19-fd694f469610	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-07 11:24:32.37158+00
58856608-fab5-4f57-9a36-b6a909ea5e37	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_updated	user	2a81452d-3ab7-4578-9438-bed90045ff84	Updated yoheroscholar2@gmail.com	2026-07-07 14:50:07.402947+00
d1958526-6117-408d-8d44-4e06eb7c4762	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_updated	user	2a81452d-3ab7-4578-9438-bed90045ff84	Updated yoheroscholar2@gmail.com	2026-07-07 14:50:07.508969+00
39fdef03-6e96-468d-9734-dacb85c1c42e	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_updated	user	2a81452d-3ab7-4578-9438-bed90045ff84	Updated yoheroscholar2@gmail.com	2026-07-07 14:57:33.271876+00
c40b3a1f-962e-4e4d-bfe2-a7a644f46ba9	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_updated	user	2a81452d-3ab7-4578-9438-bed90045ff84	Updated yoheroscholar@gmail.com	2026-07-07 14:57:52.711471+00
9bd14558-8ff2-4bf3-b784-cac01c4c115b	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	user_updated	user	2a81452d-3ab7-4578-9438-bed90045ff84	Updated yoheroscholar2@gmail.com	2026-07-07 14:58:03.90156+00
67666f56-f32d-4c8d-840d-c6873637a24d	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-08 02:07:09.701002+00
87cad350-f8f9-4e0a-9f89-310c2adec5f4	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-07-08 02:08:39.204971+00
948d19db-a720-4295-8437-81fc2f5f453f	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-07-08 02:08:47.104577+00
7cb4cb3d-99cd-4bcf-a4cb-28107705fd71	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-07-08 02:08:54.27942+00
94ee5f07-335b-43d9-ab0f-0f19e96d88d6	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-08 02:09:08.080063+00
9a303256-bafd-4c72-9b90-a119ab379533	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-07-08 02:12:03.928175+00
d2e91aaf-3baf-4ab2-98d6-d131cd1eee41	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-07-08 02:12:14.584765+00
8ba91230-3fd3-4c25-a541-ac92dc481408	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 02:12:28.510109+00
e70b5061-5ccb-4287-ab13-e061cd3c80d4	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 02:15:34.507885+00
6aa8d343-b122-4d5f-9548-85e74a2eb5db	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	announcement_posted	announcement	9	"Sunday Service Worship"	2026-07-08 02:23:12.854154+00
bd279a57-3680-4089-b0e0-9f3fc7414ca7	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 02:56:45.140036+00
b6448b44-8bf2-4f1c-9a78-fa93d0874761	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-07-08 02:56:55.312952+00
d56731f9-1e06-4b52-bc0c-da4280b4d79f	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 02:57:05.447741+00
76c5b1ed-db90-4d15-a978-1e9c64f048c8	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 02:57:50.402173+00
98664091-3a5c-4532-b2b3-4507c9f111da	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-07-08 02:57:57.196896+00
2df64f70-a237-4b04-8a5c-6ac198673067	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 03:02:34.66083+00
77efc6a4-abaa-4fb2-85cc-fd016a8ce0fd	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-07-08 03:02:48.330578+00
b72217d6-1315-41aa-ba49-e86e09897517	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-07-08 03:11:00.339839+00
5425823c-f71d-4756-b2c2-9f78a6d377f0	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-07-08 03:11:18.39445+00
87ff81e8-dc84-41c3-b8f0-6d174d94100c	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	logout	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed out	2026-07-08 03:12:31.617034+00
d36cd7d6-d554-4d85-9541-2eb03005336d	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 03:12:40.082842+00
07116bbb-e8c5-4cdd-836d-9cab259dc27e	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	logout	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed out	2026-07-08 03:14:07.159842+00
a49f9a20-e7b4-44e3-994f-c9a67877af2f	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-07-08 03:14:14.172661+00
1acc6220-f7bb-44c9-8303-14cd532e21ea	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	logout	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed out	2026-07-08 03:15:58.895165+00
3454f00d-20a6-45e4-bf95-02d2bc6841db	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-07-08 03:16:05.43326+00
a4ee1c85-5975-406d-9f25-243874d19d94	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-07-08 03:17:13.834365+00
3339e694-5057-4438-aaf0-737dbeff1b42	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	login	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed in	2026-07-08 03:17:19.775624+00
d0ea2868-239c-4aa8-8c86-c51d5fac38a0	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 03:18:21.500794+00
ab8cef34-d023-4ad5-8e15-a3b5aa6e2140	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	announcement_posted	announcement	10	"Sunday Service Worship"	2026-07-08 03:18:52.125433+00
516c95ee-953f-48fb-9c3c-ea707a90cb6b	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	announcement_posted	announcement	11	"Whole Month of July"	2026-07-08 03:20:04.383345+00
0199e88a-f9bb-476b-abe4-6eaa23a68749	3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	logout	user	3287ff5f-24b9-48d2-a4f5-0851151df4f0	Signed out	2026-07-08 03:20:09.958206+00
a322a24c-5f99-439a-9142-8b330eac6ee2	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-07-08 03:20:14.853853+00
6d4069e7-f501-46e2-8c85-12987586d55d	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-07-08 03:20:17.665469+00
b8fe3c99-c89e-415d-855f-0d0af3b169c9	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	login	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed in	2026-07-08 03:20:22.051663+00
d724d3c9-e9b9-4fed-aaf5-f6f768107825	1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	logout	user	1af0ee3d-05ac-45d6-a163-57f2066f6d55	Signed out	2026-07-08 03:20:25.262564+00
d1e09007-b41b-4637-895f-cbef5d470e2b	b6f736c7-1275-4edf-847f-dbae85526ba9	thessmalabay@gmail.com	login	user	b6f736c7-1275-4edf-847f-dbae85526ba9	Signed in	2026-07-08 03:20:34.309067+00
b867d28a-6b1e-49c3-84d5-991e6df40697	b6f736c7-1275-4edf-847f-dbae85526ba9	thessmalabay@gmail.com	logout	user	b6f736c7-1275-4edf-847f-dbae85526ba9	Signed out	2026-07-08 03:20:37.923556+00
83cec12a-679a-492e-bfb8-50d14c4c8a44	bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	login	user	bf6f048d-6397-4560-acdb-19cb222b8269	Signed in	2026-07-08 03:23:32.077075+00
76e00f1d-0f78-41e6-8894-8a998f7b4b78	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-18 11:02:05.894443+00
fa921300-b506-4559-b2d3-13f02074c58e	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-18 11:02:26.29383+00
618bd204-3353-464e-ba3d-7ebf8e810b97	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-22 05:00:14.88092+00
65781d45-e8e9-44e2-b12c-84ce3a10f3c5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	logout	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed out	2026-07-23 03:13:20.333893+00
ddd706eb-88e1-46ef-a431-f466971dfea8	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-07-23 03:49:10.423772+00
b9ed6529-86f0-4c50-90eb-9678ae7049a7	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	logout	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed out	2026-07-23 03:49:38.42523+00
b374e302-e1ea-463f-817e-401e9bd64dd5	253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	login	user	253edc87-ffa5-477f-83eb-85da0940ae9f	Signed in	2026-07-23 03:49:44.191305+00
7bf5f0a5-9d22-4b38-ad2b-8f8169f9abf1	3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	login	user	3e5f53d0-e288-45fe-9c17-92754472fb29	Signed in	2026-07-23 03:51:56.327719+00
\.


--
-- Data for Name: birthday_greetings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.birthday_greetings (id, event_id, member_id, message, created_at) FROM stdin;
14	14	0e97dc12-046f-4b6d-9883-8651dd436ce0	Happy Birthday! :)	2026-07-08 02:23:51.383849+00
\.


--
-- Data for Name: branches; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.branches (id, name, address, created_at, parent_id) FROM stdin;
e319ab92-b31d-4512-9126-0a12a86b69bc	Main – Pinamalayan	Pinamalayan Proper, Oriental Mindoro	2026-06-13 07:46:52.399302+00	\N
f11d4448-78f2-4d19-b3dd-487735deca7a	Luma	Luma, Pinamalayan	2026-06-13 07:46:52.399302+00	\N
916b1521-5401-4b29-967b-0a9fd7b76909	Papandayan		2026-06-17 09:37:15.428194+00	e319ab92-b31d-4512-9126-0a12a86b69bc
41ed046f-9c1c-453b-a506-35bbfe26f39d	Bukal		2026-06-17 09:37:33.818964+00	e319ab92-b31d-4512-9126-0a12a86b69bc
e0c4a768-0539-49c6-8cb1-7dc086bf92c7	Bacungan		2026-06-17 09:37:43.454649+00	e319ab92-b31d-4512-9126-0a12a86b69bc
4cd1ac72-0cc2-44fd-82c5-95576ad2bf75	Bagong Silang		2026-06-17 09:38:11.314457+00	e319ab92-b31d-4512-9126-0a12a86b69bc
e5eb2146-8a56-49ca-872b-84b958442097	Pamana		2026-06-17 09:38:20.658493+00	e319ab92-b31d-4512-9126-0a12a86b69bc
2a691c85-40e4-459a-b66b-a87671906296	Inclanay	Inclanay, Pinamalayan	2026-06-13 07:46:52.399302+00	\N
8334512f-5979-4cc0-9241-6e3c552e0028	Buli	Buli, Pinamalayan	2026-06-13 07:46:52.399302+00	\N
aaf6be61-c36f-4f50-a9e8-fd7c79e90127	Pier		2026-06-17 09:37:56.332096+00	e319ab92-b31d-4512-9126-0a12a86b69bc
\.


--
-- Data for Name: event_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.event_reactions (id, event_id, member_id, emoji, created_at) FROM stdin;
28	13	b69e0d20-e229-4210-807f-35119377abe6	❤️	2026-06-30 10:26:44.729818+00
29	14	0e97dc12-046f-4b6d-9883-8651dd436ce0	❤️	2026-07-08 02:23:41.361032+00
30	15	0e97dc12-046f-4b6d-9883-8651dd436ce0	🥳	2026-07-08 02:34:24.125504+00
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.events (id, name, type, date, branch, created_at, branch_id) FROM stdin;
10	Salazar, Jireeh	birthday	June 11	\N	2026-06-30 03:27:45.090587+00	e319ab92-b31d-4512-9126-0a12a86b69bc
11	Lanot, Germilyn	birthday	June 25	\N	2026-06-30 03:27:47.623268+00	e319ab92-b31d-4512-9126-0a12a86b69bc
12	Morente, Angel	birthday	June 7	\N	2026-06-30 03:27:51.071912+00	e319ab92-b31d-4512-9126-0a12a86b69bc
13	praise night	event	July 1	\N	2026-06-30 03:28:35.185935+00	e319ab92-b31d-4512-9126-0a12a86b69bc
14	Malabay, Estrelita	birthday	July 12	\N	2026-07-01 15:05:04.827978+00	e319ab92-b31d-4512-9126-0a12a86b69bc
15	Maaño, Leonar	birthday	July 28	\N	2026-07-01 15:05:07.449424+00	e319ab92-b31d-4512-9126-0a12a86b69bc
\.


--
-- Data for Name: finance_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.finance_categories (id, name, description, created_at) FROM stdin;
c53d77e1-f9ec-4451-be9e-644e614296a2	Tithes	\N	2026-06-18 00:19:51.075964+00
0c438581-d29c-431a-804d-c6a04d124fac	Offering	\N	2026-06-18 00:19:51.075964+00
72b437cd-4d3e-4059-8e90-92980f04bbb7	Pledges	\N	2026-06-18 00:19:51.075964+00
b7ec08f7-9b90-4038-a9cd-c3a35cefbda2	Mission	\N	2026-06-18 00:19:51.075964+00
bf5ad270-8349-42af-812a-6a32a1d0c858	Support	\N	2026-06-18 00:19:51.075964+00
c9dba440-3ce0-4703-b234-2167e67f6044	iCare	\N	2026-06-18 00:19:51.075964+00
2945a8f0-381b-4599-8869-fdb0c06f7ebf	First Fruit	\N	2026-06-18 00:19:51.075964+00
\.


--
-- Data for Name: finance_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.finance_records (id, member_id, branch_id, type, amount, record_date, recorded_by, created_at) FROM stdin;
\.


--
-- Data for Name: giving; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.giving (id, member_id, type, amount, note, date, branch, created_at, branch_id) FROM stdin;
\.


--
-- Data for Name: members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.members (id, member_code, name, birthdate, address, category, member_type, lifegroup_leader, branch_id, points, created_at, type, branch, user_id, is_active, gender, status) FROM stdin;
c4f53bf9-d840-4f43-a1b3-aa31dbf39123	JIL-1781354415069-4	Abel, John Mark	1981-03-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	Male	Active
0e97dc12-046f-4b6d-9883-8651dd436ce0	JIL-1781448535930432	Salvilla, Harold Greg	2006-02-21	Pinamalayan	WSAM	\N	Ptra. Ethel	\N	10	2026-06-14 14:48:55.910784+00	Youth	Main – Pinamalayan	\N	t	Male	Active
cc623c4d-cde9-499d-85a0-e70039bf8039	JIL-1782609841539788	Lumaban, Junevalyn	2005-06-02		WSAM	\N		\N	10	2026-06-28 01:24:03.311193+00	Youth	Main – Pinamalayan	\N	t	Male	Active
599dfe68-1645-4d46-8262-ad35d836afde	JIL-1781354415069-6	Aborquez, Israel	1989-04-02		WSAM	\N		8334512f-5979-4cc0-9241-6e3c552e0028	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t		Active
c67166b0-db30-4310-b177-9f94d0b36696	JIL-1781354415069-57	Atienza, Harold	1994-09-26		WSAM	\N		f11d4448-78f2-4d19-b3dd-487735deca7a	0	2026-06-13 12:40:15.893971+00	Young Adult	Luma	\N	t	Male	Active
5f1f6df6-587f-4cca-bc20-8d73ed28cd48	JIL-1781354415070-957	Regencia, Ruth	1994-04-08		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
b69e0d20-e229-4210-807f-35119377abe6	JIL-1781354415069-2	Abdon, Nolasco	1981-01-31	Zone ll, Pinamalayan	WSAM/LGAM	\N	Ptra. Ethel Fiedalan	e319ab92-b31d-4512-9126-0a12a86b69bc	190	2026-06-13 12:40:15.893971+00	Men	Main – Pinamalayan	\N	t		Active
4e7df2f5-14cd-492a-8bf1-210313fea10e	JIL-1781354415069-56	Asi, Jenny Rose	1987-11-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	Female	Active
3c1abf22-1ad6-451b-ab5e-a97c0f4655de	JIL-1781354415069-83	Basco, Baby	1990-03-01		First Timer	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
93a30615-072c-425f-9377-16b88dbdc53b	JIL-1781354415069-84	Basco, Jane	1985-02-10		First Timer	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
270248b7-e849-47fe-a9fe-c2dbb8b9008d	JIL-1782003959436732	Cantre, Cristituto	1979-12-09		WSAM	\N		\N	20	2026-06-21 01:05:59.663327+00	Men	Main – Pinamalayan	\N	t	\N	Active
af9fc6f6-94ed-4fb3-bd1b-0bc321d02592	JIL-1782610011263895	Embate, Ruth	2006-06-02		WSAM	\N		\N	10	2026-06-28 01:26:52.481889+00	Youth	Main – Pinamalayan	\N	t	Female	Active
def35d65-c7c1-4666-a7b5-ba167b0b5d46	JIL-1781354415069-118	Bragado, James Vincent	2005-11-08		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
db03d6fe-1848-4693-808f-4b8677030fc4	JIL-1781354415069-119	Bragado, Joy Angelie	1990-04-12		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
f2a99f4b-5658-4924-8441-21cb66162b50	JIL-1781354415069-139	Camansag, Angel Mae	1983-11-01		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
fc6c389d-64d2-4127-bc0a-f94f55759afc	JIL-1781354415069-142	Camansag, Mary Grace	1998-05-27		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
0258c9bf-b996-4944-b633-bfe8a0d43362	JIL-1781354415069-111	Bonifacio, Jonalyn	1994-06-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
a4a39b72-f1ad-4f38-8e60-68d53a9c1a40	JIL-1781354415069-112	Bonifacio, Jovie	1995-10-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
08b62f39-de02-4f1c-ad4c-65516384a75c	JIL-1781354415069-156	Carpio, Noel	1961-10-09	Zone ll, Pinamalayan	WSAM	\N	Ptra. Ethel Fiedalan	\N	20	2026-06-13 12:40:15.893971+00	Men	Main – Pinamalayan	\N	t	\N	Active
732d3b71-0b1e-4bae-aafd-d586d35b0f32	JIL-1782610139130488	Mameng, John Kith	2010-07-14		WSAM	\N		\N	10	2026-06-28 01:29:00.402401+00	Youth	Main – Pinamalayan	\N	t	Male	Active
0f817e63-540b-4601-832c-90864f7a7cad	JIL-1781354415069-220	De Chavez, Jhonalyn	1997-11-23		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
a54e4523-e7c3-4e4f-818e-b302ef0f2186	JIL-1781354415069-166	Catuiran, Jeroh	1992-02-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
190a2df6-93ed-44e2-b898-6509e2237bca	JIL-1781354415069-167	Catuiran, Rose Ann	1980-10-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
ec18ecea-d03a-43ad-9a55-9d46704d2869	JIL-1781354415069-441	Lanot, Manuel	1998-02-13		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	Male	Active
c0e6de1a-ceef-43f0-9bf2-4861b047aace	JIL-1781354415070-1017	Salazar, Jireeh	2009-03-06		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:17.307634+00	Youth	Main – Pinamalayan	\N	t	Female	Active
638160ab-dcb6-43d7-a417-3ecfcabbacd4	JIL-1781354415069-605	Malangis, Ricardo	1982-11-15		WSAM/LGAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Men	Main – Pinamalayan	\N	t	Male	Active
d55670ec-378f-403c-803e-ead9603f6ec5	JIL-1781354415069-222	De Chavez, Nida	1995-06-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
6300819d-e78b-405b-87ee-d43207e6eb81	JIL-1781354415070-697	Marinay, Renato	1975-05-15		WSAM	\N		\N	20	2026-06-13 12:40:16.665642+00	Men	Main – Pinamalayan	\N	t	\N	Active
0fcdc907-3411-4a6f-85d3-047029f3c1f2	JIL-1781354415069-595	Malabay, Estrelita	1990-07-12		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
6338b1d6-f55e-4e6e-a3c6-758256a45e6d	JIL-1781354415069-549	Magcamit, Diomedes	1990-10-17		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	Male	Active
6ce0190e-77cc-46be-9537-5a7193403720	JIL-1781354415069-323	Gimeno, Genesis Grace	2003-01-03		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
340ae80b-d0be-4998-b374-375cb86ae28a	JIL-1781354415069-324	Gimeno, Jose Marie Cris	1981-04-07		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
9fc6253c-729b-4510-a9f2-f9b0bb6be401	JIL-1781354415069-331	Gonzales, Nenita	1999-05-07		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
f90537cc-8de2-4f26-b9ee-9adf712c2aa8	JIL-1781354415069-309	Gamolao, Ivy	1995-08-07		Guest	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
0d1b6b43-7494-40bf-a6e0-8dc41a95f0ba	JIL-1781354415069-277	Felix, Marieta	1987-01-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
0512b736-b3ae-4349-8905-fb334aa3d4ad	JIL-1781354415069-278	Ferrera, Baltazar	1980-01-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
ca65ec58-3956-4d5a-8c62-d2fb531e76b2	JIL-1781354415070-669	Mangubat, Linda	2001-09-22		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Female	Active
f30d5945-7b43-43a0-a49a-21df3fd98b43	JIL-1781354415069-258	Espiritu, Judith	1985-01-05		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	f	Female	Active
958c65fd-c4d5-4394-8d62-e9d72bb1b3ea	JIL-1781354415070-729	Mascarinas, Vivencio	1951-08-23		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Senior	Main – Pinamalayan	\N	t	Male	Active
d293bbe2-dca5-46d4-be1a-6a4b9a60d1b6	JIL-1781354415069-333	Gonzales, Remedios	1986-08-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	t	\N	Active
ac8a0995-9fc5-4bcb-a365-d3787e610bc4	JIL-1782608337875242	Montaril, Wilson	1980-01-16		WSAM	\N		\N	10	2026-06-28 00:58:59.427895+00	Men	Main – Pinamalayan	\N	t	Male	Active
86b584c5-8474-4fd8-98b9-e96bd5a44543	JIL-1781354415070-759	Mendez, Renante	1987-02-04		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:16.665642+00	Men	Main – Pinamalayan	\N	t	Male	Active
7fc99762-2fd0-47e7-ae96-eac2f69af28b	JIL-1781354415069-387	Labaguis, Bianca	1989-12-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
ac35dd23-d860-4905-ab8f-0fde81f5ce88	JIL-1781354415070-830	Morente, Gilbert Sr.	1966-05-04		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Senior	Main – Pinamalayan	\N	t	Male	Active
e855a73b-e58b-41ed-819d-b95cea314837	JIL-1781354415069-216	David, Jeffrey	1987-10-31	Sta.Rita, Pinamalayan	WSAM/LGAM	\N	Ptra. Ethel Fiedalan	e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Men	Main – Pinamalayan	\N	t	Male	Active
71c7c301-dd61-4d10-b402-aeec1c8c755f	JIL-1781354415069-443	Lanot, Princess Bell	1997-04-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
b5e26c10-d004-4806-9085-ac4278d6a155	JIL-1782608469631335	Sosa, Mario	1985-06-16		WSAM	\N		\N	10	2026-06-28 01:01:11.324174+00	Men	Main – Pinamalayan	\N	t	Male	Active
f70d6460-84d6-4dcb-83aa-eb26e1d5a478	JIL-1781354415070-921	Peñaverde, Precious Angelle	2001-03-28		WSAM	\N		8334512f-5979-4cc0-9241-6e3c552e0028	0	2026-06-13 12:40:16.665642+00	Young Adult	Buli	\N	t	Female	Active
13f86af0-4890-4f85-9b06-a95d118ea422	JIL-1781354415069-497	Lolong, Rose	2002-09-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
257d7932-c151-4929-b4db-344374438de8	JIL-1781354415070-1089	Tuerto, Ian	1976-12-17		WSAM	\N		\N	20	2026-06-13 12:40:17.307634+00	Men	Main – Pinamalayan	\N	t	\N	Active
2fc913ba-e354-4f8b-8c97-1b6c988d241e	JIL-1781354415069-554	Magcamit, Gwyneth Dorothy	2008-04-21		WSAM/LGAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Female	Active
0e220e0b-794c-4a15-bee2-23d04d8300f1	JIL-1783237999052733	Ilao, Reanne	2011-09-03		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-07-05 07:53:19.658565+00	Youth	Main – Pinamalayan	\N	t	Female	Active
42796d00-acd6-49ae-bfc9-c1402322e426	JIL-1781354415069-569	Magpantay, Susan	1988-08-21		Guest	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
9c1cafbd-02b7-4612-a953-f05b3718f1f4	JIL-1781354415069-555	Magcamit, Loida	1999-11-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
cbe8fc96-165f-4b41-ab04-ed496f567496	JIL-1781354415069-1	Abdon, Analiza	1980-12-18		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	30	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	Female	Active
7913742e-1132-4f39-90a9-9a456e53df8f	JIL-1781354415069-129	Calidguid, Shiela	1982-10-20		WSAM/LGAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	Female	Active
173629cc-3607-4df3-ac3b-7b20fb3c64db	JIL-1781354415069-125	Calangi, Dorlie	1960-03-11		WSAM	\N		\N	20	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
5c07e6b3-9180-41e0-a075-67e89ab316f6	JIL-1781354415069-359	Ilao, Emily	1961-07-26		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
bdfd68c9-fd9a-43d2-89e5-2541674350b9	JIL-1783243633604833	Baknong, Ian Ros	2007-01-08		WSAM	\N		\N	0	2026-07-05 09:27:14.327403+00	Youth	Main – Pinamalayan	\N	t	Male	Active
0e16ca9b-aa3c-47fb-ade1-0ac8b0db17dc	JIL-1781354415070-663	Mangcupang, Vilma	1989-11-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
41f08a3a-1b7f-4678-a26f-753318a6ea30	JIL-1781354415070-664	Manggubat, Anabelle	1982-08-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
8b893f20-a053-4e4a-ab93-c5f957565cd7	JIL-1781354415069-223	De Leon, Mildorena	1995-10-12		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
f2c66819-74a2-4288-8512-8935a069c4fe	JIL-1781354415070-659	Mangante, Glezybelle	2013-01-12		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Male	Active
ef52fa00-48bd-4f68-b18e-2c19862e5ef6	JIL-1781354415070-718	Mascarinas, Emerwin	1994-10-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
dfdc25f1-4496-4c0b-9914-3b05ae6d575c	JIL-1782609013710376	Sosa, Agnes	1997-02-11		WSAM	\N		4cd1ac72-0cc2-44fd-82c5-95576ad2bf75	10	2026-06-28 01:10:15.030681+00	Young Adult	Bagong Silang	\N	t	Female	Active
443daf66-0c24-42a3-8a00-12ee4538d1b8	JIL-1781354415069-572	Magturo, Princess Rosebelle	2010-08-21		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Female	Active
cfd95683-1ac3-4a89-80ad-9e48768a0c85	JIL-1781354415070-773	Mendreje, April Iris	1985-03-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
c9586dfd-1ff1-40a0-8048-1454a66478c6	JIL-178260907032648	Montaril, Adelaida	1970-06-03		WSAM	\N		\N	10	2026-06-28 01:11:12.00588+00	Women	Main – Pinamalayan	\N	t	Female	Active
d8b86085-f8ac-4315-b05b-83aa26a1cce6	JIL-1783258654057766	Rodil, Cristoffer Ivan S.	2007-10-17		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-07-05 13:37:33.60859+00	Youth	Main – Pinamalayan	\N	t	Male	Active
3330f4b8-c241-4b08-9171-abf850b5c794	JIL-1781354415070-833	Morente, Jeiel Boaz	1998-01-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
bd791fd1-39f1-43f1-bd94-5877c45f89f6	JIL-1781354415070-834	Morente, Jerald	2004-10-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
597f5873-299e-4d3c-ab38-bf98ca4bfcfb	JIL-1782609119809301	Maaño, Charity	1954-06-01		WSAM	\N		\N	10	2026-06-28 01:12:00.987492+00	Senior	Main – Pinamalayan	\N	t	Female	Active
a1f44ce3-e752-4be4-8f0e-a7c45bffcc17	JIL-178326278848818	Laderas, Antonette	1997-10-28		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-07-05 14:46:27.774108+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
8abcf0a1-2ab1-4484-833e-aacd7b4de35d	JIL-1781354415070-883	Ondoy, Leonardo	2001-08-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
1d3bc4c0-0e4f-4fdc-955b-31382fd3d120	JIL-1781354415069-104	Bolaños, Grace Anne	1990-11-06		WSAM	\N		\N	20	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
d64d1327-555b-4e79-9ff6-162f0298ae38	JIL-1783263019362131	Asuncion, Jienel	\N		WSAM	\N		f11d4448-78f2-4d19-b3dd-487735deca7a	0	2026-07-05 14:50:18.906222+00	Women	Luma	\N	t	Male	Active
faf29306-0e77-4e71-8a28-4ee213c626d0	JIL-1781354415070-938	Ramos, Irene	1981-04-24		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
5b5b76a3-a3cd-453f-a050-8194bb4fcb23	JIL-1781354415070-939	Ramos, King Michael	1983-10-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
67069c95-9dcf-4da2-8076-fdfa84564ae5	JIL-1782609241760591	Monton, Avegail	2000-06-17		WSAM/LGAM	\N		\N	10	2026-06-28 01:14:02.962312+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
355fd0db-83cd-4e20-9d44-7efe8e9ac2cd	JIL-1781354415070-831	Morente, Gilbert Jr.	1994-12-02		WSAM	\N		\N	20	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
38113d30-6468-4cf9-8f0e-71345e38d4bf	JIL-1781354415070-852	Muyco, Keziah Esther Mae	2001-05-06		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
75e612fa-571d-48d5-9f09-3bb26e9e7f13	JIL-1781354415070-994	Sadiwa, Isabelita	1981-03-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
22d7b909-c937-437a-8423-cda727b9e299	JIL-1781354415069-284	Lafuente, Jemimah F.	1991-09-12		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
9ad28751-ba60-49f9-8382-9222e0fc39bd	JIL-1781354415069-75	Banez, Thess	1983-12-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Delisted
622f192f-f17d-41fd-9027-a7a67e5661dc	JIL-1781354415070-1000	Saez, Marie Cris	1989-11-15		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
459f0d38-d252-4202-b546-a3aadbe90f7d	JIL-1781354415070-1001	Saez, Marriane Ivilyn	2002-05-02		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
c0461e9f-7877-4f78-9340-6dec1c7bb900	JIL-1781354415069-592	Mahaguay, Kriz Ann	1992-07-14		WSAM	\N		\N	20	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
b67a60d6-6dbc-4a40-8885-0e59c1725286	JIL-1781354415070-1094	Untalan, Christian	1995-11-06		Guest	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
8aec27b0-635c-4e64-9693-16a903692dd2	JIL-1781354415070-1055	Seno, James Aaron	1992-06-19		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
5f7dad6a-e648-4010-83cb-e01c3b2aa8bb	JIL-1782609563488612	Flavier, Shiryl	2000-06-03		WSAM	\N		\N	10	2026-06-28 01:19:24.651852+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
15921afd-d317-49e6-9a5e-f2f09c678e07	JIL-1781354415070-1112	Villaruel, Althea Jane	1988-10-28		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
6cc99274-cb42-4a67-88f3-20137c5f701d	JIL-1781354415070-1113	Villaruel, Corazon	1991-12-07		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
6ce06260-e304-430b-b53b-2e76ed6b5a12	JIL-1781354415070-1114	Villaruel, Kathleen Altea	1998-07-03		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
92600e71-3048-4b48-94e0-088e04477557	JIL-1781354415070-1115	Villaruel, Nicole	2004-01-25		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
69146716-cc6d-456c-b8fa-91c99adbad75	JIL-1782609596052440	Flavier, Ralph Vincent	2000-06-11		WSAM	\N		\N	10	2026-06-28 01:19:57.134573+00	Young Adult	Main – Pinamalayan	\N	t	Male	Active
ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	JIL-1781354415069-3	Abdon, Prince Kerel Zebedee	2005-10-26	Zone ll, Pinamalayan	WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	250	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	Male	Active
e7902f31-5450-4483-8a1f-be8ff7b2a30c	JIL-1781354415069-7	Aborquez, Jemmichah	1994-08-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t		Active
79542bc2-be15-4f02-8096-65f058b2c148	JIL-1782009014140160	Selda, Edward	1992-04-19		First Timer	\N		\N	0	2026-06-21 02:30:13.821341+00	Men	Main – Pinamalayan	\N	t	\N	Active
4942304c-0292-435c-bd3d-6801d67e4011	JIL-1781354415069-8	Aborquez, Sandara	1992-11-12		WSAM	\N		8334512f-5979-4cc0-9241-6e3c552e0028	0	2026-06-13 12:40:15.893971+00	Youth	Buli	\N	t		Active
058aad98-d776-4aba-8e53-e8a531688e9a	JIL-1781354415069-9	Aborquez, Jimalen	1999-09-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	t	\N	Active
30fde74a-37cc-47ce-ad46-ebf9cee8091a	JIL-1781354415069-10	Aborquez, Michael	1990-01-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Buli	\N	t	\N	Active
170d20bd-20cf-4188-8046-0bc788d5c1c7	JIL-1781354415069-11	Aborquez, Michael Jhon	1992-04-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
27560fd1-583d-4421-9126-be799392b963	JIL-1781354415069-12	Acapulco, Blesselyn	1987-04-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
32a6a0cc-0a54-4409-9cc0-f014e21034d0	JIL-1781354415069-31	Afonte, Travis	2005-12-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
62a498a0-63a3-453e-aa21-a8c0220b4db3	JIL-1781354415069-32	Agbas, Kathleen	1999-12-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
67d36330-ea32-4458-a5ac-d057cb53ae95	JIL-1781354415069-33	Albaniel, Hannah Loraine	1982-02-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
ad6442a1-97a3-4973-a295-5739f99d4007	JIL-1781354415069-34	Albaniel, Leny	2001-01-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	t	\N	Active
e8442239-4828-460a-8621-dc2ba99a9ee2	JIL-1781354415069-36	Alvarez, Donna	1980-12-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
1fc9fb3b-4baa-4c86-847c-b3e99fefafd2	JIL-1781354415069-37	Amoguis, Roselinda	1986-05-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
87a043af-aa57-44b6-8c56-4d62af89d30b	JIL-1781354415069-39	Andaya, Glaiza Joyce	1994-06-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
9c56e517-8a6f-4100-9cf1-c365b2f25251	JIL-1781354415069-40	Andaya, Jocelyn	2002-05-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
456818aa-efa3-4b0f-bdfb-504155d87e62	JIL-1781354415069-41	Aniceto, Madel	1998-09-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
e00792cd-db31-46ad-9b31-4b94156a8c4e	JIL-1781354415069-42	Apolinar, Anafe	1980-01-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
5c53a79f-bcd5-4652-8c84-8a0f1db53f65	JIL-1781354415069-43	Apolinar, Angelo	1986-03-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
67bdc363-0a26-4721-925f-9be683335ddc	JIL-1781354415069-44	Apolinar, Beejay	1985-07-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
44547db8-65c4-49f9-9f38-ae2c8970b5be	JIL-1781354415069-45	Apolinar, Jerry	1990-08-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
f4b3379f-4d24-4ef8-adc2-8827f3c6938e	JIL-1781354415069-46	Apolinar, John Anthony	1998-02-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
af39bda3-1ee7-474a-a0b3-714fbd0519c3	JIL-1781354415069-47	Apolinar, Joshua	1992-04-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
e68fcaec-0e96-48d8-9afb-e178c7726585	JIL-1781354415069-49	Arazula, Angel	1987-12-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
411337f7-831c-4138-abf2-65f8acd1f78f	JIL-1781354415069-50	Arcipe, Arlen Marie	2000-09-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
03d772f2-2cd1-4380-92aa-a630813603d0	JIL-1781354415069-52	Arpia, Joan	1994-02-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
0e815bd0-3ccc-4969-b9b1-c071501beb75	JIL-1781354415069-53	Arriola, Jandee	2003-12-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
96be3068-cb14-4e43-9dee-3ecefe00a388	JIL-1781354415069-54	Arriola, Nestor	2001-08-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
154e5a5e-f74e-4326-a6c7-3c14936842e7	JIL-1781354415069-20	Adoyo, Jerand	1980-02-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
d9526726-1b9a-43ef-9186-811832e29197	JIL-1781354415069-5	Abel, Princess Collyn	1998-03-28		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
803aa85a-5bcd-4aa0-802c-e59bfd4a6c41	JIL-1781354415069-19	Adoyo, Jenilyn	1984-01-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
1e3f5d9d-212c-40f2-9d46-a61a3434f57f	JIL-1781354415069-17	Adoyo, Bianca	2004-07-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
eb4ddded-37d1-4d11-a6f7-2d9c3e1e3014	JIL-1781354415069-16	Adoyo, Angelita	1976-03-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
fc69a073-d6e9-41d7-986c-4d45447a4eba	JIL-1781354415069-18	Adoyo, Cesar	1984-11-21		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	50	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	f	\N	Active
7121ac1f-d665-4be7-8170-871db8d2d96f	JIL-1781354415069-25	Adoyo, Shad	1998-07-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
4eb41ffc-4ca2-49e7-9dc5-ea942c1e80f7	JIL-1781354415069-24	Adoyo, Rochelle	1992-01-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
3a4c22fa-21f4-451d-955b-75e0b5762742	JIL-1781354415069-13	Adonay, Eljay	1985-12-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
9a90503d-2cfd-4dfd-bb93-b49ac5a3b020	JIL-1781354415069-29	Adriano, Erica	2005-04-29		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
9d054b8e-33f0-407a-9f20-f7cac9978b9c	JIL-1781354415069-27	Adriano, Edmar	1996-02-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	f	\N	Active
8ce3d2cf-f26d-4591-bcb7-16dd30c2780b	JIL-1781354415069-28	Adriano, Elizabeth	1987-09-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
f6df0b9f-00b0-45d2-8f96-d89cb67e1fbf	JIL-1781354415069-35	Almo, Jhon Carlo	2004-12-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
025f7cca-a222-4648-8a68-03d3038e30ab	JIL-1781354415069-38	Amuguis, Mary Rose	2001-08-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
652c5334-eecd-4cd5-ab26-ddde370063fa	JIL-1781354415069-48	Aragon, Lance	1981-09-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
c1339944-72f6-4b7b-ade9-8f518408fb94	JIL-1781354415069-51	Arellano, Jeffrey	2002-04-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
952ddc83-8eee-420c-96b3-75f5b9de1311	JIL-1781354415069-55	Aseron, Grace	1940-04-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
a38fcd37-b028-447a-bff8-da42fcbd31bd	JIL-1781354415069-58	Aurea, John Lenard	1993-07-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
9abedce3-4535-4b54-8c18-4a8773adb2a5	JIL-1781354415069-59	Awa, Janriegn	2000-11-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
8c582ed2-5368-41db-ad41-b171dd259ac1	JIL-1781354415069-60	Awa, John Paulo	1983-07-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
23a76259-1a90-4fd1-945c-d7b354a4ecd7	JIL-1781354415069-61	Awa, Remelyn	1987-01-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
9ba2908d-261e-427e-b571-ac478c5ceb7d	JIL-1781354415069-62	Azucena, Emrei	1999-01-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
a279e1e0-be6f-404f-a5e7-a6291bea7ef0	JIL-1781354415069-63	Azucena, MJ	1995-03-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
a3965137-7489-4483-94b0-db9094b4496a	JIL-1781354415069-64	Azucena, Rhea	2004-07-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
d6772a58-17c2-4d85-aefb-48a53c99ce87	JIL-1781354415069-67	Bagui, Rose	1987-11-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
9fba1fee-4e56-4bb3-a0f2-bbb71a21aeca	JIL-1781354415069-68	Bagui, Tristan Jay	1984-03-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
c7aac336-7263-436a-b37b-7814db6835a6	JIL-1781354415069-69	Bajande, Coreen Joy	1992-01-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
0989c505-7d7a-480d-9a26-56abcd873fa2	JIL-1781354415069-72	Ballesteros, Julie Mae	1986-10-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
aa1eb49d-c0ae-4f54-b48d-c6e30f39638c	JIL-1781354415069-81	Baruel, Joel	1980-05-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
faf18878-7d57-479f-b06b-1efb07af6841	JIL-1781354415069-82	Baruel, Lina	2005-09-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
bfe5d75b-2206-4f90-a9fa-5483bc203715	JIL-1781354415069-85	Batingas, Princess Joy	1980-07-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
dd694bbb-e505-4258-8fae-aa1a49b101ee	JIL-1781354415069-86	Bautista, Aida	1982-09-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
7fae6d7c-3eff-4b09-bbc0-0635812ab5f2	JIL-1781354415069-87	Bautista, Aira	1988-09-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
95edf989-4165-464e-85f6-d9573d30719c	JIL-1781354415069-88	Bautista, Marenel	2001-07-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
b1cb5a63-30ea-4d94-b9fe-46d38d78d708	JIL-1781354415069-89	Belegano, Jhon Paul	1984-07-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
558b94c5-3219-4302-b897-f85b3bf5a8f2	JIL-1781354415069-26	Adriano, Edgar	1987-06-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Luma	\N	f	Male	Active
d92cd0b6-fc32-4c68-8d04-6ba88b242e38	JIL-1781354415069-14	Adonay, Emily	2004-08-17		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	Female	Active
1cf7e4fe-d4be-4d96-bc9a-96da56038a87	JIL-1781354415069-30	Adriano, Marlyn	1991-08-24		WSAM	\N		f11d4448-78f2-4d19-b3dd-487735deca7a	0	2026-06-13 12:40:15.893971+00	Young Adult	Luma	\N	f	Female	Active
466481c7-b1dd-405b-9fb6-2772cc535b0c	JIL-1781354415069-21	Adoyo, Ma. Amor	2002-08-09		WSAM	\N		4cd1ac72-0cc2-44fd-82c5-95576ad2bf75	0	2026-06-13 12:40:15.893971+00	Youth	Bagong Silang	\N	t	Female	Active
446aeab5-41d4-4dfb-add3-b685336c3d43	JIL-1781354415069-23	Adoyo, Niel Bert	1985-04-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Delisted
9e074161-dc94-4867-bf9d-9d850433bd1d	JIL-1781354415069-22	Adoyo, Neil Andrei	1998-06-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Delisted
28dcbb7f-499e-4118-8a2b-daeb99f70e48	JIL-1781354415069-73	Banez, Janah	1999-06-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Delisted
6d43dc1d-e3fe-4a48-b619-3e3ec05e52e5	JIL-1781354415069-74	Banez, Limuel	2000-01-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Delisted
8ce49fed-2f88-4740-80c8-d43f6fef4122	JIL-1781354415069-90	Belegano, Winelyn	1995-01-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
25d38aec-a6e9-4bac-8ae1-538fbb9f867d	JIL-1781354415069-96	Bernadit, Johnny	1995-11-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Luma	\N	t	\N	Active
ee98e3f8-cdd1-4786-9c85-9fb6484b0333	JIL-1781354415069-98	Bernadit, Princess Hadassa	2001-09-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
3fefbc81-cbeb-4027-971e-9e9ae28ff29a	JIL-1781354415069-99	Bernardo, Gerald	1984-01-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
ee69d589-7872-4e16-8f33-d43c6047d5da	JIL-1781354415069-100	Beron, Jasper	1999-06-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
50aeb3c2-bc6c-4454-8e55-43bf821ee7a3	JIL-1781354415069-101	Bihag, Ashley Nicole	1986-02-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
4c344f12-96f0-433a-8c49-4068fa8da85a	JIL-1781354415069-102	Bihag, John Karl	1983-07-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
c478f3e9-4041-4042-8baa-f15ad69deab2	JIL-1781354415069-103	Bihag, Kim Apple	2004-08-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
72dd4bf4-1615-4b83-a90c-0641ad7a1a68	JIL-1781354415069-106	Bonifacio, Elena	1987-01-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
911f3835-37ef-4efd-87e9-be3cad2bf1ad	JIL-1781354415069-107	Bonifacio, Jamaika	1991-02-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
369877e3-52ed-472d-bd20-d339ff4c2c35	JIL-1781354415069-108	Bonifacio, Jhon Cedrick	1985-10-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
6b33c947-7fb0-4c3c-9b26-b3be68c9f788	JIL-1781354415069-109	Bonifacio, John Denver	1994-10-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
a4012106-e8ad-49df-9ffb-0bd9773c92e2	JIL-1781354415069-110	Bonifacio, John Francis	1985-02-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
872ae02d-b472-496d-9b9b-fb0c5b584802	JIL-1781354415069-66	Bacay, Loveliness	1981-05-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
154edee8-ab39-4868-a441-abb2eabb6cdc	JIL-1781354415069-70	Bajeta, Marites	1998-01-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
60f7248c-e234-4d20-ba54-9ba5324f7edd	JIL-1781354415069-76	Barrameda, Liza	1975-02-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
61aacebf-0632-484a-973d-6ca60db76b8b	JIL-1781354415069-71	Bajeta, Melody	2004-03-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
0cf0133a-773d-4692-8857-188e348523bd	JIL-1781354415069-77	Barrameda, Lloyd	2004-02-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
6cfb7303-9533-4b69-8856-84506aafe1a0	JIL-1781354415069-78	Barrameda, Noel	1984-11-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	f	\N	Active
267d3efc-2ae8-4765-a910-51bf656880c3	JIL-1781354415069-79	Barrameda, Sheena	2004-12-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
14cafbad-77c1-43a6-b0be-70dc42ee0eb8	JIL-1781354415069-80	Barrientos, Junar	1994-12-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
5df42c54-96d4-4089-951e-58db88b6af65	JIL-1781354415069-113	Bonifacio, Jr	1989-06-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
3143e77f-6364-4b55-af22-aeeea0e8a1e3	JIL-1781354415069-114	Bonifacio, Maritess	2005-05-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
29a2213b-f2c2-47de-8fd1-e38eaef13f17	JIL-1781354415069-115	Bonifacio, Niel John	1983-01-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
17c10293-1c4c-404e-bab6-c9625311288b	JIL-1781354415069-116	Bonifacio, Rommel	1999-01-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
28432905-2587-4da0-8f8f-42032c8e968c	JIL-1781354415069-117	Bonifacio, Walter	2005-12-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
abe801f4-1619-48b1-b197-9ab1d06f0738	JIL-1781354415069-120	Bragado, Sofia	1982-09-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
c1b13c38-b646-4e6f-9c93-068f3cd3550d	JIL-1781354415069-123	Budot, Sherilyn	1989-07-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
70bf23f3-16ad-4cf1-a087-dee603b0c8f2	JIL-1781354415069-124	Calais, Jeline	1990-07-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
8ad1d5dd-93c8-414b-8f7a-a6cf7ef0b5e3	JIL-1781354415069-136	Camacho, Diane	2000-08-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
568dfb3e-730f-4f4a-afe6-1ea916141c43	JIL-1781354415069-140	Camansag, Angel Mae	1986-11-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
a0bc5f84-c073-4ac1-a20e-b356f0cbaa04	JIL-1781354415069-141	Camansag, Harvey	1986-04-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
04d5ea45-5a38-4d5f-bab5-c6bf98e1c742	JIL-1781354415069-143	Camansag, Mary Grace	1986-09-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
4d6b7a94-f33b-4457-9146-b39eb88b4193	JIL-1781354415069-144	Candelaria, Edward	1998-06-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	\N	Active
5f8502e3-c058-46e4-9c1b-e2a7ce7bfaf1	JIL-1781354415069-145	Candelaria, Janeth	1989-09-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
e166a25b-4362-493d-8edd-3c76ae0f54f9	JIL-1781354415069-146	Candelaria, John EJ	2002-07-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
ba21af54-96aa-429e-a71a-830faee80437	JIL-1781354415069-147	Candelaria, Keziah	1986-03-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
fb91813b-3146-45b4-a967-efd7d04368f7	JIL-1781354415069-148	Cansino, Romell	1983-03-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
0313a41c-7c1f-4ec5-813b-c2441d901fde	JIL-1781354415069-149	Cansino, Susan	1980-03-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
e64018a2-ff34-4df6-81bc-60234fa3018b	JIL-1781354415069-150	Cansino, Zorren	1984-08-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
26cbe901-449d-44a8-91dc-89223071176a	JIL-1781354415069-152	Caringal, Carmen	1991-09-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
c24a7146-10b6-40ee-b5d4-e4bbf2ba6e7a	JIL-1781354415069-153	Caringal, Daniel	1994-02-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
3002ce72-5da9-407a-95d6-98b9c1d86a4b	JIL-1781354415069-162	Castor, Jaspher	1997-07-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
a56d1be1-65ce-4d13-99dc-4a3511ee4407	JIL-1781354415069-163	Castor, May	1985-04-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
59ed1779-f851-44df-9716-8826f86e7008	JIL-1781354415069-164	Catando, Myrna	2000-04-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
c49bb219-af69-46b5-b7ac-51b1a2c84fe8	JIL-1781354415069-165	Catando, Ryan	1994-01-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
31750972-21d4-4d47-a497-81a0f82fabb2	JIL-1781354415069-121	Brucal, Jenny	1978-11-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
6cc8e30b-beaf-47c7-b6b6-dad17d5ff745	JIL-1781354415069-122	Brucal, Jham Paul	2007-03-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
29f8dee5-33dc-45a1-835f-827c01e936f4	JIL-1781354415069-91	Bernadit, Adam Jay	1993-04-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Young Adult	Luma	\N	t	Male	Active
ce8203b0-9b65-45a2-accc-3b98b57d439e	JIL-1781354415069-92	Bernadit, Corazon	1996-04-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Young Adult	Luma	\N	t	Female	Active
92294503-c4b3-4871-bee7-bbc92f8c5dc3	JIL-1781354415069-93	Bernadit, Ezekiel James	2009-07-09		WSAM	\N		f11d4448-78f2-4d19-b3dd-487735deca7a	0	2026-06-13 12:40:15.893971+00	Youth	Luma	\N	t		Active
e5b22d55-9380-43aa-8476-25e4c65fed7d	JIL-1781354415069-97	Bernadit, Mary Jay	1989-07-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Luma	\N	t	Female	Active
12589065-2014-4ff8-b222-a31bdc364bcb	JIL-1781354415069-94	Bernadit, Jason	1999-03-12		WSAM	\N		f11d4448-78f2-4d19-b3dd-487735deca7a	0	2026-06-13 12:40:15.893971+00	Young Adult	Luma	\N	t		Active
a68dd28d-eb11-4fa7-a1a2-469dacb1e88c	JIL-1781354415069-95	Bernadit, Jezreel	1989-03-23		WSAM	\N		f11d4448-78f2-4d19-b3dd-487735deca7a	0	2026-06-13 12:40:15.893971+00	Young Adult	Luma	\N	t	Male	Active
2b4402e5-72b0-4396-9556-fe0362179bb5	JIL-1781354415069-151	Cantre, Princess	1984-07-19		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
a651b2a0-d8a4-4369-8825-dd0ebee15871	JIL-1781354415069-126	Calidguid, Christia Faith	2006-12-29		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
474d2682-60e1-40d4-97b5-cfcf41682877	JIL-1781354415069-130	Calopas, Liezel Mae	1992-12-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
26fd6e9f-352a-49c4-a7fa-c7c619fdbe8b	JIL-1781354415069-131	Calzada, Jericho	2003-12-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
1ac1bf68-47d1-4fd2-8e72-c4bef1f7c6e7	JIL-1781354415069-132	Calzada, Mercy	2001-06-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
16eaf18a-e99c-4530-aaec-8a6e96b99cdb	JIL-1781354415069-134	Camacho, Danreb	2003-02-24		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
32f49f26-b956-4087-9659-b3ece5075548	JIL-1781354415069-155	Carpio, Nancy	1961-06-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
eaa7ce80-988e-485b-9f31-f13c3daa42c9	JIL-1781354415069-135	Camacho, Denmark	1996-03-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
ee04f52c-3d94-464c-a491-07e870e657fe	JIL-1781354415069-137	Camacho, Domineck	1999-02-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
48a80a3f-1a4f-4260-839e-25008b15a463	JIL-1781354415069-154	Caringal, Jethro Carl Daniel	2012-07-29		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
2041befa-4322-49d4-afd7-ff92c7a60411	JIL-1781354415069-157	Carpio, Paul John	1995-09-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
9bd9b792-4c8f-4e59-9395-9bd8ae3eb634	JIL-1781354415069-158	Castillo, Adrienne	1994-09-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
e33e8a0e-0c35-4df9-b7a2-62d4514ec8f6	JIL-1781354415069-160	Castillo, Jo	2002-11-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
7fd04be2-f9af-488b-abcf-d060e43363ea	JIL-1781354415069-161	Castillo, Zeny	1969-12-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
c76624fa-e1d6-4a39-b0a0-c259d2d97c21	JIL-1781354415069-159	Castillo, Annzhen	1981-07-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
493343e9-2cca-4215-9bb3-021c5dd2b6fa	JIL-1781354415069-173	Chavez, Lerma	1995-06-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
1c30c334-17e2-4e56-9fe3-0f49edece1fa	JIL-1781354415069-174	Clanza, Jeffrey	1991-06-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
02c1e3d3-e8e6-47c9-b0d0-9b54821906eb	JIL-1781354415069-175	Clanza, Marilyn	1991-04-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
979aea8b-5141-438f-9b15-701de4cd61be	JIL-1781354415069-176	Colonel, Lucia	1990-04-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
7889b310-7679-40e3-8316-9beced791fe4	JIL-1781354415069-177	Comia, Christine	1985-05-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5bd2b7c3-bbd4-4adf-9cff-564351164434	JIL-1781354415069-178	Comia, Jobel	1984-10-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
b7eef06f-29b4-441c-86a7-2e8cfb4b04f1	JIL-1781354415069-179	Comia, Mark Joseph	1981-01-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
1d1802f8-0457-4f56-855c-6e0a6a7f942c	JIL-1781354415069-183	Coronel, Arlene	1980-10-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
0f1cbbc0-5ef6-4fd5-84ca-e611c47d335d	JIL-1781354415069-184	Coronel, Lea	1986-06-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
b0f9edab-281e-459e-a5e4-093508dd50d6	JIL-1781354415069-185	Cotino, Chasty Gwen	1991-03-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
49cf9d2e-e7c4-43e0-9160-b8a10c560c10	JIL-1781354415069-186	Cotino, John Andrei	2005-10-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
4b3486d9-f1c3-4ee6-99a9-0ca20558ad00	JIL-1781354415069-187	Cotino, King Raynan	1998-02-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
7cffb71f-b1b3-4443-9b50-cc66393ada9b	JIL-1781354415069-188	Cotino, Lenie	1988-09-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
322ae04f-a499-4234-b414-1942c54180dc	JIL-1781354415069-189	Cotino, Mark Lawrence	1995-09-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
7f1bb6cf-90ce-4d1e-b3a3-a212813b5fe8	JIL-1781354415069-190	Cotino, Rhea Manel	1985-09-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
9c728b95-5adc-484f-98de-0bad7b2869dc	JIL-1781354415069-191	Crisanto, Lolong	1999-05-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	\N	Active
237229d6-3808-4a4b-8f75-0846e98b3ebe	JIL-1781354415069-195	Cupiado, Deniese	1985-03-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
e1b347e2-1a08-4638-893d-aaf1fd257996	JIL-1781354415069-196	Cupiado, Melba	1995-11-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
c3c8cc39-5f28-4f19-a577-7a2d4fd8de06	JIL-1781354415069-197	Curtan,  Remelyn	1988-10-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
f0fb5878-8f11-4c9c-9a58-1541b73aa7ab	JIL-1781354415069-198	Curtan, Alex	1995-07-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	\N	Active
e826e5f7-176d-41ec-9abf-43ca6724f7e9	JIL-1781354415069-199	Curtan, Alexa	1990-01-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
a2635c47-b426-4aaf-aed3-5cebf551c774	JIL-1781354415069-200	Curtan, Alexander	1980-05-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
817c5572-9661-4669-9abf-461e1bb6cbff	JIL-1781354415069-201	Curtan, Babylyn	2000-10-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
118edbdf-1e0a-428d-9b4d-829fd78bb95b	JIL-1781354415069-202	Curtan, Babylyn	1981-01-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
1c079b48-670d-4e63-b3b1-fed4d528b3ef	JIL-1781354415069-203	Curtan, Benjie	1989-04-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	\N	Active
22d4bbe8-a3e5-461c-bcc4-03121333f9ac	JIL-1781354415069-204	Curtan, Erich	1997-06-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
df9809d8-f3b5-4111-90e8-92882ee8de8c	JIL-1781354415069-205	Curtan, Jesalyn	1991-08-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
b3313ca9-08ba-40f4-b3db-488428c004dd	JIL-1781354415069-206	Curtan, Ofelia	1987-09-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
411b4e9e-32c2-4b6d-a01c-b8686d755213	JIL-1781354415069-207	Cusi, Madel Micharla	1982-09-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
631547a0-4397-41b2-a891-d99b9f4154fd	JIL-1781354415069-208	Cuzi, Madela	1990-11-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
1b2672ba-5090-45a6-b498-10f50398be65	JIL-1781354415069-209	Cuzi, Michael	1981-07-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
96367646-1332-4c87-8777-ede980f9ae5b	JIL-1781354415069-210	Dael, Joshua	1987-01-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
2dde772d-8c0d-4969-9917-34381fc0a182	JIL-1781354415069-211	Dael, Mayanil	1987-06-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
fb4f09d7-864a-402c-80f5-e86d6e4757d7	JIL-1781354415069-212	Dael, Teresa	1987-06-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
9b26626a-1c85-4ff5-83dc-436f930e890e	JIL-1781354415069-213	Dael, Teresita	1992-09-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
faf36432-6bb3-41fb-b374-5fc8f10c3816	JIL-1781354415069-217	Davis, Mylene	1993-06-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Luma	\N	t	\N	Active
1d2182b1-7c85-4f8b-8ac6-3e48450bff28	JIL-1781354415069-218	de Chavez, Gemeliano	1988-09-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	\N	Active
b886558b-08a6-4262-bc9a-89c9f89bdb87	JIL-1781354415069-219	De Chavez, Jelyn	1993-09-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
439339c9-f562-4728-83d2-72b725f2feda	JIL-1781354415069-221	De Chavez, Jonalyn	2002-11-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
6ef7bee6-7cba-46a7-ad34-cce842e3eeff	JIL-1781354415069-133	Camacho, Daniel Paul M.	2007-03-12		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	Male	Active
c811755e-4a14-4cfa-9de6-ef632e0df8df	JIL-1781354415069-172	Cay, Kyla Cristina	1986-10-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
e4c234f1-18c3-46fb-86f3-4e4c1528b82d	JIL-1781354415069-171	Cay, Japee	2001-01-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
9f249c51-26cd-4317-b773-3e21c3c4dcdf	JIL-1781354415069-169	Cay, Aaron Jay	1992-07-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
b4c128f0-2908-4aba-a807-45206c6bdfdb	JIL-1781354415069-170	Cay, Arvin	2001-11-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	f	\N	Active
ac40e33a-a9cc-4d04-9380-84b396b91354	JIL-1781354415069-180	Constantino, Sherly	1968-10-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
108a7e75-0dce-4d88-a6da-b4992f378e68	JIL-1781354415069-182	Constantino, Winiefredo	1961-03-29		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
6d5e27e8-57d2-499b-80c0-93296e9c9381	JIL-1781354415069-181	Constantino, Windhel	2002-01-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
45b7ab10-bc60-4aa2-9ee4-ba15a79e391c	JIL-1781354415069-194	Cueto, Ruth Ann	1999-04-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
bdf321f7-af58-4778-9303-1f5adcd9b063	JIL-1781354415069-192	Cueto, Nimfa	2002-07-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
ca6f0796-32bb-4a42-bc86-dcd05b089bd2	JIL-1781354415069-193	Cueto, Ruth Ann	2000-07-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	f	\N	Active
97ad20d8-98b2-48f2-87f4-81935c30a1fc	JIL-1781354415069-224	De mesa, Angilyn	1999-08-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
1f2c3032-b53c-4989-a9eb-7b64bbfd314c	JIL-1781354415069-225	De Mesa, Daryl	1985-06-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
c758a054-067e-4108-a430-55b2d6e50a05	JIL-1781354415069-226	de Mesa, Lanie	1994-03-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
16b111dd-a580-494c-9fea-4177f0e668fe	JIL-1781354415069-227	De Mesa, Lara	1981-04-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
9f19f13e-a4b6-4797-a07f-703d85ecedb6	JIL-1781354415069-228	De Mesa, Monica	2001-12-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
d996dc9f-56f0-4baa-bea0-090098adfee4	JIL-1781354415069-229	De Mesa, Zaira	1983-06-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
ea17223e-2cf0-4b98-8e7c-d6db279adbba	JIL-1781354415069-233	Delmo, Patricia	1998-09-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
59ab0284-37bf-4a14-a306-a3fe52b330a4	JIL-1781354415069-235	Delos Reyes, Fe	2005-11-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
8f0acad4-e5eb-4860-8b2e-ad84c3319b16	JIL-1781354415069-237	Delos Santos, Marianne	2000-08-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
20566418-2514-4b78-95c4-9b43658ee3d1	JIL-1781354415069-239	Ditaunon, Elinita	2000-09-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
a410808c-4d95-403d-a997-9a4e77e007ef	JIL-1781354415069-241	Dujon, Jaira	1988-05-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
147c757c-0c44-45d0-a773-3411b9c2b815	JIL-1781354415069-242	Dumaran, James Patrick	1992-01-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
f6aa3a93-3785-4da1-befb-5969f0b91545	JIL-1781354415069-243	Dumaran, Justine	1999-11-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
63b23dc6-f592-4ebd-bbb1-0c90de9e3082	JIL-1781354415069-244	Dy, Emma	1992-01-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
79130b36-97a6-4bbf-b95e-2c84d2207fb5	JIL-1781354415069-245	Eljera, Nemida	1996-03-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
e9c2488a-2b8e-417f-a802-eec85af2d1ea	JIL-1781354415069-246	Endiape, Lalaine	1987-03-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
77d7ab10-259c-45c2-ac74-e61e09139883	JIL-1781354415069-247	Endiape, Vic	1990-12-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
c9cf0b9a-c036-4b63-8364-507dd06d255a	JIL-1781354415069-248	Endriola, Precious Athena	1997-10-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5af328ed-ed2f-40f2-8c87-e45c7ee9470c	JIL-1781354415069-249	Endriola, Princess Althea	1996-06-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
9e135221-2750-49e2-aabd-009bd5e9b7f6	JIL-1781354415069-250	Enriques, Daisy Joy	1985-04-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
4ab899da-4185-414e-804d-542e56bbb2cf	JIL-1781354415069-251	Enriquez, Mark Vincent	1987-12-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
e17354a9-6eaf-4e7c-8766-06d23899cfd4	JIL-1781354415069-254	Escartin, Irene	1993-06-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
55bdc7ff-e14f-495d-8269-88d8c5c5d563	JIL-1781354415069-259	Estuaria, Ella Mae	2001-10-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
38891412-9730-40be-a9e1-21c188e69281	JIL-1781354415069-260	Estuaria, Maribel	1987-05-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
48a79179-b4df-4c16-a8a2-fa6ba45936cd	JIL-1781354415069-261	Fabillon, Myra	2002-02-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
2dfc740a-06f2-4c47-ba23-7184802a9c65	JIL-1781354415069-262	Fabregas, Jarvey Jay	1989-02-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
a5adea4a-a9ea-4f77-af81-54d3d56bb474	JIL-1781354415069-263	Fabregas, Marilyn	1990-11-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
edb9fcbf-73d6-43f8-8c66-2e5b985c2c49	JIL-1781354415069-264	Faigamne, Clark Handrie	1987-03-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
70a81b56-41ad-44a0-b294-821323f11bed	JIL-1781354415069-265	Faigmane, Aida	1994-10-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
e483be5e-55b6-4991-869a-f89554d59a8f	JIL-1781354415069-266	Faigmane, Charles Reiven	2000-01-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
8c1116b8-5701-42c2-970f-7f4622d4b32d	JIL-1781354415069-267	Faigmane, Liezel Valenton	1992-04-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
b028b21f-3604-4ad3-a7c3-4b1de4bf91fc	JIL-1781354415069-268	Falculan, Monica	1983-02-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
97aff578-4501-4ddd-8b89-169457bfb43a	JIL-1781354415069-271	Fanoga, Mark	1988-04-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
7f8f5ed4-68d2-460c-8ffc-de4eff4fecc6	JIL-1781354415069-232	Del Prado, Merlinda	1962-07-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
7c248c09-a856-490d-9bb2-0b67258c7fcd	JIL-1781354415069-230	Del Prado, Bernito	1995-11-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	f	\N	Active
7f7d07b9-0f3b-4fdf-89ed-c6f236500468	JIL-1781354415069-234	Delorzo, Edralyn	2004-02-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
2a9e5964-f1f8-415f-bc2a-5291262ab442	JIL-1781354415069-236	Delos Santos, Carlo	2003-05-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
f118de46-c09a-4c6b-8613-db2e467c6f0e	JIL-1781354415069-238	Dimaculangan, Jonelyn	1997-01-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
cad3806d-6678-459b-8a26-21013b6b991d	JIL-1781354415069-253	Entrina, Merlita	1999-10-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
03e02e2e-198a-4d63-8078-b07623487502	JIL-1781354415069-252	Entrina, Laurence	2005-03-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
587d1563-e974-4da8-8767-e8d351fa1912	JIL-1781354415069-257	Espiritu, John Lloyd	2004-03-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
97c7e342-8bc5-44d2-a93d-ee02697f3e0b	JIL-1781354415069-255	Espiritu, Aizer	1982-05-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
572e8337-e964-4005-bd90-2544ae7e55f6	JIL-1781354415069-240	Dujon, Ben	1986-07-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Delisted
566c3572-7f46-403c-900f-c8ee777efc37	JIL-1781354415069-214	David, Ana Florence	1984-10-04		WSAM/LGAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	Female	Active
80c5224d-3cf8-439f-bfba-12eca2943b9c	JIL-1781354415069-270	Faminial, Maria France Princes	2003-10-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
3abcb192-61f5-4f5b-a089-e1fb1848b79a	JIL-1781354415069-276	Fegalan, Dexner	1983-03-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
42536f85-9280-42f7-86c6-6c7218b070b3	JIL-1781354415069-275	Fegalan, Aljune Fegalan	1995-09-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
62f57138-6c31-4078-8294-a20f7299695f	JIL-1781354415069-273	Fegal, Gerry	2004-10-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	f	\N	Active
f5a250db-3930-4fa7-82ea-b2d47c1035c5	JIL-1781354415069-272	Fegal, Emily	2001-11-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
d715cd09-5d06-442d-bd17-ff0c47ee9071	JIL-1781354415069-274	Fegal, Ghiezyl	2005-07-26		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
6793ed9b-fb4f-4fcb-90f9-b6de4eb59270	JIL-1781354415069-279	Ferriol, Fe	1985-05-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
37f275b0-3e06-4a0d-b5bc-935c5a434d5e	JIL-1781354415069-280	Ferriol, Isabel	1996-11-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
39707cd0-999d-4cfc-b221-767af347ec33	JIL-1781354415069-281	Ferriol, Joseph	1996-11-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
a331d2bd-0dac-4ec3-a7f1-55922631bf9f	JIL-1781354415069-282	Ferriol, Justine Faith	2001-09-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
35785c9b-cb68-458c-a1c6-4f58d9add7e8	JIL-1781354415069-285	Fiedalan, Mark	1988-07-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
0528753a-8246-4eed-8bbf-3531903487fc	JIL-1781354415069-286	Flavier, Elizabeth	1980-06-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
f48abed9-2763-4145-8111-8d86af10d12c	JIL-1781354415069-287	Flavier, Juliane	1997-02-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
00e1d93d-2a7e-4c80-a73b-af0dad6f02e6	JIL-1781354415069-288	Flavier, Ralph Jayson	2003-02-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
ab6787f5-627d-4631-a43f-eeb4f622a73d	JIL-1781354415069-289	Flores, Gilbert	1985-12-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	\N	Active
4af184c5-7187-4b11-9dd2-9d223ac525ad	JIL-1781354415069-290	Flores, Keithlyn	1988-09-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
460aad79-67ae-4fb8-896c-23f13c62216e	JIL-1781354415069-291	Flores, Mary Grace	2002-01-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
ba87c46f-bfe7-4416-9ef9-35ed80d24a35	JIL-1781354415069-292	Formalejo, Edlyn	2000-08-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
cf0edcde-e2c7-4270-ac33-a94a5434a3d8	JIL-1781354415069-293	Frias, Antonio	2005-06-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
2f3afbca-f3eb-4ba0-9866-22e85829840a	JIL-1781354415069-294	Frias, Elsa	2001-02-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
7dda6a5c-0b53-43ca-937d-646a84925821	JIL-1781354415069-296	Gaac, Sheryl	1983-03-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
86157883-d860-4758-a18b-6d40298ee1d1	JIL-1781354415069-297	Gabayno, Chelzy Ann	1992-04-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5c981b7f-30e2-43b9-ace2-93147a52c05c	JIL-1781354415069-298	Gabayno, Florentino	1995-01-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Luma	\N	t	\N	Active
7c04046e-91a3-4771-ab49-640a1745b7aa	JIL-1781354415069-299	Gabayno, Leonora	1981-11-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
9bb47665-64a2-43e3-81d6-e4f8f7622d3b	JIL-1781354415069-300	Gabayno, Rosita	2002-08-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Luma	\N	t	\N	Active
36ef9972-a9ac-4183-930f-d730e81bc658	JIL-1781354415069-301	Gabia, Jayvee	1991-01-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
c7248661-90df-43da-910a-be8684c94767	JIL-1781354415069-302	Gabia, Minalene	1983-05-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
c8a92430-2af9-4f38-8e8e-75793f3d0f77	JIL-1781354415069-303	Gadi, Arlene	1990-08-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
dcb59d44-d146-4a5f-89ac-7986ac64f46c	JIL-1781354415069-304	Gado, Ana	1995-12-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
1e135aeb-1e02-4f0e-afa4-2e77ff59b98e	JIL-1781354415069-305	Galay, Prodencio	1986-03-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
cd9252be-a732-4631-a6fe-fee8c2bc9ffb	JIL-1781354415069-306	Galupo, Rhea Mae	1989-06-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
22c7702f-3132-4cde-8b8a-17c2804ecca3	JIL-1781354415069-307	Gamil, Jessa Joy	1997-02-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
457ddd66-3c8a-494f-ba7d-19517ebed08a	JIL-1781354415069-308	Gamil, Jonas	1998-08-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
d09b8815-9330-4648-b459-49503d3b2535	JIL-1781354415069-317	Garcia, Juares Bonifacio	1985-10-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
63593945-2009-4a1d-9343-c8041030f0ab	JIL-1781354415069-318	Garzula, James Aaron	1998-03-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
3024ab6a-e217-4423-9272-b416274c3c19	JIL-1781354415069-319	Geraldo, Mark Allen	1981-01-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
4993a819-e291-4a65-97af-7b2462479d26	JIL-1781354415069-320	Gerpacio, Carlo	1986-06-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
63028476-0cc8-498b-a561-d6b639d0d926	JIL-1781354415069-321	Gerpacio, Jaylord	2002-02-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
31ceba23-efa5-4405-9a6c-347dff64279b	JIL-1781354415069-322	Gerpacio, Jonas	1992-12-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
722644a8-68e7-4a92-9260-09d7a3d3514c	JIL-1781354415069-325	Gonzales, Alfred	1989-06-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
e2e7f326-aa18-408c-8f5b-4dab255ff90e	JIL-1781354415069-327	Gonzales, Cherrilou	2004-08-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
b8d8f898-4cff-4bcf-bec8-f8762b9a09c3	JIL-1781354415069-328	Gonzales, John Lester	1991-01-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
9e8a08f1-cf25-4d71-9bca-35701d7c0505	JIL-1781354415069-329	Gonzales, Mila	2002-06-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	t	\N	Active
acf7db64-1e09-424a-b906-9a4fd9e90fab	JIL-1781354415069-330	Gonzales, Nelia	1989-08-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	t	\N	Active
e2fa528f-63fd-4af2-9c3c-67c855b4cda1	JIL-1781354415069-295	Frias, Justine	2006-07-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
5011cce7-6bed-4661-9edc-bf7e5eb8ba0f	JIL-1781354415069-311	Gamolao, Kyra	1994-10-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
e40529d9-26c1-4d3d-8502-287af9e77254	JIL-1781354415069-312	Gamolao, Renza	2004-02-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
99552f97-2984-4363-9f5c-e021e405f004	JIL-1781354415069-310	Gamolao, Juliana	1991-11-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
e96f6ebc-c12f-4358-8745-9569bbf2831f	JIL-1781354415069-314	Ganibo, Rosechel	2004-07-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
0287c072-414f-4f13-806b-f91cea094e2c	JIL-1781354415069-313	Ganibo, Ricky Boy	1997-09-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	f	\N	Active
d2b39013-5185-42f9-b57f-f4aa60540f38	JIL-1781354415069-315	Ganibo, Sonia	1989-05-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	f	\N	Active
f33551dc-c961-42ac-b858-013a5d75e10f	JIL-1781354415069-316	Ganibo, Wilfredo	1981-06-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Buli	\N	f	\N	Active
89645b8d-65c6-4249-b5f8-9fe401950aae	JIL-1781354415069-337	Gutierez, Aime	1994-08-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5f0a590d-b829-462a-8ad3-372dcdcdfd80	JIL-1781354415069-338	Halamanan, Cori	1998-10-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
d44d957d-85c5-4ac9-9dae-653b413d3cf9	JIL-1781354415069-339	Hermosa, Christine	1983-07-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
388b8191-6f24-4f1c-be5b-af74185a4deb	JIL-1781354415069-340	Hermosa, Elsie	2003-06-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
74a611f4-140c-40be-bd3b-7f27e4cd4b2d	JIL-1781354415069-341	Hermosa, Geralyn	2000-06-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
191c19dc-4b68-4d1d-8653-91b683a14135	JIL-1781354415069-342	Hernandez, Ashley Nicole	1986-09-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
fc76d8c1-5954-49cb-ab91-5abf93635507	JIL-1781354415069-343	Hernandez, Beverlyn	2000-08-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
5c5c72f4-b33e-4838-98e8-2fa9eed94a2b	JIL-1781354415069-344	Hernandez, Clarence	2005-08-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
ca75a60f-82a1-47b9-8ffd-05eefdc62199	JIL-1781354415069-345	Hernandez, Edlyn	1981-06-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
3861e0da-6fef-4f71-9f2b-f4f3985fb5bd	JIL-1781354415069-346	Hernandez, John Yvon	1989-08-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
ab2cdd57-30e1-4275-9390-389eb202b4a5	JIL-1781354415069-348	Hernandez, Richel	1999-04-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
086ad0f1-2a1a-40dd-be6e-3247f38c6c4d	JIL-1781354415069-350	Hernandez, Veverlyn	2002-02-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
ff52d490-6a91-47ab-a8f9-3aceb404db2a	JIL-1781354415069-354	Ibiernas, Aylene	2004-08-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
77db9d21-b796-408d-9287-ab6c2a5a6173	JIL-1781354415069-355	Ibiernas, Kenneth Lawrence	1987-02-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
7df6f052-da48-4da4-8552-6201503510c9	JIL-1781354415069-356	Ibo, Orlina	1982-06-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
35720329-789f-4e9e-a343-318198cc1d76	JIL-1781354415069-357	Ibon, Charisma	1996-10-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
ef8fb1b9-7b72-4afb-a383-2479879ec063	JIL-1781354415069-360	Imperial, Aleah Sherica	2002-11-11		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
6ecaa7cb-5556-4283-828a-ca3cbc841269	JIL-1781354415069-361	Imperial, Lenie	1991-06-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
461e37eb-b756-4f18-81c3-4356e04fb191	JIL-1781354415069-362	Imperial, Mary Angelie	1987-07-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
69cda707-62f3-46e6-9231-b6bec48b225c	JIL-1781354415069-363	Jabat, Emerson	2004-05-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Buli	\N	t	\N	Active
314fdb2c-134f-456a-b325-16988348b26a	JIL-1781354415069-364	Jabat, Judy Ann	1987-08-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
f1a55225-5f7d-4397-8c79-eca9c8293e34	JIL-1781354415069-365	Jabat, Samantha Dwane	1989-04-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
4a306124-0745-4fbe-b56c-6415d3fb4d97	JIL-1781354415069-366	Jamilla, Anacita	2002-01-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
6c7adbd8-3170-41f2-aa4f-cc02e51f2209	JIL-1781354415069-367	Janda, Hannah Joy	1988-02-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
bd30da27-73fd-454c-b211-66f324cc5045	JIL-1781354415069-368	Janda, Jaymar	2003-08-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
413ce6f4-08dc-4f6a-abb4-224eea9a25ac	JIL-1781354415069-369	Janda, Mariza	2002-02-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5cb0b868-0acf-4b39-817d-c9aedbfc86da	JIL-1781354415069-370	Janda, Victoria	1996-09-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
75c04a94-f1cb-4091-83fb-efc18ce33d79	JIL-1781354415069-371	Jarabe, Charity	1989-09-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
3de796df-454a-4ff4-b1a8-89f8ddf12541	JIL-1781354415069-373	Jarlos, Veronicca Nicole	1998-05-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
073c90fe-04b3-4572-80ff-b6590d6765f2	JIL-1781354415069-374	Jasa, Angie	1994-09-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
1d758b96-032e-418e-9779-eb2af8992354	JIL-1781354415069-375	Jasa, Jayzel	1999-06-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
8079bc6a-659d-4fd5-a4cc-529dbb5979d2	JIL-1781354415069-376	Jasa, Jeniah Faith	1986-06-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
1d55f2e4-4ef3-44e8-b2fb-54be43610827	JIL-1781354415069-377	Jatulan, Mark John	1985-03-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
51fa93b6-62c6-4a24-9e23-d69b8cb3a2a1	JIL-1781354415069-378	Jatulan, Micha Aila	1985-06-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
51b95f3b-db02-4b30-90ab-0a47e62930a2	JIL-1781354415069-384	Juliano, sheryl	1995-08-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
9450d61f-6868-41b8-9a06-8f3e3406409f	JIL-1781354415069-386	Labaguis, Ashley	1989-10-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
765816e4-5a88-4577-b048-17c0dec000df	JIL-1781354415069-332	Gonzales, Princess	2003-05-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
d92168ee-74bf-4077-b5b4-b80aba1249e7	JIL-1781354415069-336	Guerra, Snooky	1994-04-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
7df0317a-fc89-437f-a756-252b03f66a40	JIL-1781354415069-335	Guerra, Erica	2004-08-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
e31f23fe-e77d-42dc-9255-da743aba39f4	JIL-1781354415069-347	Hernandez, Prudencio Jr	2003-03-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
f2fbf001-fa01-4173-ae6a-9cb686f648c0	JIL-1781354415069-349	Hernandez, Rona Jane	2002-09-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
cec4d325-92d8-4860-9013-b243a9a3c688	JIL-1781354415069-351	Hilot, Trixia	1996-06-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
0491f4c9-6f70-4f24-874d-3b266f267f3f	JIL-1781354415069-352	Honorica, Bennelyn	1973-11-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
be8d321a-1253-4d96-b353-b5c06f3b60b9	JIL-1781354415069-353	Honorica, Nicole	2002-05-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
fcb78431-8436-4d1d-8011-7a1d8946a266	JIL-1781354415069-381	Jimenez, Keila	2002-05-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
1a6867e6-a5ed-43a5-9c03-632d93316182	JIL-1781354415069-382	Jimenez, Perla	1972-03-30		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
572c38d6-c3dc-4f7d-9808-5c4349ffe0c6	JIL-1781354415069-383	Jugar, Bernadeth	1994-06-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
2b546bdb-afa8-4b46-9c73-2d84819e02e6	JIL-1781354415069-388	Labaguis, Jen-jjen	1997-08-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
9702d1dc-5a01-44b6-8e93-e24ce532aeb0	JIL-1781354415069-390	Laceda, Angelica	1987-01-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
7b7e6d2a-5431-4305-9e81-798969675928	JIL-1781354415069-391	Laceda, Carmen	1983-04-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Luma	\N	t	\N	Active
4bfaaada-18c9-42fd-88f7-8e7c09e0b0ae	JIL-1781354415069-392	Laceda, Elisa	1982-02-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Luma	\N	t	\N	Active
113c6164-3d1b-4857-bf65-80de0c69cc7a	JIL-1781354415069-393	Laceda, Juan Miguel	1983-04-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
0539e300-5fa8-4328-ad83-dc2424cd1449	JIL-1781354415069-394	Laceda, Lourdes	1995-05-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
36bfa043-8e25-4472-8750-a4a7aaed6d2a	JIL-1781354415069-395	Laceda, Mary Michaela	1983-06-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5d79d53d-be89-42c7-a8b9-c86523207d29	JIL-1781354415069-358	Ilao, Angelica	2002-08-01		WSAM	\N		\N	20	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
6ae59089-32a5-4145-bfb3-b1ad463bf22b	JIL-1781354415069-372	Jarabe, Trisha Gail	2011-10-10		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	Female	Active
41750d34-8220-4b8a-a052-7942aed874a4	JIL-1781354415069-385	La Rosa, Jenny Rose	1991-07-13		WSAM/LGAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t		Active
b49d8c0f-f8eb-4f1d-9d6c-889825969b2a	JIL-1781354415069-396	Laceda, Milo	1995-07-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Luma	\N	t	\N	Active
0cbf4686-833f-4558-9ce1-242da0d300be	JIL-1781354415069-397	Laceda, Pedrilyn	1995-03-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Luma	\N	t	\N	Active
709a9ee2-e1fd-46f0-96fb-bb2cc1578cf9	JIL-1781354415069-398	Laceda, Reuel	1993-08-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
64f14cff-08c3-4279-9a5c-52c63aa1cf39	JIL-1781354415069-399	Laceda, Williard	2003-10-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Luma	\N	t	\N	Active
b8e28b7f-3774-442c-bbe6-233e1b0b29e0	JIL-1781354415069-401	Lago, Kim John	1995-04-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
986893e7-1959-4c34-ae44-14cfc1168285	JIL-1781354415069-402	Lago, Nino James	1992-07-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
2b5aa758-c471-499a-921d-89a1ddadeb02	JIL-1781354415069-403	Laham, Daisy Lyn	2005-07-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
0d3cc085-29ef-44f8-bb9b-daa72ca0681a	JIL-1781354415069-404	Lalog, Gerald	1982-05-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
391a7c28-db90-4cb5-829e-e665a849627e	JIL-1781354415069-405	Lamboloto, Analyn	1984-01-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5dc994cd-48ce-4888-9657-cbb1c81b776b	JIL-1781354415069-406	Lamboloto, Emmanuel	1991-04-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
7ba7208c-c817-44e7-87b3-5d85be30fcf1	JIL-1781354415069-407	Lamboloto, Kriszha Maine	1998-04-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
26e90832-89f4-4262-923b-fb1f3e145254	JIL-1781354415069-408	Lamboloto, Marianne	1994-09-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
f897b77c-ef62-4d0d-986b-a1fc0a0900eb	JIL-1781354415069-409	Lamboloto, Mark Daniel	2003-11-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
8f5a0bd9-9def-4cd2-88f3-3ce22ec621e0	JIL-1781354415069-410	Lamboloto, Marlon	2005-10-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
6e2a5bc1-13e1-4374-8ba1-59c2aa8c396c	JIL-1781354415069-411	Lamboloto, Mary Ann	1997-09-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
6f60f5d2-e412-42c3-8c66-5c9510ece1ea	JIL-1781354415069-412	Lamonte, Anna Marie	1991-08-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
7f6ec11b-54c2-4182-858c-9230cb841a9d	JIL-1781354415069-413	Lamonte, Clarita	1991-08-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	t	\N	Active
d17842d4-3e6b-4834-b679-85606b2c8b36	JIL-1781354415069-419	Lampayan, Josefina	1990-11-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
52c1482a-8984-4485-9334-3783f456d7ed	JIL-1781354415069-426	Lanet, Rheyshell May	1997-04-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
f5b8bd7a-999a-48c8-8fb2-834b7385e2ef	JIL-1781354415069-427	Lanete,  Nenita	1982-09-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
3e2c8f1a-0a4d-4e4a-9748-da947d793f98	JIL-1781354415069-428	Lanete, Jazmin	1983-07-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
afcf31bb-7edc-474f-83e1-c21810688d19	JIL-1781354415069-429	Lanete, Joyce	1987-02-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	t	\N	Active
d3655cef-df1e-4b0e-92fd-0be7c3047739	JIL-1781354415069-430	Lanete, maribel	1986-04-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Buli	\N	t	\N	Active
b3b14255-5a0e-4f87-87bf-f53691c59806	JIL-1781354415069-431	Lanete, Marivic	1997-10-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
ab6bb016-edd5-4eb4-ae57-b73307f4179f	JIL-1781354415069-432	Lanete, Nenita	2001-11-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
97021b26-60e3-43d3-ab79-8d93e723beff	JIL-1781354415069-433	Lanete, Rheabell	1980-12-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
0b6ea1d7-e95b-4761-8672-e262028e1fd6	JIL-1781354415069-434	Lanete, Rheybell	2000-09-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
8caf103c-fb98-45d5-89d9-11eb4f458f99	JIL-1781354415069-389	Labaros, Denzlet	1994-10-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
8759add4-9f3b-4298-988c-fb9c7fa1278b	JIL-1781354415069-414	Lamonte, Myka Andrea	1980-12-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
751c3478-196d-4580-93c1-d13b683503d9	JIL-1781354415069-416	Lamonte, Rochelle Allen	2007-09-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
cbf1df44-43eb-443e-8f5b-c670a5519a46	JIL-1781354415069-418	Lampayan, Jomar	2005-03-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
c99484a4-d18a-49e1-ad3e-60da40e378ee	JIL-1781354415069-417	Lamonte, Serafin	1985-05-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Buli	\N	t	\N	Active
795f75cf-9d9d-4958-bc26-2cf2ff76e7b9	JIL-1781354415069-415	Lamonte, Racky	1996-10-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Buli	\N	t	\N	Active
30d46d69-91fb-4925-8fcc-e850d62e0c2a	JIL-1781354415069-420	Landoy, Lowel	2002-01-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
a37031bd-1e26-484c-b552-f264ab874e0b	JIL-1781354415069-422	Landoy, Nelman	1980-02-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Main – Pinamalayan	\N	t	\N	Active
81622d73-2f5f-440a-9ee5-cf41686189d9	JIL-1781354415069-424	Landoy, Ressie	1986-10-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
8f27affd-b334-4572-84b5-0dcb687defe8	JIL-1781354415069-423	Landoy, Princess Hannah	1986-08-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
c4ab2391-87d2-43bc-ae94-b22c525a600e	JIL-1781354415069-425	Landoy, Richelda	1962-02-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
de26ed83-276a-4541-afdb-432cc15e0b50	JIL-1781354415069-435	Lanot, Aidan	2004-03-31		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
4fc8a981-74ee-4efa-978a-feafab2e7017	JIL-1781354415069-436	Lanot, Alicia	1968-03-08		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
e9d2a2f5-0ccb-4ccf-b819-a4df5a01ca08	JIL-1781354415069-440	Lanot, Kevan Mark	1980-08-20		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
f4bfe2b9-0879-4f61-b160-36a49ac1c8c6	JIL-1781354415069-448	Largado, Marites	2005-07-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
7f06fa8a-3b34-4f67-8d03-edd6de1f5b05	JIL-1781354415069-449	Largado, Patrick James	1983-04-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
2b449673-5864-4b4b-a8f3-c0a330612643	JIL-1781354415069-450	Largo, Cherry Mae	1991-03-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5ff740a0-83ca-4509-9746-48fa7e53f4fe	JIL-1781354415069-452	Larosa, Juliet	1999-10-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
50c8b08c-76a6-4cd1-93fa-3c15e9f79b8d	JIL-1781354415069-453	Latombo, Oschel	1993-01-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
6e69f9f8-8967-4731-9a70-9ecfbc11c432	JIL-1781354415069-454	Latombo, Oschel	1983-06-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
6e9d4194-d9f3-4d20-9b60-dbafd6efffc3	JIL-1781354415069-455	Latorre, Jove	1981-09-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
367990d3-71e0-4d68-87e7-5f7b646b3eb9	JIL-1781354415069-458	Laxina, Leda	2005-03-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
82fe0067-1e2a-4247-b298-79e1e0cebc8a	JIL-1781354415069-459	Laxina, Rizza Lee	1981-12-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
d9249595-47d0-48cc-9787-4e5d8367d27e	JIL-1781354415069-460	Layante, May Anne	1993-02-14		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
c0cc18f5-df47-451b-b920-e3e4a6be0b70	JIL-1781354415069-461	Laylay, Liezel	1997-12-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
f1425ba4-f465-4547-b3ec-7f36513633e1	JIL-1781354415069-462	Laylay, Wilbert	1983-10-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Buli	\N	t	\N	Active
79843090-2b95-4228-82f4-2f2cb0e808da	JIL-1781354415069-437	Lanot, Evelyn	1965-11-26		WSAM	\N		\N	20	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t		Active
52f8fce3-318b-4761-b71f-d354169e8aa3	JIL-1781354415069-438	Lanot, Germilyn	1993-06-25		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
329f49a2-a7a2-438f-8aca-05c2dee8f283	JIL-1781354415069-463	Lazo, Juliet	1986-09-24		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
81cbab97-4eac-4ed7-8abb-06afada15c23	JIL-1781354415069-464	Ledesma, Melody	1985-07-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
1de3acc0-21a0-43e5-a530-837bf8906c73	JIL-1781354415069-465	Lem-it, Albert	1989-09-18		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
a1a930b1-3892-4d37-998d-b5c2238a8099	JIL-1781354415069-466	Lem-it, Merlinda	2005-01-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
e1b7f85d-656e-413a-873c-b11b8e33066d	JIL-1781354415069-467	Leonar, Marilyn	1980-06-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
09781a2c-66ef-4fc9-ac91-2429ee6aa634	JIL-1781354415069-468	Leonar, Scarleth	1994-10-21		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
0ddd2a2f-a7ff-4f44-9305-afded393768f	JIL-1781354415069-469	Licupa, Princess	1982-07-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
630f0ea5-755c-4172-9a24-3e6d12f4e638	JIL-1781354415069-470	Lincallo, Jhon Jimuel	1982-12-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
2175d0d0-733c-4b6e-8621-827a8784e282	JIL-1781354415069-471	Lincallo, Marilyn	2000-10-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
f3f6e7f8-3693-4f9e-b5ca-6fcd4b40f499	JIL-1781354415069-472	Lincallo, Rodel	1987-10-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Sta. Rita	\N	t	\N	Active
98555a12-b9e7-461d-9741-3949a2c94910	JIL-1781354415069-473	Lingon, Elaisa	1999-12-19		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
d6096ba4-9d09-4cbb-b4ad-09b14d6820df	JIL-1781354415069-474	Lingon, Erica	1998-08-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
f01becd5-752a-4ddc-ba81-290dd6410767	JIL-1781354415069-475	Lingon, Eunice Beth	1999-06-03		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
95e86a9e-971b-467a-8336-997b0bf59a00	JIL-1781354415069-476	Lingon, Makaela	2005-06-25		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
336cbd10-75f4-4c4f-bc7f-873d66e355d2	JIL-1781354415069-477	Lingon, Myrene	2002-12-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
d3a97610-6037-44d0-9d23-e5145d82e691	JIL-1781354415069-478	Lingon, Myrine	2000-11-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Luma	\N	t	\N	Active
631b633e-33f3-488d-834b-0d217f6bbb8b	JIL-1781354415069-479	Lingon, Neulisis	2000-02-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Buli	\N	t	\N	Active
d1f52e40-e5b1-4fdf-9507-f8df6b498fd6	JIL-1781354415069-480	Llamoso, Marjorie	1986-06-05		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Luma	\N	t	\N	Active
31f8a69c-a4a7-4c0b-96c4-d6bd414c2ebc	JIL-1781354415069-481	Llave, Irene	1990-03-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	t	\N	Active
42681f02-cedb-4d16-8e6c-b48392edae0f	JIL-1781354415069-482	Llave, Karl Hezron	1983-10-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
5a77dda0-87b8-442c-b201-2cb95f4a88e0	JIL-1781354415069-483	Llave, lanie	2002-10-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	t	\N	Active
524bd782-ade1-4768-9eab-ccead2db33dc	JIL-1781354415069-484	Lolong, Daniel	1993-12-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
1b85274b-39d0-45ea-9d5c-7962b14ad8da	JIL-1781354415069-485	Lolong, Gwendelyn	1987-07-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
96f5ee4d-99e1-40bb-93b1-bb853ef783c2	JIL-1781354415069-486	Lolong, Jimmel	1985-08-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
80870c56-6b73-4a58-920c-a5ac602046d3	JIL-1781354415069-487	Lolong, Jimmy	1996-02-28		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	\N	Active
8e526c6c-7a8a-477d-afc0-31cc7c606001	JIL-1781354415069-488	Lolong, Lealyn	1997-07-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
8224592a-fa8c-4932-ad93-9671b25bb08d	JIL-1781354415069-489	Lolong, Lynniel	2002-07-23		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
94a355b5-45fb-4c01-8f6d-f27d0329bd90	JIL-1781354415069-490	Lolong, Marialyn	2003-01-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
3e108281-8a54-4fb7-b2e3-dd794b1f7a5a	JIL-1781354415069-491	Lolong, Marife	1992-06-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
ee840c93-4f83-40d2-9315-128963f9936b	JIL-1781354415069-492	Lolong, Mark James	1996-03-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
ec9659d7-bcde-4e47-97d9-eaeeb26140c1	JIL-1781354415069-493	Lolong, Noelyn	1989-10-27		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
96f9dc2b-ac95-46fb-a10f-9376f5cde4f5	JIL-1781354415069-494	Lolong, Nora	2001-05-26		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
343834ef-c434-433a-94d5-86f0a77f89bf	JIL-1781354415069-495	Lolong, Numer	1998-10-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Men	Inclanay	\N	t	\N	Active
46e9312c-5aa7-433c-a89e-20f33fbf6809	JIL-1781354415069-496	Lolong, Rhea Joy	1988-05-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
42f1a072-6560-43f9-a2e4-27e3fd6be66e	JIL-1781354415069-444	Lanot, Reian Mark	1990-01-02		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
a9efadc7-c840-47c8-b6f5-f58df606f6dc	JIL-1781354415069-446	Lanot, Trixie	1986-12-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
a354fc45-6ec2-4547-a09d-41840a18a2c4	JIL-1781354415069-447	Lanot, Vina	2002-05-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
0b0295ca-db43-4278-a8f0-ddbac125752d	JIL-1781354415069-445	Lanot, Ronalyn	1983-08-22		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
4d520fc8-43c2-483e-9d89-d75d92a93adf	JIL-1781354415069-451	Largo, Chona	1979-07-07		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
b945cba5-b3a5-43e3-bc2b-b9279ac26c8f	JIL-1781354415069-456	Lawig, Naty	2005-02-16		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
65358194-525d-491c-8f8a-3a586e402aed	JIL-1781354415069-457	Lawig, Sheena May	2002-02-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
3ba1847f-bdef-4bf7-9b50-55dd26aa552b	JIL-1781354415069-498	Lolong, Wennalyn	1980-05-04		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Inclanay	\N	t	\N	Active
b2884669-ac07-44e9-8732-e8b6f7c8a971	JIL-1781354415069-499	Lolong, Winnie	2004-07-06		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Inclanay	\N	t	\N	Active
fa040425-57dd-4153-ba5e-a6c6b14fd1fa	JIL-1781354415069-500	Lolong, Zycelle Maria	2004-11-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
57cbf242-f9da-4ed8-a24e-568dc86b24d7	JIL-1781354415069-501	Lopez, Nemia	1990-06-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
50076f16-bd54-43d8-b0ae-65711293e157	JIL-1781354415069-502	Lopez, Veri Jane	1983-09-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
6bfd71d2-0e12-4618-a171-5a53165cda85	JIL-1781354415069-503	Lozada, Joy	1997-05-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
91df6bde-95d8-4014-9def-2fac2a474b20	JIL-1781354415069-504	Lozano, Alexa Mae	2000-02-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
333a4c18-98c1-4fd2-ae71-26d971e8584c	JIL-1781354415069-505	Lozano, Illuminada	1997-03-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
cc9b68fa-4c8a-41cb-8d93-12ce08c702d2	JIL-1781354415069-506	Lozano, Lorna	1981-12-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
9bfd2c15-5d31-4cd1-88ec-d4fea8167f47	JIL-1781354415069-507	Luarca, Calyn	1988-01-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4409db76-59b9-43e3-b15a-49345ac18bbf	JIL-1781354415069-508	Luarca, Ma. Carla	1994-02-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f47977fd-a55d-41ba-9a04-2f3a1241df0d	JIL-1781354415069-509	Luarca, Marilyn	1985-01-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
3f80d520-cab9-44e8-a1f3-0cca947e5b4c	JIL-1781354415069-510	Luarca, Micah Jane	1992-09-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
481d04b6-1dea-4f77-91c8-0bea356ec6dd	JIL-1781354415069-511	Luarca, Rosita	1995-01-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
22fe1dcc-19b2-42d7-8c0b-ea5e1044752a	JIL-1781354415069-512	Luceriaga, Judy Ann	1989-08-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4be0b178-b93a-44e7-aa84-d9282b899781	JIL-1781354415069-513	Luceriaga, Nora	1996-05-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
46632b2b-c541-4c8e-acd1-df9ce4f74192	JIL-1781354415069-514	Lucido, Ely	1999-11-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
a0ae3149-8688-4775-b616-70b8b5e71e7b	JIL-1781354415069-515	Luha, Andrea Clavel	1984-01-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
940ec6aa-6190-4e90-b31c-97484ceeac17	JIL-1781354415069-516	Luha, Anna Marie	1980-09-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
55affa0f-ccb9-4d64-a1df-52531ffe2d85	JIL-1781354415069-517	Luha, Hilda	2004-05-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
a1e9b1fb-05c4-420a-bd2f-43f82c47ef16	JIL-1781354415069-518	Luha, Jaylord	1988-10-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
e2a5d69b-48f6-4739-95e1-6e9741068382	JIL-1781354415069-519	Luha, Jaylord	1994-08-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
20db50fb-fae0-4057-8d6a-5b2d82e0e89b	JIL-1781354415069-520	Luha, Lucita	2003-02-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	\N	Active
8fde651f-6cc5-489f-a78e-67520a2d7b39	JIL-1781354415069-521	Luha, Marissa	2005-10-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
57f45826-1bda-4574-95b0-d535a10ba7f0	JIL-1781354415069-522	Luha, Niel Zaijan	1987-04-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
55c223bc-ed2b-41ce-b999-45a67a86186e	JIL-1781354415069-523	Luha, Rogelio	1996-07-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Buli	\N	t	\N	Active
f3734af1-68c9-4ea3-a5e4-765203596e0e	JIL-1781354415069-524	Luha, Rosedelle	1999-08-24		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
8e29aca5-68b7-4639-bd9e-4cac370e748b	JIL-1781354415069-525	Luha, Ryan	1982-02-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Buli	\N	t	\N	Active
5e57cafd-71ed-4675-bcc8-aa97f8ae2f98	JIL-1781354415069-526	Luha, Ryan	1990-07-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Inclanay	\N	t	\N	Active
b6739d9d-5866-412c-ac5e-0e14eb352eb7	JIL-1781354415069-527	Luha, Wendy	1980-01-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
c5cf4185-9516-41a7-903f-b6e8275af56a	JIL-1781354415069-529	Lumague, Rutchie	1987-06-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
21e13ef6-5d81-4764-9eaa-12befba51229	JIL-1781354415069-530	Lumat, Adonis	1999-10-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
4cc1160a-5016-47c4-b7ed-74ce753638c2	JIL-1781354415069-531	Lustanas, Japheth	1985-06-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
9f74f8f8-cdb9-41f2-ac38-25dd69ca27c4	JIL-1781354415069-532	Luz, Samuel	2000-08-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
cea08fcf-a7cb-431d-8628-02c34fcc8044	JIL-1781354415069-538	Mabuti, Jeffrey Bryan	1992-05-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
e9c5ba3f-054a-4336-ace9-1468eb0aa1b4	JIL-1781354415069-539	Mabuti, Ma. Lea Lou	1995-12-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
2ef04d53-c42d-4dbb-890b-b170c91ea013	JIL-1781354415069-540	Macaraig, Ariane	2003-03-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0415923b-39f4-4464-a363-b7f52ee67cc6	JIL-1781354415069-541	Macaraig, Lyn	2001-05-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
69164a32-b63b-4616-a2e1-a20eed58cc1f	JIL-1781354415069-545	Madrigal, Yorie Isabela	1992-02-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
abbfa6d5-b7f3-4988-bc10-be6193185420	JIL-1781354415069-546	Magalang, Mariel Joyce	1990-06-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
835d8606-7e86-4b12-ae4f-657b7d9eb82a	JIL-1781354415069-547	Magalang, Marjorie	1996-06-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
bccfbd8a-8a5e-44f2-9dc9-f560897b95b3	JIL-1781354415069-548	Magallanes, Erica	1980-08-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
0f03e216-9c5f-4b90-b237-f663ea4d11e8	JIL-1781354415069-550	Magcamit, Ferlyn	1995-02-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
18214ddc-0c43-4b56-870a-530ac89805f0	JIL-1781354415069-551	Magcamit, Francis	1984-01-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
1405b0c3-76c9-4cca-8d98-3efbe3d4415a	JIL-1781354415069-543	Madrigal, Paolo	2005-10-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	f	\N	Active
cf59bd26-4c41-4a3b-a64d-d27fff263bac	JIL-1781354415069-544	Madrigal, Rosalinda	1998-08-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	f	\N	Active
7d723030-17ae-4b51-ae87-2bc434d9f685	JIL-1781354415069-535	Maaño, Haggai	2014-09-16		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Kids	Main – Pinamalayan	\N	t	\N	Active
2f60711c-016d-4fdd-98c3-15a9b7adf28c	JIL-1781354415069-556	Magcamit, Marriane Joy	1989-11-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
340aa76a-347a-4041-9768-2c3565db99b1	JIL-1781354415069-558	Magcamit, Shyrene	1981-01-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
1617d98f-2c85-4045-85c4-40ad1477eaec	JIL-1781354415069-559	Magcamit, Yolanda	1999-03-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
ce45e879-7759-4d27-b98d-f13257322795	JIL-1781354415069-560	Maglacas, Andrei	1982-01-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
782209b3-be4d-4f92-b0ab-cace74111765	JIL-1781354415069-561	Maglacas, Sean Lloyd	1990-12-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
53514246-3d7a-4b5b-87a1-639fea53a458	JIL-1781354415069-562	Magpali, Emma	2001-01-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
4e9c74a0-5c94-4c0a-b6e2-9567f5e3d174	JIL-1781354415069-563	Magpantay, Aira	1997-08-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
271a42d2-4659-4a6d-b576-9ceaf652b598	JIL-1781354415069-566	Magpantay, Lord Cedrick	2000-01-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
5c8583f8-12b4-42e2-a1d6-583a2a5071ba	JIL-1781354415069-567	Magpantay, Monica Ann	1991-11-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
bda96b1f-7773-4b0e-879a-16772ae65149	JIL-1781354415069-568	Magpantay, Nicole	1992-11-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
b8e637d1-4948-4124-b621-7840e02f3e7e	JIL-1781354415069-570	Magsino, Elizabeth	1989-05-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
a38a33ef-a379-4a14-8b7b-c61a37f95711	JIL-1781354415069-571	Magturo, Garibelle	1984-06-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
cebb55be-0547-46c8-9d8d-2c30fe0ba552	JIL-1781354415069-573	Magyaya, Adela	1990-09-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
036c8f15-88e9-486d-b06f-a96aac9b2232	JIL-1781354415069-574	Magyaya, Allysa	1996-02-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f8db5d4e-37de-4243-bde0-6ce206f0d643	JIL-1781354415069-575	Magyaya, Ana France	1996-01-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
c07278e7-83ec-43c5-b87c-c1568451b62e	JIL-1781354415069-576	Magyaya, Ana Trixia	1997-08-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
507469d4-b060-4d1d-a5a9-df6b15f43a96	JIL-1781354415069-577	Magyaya, Analyn	1995-03-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
2278dc05-0e4b-4f5b-9149-43858abf857a	JIL-1781354415069-578	Magyaya, Andrey	1996-03-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
587d80e4-9544-4d0e-b4f6-8d70c4f94339	JIL-1781354415069-534	Maaño, Ava Marie	1978-08-29		WSAM	\N		\N	20	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t	\N	Active
0b70a942-3407-4808-9e0c-31751812a11b	JIL-1781354415069-552	Magcamit, Gaddiel Love N.	2011-02-22		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Female	Active
0d198521-6170-432b-b5f5-092b118a4e41	JIL-1781354415069-542	Madrigal, Dave	1998-02-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	f	\N	Delisted
9bacb1d4-162d-47f1-9b89-36b637c2331e	JIL-1781354415069-536	Maaño, Jaica Jane	1985-05-25		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t	Female	Active
90c2cf00-edc1-408d-a89c-9c28e4697f8d	JIL-1781354415069-528	Lumague, Marielle Danielle	2004-08-25		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Female	Active
f12e141a-75ca-4d14-8264-3b3f68ea1272	JIL-1781354415069-579	Magyaya, Araceli	1995-11-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
7240d2aa-3342-4d0e-b71e-2383caabe74c	JIL-1781354415069-580	Magyaya, Armando	1990-12-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
7b749b4e-3fc1-4445-a9d3-ad2ed1f5d4a7	JIL-1781354415069-581	Magyaya, Armie	2000-03-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
e1ab6631-c3c2-4ab8-8c77-92a035de0e62	JIL-1781354415069-582	Magyaya, Arvie	1983-05-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2160ba00-7241-4c18-b703-2229d9a97221	JIL-1781354415069-583	Magyaya, Lemuel	1989-10-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0b1c55aa-acee-457d-9780-02e04b9879c3	JIL-1781354415069-584	Magyaya, Maribel	1986-05-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
506d0803-f627-4ecb-bc1c-7dd411c94544	JIL-1781354415069-585	Magyaya, Nonalyn	1996-10-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
58f78f58-9bc0-4e32-90a6-d263fa3dbe85	JIL-1781354415069-586	Magyaya, Nonilon	1992-09-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
fbdf9f31-3cce-40e9-a6f8-5868718f69b6	JIL-1781354415069-587	Magyaya, Novan Jay	1990-09-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
7a6daab7-752b-4a49-8bcd-9c978cbaa0d5	JIL-1781354415069-588	Magyaya, Prince Mateo	2001-07-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
3e554e3e-c615-4ce0-abb1-ca4eab0e7927	JIL-1781354415069-589	Magyaya, Princess	1993-02-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
45e84432-52dd-44fc-afda-23ca5aa1a250	JIL-1781354415069-590	Mahaguay, Heward	1990-10-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
e11a4936-182f-48c3-9a44-0af1a4c19726	JIL-1781354415069-591	Mahaguay, Key Ann	1983-11-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
9aa02d8a-c46f-4468-9fea-b7049bebaf1e	JIL-1781354415069-594	Maines, Maricel	1996-12-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
8f0ed0b4-7dfd-49ed-816c-fd0ead398fae	JIL-1781354415069-601	Malabayabas, Joel	1991-04-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
aa99b9d7-6b43-46f0-878f-433a79ba0bcb	JIL-1781354415069-602	Malalad, Florence	1997-07-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
bc9a3ae7-c143-434b-adba-ec86ac72b6f0	JIL-1781354415069-603	Malangis, Analyn	1984-07-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b203b186-8d23-476c-945e-b2c7b2ff8c27	JIL-1781354415069-606	Malapote, Jinky	1984-12-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
2c990402-023b-46d3-90c7-09d8739ba9b6	JIL-1781354415069-607	Malibiran, Leonel Saguid	2002-08-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
02cb479d-680a-4087-952d-eae76bfe1bf1	JIL-1781354415069-593	Mahaguay, Leonisa	1987-03-13		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
671ca314-2d76-46fe-8d9f-c9c4e6e451bd	JIL-1781354415069-557	Magcamit, Neslyn	1991-03-14		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
c1f5b952-d857-441d-a165-de6914413e23	JIL-1781354415069-608	Malimata, Aizle	1990-02-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
694dea7d-5f10-4862-84aa-135280d0ee09	JIL-1781354415069-609	Malimata, Angela	1995-03-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
10c2231f-72a7-4f15-937b-b531902a85c7	JIL-1781354415069-610	Malimata, Anjaneth	1983-07-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
a79a0c38-0d79-4ce0-bb57-a594c9541bb1	JIL-1781354415070-611	Malimata, Chariz	1982-11-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ada4ccaf-75b8-45df-9610-173f9e69e437	JIL-1781354415070-612	Malimata, Daisy	1984-07-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4539c463-1f5d-4841-8ac3-5aed5f11fdd0	JIL-1781354415070-613	Malimata, Dianne	1993-07-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0c607f60-3b44-4d23-8e2e-3df53c4c9fbf	JIL-1781354415070-614	Malimata, Emily	1997-03-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
a3726f5a-ae60-49fd-a2c2-25c8f20d3861	JIL-1781354415070-615	Malimata, Jhon Carl	1988-06-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
be33d819-e7e0-4678-abc6-5e9ac2369498	JIL-1781354415070-616	Malimata, Kia	1991-02-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
7303ff2a-0fc7-49ee-aa70-a56470cc65ce	JIL-1781354415070-617	Malimata, Laurence	1993-06-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f1acc0c9-c667-4e20-9ac3-6ee9777881d5	JIL-1781354415070-618	Malimata, Lorenzo	1996-01-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
87d8d921-465b-432e-851f-7dfed2860cc5	JIL-1781354415070-619	Malimata, Rhea	2005-09-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
570b8077-8ec5-455c-a6a5-11fdb02584a0	JIL-1781354415070-620	Malimata, Shaira Joy	1992-01-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
78a278e7-c0bd-44f0-991a-ada8627440df	JIL-1781354415070-621	Mallen, Rolando	1999-05-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
6588c49c-d07d-48c8-ab71-3efc29ef3308	JIL-1781354415070-622	Mallory, Mike	2002-11-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
d6dbeb32-cbc3-4e32-b944-be823c9744c1	JIL-1781354415070-623	Mallory, Teresa	1984-02-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
24e12afc-ca6f-4d2c-bd71-1e9fc9252941	JIL-1781354415070-624	Malubag, Alona	1993-03-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
33e69b23-2440-418d-81fd-dc56a8244ae3	JIL-1781354415070-625	Malubag, Florenda	2005-02-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Luma	\N	t	\N	Active
4fd68ad2-2280-4ca2-b01a-364000b97a58	JIL-1781354415070-626	Malubag, Jessabel	1999-01-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
9ca99ffc-2d6c-49c3-8459-df1303294e78	JIL-1781354415070-627	Malubag, Michelle	1997-10-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Luma	\N	t	\N	Active
baf90c75-53d3-43f0-ad00-80b34aaa97ee	JIL-1781354415070-628	Malubag, Rachel	1996-07-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
5420d426-cf42-40d2-8956-e75a59464915	JIL-1781354415070-629	Malubag, Regine	1997-10-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
03b5cc4f-9861-483e-91c3-f72183ab9c8d	JIL-1781354415070-630	Malubag, Renzo	1982-10-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
ab5ed69c-312c-4676-a508-c5172097cc20	JIL-1781354415070-631	Malungay, Filipina	1981-02-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
e6930b52-2cbf-4ff2-b7fb-b206c900a3bd	JIL-1781354415070-632	Malungay, Recxon	2005-03-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
11514ff1-cfac-40f4-8667-7c59abdc4fb6	JIL-1781354415070-633	Mameng, Hanica	2004-05-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
808dc296-962c-491e-a2cd-a79883d50087	JIL-1781354415070-634	Mampusti, John Clarence	2004-05-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
6369071b-a2fc-4cfc-a5ce-e255012a974e	JIL-1781354415069-564	Magpantay, Joselyn	2002-09-01		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Female	Active
d43a30df-92b6-42c2-ab80-ea060627c64d	JIL-1781354415069-597	Malabay, Jonathan	1992-05-19		WSAM	\N		8334512f-5979-4cc0-9241-6e3c552e0028	0	2026-06-13 12:40:16.665642+00	Young Adult	Bagong Silang	\N	t	Male	Active
82e44072-b750-4c63-9da4-3605604f8731	JIL-1781354415069-600	Malabay, Teresita	1994-11-12		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
420573f1-b8f6-4342-9669-6ccdd7ab7456	JIL-1781354415069-596	Malabay, Jedediah	1982-05-07		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:16.665642+00	Men	Main – Pinamalayan	\N	t	Male	Active
fb52810a-3ef3-4aac-a1c3-a4642a06c566	JIL-1781354415069-604	Malangis, Julie Anne	1985-04-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Main – Pinamalayan	\N	t	Male	Active
8f62c753-b403-4752-adab-53a98479c448	JIL-1781354415069-598	Malabay, Lloyd	1999-05-06		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	0	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	Male	Active
f4e29d7f-62f2-4271-8928-2e0d0aa58c49	JIL-1781354415070-635	Mampusti, Marco John	1986-10-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
68fcc528-d482-49d2-831c-82b4cd1699c6	JIL-1781354415070-636	Mampusti, Mary Joy	1999-05-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
d86fb7b4-fe66-4b25-9978-24643f628f20	JIL-1781354415070-637	Manalo, Jenifer	2005-01-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
79f7b5ff-6c03-4e74-bb36-84ed8cc95884	JIL-1781354415070-638	Manalo, Jessa	2001-07-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
676ace38-2e10-4dc7-93d6-dc7a02c689df	JIL-1781354415070-639	Manalo, Myka	1986-06-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ecc920bd-364f-4161-9110-8670aef116b8	JIL-1781354415070-640	Manao, Florencia	2004-07-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
d50f5ae4-994e-4bde-a389-5fa66d14a21d	JIL-1781354415070-641	Manao, Francis Laurence	1991-12-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
a573bfa2-2aae-412d-925d-3846008acc7a	JIL-1781354415070-642	Manao, Jenilyn	1992-08-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
38010f0a-f841-4a53-afef-6e3cb9038ade	JIL-1781354415070-643	Manao, Kianah Angela	1987-11-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
82d7a0f6-ecc3-484c-9b33-d0b133956115	JIL-1781354415070-644	Manao, Leaflor	1988-04-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
c73ffb66-1c5a-459e-815f-4717b8199c78	JIL-1781354415070-645	Manay, Delia	1998-07-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
1c94987d-b0c7-467b-b69d-e537a5d5c761	JIL-1781354415070-646	Mandayo, Aleah Mae	1990-05-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b35e1e5a-fd71-4b17-ba50-02efc431c368	JIL-1781354415070-647	Mandayo, Aleah Nicole	2003-02-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
60ebfc72-cfe8-4147-a24e-e7efffd754c6	JIL-1781354415070-648	Mandayo, Blessie	2005-08-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
e085e061-a623-40ca-ae54-b94a3251e6fa	JIL-1781354415070-649	Mandayo, Eunice	1985-11-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
812ffb17-5d6a-4a79-add8-6675748797c8	JIL-1781354415070-650	Mandayo, Reniel	1986-11-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
353967f7-4b81-4a99-a965-c24e704ed8af	JIL-1781354415070-651	Mandayo, Rica	1992-06-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f23811c5-684e-4eb6-ba16-6ff3d9d57dd5	JIL-1781354415070-652	Mandayo, Vince	2005-07-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
8306c0fe-0d00-4b0f-9d96-4daf4d7b904b	JIL-1781354415070-653	Mandia, Ace Harvey	1987-04-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
493b1d9f-eb13-4190-915d-c8a322f644f9	JIL-1781354415070-654	Mandia, Cherry Ann	1985-10-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
7c7a9171-b112-487c-abe2-05956f11e2a1	JIL-1781354415070-655	Mandia, John Harold	1983-05-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
04936370-397b-44e5-a950-9b21f4316289	JIL-1781354415070-656	Mandia, John Mark	1987-12-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
87f41ceb-f0fa-4079-b473-3d03bea04075	JIL-1781354415070-657	Mandia, Marlyn	1990-08-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
57a0c897-eb0b-4052-890e-b00f350f2cba	JIL-1781354415070-658	Mandia, Tess	1988-03-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Luma	\N	t	\N	Active
97b79b4f-d3c1-4155-8c37-b1d4274d5eb6	JIL-1781354415070-660	Mangante, Jennybel	2002-10-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
b1494af2-61ef-4c64-8019-640e87befa23	JIL-1781354415070-661	Mangcupang, Azelle Ann	1986-07-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
98992d8c-917c-4a8c-a3a2-58b63c542c24	JIL-1781354415070-662	Mangcupang, Rica Jean	1999-05-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4c358040-bab8-4216-8187-b48fe4686029	JIL-1781354415070-665	Manggubat, Jaysibel	2000-10-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
3a9ddcef-ac9a-4423-9f0e-abaa601971d4	JIL-1781354415070-666	Mangubat, Elinita	2002-10-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
f63faa24-57c0-4912-9b95-da2088f1e254	JIL-1781354415070-667	Mangubat, Heizel Mae	1981-03-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4d1f64ad-7b7d-4d67-83b9-e403b61a5c2a	JIL-1781354415070-668	Mangubat, Jiesel	1998-11-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
216e58e3-7e81-4ca3-a87e-19b2c54edfcc	JIL-1781354415070-670	Manlises, Eljay	1985-02-24		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
9cd26246-7949-4c3f-b677-0b2cc5d1e019	JIL-1781354415070-671	Manlises, Ma. Mercedes	2004-03-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
057e63bb-dc9c-4454-a027-5ecf04b6b84d	JIL-1781354415070-672	Manongsong, Pedro	1996-11-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
30ab88c2-d373-4f17-9030-6905e7471bf7	JIL-1781354415070-673	Mansalapuz, John Wayne	2003-06-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2c8c037c-fd75-437c-b7fc-1ef4cd74c0da	JIL-1781354415070-674	Mante, Crystal	1989-08-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
af58af0c-d6cd-4447-9574-8e22a898e184	JIL-1781354415070-675	Mante, Joan	1981-12-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
134b7bd7-ea3c-490a-a509-053b41c32896	JIL-1781354415070-676	Mapacpac, Adrian	1987-04-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0eae82ae-d754-452c-a4fa-f131fb4e3486	JIL-1781354415070-677	Mapacpac, Saturnina	2005-04-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
a9049b20-5f92-43f0-8938-cc275e520b45	JIL-1781354415070-678	Mapacpac, Single	1980-08-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
899faa9e-f718-47dc-a570-5beafb076675	JIL-1781354415070-679	Mapalada, Rizza	2000-12-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
e84c2f58-1660-4406-8d04-db4efacce8d4	JIL-1781354415070-680	Marahan, Mary Joy	2002-04-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
5cfc5d9c-54aa-4c93-b94a-09f9f02ea973	JIL-1781354415070-681	Maranan, Joy	2000-05-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
fe9a1fbc-3cde-4656-af6e-d67a188374e4	JIL-1781354415070-682	Maranan, Ma. Danella	1992-09-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
fd04ef1c-6cc3-4c5e-aae8-63a66ac73b1d	JIL-1781354415070-683	Marasigan, Judy Ann	1998-10-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
98293b94-1d62-47c5-b9c7-1a51c60a2943	JIL-1781354415070-684	Marayan, Erlinda	2002-07-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
4986ea87-3c02-487e-abea-362eda1aa8c1	JIL-1781354415070-685	Marayan, Orlex	1998-04-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b9cf79a5-6160-43c7-839e-23ca2ec78e51	JIL-1781354415070-686	Marayan, Peter	1995-02-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
c8820c7e-9c12-4471-9427-1272df5d0e3a	JIL-1781354415070-687	Marayan, Yssa	1987-01-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
6e15d353-40c1-400e-9deb-859c005d9c2a	JIL-1781354415070-688	Marayan, Yvette	1984-03-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
37251a1a-ec6a-4a88-bd45-2c9f08305b7e	JIL-1781354415070-689	Marayan, Zanji	1996-10-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
e32d7e5e-c667-48ec-98ce-f7145b2f9814	JIL-1781354415070-690	Marciano, Lorena	1981-09-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	\N	Active
5d1fbbd6-a9c1-43b9-9143-f8c374c2d1b3	JIL-1781354415070-691	Marciano, Maricel	1982-05-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	\N	Active
652684da-c3ef-42e4-a9e9-4a1b6f8d0793	JIL-1781354415070-698	Mariposque, Eleanor	2001-06-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
c9dacdab-576e-476f-b707-034a407b4740	JIL-1781354415070-699	Mariposque, Nikko Ivan	2005-08-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
8be1c680-c1b7-4290-82cf-6b1950877c79	JIL-1781354415070-700	Mariposque, Orlando	2001-12-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
12f58574-90e9-49e8-92c3-02d4961e1e19	JIL-1781354415070-701	Marticio, Airene	1987-10-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
edb7487e-8854-400c-b0bd-d2904745641a	JIL-1781354415070-702	Marticio, Angel	1986-09-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4e474a12-2174-4077-a21c-d426e0a37211	JIL-1781354415070-703	Marticio, Jayem	2002-06-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
6173c706-af00-42e4-9e8a-a6cd1d1afb4f	JIL-1781354415070-704	Marticio, Kaycee	1995-10-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4e95393c-b0b6-4b1f-b0de-79042342bfbf	JIL-1781354415070-705	Marticio, Lovely Rose	1989-05-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4466143c-59cf-4fc4-9b18-b9d8df598d58	JIL-1781354415070-706	Marticio, Mark Angelo	1984-05-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0511196f-a868-4cc0-9ae8-b3b1569edb0f	JIL-1781354415070-707	Marticio, May	1985-01-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
dc1ec7c5-daf3-43d8-b410-1ccdbc8944a9	JIL-1781354415070-708	Marticio, Yolanda	1980-12-24		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
e41cb751-2775-4539-b85d-ecbda77b2b11	JIL-1781354415070-709	Martos, James Rowen	1990-04-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
97a5dcdf-c931-4c70-93c7-57cde96fcf33	JIL-1781354415070-710	Martos, Shyrene Joy	1982-08-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
d8239ab7-c788-401e-b7d6-4b0b1fe63ddc	JIL-1781354415070-711	Mascarinan, TJ	1990-04-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
e0efa999-4f9f-4c29-8a2c-0b068e838f93	JIL-1781354415070-712	Mascarinas, Aileen Jane	1980-11-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4f63d456-66aa-4eeb-b1e6-cae2769cbbc3	JIL-1781354415070-713	Mascarinas, Berna	1986-04-24		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
1639423e-b73e-4323-99a0-33f9c484496d	JIL-1781354415070-714	Mascarinas, Carmela	2001-03-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f0a8bfed-9b3e-4b1d-a917-6fb168b6c733	JIL-1781354415070-717	Mascarinas, Edwindo	1997-08-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
22402836-8c15-48de-99a7-ce61781c7c8a	JIL-1781354415070-693	Marinay, Prince Ethan	2016-08-07		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Kids	Main – Pinamalayan	\N	t	\N	Active
81715602-1f4e-4bf2-8843-193354a719c0	JIL-1781354415070-696	Marinay, Princess Yhessa	2004-04-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Main – Pinamalayan	\N	t	\N	Active
a1c43c09-51ba-408e-84c5-63491da2139e	JIL-1781354415070-694	Marinay, Prince Nate	2014-06-23		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Kids	Main – Pinamalayan	\N	t	\N	Active
edf4c2d2-d99a-46c7-bfd5-1103ee1bfc73	JIL-1781354415070-719	Mascarinas, Jewel	2004-04-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
fe51073b-6830-4ec6-bdd0-dfd323fe8773	JIL-1781354415070-720	Mascarinas, Joana Mae	1998-09-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
7708e6c4-2926-4f32-8e5b-c751e3f45a6c	JIL-1781354415070-721	Mascarinas, Josefina	1983-12-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
db2fed6c-55b5-43b7-ae49-24c78c54ae0e	JIL-1781354415070-722	Mascarinas, Joy	1982-01-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
3587a324-491a-4c9c-9233-eb564a5a8053	JIL-1781354415070-723	Mascarinas, Justine	1981-08-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
98a41c87-ba9a-479d-bf4e-92abf63ab43e	JIL-1781354415070-725	Mascarinas, Leny	1982-11-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
5ca79b85-7b1a-4228-bdfe-63f1326ea1b3	JIL-1781354415070-726	Mascarinas, Michael	1998-09-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
98db08c4-c517-458b-b494-dddc1f8dac2b	JIL-1781354415070-727	Mascarinas, Nely	1982-09-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
af2fe4e3-f024-4e6f-a4f1-bf64f3fb99ed	JIL-1781354415070-731	Materiales, Liezel	1983-12-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
47ce33fd-c339-484c-b6e4-222235da2184	JIL-1781354415070-732	Matining, Maribel	1980-01-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
c9ac73c4-2f62-4d14-8d19-b4031358c7f5	JIL-1781354415070-733	Matining, Marites	1994-09-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
32f77ff7-2762-4063-8d2a-0306e89ace94	JIL-1781354415070-734	Maupay, Gileonida	1985-04-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
3bc6d63d-1a6b-4ee3-ac86-6c897810bd86	JIL-1781354415070-735	Mayo, Agustina	1990-03-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
d0f84265-8eac-463a-b3e1-9e65d871a94f	JIL-1781354415070-736	Mayo, Carl	1998-02-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
acc94eee-4149-41dc-a7f6-eafda98728b8	JIL-1781354415070-737	Mayo, Carlos	2002-10-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
ae1a53b1-1b70-43bf-ba34-6f872f65e6cd	JIL-1781354415070-738	Mayo, Dina	1993-10-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
4a4e7695-8595-4038-a4a2-41a9b403ac82	JIL-1781354415070-739	Mayo, Emilita	1995-04-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
d4c69c10-b1ff-4724-90e5-d9a18bff785f	JIL-1781354415070-740	Mayo, King Ivan Carl	1990-06-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
1e3d2669-4c34-4d8e-a642-abcf83e40c85	JIL-1781354415070-741	Mayo, Miguel	1994-05-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
27cc11ba-43f4-4e70-ab4f-44566ba10966	JIL-1781354415070-742	Mayores, Shiela Marie	1997-12-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
5cb1468e-8fdb-4ac2-a164-8bf6f9759100	JIL-1781354415070-743	Mejico, Janita	1994-09-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
e6bd17d8-d0b8-4791-96e8-72695d6a45bb	JIL-1781354415070-744	Mejico, Jelian	2001-07-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
62dd828a-cead-4d4e-ab8b-287b50be1f9a	JIL-1781354415070-745	Mejico, Mariel	1999-02-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
261b74ea-0076-456f-b232-4c5156ed77e4	JIL-1781354415070-746	Mejico, Miguel	1989-12-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0acbf18d-7ed5-4ffd-ab22-0e68f9eea974	JIL-1781354415070-747	Mejico, Nicole	2004-02-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
29358f48-0087-48e8-8dcd-ee0a720adeed	JIL-1781354415070-748	Mejico, Regielyn	1990-02-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
d1a4c1a7-6c81-41d0-a648-34fd0399e4c1	JIL-1781354415070-749	Mejico, Reyjohn	1984-10-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f1ebd80e-c8b4-43fa-ba79-d45aa46b7694	JIL-1781354415070-750	Mejico, Rodmar	1994-09-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
1a2c8b5c-55ff-45a8-98dc-0804be8bce6b	JIL-1781354415070-751	Mejico, Royjohn	1993-12-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2a266992-6b19-4542-bac5-d2684927f485	JIL-1781354415070-752	Mejos, Elinita	2001-09-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
03feeeb7-d52d-407d-878a-77703ac27522	JIL-1781354415070-753	Mejos, Jezzeil	1996-09-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
5fb0b9a3-24ba-49ee-88dc-e11c6c062ee8	JIL-1781354415070-754	Melaya,  Reymark	1992-06-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
d6f87305-89fc-41e9-b43f-07dbca3f091f	JIL-1781354415070-755	Mendeja, Felix	2001-12-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
35022f59-bf82-4d89-b761-0cf88918c156	JIL-1781354415070-756	Mendeja, Mark Allan	1981-09-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2623ed6d-71ab-431d-8a45-c74dab443a48	JIL-1781354415070-715	Mascarinas, Coreta	1990-03-03		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t	Female	Active
ff41e45b-6dbb-4995-b5b7-816c9f3b9e5e	JIL-1781354415070-724	Mascarinas, Lagrimas	1997-10-08		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
8fdc491d-3201-4370-8f61-ab02c43f2836	JIL-1781354415070-757	Mendes, melissa	1984-02-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b41555e1-c24c-46ac-bf2d-cc4264267db9	JIL-1781354415070-760	Mendez, Rica	1988-05-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
6fb06db3-afda-4281-b85b-078733b57176	JIL-1781354415070-761	Mendones, Maricar	1998-11-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ece6111e-c95d-42bc-96ad-3545206e3dc9	JIL-1781354415070-762	Mendones, Mark	2005-01-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
8a3d045c-330c-42d1-aeed-1a16c472bd17	JIL-1781354415070-763	Mendones, Rio	1989-12-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
8808e490-8b3c-44ad-b34c-ab82d85f63f6	JIL-1781354415070-764	Mendones, Roy	1991-08-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
71dfb004-5073-4520-aa74-2173671c2297	JIL-1781354415070-765	Mendones, Ruel	1993-01-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
8c8c04f5-6f0c-4294-9fad-b8c596d14d2c	JIL-1781354415070-766	Mendoza, Apolonia	1996-06-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
a0643883-4b23-41b6-8efb-cb4f4cdb1431	JIL-1781354415070-767	Mendoza, John Razel	1985-03-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
c9bdf41a-1822-40be-8cbc-2b1b71c028c2	JIL-1781354415070-768	Mendoza, Kaycee	1995-04-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
182cbaf7-29a5-4d27-8338-2f1d0a3de4e2	JIL-1781354415070-769	Mendoza, Lea May	1993-02-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
77e0ee2a-f52f-4300-ba7d-119424b8e80a	JIL-1781354415070-770	Mendoza, Menchie	1984-07-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
39e9c72c-38ed-47bb-a33f-69cacbb3fdfc	JIL-1781354415070-771	Mendoza, Menchieta	1995-01-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
038b0a06-f123-415d-b8dc-6e9f76b25e1d	JIL-1781354415070-772	Mendrehe, Mark Allan	1994-09-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
8896fe65-05cd-49cd-bac9-8a79f55bf65b	JIL-1781354415070-774	Menor, Analiza	1983-12-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
352732fb-1850-4d03-a853-8027d3106d03	JIL-1781354415070-775	Menor, Marian	2001-07-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4c5c7b23-6371-4b93-988e-d32481fce845	JIL-1781354415070-776	Menor, Orlando	1987-03-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
03e00184-9d28-4447-acdc-910ac031b3ea	JIL-1781354415070-777	Menorca, Mae	1993-07-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
dd437bde-e12a-454c-905f-5502e805dc74	JIL-1781354415070-778	Menorca, Merla	1997-01-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Luma	\N	t	\N	Active
cbf9f4cb-8e6e-4857-b317-ceb0c9245e79	JIL-1781354415070-779	Menorca, Rainmar	1983-04-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
14fa93e9-9e7b-40bb-82a5-ca585d14ad0a	JIL-1781354415070-780	Mercado, Ivan	1981-09-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
610e4bf0-82bf-4224-b7b2-d84595c7a09d	JIL-1781354415070-781	Mercado, JJ	1995-06-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
8d2a888a-4ea6-4ba9-9288-aee567984c11	JIL-1781354415070-782	Merhan, Francis Jonnel	1994-06-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
35f360e6-f3d5-41d0-85a9-e284253d5269	JIL-1781354415070-783	Merhan, Mariafe	1982-12-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	\N	Active
10a980fd-d1bd-41db-9ada-7e502ed586bc	JIL-1781354415070-784	Merhan, Meljohn	1993-06-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
faaebe4c-24da-48d0-844b-6858dc4f3fcb	JIL-1781354415070-785	Micaya, Alyssa	2004-11-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f89be3ff-f891-4f40-a6af-f212f125da7b	JIL-1781354415070-786	Mindoro, Cecille	1995-03-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
21500335-9c92-46bb-b25b-6b6f041e6c79	JIL-1781354415070-787	Mindoro, Gene	1991-08-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
d450418b-a2fb-4fd2-a020-c6f5090e1bee	JIL-1781354415070-788	Mindoro, Gilxienneun Yhanzzi	1997-07-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
d9c0fb15-525a-4096-93d3-fee92bf65b2c	JIL-1781354415070-789	Mindoro, Jairus Aldred	1990-10-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f76e4d6a-85f2-4f1d-a105-53e8dbc3ec14	JIL-1781354415070-791	Modanza, Peejay	1981-08-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ef6a9cdf-4d06-496c-a52b-1366ec5a0e28	JIL-1781354415070-792	Mogol, Kathlyn	1986-02-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
7a462b37-1394-4846-a6c5-9a8da9609692	JIL-1781354415070-793	Mojico, Ronalyn	1999-07-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
59405e03-07fa-4bac-8243-f56fbe2c8f5d	JIL-1781354415070-794	Mojico, Ruel	1988-08-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Inclanay	\N	t	\N	Active
c745e7ff-d960-4414-87ce-edaf5acfbc35	JIL-1781354415070-795	Mojico, Ruel Ephraim	2002-08-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
1251aeb1-279a-444c-99bf-e9eb01cb6c2d	JIL-1781354415070-796	Mojico, Ruel Joshua	2005-08-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
83cdd176-2388-4440-804e-009f548cb83a	JIL-1781354415070-797	Molato, Avegail	1985-03-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
0a1350d1-1bac-4910-aa10-e927c6ffd5f8	JIL-1781354415070-798	Molato, Brix	1995-04-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
04b3d380-db80-4a34-8d5c-d9aae468b267	JIL-1781354415070-799	Molato, Domenador	1985-04-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Buli	\N	t	\N	Active
16e15968-2dae-43b1-97ca-06a4141ea248	JIL-1781354415070-800	Molato, Eian	1982-02-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
cd184630-588a-440b-89a9-b5756a43704b	JIL-1781354415070-801	Molato, Gian Kyle	2001-07-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
33257c20-3c1e-4645-b98c-bc16fa43105e	JIL-1781354415070-802	Molato, Joseph	1988-03-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
145c9118-800d-411e-bbd9-7cd4b45712bd	JIL-1781354415070-803	Molato, Judelyn	1981-07-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
e163eeb0-8a06-4c62-9616-30893f7d546a	JIL-1781354415070-804	Molato, Lorence	1998-12-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
4a193955-1af9-4b2e-8ab7-e61066ad1d38	JIL-1781354415070-805	Molato, Mark	2001-11-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
45b45bda-72d2-4a93-a8bb-4f3f4e9b04ea	JIL-1781354415070-806	Molato, Sheryll	1982-08-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
d4c3c053-496a-4a70-9fb2-ba21902e4314	JIL-1781354415070-807	Mollo, Jeneth	2000-07-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
45d3bdc4-c5cf-40e8-8e29-021f0921a5d6	JIL-1781354415070-808	Mollo, Jeward	2002-06-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
558fd571-6d9f-4f03-b872-d2f1d5b2ede9	JIL-1781354415070-809	Mollo, Mariel	1987-06-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ca7192ef-1bbb-45ff-bbec-5f514d0060bc	JIL-1781354415070-810	Monleon, Lorie	2000-07-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
cbd008d5-1706-4077-81fb-32685f888248	JIL-1781354415070-811	Monreal, Esmeralda	1984-02-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	\N	Active
5edb9b1e-c08c-4f21-b96d-1faf38a767b3	JIL-1781354415070-812	Monreal, Victor	1982-01-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
c258422e-b53e-4157-917f-60146f75e8fd	JIL-1781354415070-813	Monte, Jessabel	1993-01-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
981fb578-7140-4e36-9780-12a4fb94a6b8	JIL-1781354415070-730	Mascariñas, Zenaida	1978-02-14		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t		Active
72a076f8-c919-4f30-8adc-19710568511d	JIL-1781354415070-758	Mendez, Daisy	1988-01-16		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t	Female	Active
6459d7d0-692d-44f1-86b4-96770d1680cd	JIL-1781354415070-814	Montesa, Bong	2002-03-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
d08e1d98-d51c-4075-b3a1-7a5d56f9680a	JIL-1781354415070-815	Montesa, Maylyn	1983-08-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
c7e8dd6f-6146-4c10-b2d7-5f0791a0417b	JIL-1781354415070-816	Morales, Aldwin	2000-05-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
73daa8a8-e0ba-4976-ae3b-55b1202759d6	JIL-1781354415070-817	Morales, Curt Tyron	1982-02-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
c2acadf4-6c18-4fda-8765-1b72273e1296	JIL-1781354415070-818	Morales, Diomedis	1980-12-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Inclanay	\N	t	\N	Active
660f84cd-ce72-41e2-809a-6c597f4f17c8	JIL-1781354415070-819	Morales, Ezra Mae	1995-06-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
41a1a78d-882a-4ecf-8e8c-fbad21c5590f	JIL-1781354415070-820	Morales, Joey	2004-02-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
1bbac883-a3a5-48c7-8c55-71231308af82	JIL-1781354415070-821	Morales, Mariel	1984-04-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
062e707d-8181-4fa3-85eb-aad8f683b87c	JIL-1781354415070-822	Morales, Nenet	1993-03-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
1324beb6-686d-44f5-86b5-7f3e9988f721	JIL-1781354415070-823	Morales, Rechel Ann	2004-10-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
6de189b4-dd24-4f8a-ad19-a88900fb486a	JIL-1781354415070-824	Morales, Roselie	1983-04-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
e1d28ea6-60c3-4cc4-b269-f0a09353efc0	JIL-1781354415070-825	Morales, Ryan	1985-07-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Inclanay	\N	t	\N	Active
d9e64567-58ef-4040-abba-d8c96a155fce	JIL-1781354415070-826	Moreno, Annie Jose	2004-05-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
a1bf3f04-098a-4559-aeda-d33052a15412	JIL-1781354415070-827	Moreno, Pijay	1999-07-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
d6974898-88de-457b-abee-9a100196fc1d	JIL-1781354415070-837	Morente, Sarah Joy	1995-07-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4b81adca-b168-4754-af8d-a0c57cf5e0d8	JIL-1781354415070-838	Morente, Shemuel	1980-08-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
9cc7ce67-4953-4d90-b538-7f2574a73fbc	JIL-1781354415070-839	Morgado, Emerita	2000-01-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
c6f95373-01d6-438b-85cb-5e241b5d3d50	JIL-1781354415070-840	Morilla, Christopher	1983-02-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
da002026-b19d-453b-9ec0-abb468e6f80d	JIL-1781354415070-841	Morong, Gina	2000-12-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
36874824-c96e-443b-80cc-b6f06d8ded19	JIL-1781354415070-842	Morong, Jojiet	1988-12-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
1b7fd404-2198-454a-9726-827dddf5840d	JIL-1781354415070-843	Motol, Adrian Gabriel	1981-12-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
88da6c70-8325-418f-bae9-b8f2629bd1df	JIL-1781354415070-844	Motol, Rona Althea	1997-08-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b8f67335-c949-4c00-806a-eeb431808f7b	JIL-1781354415070-846	Muje, Ma. Kryzhalen	1989-02-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ab0bf913-adfb-4b80-ab90-04d9390fdd28	JIL-1781354415070-847	Mulawin, Arlene	1991-08-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
d3da7e12-8e72-4fa2-bf91-257dfcda126b	JIL-1781354415070-848	Munat, Mc Gerald	2003-04-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b4fb1331-9f14-4355-abf3-97f78a131dcf	JIL-1781354415070-849	Murillion, Jimboy	2000-02-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
aa7fcff1-bf10-4b40-8014-6bd1a1dab670	JIL-1781354415070-850	Mutya, Jennah Lyza	1993-03-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
09b252d1-1647-41ed-9355-1df346fcbe84	JIL-1781354415070-851	Muyco, Ava Veronica	1988-11-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
c7fc89d4-5d25-4af5-9625-d7159cbc8ff9	JIL-1781354415070-853	Napolitano, Dave Wendell	2005-10-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0a579eb0-39d2-438d-bfc9-147fe8a310fa	JIL-1781354415070-854	Napolitano, Leigh Andrei	1995-06-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
165944be-b42e-40b7-9c1b-f62ef7f48c8f	JIL-1781354415070-855	Napolitano, Mariannette	1980-11-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
cc18a5a9-58d3-4310-a068-5bd1125f5ded	JIL-1781354415070-856	Napolitano, Mary Ann	1996-12-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
40deaad2-a880-4e05-8514-de7d6288e999	JIL-1781354415070-857	Napolitano, Randell	1983-12-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
45019019-0010-4140-a2f8-351ad6f78f17	JIL-1781354415070-858	Napolitano, Venizs	1993-05-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
caf0600d-9def-47e6-bedb-595dd6c76878	JIL-1781354415070-859	Narciso, Emelina	1981-07-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
0be70e2f-1a86-45f6-8a67-ab4e121bd54c	JIL-1781354415070-860	Narciso, Hannah	1997-04-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
bf2e7f24-47b3-4df8-8ba6-dc1ccc770326	JIL-1781354415070-861	Narciso, Israel	1985-11-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
bbf75dc7-3708-4c72-912f-b7b430301a2a	JIL-1781354415070-862	Narciso, Ray	1995-04-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Inclanay	\N	t	\N	Active
bffe684b-f1f6-4619-958f-4648aa82d727	JIL-1781354415070-863	Natal, Avelina	2002-09-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	\N	Active
467034d8-2625-4668-81bd-f3c26b218e81	JIL-1781354415070-864	Natal, Romeo	1998-01-24		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Buli	\N	t	\N	Active
46995ad8-5ab7-4229-990a-508e88209877	JIL-1781354415070-865	Navarro, Chrishiel	1991-06-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2b1eaf84-cd64-4242-90cf-10e3fd2704c4	JIL-1781354415070-866	Navarro, Cristy	1992-08-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
9b53c80f-6562-4f1e-ba0d-a77e5df10729	JIL-1781354415070-867	Neri, Angelica	1983-11-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
bd251cd3-45c8-487c-b84f-84d6892cf96c	JIL-1781354415070-868	Neri, Ariane	1994-05-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
09ba075d-0c90-4da4-9fe6-0e1c8e9d23bc	JIL-1781354415070-869	Nieva, Jun	1996-12-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Buli	\N	t	\N	Active
94fad9ed-48ff-478b-9cb7-90afd79e8af9	JIL-1781354415070-870	Nieva, Nelina	1995-07-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	\N	Active
ae0925d8-0e1c-4fed-9f97-0c992f8ce36e	JIL-1781354415070-871	Nievera, Jairo	2000-09-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
555024d0-c66b-46c4-9f0c-678129bd71c0	JIL-1781354415070-872	Nitural, Jhon Lanbert	1988-09-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
76ac59a5-320d-4000-be35-7c62b1e82b61	JIL-1781354415070-873	Nitural, Melanie	2002-04-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
82f475b4-acf3-4c8a-a348-9999f29e0675	JIL-1781354415070-874	Noblesa, Joshua	1981-06-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
b5457368-9efe-447c-b32a-7c297d8e005e	JIL-1781354415070-875	Obing, Chritopher	1984-10-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ee428307-fa2c-4b02-bf9f-21e006c9341e	JIL-1781354415070-876	Obing, Eizabeth	1992-05-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
ce79c0af-9ce5-46db-ab89-de7369b954a6	JIL-1781354415070-877	Olaso, Angel	1985-02-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
c1d1bf6a-23de-423b-b897-e0bc2faad013	JIL-1781354415070-878	Olaso, Hermilina	2005-09-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Luma	\N	t	\N	Active
289aff10-718a-40b2-adee-92422a682850	JIL-1781354415070-879	Olaso, Jaykim	1989-09-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
aea9d6fb-296e-4bb5-a5f2-69df354d3049	JIL-1781354415070-880	Olaso, Zaijan	2004-05-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
99b1acb2-6ed4-464e-8b0b-7823b8628ea4	JIL-1781354415070-881	Omnes, Christine Mae	1982-11-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
96c4a150-b401-4011-8099-aa076bcd000f	JIL-1781354415070-882	Omnes, Corazon	1991-09-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
c14a7d27-197e-4bfc-92b3-64644dca20e2	JIL-1781354415070-836	Morente, Mila	1983-05-06		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
821500c3-6a71-4153-a00f-520b35332cf6	JIL-1781354415070-884	Ondoy, Leopando	1998-07-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0e3d8e41-21c9-4240-bd19-be2189dd0471	JIL-1781354415070-885	Ondoy, Roman John	1991-08-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
6bb4bcb3-8768-4d68-b49d-9696cfaaccfc	JIL-1781354415070-886	Ondoy, Ronna Marie	1991-12-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
94743bba-51d4-4b33-8645-8534d0ec73c0	JIL-1781354415070-887	Osensao, Roland	1991-07-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
c15d6463-3acc-4969-a81f-ede1aeeee0ed	JIL-1781354415070-888	Osinsao, Aisa	1982-02-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
1135bb4d-73bc-4cde-8dc7-fcd79373a043	JIL-1781354415070-889	Pacres, Reynan	1989-10-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b8c95064-7450-4f08-a62e-89b1882520ab	JIL-1781354415070-890	Padilla, Kate	1989-05-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
f817a6ef-b191-4547-bed8-37a004dac05a	JIL-1781354415070-891	Padilla, Roberto	2001-01-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2a8f836a-7899-42c7-80a8-2ca8ae740be6	JIL-1781354415070-892	Palacio, Analyn	1996-03-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
15a5e493-ac00-4285-8a50-6de6083013f9	JIL-1781354415070-893	Palmero, Analyn	1981-10-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
f3a0c8ab-0960-4e6d-8d8d-13f40018f40e	JIL-1781354415070-894	Palmero, Christine Mae	1991-07-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
409c0b88-9247-48b1-84af-dfde5e20f4e7	JIL-1781354415070-895	Palmero, Elyjane	1995-02-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
a83f3acc-6566-4057-9a85-67a18c8497db	JIL-1781354415070-897	Palmero, Mariel	2001-05-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ac2a3b9c-269a-4cc2-aad8-5ab0a2cec0b9	JIL-1781354415070-898	Palmero, Romel	2002-09-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
87f3de16-c37b-4976-a608-a9defd0c535f	JIL-1781354415070-899	Palmero, Tyriel John Paul	1984-04-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
8446d280-5abc-41a3-a17e-b627892d579f	JIL-1781354415070-900	Palmes, Carlota	1991-06-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4f0a5ff6-9c76-4424-907b-f4f6fe5634b7	JIL-1781354415070-901	Paneba, Melchizedek	1992-08-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4c2f8630-d62e-47e9-93a2-90a84e9ca5af	JIL-1781354415070-902	Paner, Jackilyn	1997-12-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
0299d5b9-f4ab-47b3-ae87-7faddf3fcc05	JIL-1781354415070-903	Paner, John Mark	1994-04-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Buli	\N	t	\N	Active
9980b877-75c6-479d-b18a-cdc812c54140	JIL-1781354415070-904	Panganiban, Mary Joy	1989-03-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
527c8c3f-ca15-40f5-9f0c-54f8c17b8e69	JIL-1781354415070-905	Pastorfide, Daisy	1983-05-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
6add9a8d-0982-4ae9-bf60-0cfb4fa4b05d	JIL-1781354415070-906	Pastorfide, Daniel	2000-05-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
9ec334ae-7f38-42bd-bb17-43bfbd3e8152	JIL-1781354415070-907	Pastorfide, Davesan Christopher	2004-09-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
a4d2b4c9-6d39-4295-a723-e61a504c04aa	JIL-1781354415070-908	Pastorfide, Joy	1982-02-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
fb952558-7aac-4b2c-8838-cb4029b74b44	JIL-1781354415070-909	Pastorfide, Michelle	1984-02-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
23997e63-ca2f-4956-a331-7705ff397ee1	JIL-1781354415070-910	Patyag, Maricris	1981-09-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
8dcea3e8-2bbe-4ff9-b1da-35b22c696556	JIL-1781354415070-911	Paunan, Odessa	1986-06-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2971fffb-8df8-47a1-aabb-eeffe208603a	JIL-1781354415070-912	Paunon, Liwayway	1991-10-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
ffe3f78e-2947-4ea7-85db-8f8ed226129d	JIL-1781354415070-913	Paz, Jerry	1991-03-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4e48bf29-a3fb-4f67-874a-41a2bd0811f3	JIL-1781354415070-914	Paz, Sandrie	1987-09-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
be12ee7d-c89f-45ae-8ebf-2a464736befe	JIL-1781354415070-915	Pelaez, Liza	1994-11-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
66175993-ebe8-4e02-8147-e6e7065f4625	JIL-1781354415070-916	Pelaez, Rakie	1989-05-24		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
e629f492-077b-467a-b489-d734b1624658	JIL-1781354415070-923	Peneba, Claire	2000-06-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
0fee20b9-4562-4e78-bc75-22e2c2b19111	JIL-1781354415070-924	Penoliad, Jedidiah	2003-04-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b08cfe91-5809-471c-b17d-935f32cb06fd	JIL-1781354415070-925	Pestano, Joan	1983-12-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
56bd3c24-c325-4b71-9ba3-b46c68f9026f	JIL-1781354415070-926	Pineda, Lyn Rose	2002-03-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2c66f58a-9059-4d6b-be4a-2c6487cf32d7	JIL-1781354415070-927	Pinon, Alpha Mia	1996-03-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
73009959-e7a6-41f1-93de-226e86f2bd3c	JIL-1781354415070-929	Pinon, Johans	1981-03-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
097cf247-3dac-436a-869d-dd25fbcb832e	JIL-1781354415070-930	Pinon, Randy	1992-08-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
07d1966e-763e-46ad-9061-125c452d9bea	JIL-1781354415070-931	Pontega, Elizabeth	1998-12-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
a06311a7-4d81-463d-a792-5b24b559c01d	JIL-1781354415070-932	Pontega, Prince Gio	2003-11-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
49fbf15d-549c-4aff-9e69-fac8019349de	JIL-1781354415070-933	Quarre, Ashely	1996-03-10		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
26dd8125-1049-49ed-a67c-da6adc6bf396	JIL-1781354415070-928	Pinon, Jezreel	2005-01-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Delisted
a4ae75e8-b8fb-4f40-b30b-2365d8324fd2	JIL-1781354415070-828	Morente, Angel	2000-06-07		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	Female	Active
cd2bfb39-f90a-419d-a24a-da3a98bcc336	JIL-1781354415070-835	Morente, Jocelyn	1980-01-01		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t	Female	Active
37908ad3-6a80-47a2-8747-c71b70c0cc02	JIL-1781354415070-845	Muje, Emma	2005-03-02		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Female	Active
f9809ab5-2414-45c5-91b4-71b1c99675b1	JIL-1781354415070-918	Peñaverde, Haven Josh	2006-07-08		WSAM	\N		8334512f-5979-4cc0-9241-6e3c552e0028	0	2026-06-13 12:40:16.665642+00	Youth	Buli	\N	t	Female	Active
010fd11f-1068-4b72-9f47-333dfb4f8459	JIL-1781354415070-920	Peñaverde, Nicanor	1984-05-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t		Deceased
0b03aa83-217a-41ab-b2a2-b5b82a14cf2c	JIL-1781354415070-922	Peñaverde, Psalm Josh	2008-03-05		WSAM	\N		8334512f-5979-4cc0-9241-6e3c552e0028	0	2026-06-13 12:40:16.665642+00	Youth	Buli	\N	t	Male	Active
eafb16ea-73a6-459d-a296-7a816fc42224	JIL-1781354415070-919	Peñaverde, Marissa	1975-09-09		WSAM/LGAM	\N		8334512f-5979-4cc0-9241-6e3c552e0028	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	Female	Active
235b7af6-39ae-43f0-8211-9d1ee26d14e2	JIL-1781354415070-917	Peñaverde, Cherished Jewel	1983-10-05		WSAM	\N		8334512f-5979-4cc0-9241-6e3c552e0028	0	2026-06-13 12:40:16.665642+00	Women	Buli	\N	t	Female	Active
69b45b3f-1a8b-40d6-928e-3e8f8682542f	JIL-1781354415070-934	Quimora, Cherrylou	1988-07-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b8fdf86e-7eba-44a7-90d3-171e73b2ffca	JIL-1781354415070-935	Quimora, Lorna	1980-05-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
19d08c37-71b6-4d2c-83bb-b7f8dbe59bcf	JIL-1781354415070-936	Rada, Celyn	2002-09-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b677eaa3-eaf4-4e10-bc8e-81787d07f1ac	JIL-1781354415070-937	Ramirez, David	1980-10-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Buli	\N	t	\N	Active
410b94af-2838-4259-8070-f8578c7b1951	JIL-1781354415070-940	Ramos, Mina	1995-07-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Luma	\N	t	\N	Active
eee01634-0d86-475a-b859-c92ba4f5ad07	JIL-1781354415070-941	Rance, Christian Jay	1996-10-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
a1476d38-740d-4e2d-98dc-5a04426fe6a8	JIL-1781354415070-942	Red, Jhon Arvenail	1995-12-09		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
610f6f2f-0432-47b2-9850-e4030c3cb946	JIL-1781354415070-943	Red, Matilde	1987-02-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
6e4ac2ae-ee24-4743-b79e-59473c8e71a5	JIL-1781354415070-944	Red, Sherlock	1987-08-13		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
d3bc2198-1a88-48d7-9d64-0caa01a8aa34	JIL-1781354415070-945	Red, Swerlita	1993-11-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
f6e27530-8783-4c81-a313-93a0aa3f7708	JIL-1781354415070-946	Regala, Jessamae	1988-01-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
d0a2d330-1651-493d-90f9-a6dd88982404	JIL-1781354415070-947	Regencia, Amielyn	1999-09-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
e5dce875-aceb-470b-8c27-52dc7afd58d8	JIL-1781354415070-948	Regencia, Elvie	1996-02-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
26cb090d-9696-4ae0-9bbb-7c9c17ebeb4d	JIL-1781354415070-950	Regencia, Gerald	1981-07-04		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
bb62f9fb-d97f-40be-921d-d52c67f22207	JIL-1781354415070-951	Regencia, Gerry	1984-10-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Inclanay	\N	t	\N	Active
ccd9e008-bd63-4cc2-920a-10a449912db4	JIL-1781354415070-954	Regencia, Jeffrey	1980-09-12		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
98351e61-ee20-4f4f-b551-4654662690d7	JIL-1781354415070-956	Regencia, Lanie	1986-12-24		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
8de04f6e-aee0-4076-81fa-66d26561b208	JIL-1781354415070-958	Regidor, Daniela	1993-12-23		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
5917be18-7d57-4c70-8a02-91fa2155c6e7	JIL-1781354415070-959	Regidor, Diana	2002-12-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
0fe58159-c4df-47b4-bfeb-69e51b8cb1f5	JIL-1781354415070-960	Remo, Khianne	2000-02-07		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4b13ac4d-ae32-4f69-8ab7-62cf93dab062	JIL-1781354415070-961	Reyes, Jayrol	1984-10-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
08d6b150-15b9-4a99-9bae-ae1228a5fd75	JIL-1781354415070-962	Reyes, Jessica	2001-08-22		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
111ea589-47de-493e-a765-b7c7b595a3af	JIL-1781354415070-963	Reyes, Trestan	1982-03-08		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
badc3792-2283-465d-8228-8b9a309aa872	JIL-1781354415070-965	Rieta, Micah Jane	2000-10-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b5b3e41a-a390-41e1-bc50-0e57d2ade67a	JIL-1781354415070-966	Rivera, Edwin	1982-09-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
4d399393-7617-4151-bd05-fe641e7bf4e1	JIL-1781354415070-967	Rivera, Kevin	1980-02-03		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b5834931-9b55-45aa-9587-0af1e4c62a67	JIL-1781354415070-968	Rivera, Liza	1996-04-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
0b4e87ed-d478-46af-abcd-e91f9ea550fb	JIL-1781354415070-969	Rivera, Marivel	1992-01-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
4a350483-cf1e-49b2-8897-278cb7c82e03	JIL-1781354415070-970	Rivera, Ruel	1997-09-16		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
596b665f-a5b0-4955-beb9-9993aadc62d7	JIL-1781354415070-971	Rivera, Wendy	2003-06-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
722d6855-0a8e-489c-8d62-28dab32de109	JIL-1781354415070-972	Rodelia, Imelda	1984-04-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
3b9510e3-9392-4d02-83f8-e4f243ed054f	JIL-1781354415070-973	Rodella, Ermelyn	1992-12-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
6457ceae-e62f-4dab-a321-af1787ec5379	JIL-1781354415070-974	Rodella, Shielyka	1983-09-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
428a92b4-0f16-4265-8987-2d1d2738d6b9	JIL-1781354415070-975	Rodella, Zyriel	1985-12-27		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
d03bafc4-98a0-494f-96a1-890f460535da	JIL-1781354415070-976	Rodellas, Cyjay	1984-10-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
b63ff96d-c4e0-43c7-8519-6a8cde05cc4c	JIL-1781354415070-977	Roderick Olaso	1982-04-19		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Men	Luma	\N	t	\N	Active
6f73bf00-3f08-4268-ad2a-845fc061f4d7	JIL-1781354415070-978	Roderos, Miraflor	2002-03-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
22487ca2-7576-4249-8707-d6fe8701f166	JIL-1781354415070-979	Rodilla, Elsa	1999-11-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
9fcb2611-c23f-4989-aed9-729349ff6f14	JIL-1781354415070-980	Rodilla, Imelda	1999-11-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Inclanay	\N	t	\N	Active
341e7f61-4501-4a22-9815-baa051eeb596	JIL-1781354415070-981	Rodilla, John Robert	1988-03-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
6c3ed9f8-32b6-4e1a-af73-0cdca7706693	JIL-1781354415070-982	Rodilla, Katnisha	2002-12-26		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
845bd614-5664-4dbf-a4d1-35c0a08b4954	JIL-1781354415070-983	Rodilla, Krisha Mae	1986-06-25		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
2c672e9a-d244-4046-9a93-9b5dfe077cfa	JIL-1781354415070-984	Rodilla, Yves Jerome	1985-10-02		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
9f6b5da8-e410-4df5-8870-2963d26584ba	JIL-1781354415070-985	Rodriguez, Emie	1998-12-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
c00fe3e2-a488-4e44-91c5-8821fca2a16a	JIL-1781354415070-986	Rodriguez, Johnrick Nino	1982-11-01		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
161c4b98-f5b1-4ebd-bd74-72d3199fee94	JIL-1781354415070-987	Rogelio, Marvie Ann	1996-01-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
096a693b-2edb-486c-8e7e-8240ed64c36c	JIL-1781354415070-988	Romero, John Carlo	1984-10-15		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
2fc7a5cf-643e-427f-a0fb-4a194b8a607e	JIL-1781354415070-989	Sabas, Elaiza	1982-02-21		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
ffb986e6-edba-499a-a8df-6469b090cfda	JIL-1781354415070-990	Sabida, Criselda	1991-03-20		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Luma	\N	t	\N	Active
c480fef0-ad12-4485-80b9-81c7a0c5a53f	JIL-1781354415070-991	Sabida, Nelia	1989-08-28		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Luma	\N	t	\N	Active
bf813e1a-9b5e-41f8-86c4-75d495fcb9ab	JIL-1781354415070-992	Sadim, Clark	1988-05-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
a46110ff-4634-45a8-b60a-68dabc046483	JIL-1781354415070-993	Sadim, Mark Angelo	1988-02-06		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
15473380-816d-42a3-a058-e876140357ad	JIL-1781354415070-955	Regencia, Jerwel	1998-03-16		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
6ec7263c-a505-4951-a6f6-fa1464265ef5	JIL-1781354415070-995	Sadiwa, Rowena	2001-02-17		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
9dcf1265-8843-494b-a1a7-b5507cb9be7a	JIL-1781354415070-996	Sadiwa, Zhandy	1988-02-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
969f2aec-7a06-444b-a590-26ea15cd998c	JIL-1781354415070-964	Reyes, Tristan R.	2011-10-25		WSAM	\N		2a691c85-40e4-459a-b66b-a87671906296	0	2026-06-13 12:40:16.665642+00	Youth	Inclanay	\N	t	Male	Active
c3014355-08e8-4077-ac92-0de257ecb0f6	JIL-1781354415070-997	Sael, Judy Ann	1999-09-18		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Inclanay	\N	t	\N	Active
685a69e9-c16d-40e5-ba51-a9a33d427eeb	JIL-1781354415070-998	Saez, Editha Miciano	1999-12-14		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Women	Sta. Rita	\N	t	\N	Active
9a2eb7d2-2f7b-4d3d-b69f-a70d54c172d4	JIL-1781354415070-999	Saez, Joerge Emmanuel	1982-06-05		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Kids	Sta. Rita	\N	t	\N	Active
6fa7b76c-2566-4e21-901d-10ce5d2d31a3	JIL-1781953871370976	Mary Dane Yray	2010-11-22		WSAM	\N		\N	0	2026-06-20 11:11:11.356389+00	Youth	Main – Pinamalayan	\N	t	\N	Active
9a1cdb26-a48d-4074-a40f-a36ebf8008f6	JIL-1781354415070-692	Marinay, Marites	1976-07-08		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t	\N	Active
da0466b1-3893-4d09-9ade-84eb9b772635	JIL-1781354415069-15	Adonay, John Emman	2007-04-13		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
c8dbd94b-75e5-4056-8722-ab8619969d71	JIL-1781354415069-65	Bacay, King Carlos	1982-11-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Sta. Rita	\N	f	\N	Active
92a0a1ea-976c-403d-bf2b-eda30baaae6b	JIL-1782004112914155	Embate, Jimmy	1969-09-28		WSAM	\N		\N	10	2026-06-21 01:08:33.750599+00	Men	Main – Pinamalayan	\N	t	\N	Active
920c3e54-d15a-4bc9-b473-b418808970e7	JIL-1781354415069-231	Del Prado, Daryl	2001-11-09		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
1c014f38-d865-4c35-b2b5-7d6b0710485d	JIL-1781354415069-269	Fallorna, Mary Joy	2002-06-10		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	\N	Active
de3555be-b25b-4866-82df-050c1ca41e41	JIL-1781354415069-326	Gonzales, Anamae	1985-01-01		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Kids	Buli	\N	t	\N	Active
768d6ccb-43e3-4b23-86b4-d5b072908fed	JIL-1781354415069-334	Gonzales, Rosalie	1966-05-17		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
f3658219-0cfb-4ac3-8031-34cfe7bc2bba	JIL-1781354415069-421	Landoy, Michael	1993-12-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
ef63311b-6261-4671-93f7-0df7cf9bcfb4	JIL-1781354415069-439	Lanot, Joy	1988-10-15		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
0d78caf4-93bf-4598-bef4-56453c351843	JIL-1781354415069-442	Lanot, Olivia	2002-04-12		WSAM	\N		\N	0	2026-06-13 12:40:15.893971+00	Women	Sta. Rita	\N	f	\N	Active
f8bd29d9-d6ba-4d45-9738-de6b78066ba1	JIL-1781354415069-283	Fiedalan, Estelita	1962-10-23		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
64cbb814-aea5-4a81-a9d4-1fa772dfc6c2	JIL-1782003147574480	Fiedalan, Liberty	1961-12-03		WSAM	\N		\N	10	2026-06-21 00:52:27.987269+00	Senior	Main – Pinamalayan	\N	t	\N	Active
303136e7-9583-4e37-9ffb-f749cda18e6a	JIL-1782003617345217	Mascarinas, Rosalie	\N		WSAM	\N		\N	0	2026-06-21 01:00:18.186433+00	Women	Main – Pinamalayan	\N	t	\N	Active
6ca43bf0-36dd-4aff-b0f6-d3197376644a	JIL-1781354415070-1016	Salazar, Genevieve	1986-03-27		WSAM	\N		\N	10	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
1f8077c5-af7c-4350-8430-9f032722b8bd	JIL-1781354415070-1090	Tuerto, Pacencia	1994-05-04		WSAM	\N		\N	10	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
285d9d80-cfc9-405b-8310-d84710d2e8b5	JIL-1781354415069-128	Calidguid, George Victor	1972-02-22	Marfranciso, Pinamalayan	WSAM	\N	Ptra. Ethel Fiedalan	\N	10	2026-06-13 12:40:15.893971+00	Men	Main – Pinamalayan	\N	t	\N	Active
20eee381-1cde-474b-9d46-2a38571b0bed	JIL-1781354415069-533	Maaño, Adam Qiji Lei	2013-02-04		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	\N	Active
e5d58456-5987-45f2-ac79-43aebca0e275	JIL-1781354415070-1002	Saguid, Jerald	2003-12-18		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
b49e892a-f724-41a5-b534-72eef3cca323	JIL-1781354415070-1003	Sagundo, Bea	1994-02-27		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
6c5db9ec-3fab-4708-b8ed-f7bacc4c64f8	JIL-1781354415070-1004	Sagundo, Beverlyn	1991-12-03		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
fc679ff3-7d1e-4802-bb87-176b3774deed	JIL-1781354415070-1005	Sagundo, Cyrel Joy	1985-03-01		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
4df44b9c-ef7d-4843-bfb3-a9798fd1f353	JIL-1781354415070-1006	Sagundo, Cyrene Jane	1988-02-11		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
4a15d773-f0a7-4eec-a665-c315b3cba296	JIL-1781354415070-1007	Sagundo, Fatima	2002-01-05		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
9b01146b-970b-49e8-8ad2-e761f227d364	JIL-1781354415070-1008	Sagundo, Kimberly	2002-03-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
e5c6c350-4b2f-4f28-9a98-011e513f1583	JIL-1781354415069-168	Causapin, Daniel	1954-07-29	Juan Luna, Pinamalayan	WSAM	\N	Ptra. Ethel Fiedalan	\N	20	2026-06-13 12:40:15.893971+00	Senior	Main – Pinamalayan	\N	t	\N	Active
c13c4cd0-9b1c-41dc-a586-c0bc45cd5981	JIL-1781354415069-553	Magcamit, Glenda	1985-01-22		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t	Female	Active
ceec8411-7036-45f9-8df9-f13db0601590	JIL-1781969937544671	Sigue, Charisse Joselle S.	2005-10-02		WSAM	\N		\N	20	2026-06-20 15:38:57.924948+00	Youth	Main – Pinamalayan	\N	t	\N	Active
38e7a7c8-1d38-4a24-aecb-a96173ff1aec	JIL-1781354415069-599	Malabay, Rodolfo	1966-03-12		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:16.665642+00	Senior	Main – Pinamalayan	\N	t	Male	Active
7124a3ab-dee2-4949-856a-6606e9cb3fe5	JIL-1781354415069-537	Maaño, Leonar	1977-07-28		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Men	Main – Pinamalayan	\N	t	Male	Active
e4333720-3c25-427b-92a8-b6d3a7eb6a9d	JIL-1781354415070-896	Palmero, Jaspher	2009-01-07		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	Male	Active
17c66a47-97ba-466a-966b-fe4d96d369a0	JIL-1781354415069-379	Jimenez, Efraim	2004-08-21		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	Male	Active
02ef26bb-ae4e-4573-8ee9-6e3f8772afe2	JIL-1781970025201405	Villanueva, Wyl Amram T.	2011-11-07		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-20 15:40:25.192815+00	Youth	Main – Pinamalayan	\N	t		Active
a1377609-e9be-4217-9b95-8514a51c84ec	JIL-1782003468487403	Manjares, Carmensita	1978-03-14		WSAM	\N		\N	20	2026-06-21 00:57:48.585421+00	Women	Main – Pinamalayan	\N	t	\N	Active
66803bd3-d447-42f3-89fa-87eaed56d6a4	JIL-1781354415070-953	Regencia, Jeanitha	1972-04-09		WSAM	\N		\N	20	2026-06-13 12:40:16.665642+00	Women	Main – Pinamalayan	\N	t	\N	Active
e7519785-a169-436d-8bcc-07ddaa90769a	JIL-1781354415069-105	Bolanos, Mark Leo	1990-08-27		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
7d050ab6-9019-4425-bc0c-552dc0eff256	JIL-1781354415070-829	Morente, Bienvenido	1970-02-21		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Men	Main – Pinamalayan	\N	t	Male	Active
a974878e-ee1c-4c6b-816e-4073e32f7d14	JIL-1781354415069-138	Camacho, Donavel	1993-08-15		WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Women	Main – Pinamalayan	\N	t	\N	Active
0e6428b9-396e-4936-9d84-cac17f8241f8	JIL-1781953629792784	Falculan, Caleb Joshua	2006-06-29		WSAM	\N		\N	20	2026-06-20 11:07:09.688306+00	Youth	Main – Pinamalayan	\N	t	\N	Active
10e98a1d-539c-40e6-ac71-4bf4ab0bb029	JIL-1781354415069-127	Calidguid, David James C.	2011-05-14		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	Male	Active
480cd97b-4cc6-45ce-b004-9f08bf8a4650	JIL-1781354415069-400	Lafuente, Daniel	1995-04-01		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Young Adult	Main – Pinamalayan	\N	t	Male	Active
4319944f-03e5-4a57-9722-180364fad573	JIL-1781354415070-1045	Sapul, Luisito	1971-12-17		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:17.307634+00	Men	Main – Pinamalayan	\N	t	Male	Active
a8a9c3b1-e52c-4789-a093-0c5a94381d13	JIL-1781354415070-1109	Villanueva, Willy	1982-06-16		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:17.307634+00	Men	Main – Pinamalayan	\N	t	Male	Active
12e0ef3b-eeaa-4873-990d-f99b893a758c	JIL-1781953500678455	Villanueva, Wyl Malakhi	2014-08-12		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-20 11:05:00.440232+00	Youth	Main – Pinamalayan	\N	t	Male	Active
19ff118e-130a-45a6-8546-4904f543082b	JIL-1781354415070-1009	Sagundo, Lea Mae	1988-02-16		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
ac9d4252-714d-4268-aa2c-bddf2c38705f	JIL-1781354415070-1010	Sagundo, Loryn	1991-06-03		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
87c7a413-529d-4a05-b2db-ac026e7700b3	JIL-1781354415070-1011	Salamat, Christian	1985-06-16		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
9267f16f-bdad-44a5-8f2e-e5787ef97c3c	JIL-1781354415070-1012	Salamat, Erica	1986-04-21		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
7efe8188-54ab-4a67-9a6b-4cd06b720973	JIL-1781354415070-1013	Salazar, Carol	1995-09-23		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
9b3e9075-05ce-47dc-be5f-2c145e9bfd71	JIL-1781354415070-1014	Salazar, Cora	2002-08-23		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
572281d2-8e71-47ed-b971-515181b1d010	JIL-1781354415070-1015	Salazar, Floreza	1984-05-03		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
2aa75723-219f-4bdc-b4c0-bf26d99950f4	JIL-1781354415070-1018	Salazar, John Cedrick	1985-09-23		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
c29c100d-c648-4a06-b5b5-5d68f1553f8a	JIL-1781354415070-1019	Salazar, Monie	2000-02-15		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
339b3bd8-6aea-46fc-9361-3652fdff9017	JIL-1781354415070-1022	Sales, A-Jay	1985-03-27		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
1475bfec-1b98-4d1d-babb-17dbce23ab1e	JIL-1781354415070-1023	Sallutan, John Alexis	1984-05-23		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
fd9a0a66-a0cf-4607-9d1d-1e8e85885bd9	JIL-1781354415070-1024	Sallutan, Lalyn	1984-12-06		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
2816f52c-7fdc-4812-b6d0-af42364e234f	JIL-1781354415070-1025	Sallutan, Lexter	1981-02-08		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
30a1e0c2-35f9-46d9-9495-99546495ff07	JIL-1781354415070-1026	Sallutan, Lucibel	2005-04-02		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
9e3900ca-b23e-4ba2-9316-fd3834ebb968	JIL-1781354415070-1027	Sallutan, Maria Erica	2005-06-08		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
668070a8-ec17-4eda-aba1-d8f512895387	JIL-1781354415070-1028	Sallutan, Mary Jane	2000-12-03		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
19c4995c-6476-4c2d-b3ae-b4f19d95cf01	JIL-1781354415070-1029	Sallutan, Rhea	1980-01-11		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
4335de45-2ea4-4154-9b66-34a10c95f639	JIL-1781354415070-1030	Salva, John Paul	2005-04-18		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Inclanay	\N	t	\N	Active
1cf373a5-3aef-4cf3-8a01-fb8a7853ad92	JIL-1781354415070-1031	Salva, Miah	1998-10-01		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Inclanay	\N	t	\N	Active
c2cd545b-64f0-4b7a-9ce7-85451733a629	JIL-1781354415070-1032	Salvacion, Anica	1992-02-03		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
8e2d9eec-ea9f-4434-91de-55312faad259	JIL-1781354415070-1033	Salvacion, Bea	1980-03-07		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
9e11d1d8-2705-4e1f-a47a-828c1bfe29b1	JIL-1781354415070-1034	Salvacion, Cyril Methodius	1994-05-25		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
5dd9eb40-a4db-4d7e-8adb-82c4979e6c7a	JIL-1781354415070-1035	Salvacion, Reign Heart	1988-11-06		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
ae3d9a91-7046-4b55-a897-42504b314f6d	JIL-1781354415070-1036	Salvacion, Rezel Villamor	1994-12-03		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
a66e75ea-14c9-4e79-b713-b950a11bdcb6	JIL-1781354415070-1037	Sanchez, Caira Faith	1996-07-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
416b460f-6396-49f3-b7e4-d4d5ca31a273	JIL-1781354415070-1038	Sanchez, Kate Ericka	1991-02-22		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
461a45c7-3302-49e5-a4a7-4f7912a47de1	JIL-1781354415070-1039	Sanchez, Morena	1988-04-22		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
eae3024d-19e7-4569-afc3-3596c562a0b6	JIL-1781354415070-1040	Sandoval, Louis Jane	2005-08-01		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
c1944863-6ada-4219-b4e9-4d94002916bc	JIL-1781354415070-1041	Santos, April	2002-09-19		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
73cae09e-b85b-47e1-8092-54335f2a9096	JIL-1781354415070-1042	Sapul, Flordeliza	1989-05-19		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
c5fd2802-3ff3-4706-88e8-33c910b91155	JIL-1781354415070-1043	Sapul, Lance	1980-05-22		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
8fa30dc5-156e-4796-910a-ed75cf08b5b9	JIL-1781354415070-1044	Sapul, Lorilyn	2005-09-25		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
c31a3bd0-9866-4dd8-a582-a332aa996e9c	JIL-1781354415070-1046	Sapungan, Aleah Mae	2001-05-20		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
a6db0e23-250b-4d96-8027-984518ace086	JIL-1781354415070-1047	Sapungan, Gwendolyn	1981-02-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
99948543-6075-4c44-b892-9d66544c4418	JIL-1781354415070-1048	Savalbaro, Maribeth	2002-08-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
472b95b2-dfe6-43d5-beb3-b006b3c73317	JIL-1781354415070-1049	Seco, Ofelia	1989-08-28		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
cd38fe06-95c3-48f1-b061-7bfeabb61cd4	JIL-1781354415070-1050	Sena,  Princess Racquel	1986-02-09		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
c922f54b-fd65-42fb-9f58-90e3d00c0869	JIL-1781354415070-1051	Sena, Edelyn	1988-09-28		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
9c74cf3c-d8b0-40cf-9a32-25e4f8ef15e2	JIL-1781354415070-1052	Sena, Heart Angel	1980-06-21		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
a61df852-f0ba-4c63-9dcd-011366565e52	JIL-1781354415070-1053	Seno, Cielo	1986-06-07		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
4f401096-3595-431e-bd9d-ce3b3725a0da	JIL-1781354415070-1054	Seno, Ethan	1982-05-16		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
4266ec51-58e4-4486-afbe-f13d24ff2210	JIL-1781354415070-1020	Salazar, Pablo Jr	1968-07-28		WSAM	\N		\N	10	2026-06-13 12:40:17.307634+00	Men	Main – Pinamalayan	\N	t	\N	Active
5213c3b3-0bda-41e2-9627-fedcc57e4063	JIL-1781354415070-1056	Seno, Maricar	1981-02-10		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
0916200f-29a1-4471-adac-8b221df927cc	JIL-1781354415070-1057	Sibulan, Jenifer	1997-02-21		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
2150dc53-c886-4cf6-aa64-66f4816f6bc9	JIL-1781354415070-1058	Silanga, Jericho	1985-07-22		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
0f1e231c-8b12-44fa-b87d-adf265766b4e	JIL-1781354415070-1059	Silanga, Mark Daniel	2001-10-16		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
7bedc415-f8e4-4b93-9b70-d7ae4ca871b0	JIL-1781354415070-1060	Silvano, John Kevin	1986-01-05		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
2ec109d8-f4b3-4c00-8e9e-f1be8f757783	JIL-1781354415070-1061	Silvano, Mercy	1994-02-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
de37d132-e94d-45e6-bd75-c7463c8d1dcf	JIL-1781354415070-1062	Sino, Lilibeth	1994-11-12		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
520509ec-348b-4879-9be8-ac422071ddff	JIL-1781354415070-1063	Sino, Romel	1996-06-07		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
f797ad32-dea3-45d7-b733-2aab3da6a8d0	JIL-1781354415070-1064	Sison, Pio Angelo	1988-06-17		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
5a4ab35d-e1ca-476f-a82b-28c0011bd39a	JIL-1781354415070-1065	Solas, Emil	1993-04-13		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Men	Sta. Rita	\N	t	\N	Active
4b6ada8f-c413-4f54-833b-884ef8e34cef	JIL-1781354415070-1066	Solis, Brenda	1996-01-23		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
7a79b8a9-2827-4a9f-ba76-7da0d2fbcf24	JIL-1781354415070-1067	Solis, Roxanne	1987-10-04		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
24729a64-82e6-4707-b848-e52828d5d0cf	JIL-1781354415070-1021	Salazar, Zion Reign	1989-11-19		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:17.307634+00	Women	Main – Pinamalayan	\N	t	Female	Active
84c1f3a8-1c79-47db-ba07-0ce4872bb8f3	JIL-1781354415070-1068	Sore, Louisa	2005-01-05		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
0951f5dc-62d6-467d-9a0b-c30f52d4d7e8	JIL-1781354415070-1069	Sore, Sheila	2005-06-27		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
9ea2d326-01c6-4d36-8ec2-181fcefc673a	JIL-1781354415070-1070	Sosa, Anafe	1990-01-13		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
348384ee-8ae3-4ff9-bdfd-bddae3b17122	JIL-1781354415070-1071	Sosa, Azel	2002-06-11		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
32df3922-6c94-482f-a650-4443b5f4a834	JIL-1781354415070-1072	Sosa, Mark Daniel	1981-03-24		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
bc367131-927e-42ce-bf5a-54e851f41ac7	JIL-1781354415070-1073	Sotta, Angel Mae	2005-12-23		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
eb44730f-1331-4162-9963-6b1055174c7d	JIL-1781354415070-1074	Sotta, Emelia	1997-04-02		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
7d38a22f-f270-4838-8b6f-5ada47abcc31	JIL-1781354415070-1075	Sotta, Raymond	2000-06-08		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Men	Sta. Rita	\N	t	\N	Active
ba9b404b-6770-4eb9-b45e-4fb31deaaffe	JIL-1781354415070-1076	Sotta, Ryan	1995-12-12		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
04368f92-621f-4dbb-9058-16f298a3bd2a	JIL-1781354415070-1077	Sotto, Mia	1986-04-24		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
58faa6fb-bea0-438d-ba26-2480ef5577fb	JIL-1781354415070-1078	Sotto, Rosedelle	2000-07-18		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Buli	\N	t	\N	Active
99e87aab-c666-49d9-95ad-a0c70213352c	JIL-1781354415070-1079	Tara-tara, Felicidad	1992-01-03		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Buli	\N	t	\N	Active
3c826cab-a1fd-4b4c-9a76-f02488dd1bb3	JIL-1781354415070-1080	Tawatao, Frinchsis	1980-11-27		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Inclanay	\N	t	\N	Active
7b8f2b6e-62d7-4241-be35-fa68de4e63c5	JIL-1781354415070-1081	Tawatao, Randle	1990-12-01		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Inclanay	\N	t	\N	Active
2bc3375c-3ca0-4b34-a7f4-66c41528121e	JIL-1781354415070-1082	Tawatao, Zarah	2000-04-08		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Inclanay	\N	t	\N	Active
2df8bd22-d2c3-442a-85d0-fc303fb753e6	JIL-1781354415070-1083	Tejada, Wilma	1998-06-19		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
9b8214b4-7b07-43b7-8d78-c3652e615b1e	JIL-1781354415070-1084	Teloza, Jamahlyn	2005-05-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
9ec82987-3613-46d8-8324-20220ed0f1cb	JIL-1781354415070-1085	Teodoro, Merly	1989-09-23		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
af92723c-e1c1-4e03-97d8-105736090300	JIL-1781354415070-1086	Tolentino, Kaye Mariz	1996-03-14		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
d51317a7-6bcf-4459-9c8c-df96174ec72e	JIL-1781354415070-1087	Tolentino, Nimfa	2002-01-27		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
7bb8c59e-040d-4e8b-ac8b-6c43ae5ba1f0	JIL-1781354415070-1091	Tunog, Jenielyn	1982-05-08		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
6d502259-3674-41c7-be96-60ce3abdbfb9	JIL-1781354415070-1092	Umbao, Jervin	2003-04-08		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
321d562c-4a76-499b-b5ee-be6c34d4e1fc	JIL-1781354415070-1093	Umbao, Marilou	1994-08-10		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
bb0486de-dd56-46ef-ad38-45bd70628d1d	JIL-1781354415070-1095	Untalan, Christian	1996-09-19		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
2cc5b013-6283-480a-8355-5edcdd890f85	JIL-1781354415070-1096	Untalan, Ian James	1996-09-09		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
3e7bb212-71e3-4523-834c-7297c57071a2	JIL-1781354415070-1097	Untalan, Jun	1996-12-14		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Men	Sta. Rita	\N	t	\N	Active
121a51f3-c86e-4b76-a44a-ae1a865d38b7	JIL-1781354415070-1098	Untalan, Noemi	2003-06-14		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
919873ff-def3-4b54-a6e6-a034d624a075	JIL-1781354415070-1101	Villamarin, Ayessa	1984-11-13		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
34cebee8-08eb-4b3e-80dd-6ff37f02d331	JIL-1781354415070-1102	Villamarin, Bernard	2000-06-06		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
6d7cef8c-8254-47d2-af01-04b0dbfa9d9d	JIL-1781354415070-1103	Villamarin, Jasmin	2002-04-02		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
eed5768b-0a2f-4588-936c-7033f89a5535	JIL-1781354415070-1104	Villamarin, Jeffrey	1996-07-12		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
743c687a-d154-47ec-9f35-6e240c0b3939	JIL-1781354415070-1105	Villamarin, Mark Jhayden	1981-08-08		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
8653c91f-d993-4258-89d4-d96b1044ff32	JIL-1781354415070-1106	Villamena, Vicente	2003-05-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Men	Sta. Rita	\N	t	\N	Active
f00e6bb4-ecf6-464e-9c59-c039601994f2	JIL-1781354415070-1088	Tuerto, Fely	1982-04-08		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	f	\N	Active
82e491b7-deca-4a63-8204-66368e7fbb01	JIL-1781354415070-1099	Villaluna, Irish Faith	2002-03-25		WSAM	\N		\N	10	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
e61253d5-41ca-404b-ac3e-a2b01e6a8032	JIL-1781354415070-1100	Villaluna, Mary Grace	1977-12-08		WSAM	\N		\N	10	2026-06-13 12:40:17.307634+00	Women	Main – Pinamalayan	\N	t	\N	Active
13cb5533-d46a-4b85-9ada-786dd8eaab73	JIL-1781354415070-1116	Villena, Gleniel	1986-09-12		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
077fd276-3b59-4f80-8c73-bae42165b628	JIL-1781354415070-1117	Villena, Marriane	1985-07-27		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
2f142571-4a4a-4052-9811-c6c87b614379	JIL-1781354415070-1118	Villena, Ruel	1989-11-17		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
3c4b3f45-125e-4690-a9c8-bcbadd39d1ef	JIL-1781354415070-1119	Villena, Shenalyn	2004-10-05		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
d3934121-dd32-4434-9f47-6b6bc1a610d5	JIL-1781354415070-1120	Villeza, Ana	2003-04-27		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
d9fc34d8-f4e8-4452-bccc-b9418c427c51	JIL-1781354415070-1121	Villeza, Rod	1995-01-17		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Men	Sta. Rita	\N	t	\N	Active
66deff18-95a5-4487-ba23-c35d69877570	JIL-1781354415070-1122	Vinas, Carmelita	2000-11-17		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Inclanay	\N	t	\N	Active
db04447f-a00c-4c1a-bdf9-e3a8fb5af9c6	JIL-1781354415070-1123	Vinzon, Beatriz	1981-08-17		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
52f99a9a-eeee-4b6f-888a-337a44b69fa0	JIL-1781354415070-1124	Vinzon, Dezsa Krishenlae	1989-07-20		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
fa20b2fb-b613-4cb8-8139-e7c553052c42	JIL-1781354415070-1125	Virtucio, Elizabeth	2001-06-01		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
df25c7ea-da45-477f-abcc-dbe72faa9386	JIL-1781354415070-1126	Virtucio, Jake	1987-12-19		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
e16b99c0-bdb4-4833-bfb8-b6c278f2d266	JIL-1781354415070-1127	Vitto, Gemma	1989-11-16		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Inclanay	\N	t	\N	Active
430b8072-525d-4f9b-b703-d6490293d366	JIL-1781354415070-1128	Vitto, Jennifer	1983-06-22		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
5269fe55-2f16-4e54-ac3d-037fe2b01282	JIL-1781354415070-1129	Vitto, Khaye	1997-08-02		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
acaf2498-2b42-4127-a457-df6c2c7701a5	JIL-1781354415070-1131	Watiwat, Aleah Katrina	1988-05-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
fb7a935c-276d-4a4f-9727-f6a6ae708e8d	JIL-1781354415070-1107	Villanueva, Aibeth	1985-06-30		WSAM	\N		\N	20	2026-06-13 12:40:17.307634+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
ba7f28be-f218-44e9-95be-50fd032ca17d	JIL-1781354415070-1130	Watiwat, Adriel James	1982-04-21		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Delisted
2027bb82-e3b9-4405-907a-33b0f1205906	JIL-1781354415070-1132	Watiwat, Ana Grace	1995-03-12		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Delisted
1e31aa0e-86cd-407a-ab1d-b227a7f43fcc	JIL-1781354415070-1108	Villanueva, Ullypa	1983-03-28		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:17.307634+00	Women	Main – Pinamalayan	\N	t	Female	Active
c13b6b21-cd6f-4781-8689-b4c19280bc2b	JIL-1781354415070-1134	Watiwat, Angelo	1988-11-27		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
9fb6d6e6-d2ec-460c-97f8-da1bfca4fbb0	JIL-1781354415070-1135	Watiwat, Corazon	2003-01-23		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
3b56ab4f-e97d-4a5b-a15a-00d80f614da9	JIL-1781354415070-1136	Watiwat, Creselda	2002-12-20		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
d54b3de4-7685-47f0-b4bf-18e2fc959cc8	JIL-1781354415070-1138	Watiwat, Rhea Mae	1998-09-11		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
0059f8af-cdab-4f5b-8561-1b5b7e34ca27	JIL-1781354415070-1139	Yap, Fe	1997-04-04		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
63c1a186-4c52-434f-9424-04c9a1c87d09	JIL-1781354415070-1140	Yray, Erlinda	1988-03-19		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
921f6ac3-13f6-4a4e-925f-9dfa051064fb	JIL-1781354415070-1141	Yray, Mary Dane	1996-03-13		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
e6f89acf-5528-4aac-a2ba-7b2cc35957f8	JIL-1781354415070-1142	Zoleta, Ecel Ann	2000-04-02		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
e0e76c7f-452d-43cb-abeb-b650fafab0ac	JIL-1781354415070-1143	Zoleta, Kimberly	1999-06-14		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
e59115fe-9da7-4bd1-bf9e-07b791ced060	JIL-1781354415070-1144	Zoleta, Lerma	1993-04-09		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
fe2bd979-b0c8-417a-a4df-e8f0cc8d84e3	JIL-1781354415070-1145	Zoleta, Liwayway	1990-03-12		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
4a7e064c-e347-4b66-a2a4-690973049992	JIL-1781354415070-1146	Zoleta, Lovegen	1996-01-21		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
5be6f61a-607c-40ef-ad76-78f7eeeab0e5	JIL-1781354415070-1147	Zoleta, Mac Alexander	1991-09-26		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
33ec7324-1128-46df-93f8-09e0e97117bc	JIL-1781354415070-1148	Zoleta, Melflor	1985-05-04		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
5df41acc-d1cb-4db1-9fbf-02a630205feb	JIL-1781354415070-1149	Zoleta, Norvel	1982-08-04		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
9ff38524-69df-4c16-a467-d0770925e628	JIL-1781354415070-1150	Zoleta, Vergel	2002-03-19		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Kids	Sta. Rita	\N	t	\N	Active
f317fdca-a9b1-4356-a464-7a41728644d6	JIL-1781354415070-1151	Zollner, Agustina	1985-04-16		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Active
010165e9-2c36-4e06-aed6-3f7a548d93be	JIL-1781354415069-380	Jimenez, Erwin	1974-04-05	Jaena, Pinamalayan	WSAM	\N		\N	10	2026-06-13 12:40:15.893971+00	Men	Main – Pinamalayan	\N	t	\N	Active
7293eb16-166e-41eb-b939-fba5192332e8	JIL-1781354415070-728	Mascarinas, Silvestre	1967-01-21		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
6f69e8b5-4f73-4ebc-a3bd-0a4462870bbc	JIL-1781354415070-952	Regencia, Henry	1972-05-29		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Men	Sta. Rita	\N	t	\N	Active
a52004f2-2bc7-409a-b09d-6b9f66550648	JIL-1782008826012988	Lozada, Richard	1997-05-01		WSAM	\N		\N	10	2026-06-21 02:27:05.661037+00	Men	Main – Pinamalayan	\N	t	\N	Active
4d648f7d-4745-457e-b0d8-0e8a0dff331d	JIL-1782009132949740	Dela Cruz, Ayessa	\N		WSAM	\N		\N	10	2026-06-21 02:32:12.460651+00	Youth	Main – Pinamalayan	\N	t	\N	Active
25729cc6-db38-4342-9bda-2fe1fd5d5279	JIL-1782009178667789	Fajutagna, Aira	2008-03-26		WSAM	\N		\N	10	2026-06-21 02:32:58.286602+00	Youth	Main – Pinamalayan	\N	t	\N	Active
08496ade-6c10-4623-b70d-c67d531c5f4a	JIL-1782009237668113	Fajutagana, Ierene	2009-07-16		WSAM	\N		\N	10	2026-06-21 02:33:57.058588+00	Youth	Main – Pinamalayan	\N	t	\N	Active
f0e50ead-69b0-41ba-9bd2-f4800fea7072	JIL-1782011343990214	Espiritu, Alfrey	\N		WSAM	\N		\N	10	2026-06-21 03:09:03.376825+00	Kids	Main – Pinamalayan	\N	t	\N	Active
7cf9e15a-42d8-473d-884f-a3fe10bb64b9	JIL-1782009311937679	Falculan, Trisha Mae	2001-07-06		WSAM	\N		\N	10	2026-06-21 02:35:11.238063+00	Youth	Main – Pinamalayan	\N	t	\N	Active
34b2a69d-8173-4da5-a053-bf6dc5db01f0	JIL-1782009376997813	Fegal, Maria Elena	\N		WSAM	\N		\N	10	2026-06-21 02:36:16.273439+00	Youth	Main – Pinamalayan	\N	t	\N	Active
e25732ca-6445-46ab-a726-94bceb349e7f	JIL-1782009411155466	Galang, Edlyn	\N		WSAM	\N		\N	10	2026-06-21 02:36:50.431619+00	Youth	Main – Pinamalayan	\N	t	\N	Active
2b14e5c3-9164-4794-a4a1-037446d22488	JIL-1782009439992575	Guerra, Edralyn	\N		WSAM	\N		\N	10	2026-06-21 02:37:19.229443+00	Youth	Main – Pinamalayan	\N	t	\N	Active
0ea3de17-fac4-444b-af39-37a68c7e17e5	JIL-1782009651098743	Sapallo, Phil	2003-03-28		WSAM	\N		\N	0	2026-06-21 02:40:50.615324+00	Youth	Main – Pinamalayan	\N	t	\N	Active
6466176a-45c5-48ef-a6d4-c1bcf68023b5	JIL-1781354415070-790	Regencia, Keith Venice M.	1991-08-14		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
3db467e0-9e46-4b17-99d2-3eb1bf00526a	JIL-1781354415070-832	Morente, Hannah Kate	2001-11-16		WSAM	\N		\N	10	2026-06-13 12:40:16.665642+00	Youth	Main – Pinamalayan	\N	t	\N	Active
1c800bfb-5bc1-4f0e-93f8-d6cc75411182	JIL-1782011002090837	Abdon, Precious Keren Zshauna	2021-03-27		WSAM	\N		\N	10	2026-06-21 03:03:21.904921+00	Kids	Main – Pinamalayan	\N	t	\N	Active
f6259078-04af-442c-b1b0-5f95aa2c26da	JIL-1782011131436690	Bolaños, Marianne Elyana Zephany	2021-06-20		WSAM	\N		\N	10	2026-06-21 03:05:31.103337+00	Kids	Main – Pinamalayan	\N	t	\N	Active
49c2aa15-4a1f-4f25-9421-455436d3880c	JIL-1782011219847363	Calidgud, Heart C.	2019-02-14		WSAM	\N		\N	0	2026-06-21 03:06:59.202085+00	Kids	Main – Pinamalayan	\N	t	\N	Active
a0bbb937-07ac-4235-b0ce-ca9d38e6b9e7	JIL-1782011294451912	Caringal, Charles	\N		WSAM	\N		\N	10	2026-06-21 03:08:13.897712+00	Kids	Main – Pinamalayan	\N	t	\N	Active
fcce3ece-fb6c-498a-b95b-e883bcc44935	JIL-1782011422649563	Magcamit, Deolinda	\N		WSAM	\N		\N	10	2026-06-21 03:10:22.031999+00	Kids	Main – Pinamalayan	\N	t	\N	Active
ec7fde3e-b530-4199-87ed-6d6f64359301	JIL-1782011494971674	Morente, Genesis	2017-08-03		WSAM	\N		\N	10	2026-06-21 03:11:34.661483+00	Kids	Main – Pinamalayan	\N	t	\N	Active
b53621c9-2b60-4fb8-ba67-26dee55d5956	JIL-1782011649061453	Regencia, Viera	2016-03-29		WSAM	\N		\N	10	2026-06-21 03:14:08.507368+00	Kids	Main – Pinamalayan	\N	t	\N	Active
2af9861a-ae3f-4b2d-b672-f0b5f95d350a	JIL-1781953699519653	Caringal, Jesther Carl Daniel	2012-07-29		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-20 11:08:19.328369+00	Youth	Main – Pinamalayan	\N	t	Female	Active
78a6ec34-6f53-4e8d-8f94-c0706ba96a1b	JIL-1781354415070-1137	Watiwat, Jesus	1982-03-11		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Men	Sta. Rita	\N	t	\N	Deceased
37a3403a-6d49-4703-b78f-416c732e7e1f	JIL-1781354415069-256	Espiritu, Arnel	1980-09-01		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:15.893971+00	Men	Main – Pinamalayan	\N	t	Male	Active
6caf31bd-d0fa-4167-a332-fa43d1ed44ca	JIL-1782008900729584	Maaño, Emilio	\N		WSAM	\N		\N	20	2026-06-21 02:28:20.019319+00	Senior	Main – Pinamalayan	\N	t	\N	Active
814624a8-bbb4-477b-a3b3-160286cbecad	JIL-1782009912827619	Morente, Marimar	1996-06-21		WSAM	\N		\N	20	2026-06-21 02:45:12.504037+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
869a19cd-f071-4034-9142-3e6d122e2409	JIL-1782010034964375	Morente, Sheena	1996-01-12		WSAM	\N		\N	20	2026-06-21 02:47:14.678409+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
59539988-c0cf-4119-978c-976b6a4bce9c	JIL-1782010920846381	Embate, Charmaine	\N		WSAM	\N		\N	20	2026-06-21 03:02:00.351782+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
9785feec-4480-42af-baf8-8a9233610652	JIL-1782010726475698	Magcamit, Kenneth	\N		WSAM	\N		\N	20	2026-06-21 02:58:45.834495+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
0abac385-1ba2-4706-a584-9e856f745018	JIL-1781354415069-0	Abarientos, Elma May	2007-05-15		WSAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	10	2026-06-13 12:40:15.893971+00	Youth	Main – Pinamalayan	\N	t	Female	Active
305e0e7d-c403-4ab9-863e-0d1546bebd7d	JIL-1781354415070-1133	Watiwat, Analiza	1986-09-22		WSAM	\N		\N	0	2026-06-13 12:40:17.307634+00	Women	Sta. Rita	\N	t	\N	Delisted
5996dedd-c7d5-4bd8-83c7-f297507355d1	JIL-1781964126598230	David, Zabdiel Kent Jarence M.	2012-02-14		WSAM	\N		\N	20	2026-06-20 14:02:06.815814+00	Youth	Main – Pinamalayan	\N	t	\N	Active
a7449003-7672-457c-853d-2b391dc7a37f	JIL-1781354415070-716	Mascarinas, Edwin	1973-04-26		WSAM/LGAM	\N		e319ab92-b31d-4512-9126-0a12a86b69bc	20	2026-06-13 12:40:16.665642+00	Men	Main – Pinamalayan	\N	t	Male	Active
15543fd3-3bd4-4d88-9d30-2b2b4420cb2f	JIL-1782011698255611	Regencia, Zaiden Keoon	\N		WSAM	\N		\N	10	2026-06-21 03:14:57.62654+00	Kids	Main – Pinamalayan	\N	t	\N	Active
ee192999-176b-42c7-b3d6-c2c616dd9ec2	JIL-1782011770027494	Sosa, Alexa Mia	2021-10-29		WSAM	\N		\N	10	2026-06-21 03:16:09.421293+00	Kids	Main – Pinamalayan	\N	t	\N	Active
f43be6e8-0ab7-4d33-8a36-66a4037daa00	JIL-1782011919915715	Villanueva, Wyl Elijah	2014-08-12		WSAM	\N		\N	10	2026-06-21 03:18:39.307768+00	Kids	Main – Pinamalayan	\N	t	\N	Active
2306de94-3fb2-4f6c-b94d-be835e7f2c35	JIL-178201202747666	Linga, Bernadeth	\N		WSAM	\N		\N	10	2026-06-21 03:20:27.074104+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
229b6adb-6b77-43ff-aaa9-a611efb86e51	JIL-1782012063491730	Metin, Kristian	\N		WSAM	\N		\N	10	2026-06-21 03:21:02.762556+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
d08248db-ffac-4fc7-8f97-5dd314cf949e	JIL-1781354415070-695	Escal, Princess Mhonezz M.	1996-05-11		WSAM	\N		\N	0	2026-06-13 12:40:16.665642+00	Young Adult	Main – Pinamalayan	\N	t	\N	Active
63a62e01-2145-4beb-a3a0-1ba81785b030	JIL-1782609670133395	Salvilla, Mark	2000-06-03		WSAM	\N		\N	10	2026-06-28 01:21:11.440378+00	Young Adult	Main – Pinamalayan	\N	t	Male	Active
99785ae3-8d0e-45f7-aa2e-a5cf9628adca	JIL-1782010311480323	Sapallo, Nhielross	1997-01-09		WSAM	\N		\N	20	2026-06-21 02:51:51.093308+00	Young Adult	Main – Pinamalayan	\N	t	Male	Active
\.


--
-- Data for Name: monthly_theme; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.monthly_theme (id, image_url, updated_at, color) FROM stdin;
1	https://abcgwffjvmlnhrbmiqzu.supabase.co/storage/v1/object/public/theme/theme-1784778731006.jpg	2026-07-23 03:52:12.723+00	#D3C5AC
\.


--
-- Data for Name: prayer_prays; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prayer_prays (id, prayer_request_id, member_id, created_at) FROM stdin;
ef2c5aa4-2240-4c94-8b3d-0e7817319aee	3ee8c385-002e-41ac-9bd6-d5c2f9d90a9a	480cd97b-4cc6-45ce-b004-9f08bf8a4650	2026-06-26 01:27:15.716927
dfd46444-59c8-47cd-90b5-6efd5b034c7f	3ee8c385-002e-41ac-9bd6-d5c2f9d90a9a	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	2026-06-26 01:28:22.596036
36d407b4-47bf-4af5-8ad5-41ffbd2d74ab	d9496624-2848-45be-b3e8-928c415df619	480cd97b-4cc6-45ce-b004-9f08bf8a4650	2026-06-26 01:30:02.624155
e98431d6-619d-49fa-ae76-726f6030d1d1	d9496624-2848-45be-b3e8-928c415df619	b69e0d20-e229-4210-807f-35119377abe6	2026-06-30 10:28:16.964609
\.


--
-- Data for Name: prayer_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prayer_requests (id, member_id, title, description, category, is_anonymous, status, prayer_count, created_at, expires_at, updated_at, branch_id) FROM stdin;
3ee8c385-002e-41ac-9bd6-d5c2f9d90a9a	b69e0d20-e229-4210-807f-35119377abe6	world problem	peace all over the world	General	f	approved	2	2026-06-25 17:02:59.190075	2026-07-25 17:02:59.190075	2026-06-25 17:02:59.190075	e319ab92-b31d-4512-9126-0a12a86b69bc
d9496624-2848-45be-b3e8-928c415df619	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Healing Galing	Healing galing para sa may sakit	Health	t	approved	1	2026-06-26 01:29:30.872258	2026-07-26 01:29:30.872258	2026-06-26 01:29:30.872258	e319ab92-b31d-4512-9126-0a12a86b69bc
477186ab-0434-490e-bb49-4d63ddccb07b	d43a30df-92b6-42c2-ab80-ea060627c64d	family problem	sample family problem	Family	f	approved	0	2026-06-29 13:14:16.024232	2026-07-29 13:14:16.024232	2026-06-29 13:14:16.024232	4cd1ac72-0cc2-44fd-82c5-95576ad2bf75
\.


--
-- Data for Name: prayer_responses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prayer_responses (id, prayer_request_id, member_id, message, is_prayer, created_at) FROM stdin;
55fc274a-72ff-4317-8b7f-b5f186d4a37a	3ee8c385-002e-41ac-9bd6-d5c2f9d90a9a	480cd97b-4cc6-45ce-b004-9f08bf8a4650	Peace be with you!	f	2026-06-26 01:27:39.883847
e375b3ec-c601-4324-9b07-d6fd3cde55b4	3ee8c385-002e-41ac-9bd6-d5c2f9d90a9a	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	Peace be with you, too!	f	2026-06-26 01:28:45.504415
cbb7eec5-2ea0-4b80-8858-1c31bb51aa7f	d9496624-2848-45be-b3e8-928c415df619	480cd97b-4cc6-45ce-b004-9f08bf8a4650	Heal! Be Healed!	f	2026-06-26 01:30:19.588486
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profiles (id, name, role, branch_id, member_id, created_at, username, theme_color) FROM stdin;
bf6f048d-6397-4560-acdb-19cb222b8269	mobilelegendmythic7@gmail.com	superadmin	e319ab92-b31d-4512-9126-0a12a86b69bc	0e97dc12-046f-4b6d-9883-8651dd436ce0	2026-06-13 09:12:33.47541+00	salvillahg	blue
3e5f53d0-e288-45fe-9c17-92754472fb29	abdonnoli@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	b69e0d20-e229-4210-807f-35119377abe6	2026-06-15 09:39:15.100031+00	abdonn	blue
1af0ee3d-05ac-45d6-a163-57f2066f6d55	adoyocesar@gmail.com	regular	f11d4448-78f2-4d19-b3dd-487735deca7a	fc69a073-d6e9-41d7-986c-4d45447a4eba	2026-06-16 04:01:25.482746+00	adoyoc	blue
3287ff5f-24b9-48d2-a4f5-0851151df4f0	danielslafuente@gmail.com	admin	e319ab92-b31d-4512-9126-0a12a86b69bc	480cd97b-4cc6-45ce-b004-9f08bf8a4650	2026-06-14 14:34:21.104167+00	lafuented	blue
bb62da18-fc10-41be-82c6-a611226b2212	villanuevawilly@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	a8a9c3b1-e52c-4789-a093-0c5a94381d13	2026-06-26 09:40:22.531613+00	willy.v	blue
9acdd0f1-06b0-4b19-9620-f59a4f2bca30	villanuevaullypa@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	1e31aa0e-86cd-407a-ab1d-b227a7f43fcc	2026-06-26 09:28:23.96959+00	ullypa.v	blue
253edc87-ffa5-477f-83eb-85da0940ae9f	zebedeeabdon@gmail.com	superadmin	e319ab92-b31d-4512-9126-0a12a86b69bc	ba914fb8-8ab0-4265-a508-9c99c8b8a9e0	2026-06-14 08:25:57.5385+00	abdonz	blue
2c9f909e-35ec-466b-a24d-30e9a2e5ec53	villanuevaelijah@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	f43be6e8-0ab7-4d33-8a36-66a4037daa00	2026-06-26 10:01:45.711296+00	elijah.vw	blue
da847a0a-eaad-4d0b-9e55-027e0b7cefde	abeljohnmark@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	c4f53bf9-d840-4f43-a1b3-aa31dbf39123	2026-06-26 10:08:38.349721+00	mark.aj	blue
39bbabfc-9ff5-4e56-8d34-7e60f72712b9	adonayemily@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	d92cd0b6-fc32-4c68-8d04-6ba88b242e38	2026-06-26 10:10:35.949869+00	emily.a	blue
5ac943a1-6abd-4a2a-98b5-6e595a43837d	bautistaaida@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	dd694bbb-e505-4258-8fae-aa1a49b101ee	2026-06-26 10:21:37.361758+00	bautista,.a	blue
de5cfeb0-925b-48a4-a188-1a610ba87047	arriolajandee@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	0e815bd0-3ccc-4969-b9b1-c071501beb75	2026-06-26 10:27:08.057414+00	arriola.j	blue
5e92f942-00c9-4694-a992-f6f8493ad06d	bajandecoreenjoy@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	c7aac336-7263-436a-b37b-7814db6835a6	2026-06-26 10:34:33.78734+00	bajande.cj	blue
c6ce9dda-3c52-4f7b-9876-f3b113a0a441	adoyomaamor@gmail.com	regular	4cd1ac72-0cc2-44fd-82c5-95576ad2bf75	466481c7-b1dd-405b-9fb6-2772cc535b0c	2026-06-29 13:38:52.638564+00	adoyo.ma	blue
1801f3bc-0a0b-43d9-94b1-e0514f27d38a	nholliea006@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	b69e0d20-e229-4210-807f-35119377abe6	2026-07-03 04:16:45.175701+00	abdon.n	blue
6c3c168f-ee29-4acb-9760-4cb802db727e	jinkykay006@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	cbe8fc96-165f-4b41-ab04-ed496f567496	2026-07-04 13:06:40.298859+00	abdon.a	blue
341f3b46-8f81-4db4-9e83-c6c77c23abbc	gracezephbolanos@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	1d3bc4c0-0e4f-4fdc-955b-31382fd3d120	2026-07-04 13:10:16.670287+00	bolaños.ga	blue
a4d291ad-9480-4d62-ad61-ad95d1fe5f26	zabdiel.david14@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	5996dedd-c7d5-4bd8-83c7-f297507355d1	2026-07-05 00:23:59.901614+00	david.zkjm	blue
7209d01b-1cec-4de4-bf98-517b3405d68e	charissejosellesg@gmail.com	regular	\N	ceec8411-7036-45f9-8df9-f13db0601590	2026-07-05 00:34:56.745084+00	sigue.cjs	blue
e9b2a1fd-bf6c-4bbb-ba75-414932663b5d	gideonmasc@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	a7449003-7672-457c-853d-2b391dc7a37f	2026-07-05 08:03:47.755845+00	mascarinas.e	blue
991ecb04-59f0-4ea0-b653-4de004b572b2	gwynethdorothymagcamit3@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	2fc913ba-e354-4f8b-8c97-1b6c988d241e	2026-07-05 08:14:40.779642+00	magcamit.gd	blue
704ffd7e-85cc-4121-ab38-13a124b29aa5	dan094232@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	6ef7bee6-7cba-46a7-ad34-cce842e3eeff	2026-07-05 08:18:18.65409+00	camacho.dpm	blue
a470f357-9ae7-4655-b675-2b463e0b1374	jesthercaringal@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	2af9861a-ae3f-4b2d-b672-f0b5f95d350a	2026-07-05 08:22:12.559678+00	caringal.jcd	blue
d9b5a9d8-a21d-4b0d-bedd-cd13de3d8816	jethrocaringal@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	48a80a3f-1a4f-4260-839e-25008b15a463	2026-07-05 08:24:29.565044+00	caringal.jcd2	blue
27f4313b-a23d-4ab9-8705-16ddbb3d33a2	calidguiddavid@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	10e98a1d-539c-40e6-ac71-4bf4ab0bb029	2026-07-05 08:26:21.597703+00	calidguid.djc	blue
f697573a-9cd9-44be-a3ca-9c8de8c86377	reanneilao@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	0e220e0b-794c-4a15-bee2-23d04d8300f1	2026-07-05 09:32:36.120977+00	ilao.r	blue
b04bf73c-6ae9-408d-a8e7-b783d4efc1a7	regenciatristan87@gmail.com	regular	2a691c85-40e4-459a-b66b-a87671906296	969f2aec-7a06-444b-a590-26ea15cd998c	2026-07-05 09:34:22.551783+00	reyes.tr	blue
834c21d2-c954-4d25-967d-ea608f36cda0	penaverdehavenjosh@gmail.com	regular	8334512f-5979-4cc0-9241-6e3c552e0028	f9809ab5-2414-45c5-91b4-71b1c99675b1	2026-07-05 09:35:52.305435+00	peñaverde.hj	blue
9858c180-9eac-4c23-9a66-21593301c142	palmerojaspher@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	e4333720-3c25-427b-92a8-b6d3a7eb6a9d	2026-07-05 09:40:23.193716+00	palmero.j	blue
08679fae-f4ea-46e4-877c-4fc509bce66e	amramvillanueva@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	02ef26bb-ae4e-4573-8ee9-6e3f8772afe2	2026-07-05 09:22:41.855068+00	villanueva.wat	blue
08b84fab-3d1f-478b-8cc3-58584746f8d3	penaverdepsalmjosh@gmail.com	regular	8334512f-5979-4cc0-9241-6e3c552e0028	0b03aa83-217a-41ab-b2a2-b5b82a14cf2c	2026-07-05 09:30:41.55362+00	peñaverde.pj	blue
16571d05-3777-45e1-819a-20bbd9358f48	angelmorentep@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	a4ae75e8-b8fb-4f40-b30b-2365d8324fd2	2026-07-05 09:43:21.196656+00	morente.a	blue
056957bc-47ac-461a-9a73-7b8a1863d0b5	jireeh0306@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	c0e6de1a-ceef-43f0-9bf2-4861b047aace	2026-07-05 09:45:32.673603+00	salazar.j	blue
31faae60-b91d-4bae-99a8-51edf6c939a8	gilbertmangante@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	f2c66819-74a2-4288-8512-8935a069c4fe	2026-07-05 13:16:19.244457+00	mangante.g	blue
3da69563-ecc2-457b-b608-c2b16b4fb712	rosebellemagturo@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	443daf66-0c24-42a3-8a00-12ee4538d1b8	2026-07-05 13:19:34.267761+00	magturo.pr	blue
f05f56f8-93d7-4af3-9c67-d33cac2f3a75	mlumague566@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	90c2cf00-edc1-408d-a89c-9c28e4697f8d	2026-07-05 13:24:07.440229+00	lumague.md	blue
99d25b56-8054-4cc7-9000-ed0b3a01a359	magcamitgaddiel@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	0b70a942-3407-4808-9e0c-31751812a11b	2026-07-05 13:27:59.035162+00	magcamit.g	blue
aeacc657-6e9b-444b-b52a-10b4f9a62715	rhitsaresya@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	6ae59089-32a5-4145-bfb3-b1ad463bf22b	2026-07-05 13:31:29.818306+00	jarabe.tg	blue
4863bb41-c8a8-4c16-af1c-5aead378ddc1	wylmalakhiv@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	12e0ef3b-eeaa-4873-990d-f99b893a758c	2026-07-05 13:34:11.358536+00	villanueva.wm	blue
922a40c0-b382-4e86-8871-26611aa68b0c	ivanrodil308@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	d8b86085-f8ac-4315-b05b-83aa26a1cce6	2026-07-05 13:38:36.416716+00	rodil.cis	blue
289c35fb-751e-4ac8-8060-22be4d001ccc	genevievesalazar@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	6ca43bf0-36dd-4aff-b0f6-d3197376644a	2026-07-05 14:02:16.844688+00	salazar.g	blue
6d75a29b-b271-4af3-b658-449fc06a2169	zenfavor2018@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	981fb578-7140-4e36-9780-12a4fb94a6b8	2026-07-05 14:04:27.570373+00	mascarinas.z	blue
16184f27-1940-4d9e-b0c6-7f8a7f340897	glendamagcamit@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	c13c4cd0-9b1c-41dc-a586-c0bc45cd5981	2026-07-05 14:07:57.904096+00	magcamit.g2	blue
e4010c82-5c16-4584-a288-8c33c382c78d	angelleprecious.penaverde@gmail.com	regular	8334512f-5979-4cc0-9241-6e3c552e0028	f70d6460-84d6-4dcb-83aa-eb26e1d5a478	2026-07-05 14:10:48.933833+00	peñaverde.pa	blue
f1c79b67-86b5-48dc-a6f6-38100bf6aaf2	marissapenaverde@gmail.com	regular	8334512f-5979-4cc0-9241-6e3c552e0028	eafb16ea-73a6-459d-a296-7a816fc42224	2026-07-05 14:15:32.336051+00	peñaverde.m	blue
94f26f23-2e6b-418b-851a-34c651e5f24b	ullypavillanueva@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	1e31aa0e-86cd-407a-ab1d-b227a7f43fcc	2026-07-05 14:16:43.17492+00	villanueva.u	blue
3fa4e9d8-f744-47ae-bb5b-e2f69135cd26	pulis_villa16@yahoo.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	a8a9c3b1-e52c-4789-a093-0c5a94381d13	2026-07-05 14:19:47.660495+00	villanueva.w	blue
34bbfe8b-37f9-437d-aa1a-74bdd6870433	ricky111585@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	638160ab-dcb6-43d7-a417-3ecfcabbacd4	2026-07-05 14:22:45.563281+00	malangis.r	blue
8fc730c3-044d-48c9-b542-22c23753e989	luissapul@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	4319944f-03e5-4a57-9722-180364fad573	2026-07-05 14:29:44.701654+00	sapul.l	blue
b5f12c36-b5d2-48fd-9dbc-d3e51e1ee93c	shezkynicole@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	7913742e-1132-4f39-90a9-9a456e53df8f	2026-07-05 14:32:14.276427+00	calidguid.s	blue
6ef45081-88a6-4713-92f9-5bf033668d06	jeffrey.david06pirates@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	e855a73b-e58b-41ed-819d-b95cea314837	2026-07-05 14:33:51.993795+00	david.j	blue
0da9d57e-0e51-48f0-bd1c-a9ccbde207c2	anaflorence@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	566c3572-7f46-403c-900f-c8ee777efc37	2026-07-05 14:35:09.501353+00	david.af	blue
fafc7719-006b-4ba4-816a-e7dee6f52401	amielynregencia@gmil.com	regular	2a691c85-40e4-459a-b66b-a87671906296	d0a2d330-1651-493d-90f9-a6dd88982404	2026-07-05 14:52:25.546283+00	regencia.a	blue
5d1b41a2-c4cd-4e03-94e8-b18c36f20c21	antonetteladeras@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	a1f44ce3-e752-4be4-8f0e-a7c45bffcc17	2026-07-05 14:53:16.228384+00	laderas.a	blue
f05dc39a-27e3-4358-bffe-df2d3306e39d	avamarie@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	587d80e4-9544-4d0e-b4f6-8d70c4f94339	2026-07-05 14:53:57.051462+00	maaño.am	blue
51c278c7-985f-43ad-b1a1-6511d4774d2d	danreb@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	16eaf18a-e99c-4530-aaec-8a6e96b99cdb	2026-07-05 14:54:36.846263+00	camacho.d	blue
a8fb11be-ee5e-4bfa-9363-bbe391bf7ab6	efraimjimenez821@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	17c66a47-97ba-466a-966b-fe4d96d369a0	2026-07-05 14:55:37.20648+00	jimenez.e	blue
7eb706a0-bf7a-4398-b7df-b0857cec9668	jrmorente@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	355fd0db-83cd-4e20-9d44-7efe8e9ac2cd	2026-07-05 14:56:15.187395+00	morente.gj	blue
92927591-a31a-4d9b-a828-67f78a367005	gracev@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	e61253d5-41ca-404b-ac3e-a2b01e6a8032	2026-07-05 14:56:52.158756+00	villaluna.mg	blue
b5d78d9c-162c-46f6-9479-9a3359d65f56	jeanethr@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	66803bd3-d447-42f3-89fa-87eaed56d6a4	2026-07-05 14:57:55.677535+00	regencia.j	blue
2798911c-e175-4b2a-8d9a-7ca4cdae816b	jienela@gmail.com	regular	f11d4448-78f2-4d19-b3dd-487735deca7a	d64d1327-555b-4e79-9ff6-162f0298ae38	2026-07-05 14:58:33.57782+00	asuncion.j	blue
b6f736c7-1275-4edf-847f-dbae85526ba9	thessmalabay@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	82e44072-b750-4c63-9da4-3605604f8731	2026-07-05 14:59:36.779664+00	malabay.t	blue
18f725da-689b-4512-ae57-0e7996e3b930	zions@gmail.com	regular	e319ab92-b31d-4512-9126-0a12a86b69bc	24729a64-82e6-4707-b848-e52828d5d0cf	2026-07-05 15:00:16.461651+00	salazar.zr	blue
2a81452d-3ab7-4578-9438-bed90045ff84	yoheroscholar2@gmail.com	admin	4cd1ac72-0cc2-44fd-82c5-95576ad2bf75	d43a30df-92b6-42c2-ab80-ea060627c64d	2026-06-17 04:21:57.557242+00	malabaya	blue
\.


--
-- Data for Name: service_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_events (id, event, date, "time", branch, expiry, is_active, created_at) FROM stdin;
1	Sunday Worship Service	2026-06-15	01:20:00	Main – Pinamalayan	2026-06-14 17:21:00+00	f	2026-06-14 17:19:42.687498+00
3	Sunday Worship Service	2026-06-15	12:53:00	Main – Pinamalayan	2026-06-15 04:59:00+00	f	2026-06-15 04:53:35.455547+00
4	Sunday Worship Service	2026-06-15	15:51:00	Main – Pinamalayan	2026-06-15 07:59:00+00	f	2026-06-15 07:49:27.03326+00
5	Sunday Worship Service	2026-06-15	16:00:00	Main – Pinamalayan	2026-06-15 10:59:00+00	f	2026-06-15 08:00:45.727582+00
6	Sunday Worship Service	2026-06-16	12:04:00	Main – Pinamalayan	2026-06-16 10:59:00+00	f	2026-06-16 04:03:58.128206+00
2	Sunday Worship Service	2026-06-15	01:33:00	Main – Pinamalayan	2026-06-16 16:00:00+00	f	2026-06-14 17:31:07.334627+00
7	Sunday Worship Service	2026-06-18	09:33:00	Main – Pinamalayan	2026-06-18 16:00:00+00	f	2026-06-18 01:30:28.575652+00
8	Sunday Worship Service	2026-06-18	22:33:00	Main – Pinamalayan	2026-06-18 15:00:00+00	f	2026-06-18 14:24:09.24344+00
9	Saturday Practice	2026-06-20	16:30:00	Main – Pinamalayan	2026-06-20 12:00:00+00	f	2026-06-20 10:33:09.111906+00
10	Sunday Service	2026-06-21	07:30:00	Main – Pinamalayan	2026-06-21 03:00:00+00	f	2026-06-21 00:36:39.747306+00
11	Sunday Service	2026-06-28	07:30:00	Main – Pinamalayan	2026-06-21 03:00:00+00	f	2026-06-28 00:36:59.176477+00
12	Sunday Service	2026-06-28	07:30:00	Main – Pinamalayan	2026-06-21 03:00:00+00	f	2026-06-28 00:37:14.624458+00
13	Sunday Service	2026-06-28	07:30:00	Main – Pinamalayan	2026-06-21 03:00:00+00	f	2026-06-28 00:37:27.599999+00
14	Sunday Service	2026-06-28	07:30:00	Main – Pinamalayan	2026-06-21 03:00:00+00	f	2026-06-28 00:37:32.999619+00
15	Sunday Service	2026-06-28	07:30:00	Main – Pinamalayan	2026-06-21 03:00:00+00	f	2026-06-28 00:37:47.494913+00
16	Sunday Service	2026-06-28	07:30:00	Main – Pinamalayan	2026-06-21 03:00:00+00	f	2026-06-28 00:38:18.700468+00
17	Sunday Service	2026-06-28	07:30:00	Main – Pinamalayan	2026-06-28 03:00:00+00	f	2026-06-28 00:41:07.511757+00
18	Sunday Service	2026-07-05	07:30:00	Main – Pinamalayan	2026-06-28 03:00:00+00	f	2026-07-05 00:36:47.368244+00
19	Sunday Service	2026-07-05	07:30:00	Main – Pinamalayan	2026-07-05 03:00:00+00	t	2026-07-05 00:37:25.881056+00
\.


--
-- Name: announcement_reactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.announcement_reactions_id_seq', 27, true);


--
-- Name: announcements_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.announcements_id_seq', 11, true);


--
-- Name: birthday_greetings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.birthday_greetings_id_seq', 14, true);


--
-- Name: event_reactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.event_reactions_id_seq', 30, true);


--
-- Name: events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.events_id_seq', 15, true);


--
-- Name: service_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_events_id_seq', 19, true);


--
-- Name: announcement_reactions announcement_reactions_announcement_id_member_id_emoji_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcement_reactions
    ADD CONSTRAINT announcement_reactions_announcement_id_member_id_emoji_key UNIQUE (announcement_id, member_id, emoji);


--
-- Name: announcement_reactions announcement_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcement_reactions
    ADD CONSTRAINT announcement_reactions_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (key);


--
-- Name: attendance attendance_member_id_service_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_member_id_service_date_key UNIQUE (member_id, service_date);


--
-- Name: attendance attendance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: birthday_greetings birthday_greetings_once; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.birthday_greetings
    ADD CONSTRAINT birthday_greetings_once UNIQUE (event_id, member_id);


--
-- Name: birthday_greetings birthday_greetings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.birthday_greetings
    ADD CONSTRAINT birthday_greetings_pkey PRIMARY KEY (id);


--
-- Name: branches branches_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_name_key UNIQUE (name);


--
-- Name: branches branches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_pkey PRIMARY KEY (id);


--
-- Name: event_reactions event_reactions_event_id_member_id_emoji_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_reactions
    ADD CONSTRAINT event_reactions_event_id_member_id_emoji_key UNIQUE (event_id, member_id, emoji);


--
-- Name: event_reactions event_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_reactions
    ADD CONSTRAINT event_reactions_pkey PRIMARY KEY (id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (id);


--
-- Name: finance_categories finance_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_categories
    ADD CONSTRAINT finance_categories_pkey PRIMARY KEY (id);


--
-- Name: finance_records finance_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_records
    ADD CONSTRAINT finance_records_pkey PRIMARY KEY (id);


--
-- Name: giving giving_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.giving
    ADD CONSTRAINT giving_pkey PRIMARY KEY (id);


--
-- Name: members members_member_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_member_code_key UNIQUE (member_code);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (id);


--
-- Name: monthly_theme monthly_theme_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_theme
    ADD CONSTRAINT monthly_theme_pkey PRIMARY KEY (id);


--
-- Name: prayer_prays prayer_prays_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_prays
    ADD CONSTRAINT prayer_prays_pkey PRIMARY KEY (id);


--
-- Name: prayer_prays prayer_prays_prayer_request_id_member_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_prays
    ADD CONSTRAINT prayer_prays_prayer_request_id_member_id_key UNIQUE (prayer_request_id, member_id);


--
-- Name: prayer_requests prayer_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_requests
    ADD CONSTRAINT prayer_requests_pkey PRIMARY KEY (id);


--
-- Name: prayer_responses prayer_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_responses
    ADD CONSTRAINT prayer_responses_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_username_key UNIQUE (username);


--
-- Name: service_events service_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_events
    ADD CONSTRAINT service_events_pkey PRIMARY KEY (id);


--
-- Name: idx_attendance_branch_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_branch_date ON public.attendance USING btree (branch_id, service_date);


--
-- Name: idx_attendance_event; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_event ON public.attendance USING btree (event_id);


--
-- Name: idx_attendance_member_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_attendance_member_date ON public.attendance USING btree (member_id, service_date);


--
-- Name: idx_members_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_members_status ON public.members USING btree (status);


--
-- Name: idx_service_events_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_service_events_active ON public.service_events USING btree (is_active, created_at DESC);


--
-- Name: announcement_reactions announcement_reactions_announcement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcement_reactions
    ADD CONSTRAINT announcement_reactions_announcement_id_fkey FOREIGN KEY (announcement_id) REFERENCES public.announcements(id) ON DELETE CASCADE;


--
-- Name: announcement_reactions announcement_reactions_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcement_reactions
    ADD CONSTRAINT announcement_reactions_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: announcements announcements_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: attendance attendance_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: attendance attendance_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.service_events(id);


--
-- Name: attendance attendance_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: attendance attendance_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.attendance
    ADD CONSTRAINT attendance_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;


--
-- Name: birthday_greetings birthday_greetings_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.birthday_greetings
    ADD CONSTRAINT birthday_greetings_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: birthday_greetings birthday_greetings_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.birthday_greetings
    ADD CONSTRAINT birthday_greetings_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: branches branches_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.branches(id) ON DELETE SET NULL;


--
-- Name: event_reactions event_reactions_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_reactions
    ADD CONSTRAINT event_reactions_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id) ON DELETE CASCADE;


--
-- Name: event_reactions event_reactions_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_reactions
    ADD CONSTRAINT event_reactions_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: events events_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: finance_records finance_records_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_records
    ADD CONSTRAINT finance_records_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: finance_records finance_records_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_records
    ADD CONSTRAINT finance_records_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id);


--
-- Name: finance_records finance_records_recorded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finance_records
    ADD CONSTRAINT finance_records_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES public.profiles(id);


--
-- Name: giving giving_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.giving
    ADD CONSTRAINT giving_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: giving giving_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.giving
    ADD CONSTRAINT giving_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id);


--
-- Name: members members_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: members members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.members
    ADD CONSTRAINT members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);


--
-- Name: prayer_prays prayer_prays_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_prays
    ADD CONSTRAINT prayer_prays_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE CASCADE;


--
-- Name: prayer_prays prayer_prays_prayer_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_prays
    ADD CONSTRAINT prayer_prays_prayer_request_id_fkey FOREIGN KEY (prayer_request_id) REFERENCES public.prayer_requests(id) ON DELETE CASCADE;


--
-- Name: prayer_requests prayer_requests_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_requests
    ADD CONSTRAINT prayer_requests_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: prayer_requests prayer_requests_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_requests
    ADD CONSTRAINT prayer_requests_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE SET NULL;


--
-- Name: prayer_responses prayer_responses_member_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_responses
    ADD CONSTRAINT prayer_responses_member_id_fkey FOREIGN KEY (member_id) REFERENCES public.members(id) ON DELETE SET NULL;


--
-- Name: prayer_responses prayer_responses_prayer_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prayer_responses
    ADD CONSTRAINT prayer_responses_prayer_request_id_fkey FOREIGN KEY (prayer_request_id) REFERENCES public.prayer_requests(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_member_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_member_fk FOREIGN KEY (member_id) REFERENCES public.members(id);


--
-- Name: prayer_requests Admins and requester can view own requests; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins and requester can view own requests" ON public.prayer_requests FOR SELECT USING (((auth.uid() = member_id) OR (EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::text, 'superadmin'::text])))))));


--
-- Name: prayer_requests Admins can approve/reject prayers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can approve/reject prayers" ON public.prayer_requests FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::text, 'superadmin'::text]))))));


--
-- Name: app_settings Admins can read settings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can read settings" ON public.app_settings FOR SELECT USING (true);


--
-- Name: app_settings Admins can update settings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Admins can update settings" ON public.app_settings USING ((auth.role() = 'authenticated'::text));


--
-- Name: audit_logs Allow authenticated inserts; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow authenticated inserts" ON public.audit_logs FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: announcements Allow delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow delete" ON public.announcements FOR DELETE USING (true);


--
-- Name: events Allow delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow delete" ON public.events FOR DELETE USING (true);


--
-- Name: announcements Allow insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow insert" ON public.announcements FOR INSERT WITH CHECK (true);


--
-- Name: events Allow insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow insert" ON public.events FOR INSERT WITH CHECK (true);


--
-- Name: attendance Allow insert attendance for authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow insert attendance for authenticated" ON public.attendance FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: service_events Allow insert for authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow insert for authenticated" ON public.service_events FOR INSERT WITH CHECK (true);


--
-- Name: service_events Allow insert service_events for authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow insert service_events for authenticated" ON public.service_events FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: attendance Allow read attendance for authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow read attendance for authenticated" ON public.attendance FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: service_events Allow read for all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow read for all" ON public.service_events FOR SELECT USING (true);


--
-- Name: service_events Allow read service_events for authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow read service_events for authenticated" ON public.service_events FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: monthly_theme Allow update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow update" ON public.monthly_theme FOR UPDATE USING (true);


--
-- Name: service_events Allow update for authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow update for authenticated" ON public.service_events FOR UPDATE USING (true);


--
-- Name: service_events Allow update service_events for authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Allow update service_events for authenticated" ON public.service_events FOR UPDATE USING ((auth.role() = 'authenticated'::text));


--
-- Name: announcement_reactions Anyone can read announcement reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can read announcement reactions" ON public.announcement_reactions FOR SELECT USING (true);


--
-- Name: birthday_greetings Anyone can read birthday greetings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can read birthday greetings" ON public.birthday_greetings FOR SELECT USING (true);


--
-- Name: event_reactions Anyone can read event reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can read event reactions" ON public.event_reactions FOR SELECT USING (true);


--
-- Name: announcement_reactions Anyone can view ann reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view ann reactions" ON public.announcement_reactions FOR SELECT USING (true);


--
-- Name: prayer_requests Anyone can view approved prayer requests; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view approved prayer requests" ON public.prayer_requests FOR SELECT USING ((status = 'approved'::text));


--
-- Name: event_reactions Anyone can view event reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view event reactions" ON public.event_reactions FOR SELECT USING (true);


--
-- Name: birthday_greetings Anyone can view greetings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view greetings" ON public.birthday_greetings FOR SELECT USING (true);


--
-- Name: prayer_responses Anyone can view responses to approved prayers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view responses to approved prayers" ON public.prayer_responses FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.prayer_requests
  WHERE ((prayer_requests.id = prayer_responses.prayer_request_id) AND (prayer_requests.status = 'approved'::text)))));


--
-- Name: prayer_prays Anyone can view who prayed; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Anyone can view who prayed" ON public.prayer_prays FOR SELECT USING (true);


--
-- Name: prayer_responses Authenticated users can add prayer responses; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can add prayer responses" ON public.prayer_responses FOR INSERT TO authenticated WITH CHECK ((member_id IN ( SELECT profiles.member_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: announcement_reactions Authenticated users can insert announcement reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can insert announcement reactions" ON public.announcement_reactions FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: birthday_greetings Authenticated users can insert birthday greetings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can insert birthday greetings" ON public.birthday_greetings FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: event_reactions Authenticated users can insert event reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Authenticated users can insert event reactions" ON public.event_reactions FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: announcements Public read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public read" ON public.announcements FOR SELECT USING (true);


--
-- Name: events Public read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public read" ON public.events FOR SELECT USING (true);


--
-- Name: monthly_theme Public read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Public read" ON public.monthly_theme FOR SELECT USING (true);


--
-- Name: announcement_reactions Users can add ann reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can add ann reactions" ON public.announcement_reactions FOR INSERT WITH CHECK ((auth.uid() = member_id));


--
-- Name: event_reactions Users can add event reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can add event reactions" ON public.event_reactions FOR INSERT WITH CHECK ((auth.uid() = member_id));


--
-- Name: announcement_reactions Users can delete their own announcement reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own announcement reactions" ON public.announcement_reactions FOR DELETE USING ((auth.uid() IS NOT NULL));


--
-- Name: event_reactions Users can delete their own event reactions; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can delete their own event reactions" ON public.event_reactions FOR DELETE USING ((auth.uid() IS NOT NULL));


--
-- Name: prayer_requests Users can insert their own prayer requests; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can insert their own prayer requests" ON public.prayer_requests FOR INSERT TO authenticated WITH CHECK ((member_id IN ( SELECT profiles.member_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: prayer_prays Users can mark that they prayed; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can mark that they prayed" ON public.prayer_prays FOR INSERT TO authenticated WITH CHECK ((member_id IN ( SELECT profiles.member_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid()))));


--
-- Name: birthday_greetings Users can post greetings; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "Users can post greetings" ON public.birthday_greetings FOR INSERT WITH CHECK ((auth.uid() = member_id));


--
-- Name: branches admins can delete branches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins can delete branches" ON public.branches FOR DELETE TO authenticated USING (true);


--
-- Name: branches admins can insert branches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins can insert branches" ON public.branches FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: audit_logs admins can read audit_logs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins can read audit_logs" ON public.audit_logs FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::text, 'superadmin'::text]))))));


--
-- Name: branches admins can update branches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "admins can update branches" ON public.branches FOR UPDATE TO authenticated USING (true);


--
-- Name: giving allow insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "allow insert" ON public.giving FOR INSERT WITH CHECK (true);


--
-- Name: profiles allow username lookup; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "allow username lookup" ON public.profiles FOR SELECT USING (true);


--
-- Name: announcement_reactions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.announcement_reactions ENABLE ROW LEVEL SECURITY;

--
-- Name: announcements; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;

--
-- Name: app_settings; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

--
-- Name: attendance; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

--
-- Name: attendance attendance_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY attendance_select ON public.attendance FOR SELECT USING ((public.is_admin() OR (branch_id = ( SELECT profiles.branch_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))));


--
-- Name: attendance attendance_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY attendance_update ON public.attendance FOR UPDATE USING ((public.is_admin() OR (branch_id = ( SELECT profiles.branch_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))));


--
-- Name: attendance attendance_write; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY attendance_write ON public.attendance FOR INSERT WITH CHECK ((public.is_admin() OR (branch_id = ( SELECT profiles.branch_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))));


--
-- Name: audit_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs authenticated can insert audit_logs; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "authenticated can insert audit_logs" ON public.audit_logs FOR INSERT WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: branches authenticated can view branches; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "authenticated can view branches" ON public.branches FOR SELECT TO authenticated USING (true);


--
-- Name: birthday_greetings; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.birthday_greetings ENABLE ROW LEVEL SECURITY;

--
-- Name: branches; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

--
-- Name: branches branches_read_all; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY branches_read_all ON public.branches FOR SELECT USING ((auth.uid() IS NOT NULL));


--
-- Name: finance_categories delete finance_categories; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "delete finance_categories" ON public.finance_categories FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::text, 'superadmin'::text]))))));


--
-- Name: event_reactions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.event_reactions ENABLE ROW LEVEL SECURITY;

--
-- Name: events; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;

--
-- Name: finance_categories; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.finance_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: finance_records; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.finance_records ENABLE ROW LEVEL SECURITY;

--
-- Name: finance_records finance_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY finance_select ON public.finance_records FOR SELECT USING ((public.is_admin() OR (branch_id = ( SELECT profiles.branch_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))));


--
-- Name: finance_records finance_write; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY finance_write ON public.finance_records FOR INSERT WITH CHECK ((public.is_admin() OR (branch_id = ( SELECT profiles.branch_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))));


--
-- Name: finance_categories insert finance_categories; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "insert finance_categories" ON public.finance_categories FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::text, 'superadmin'::text]))))));


--
-- Name: members; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;

--
-- Name: members members_admin_delete; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY members_admin_delete ON public.members FOR DELETE USING (public.is_admin());


--
-- Name: members members_admin_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY members_admin_update ON public.members FOR UPDATE USING (public.is_admin());


--
-- Name: members members_admin_write; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY members_admin_write ON public.members FOR INSERT WITH CHECK (public.is_admin());


--
-- Name: members members_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY members_select ON public.members FOR SELECT USING ((public.is_admin() OR (branch_id = ( SELECT profiles.branch_id
   FROM public.profiles
  WHERE (profiles.id = auth.uid())))));


--
-- Name: monthly_theme; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.monthly_theme ENABLE ROW LEVEL SECURITY;

--
-- Name: prayer_prays; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.prayer_prays ENABLE ROW LEVEL SECURITY;

--
-- Name: prayer_requests; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.prayer_requests ENABLE ROW LEVEL SECURITY;

--
-- Name: prayer_responses; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.prayer_responses ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_admin_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_admin_insert ON public.profiles FOR INSERT WITH CHECK (public.is_admin());


--
-- Name: profiles profiles_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_select_own ON public.profiles FOR SELECT USING (((auth.uid() = id) OR public.is_admin()));


--
-- Name: profiles profiles_update_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE USING (((auth.uid() = id) OR public.is_admin()));


--
-- Name: members public access; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "public access" ON public.members USING (true) WITH CHECK (true);


--
-- Name: finance_categories read finance_categories; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "read finance_categories" ON public.finance_categories FOR SELECT USING ((auth.role() = 'authenticated'::text));


--
-- Name: service_events; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.service_events ENABLE ROW LEVEL SECURITY;

--
-- Name: finance_categories update finance_categories; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "update finance_categories" ON public.finance_categories FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::text, 'superadmin'::text]))))));


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.handle_new_user() TO anon;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;


--
-- Name: FUNCTION is_admin(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.is_admin() TO anon;
GRANT ALL ON FUNCTION public.is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.is_admin() TO service_role;


--
-- Name: FUNCTION rls_auto_enable(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.rls_auto_enable() TO anon;
GRANT ALL ON FUNCTION public.rls_auto_enable() TO authenticated;
GRANT ALL ON FUNCTION public.rls_auto_enable() TO service_role;


--
-- Name: TABLE announcement_reactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.announcement_reactions TO anon;
GRANT ALL ON TABLE public.announcement_reactions TO authenticated;
GRANT ALL ON TABLE public.announcement_reactions TO service_role;


--
-- Name: SEQUENCE announcement_reactions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.announcement_reactions_id_seq TO anon;
GRANT ALL ON SEQUENCE public.announcement_reactions_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.announcement_reactions_id_seq TO service_role;


--
-- Name: TABLE announcements; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.announcements TO anon;
GRANT ALL ON TABLE public.announcements TO authenticated;
GRANT ALL ON TABLE public.announcements TO service_role;


--
-- Name: SEQUENCE announcements_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.announcements_id_seq TO anon;
GRANT ALL ON SEQUENCE public.announcements_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.announcements_id_seq TO service_role;


--
-- Name: TABLE app_settings; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.app_settings TO anon;
GRANT ALL ON TABLE public.app_settings TO authenticated;
GRANT ALL ON TABLE public.app_settings TO service_role;


--
-- Name: TABLE attendance; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.attendance TO anon;
GRANT ALL ON TABLE public.attendance TO authenticated;
GRANT ALL ON TABLE public.attendance TO service_role;


--
-- Name: TABLE audit_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.audit_logs TO anon;
GRANT ALL ON TABLE public.audit_logs TO authenticated;
GRANT ALL ON TABLE public.audit_logs TO service_role;


--
-- Name: TABLE birthday_greetings; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.birthday_greetings TO anon;
GRANT ALL ON TABLE public.birthday_greetings TO authenticated;
GRANT ALL ON TABLE public.birthday_greetings TO service_role;


--
-- Name: SEQUENCE birthday_greetings_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.birthday_greetings_id_seq TO anon;
GRANT ALL ON SEQUENCE public.birthday_greetings_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.birthday_greetings_id_seq TO service_role;


--
-- Name: TABLE branches; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.branches TO anon;
GRANT ALL ON TABLE public.branches TO authenticated;
GRANT ALL ON TABLE public.branches TO service_role;


--
-- Name: TABLE event_reactions; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.event_reactions TO anon;
GRANT ALL ON TABLE public.event_reactions TO authenticated;
GRANT ALL ON TABLE public.event_reactions TO service_role;


--
-- Name: SEQUENCE event_reactions_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.event_reactions_id_seq TO anon;
GRANT ALL ON SEQUENCE public.event_reactions_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.event_reactions_id_seq TO service_role;


--
-- Name: TABLE events; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.events TO anon;
GRANT ALL ON TABLE public.events TO authenticated;
GRANT ALL ON TABLE public.events TO service_role;


--
-- Name: SEQUENCE events_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.events_id_seq TO anon;
GRANT ALL ON SEQUENCE public.events_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.events_id_seq TO service_role;


--
-- Name: TABLE finance_categories; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.finance_categories TO anon;
GRANT ALL ON TABLE public.finance_categories TO authenticated;
GRANT ALL ON TABLE public.finance_categories TO service_role;


--
-- Name: TABLE finance_records; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.finance_records TO anon;
GRANT ALL ON TABLE public.finance_records TO authenticated;
GRANT ALL ON TABLE public.finance_records TO service_role;


--
-- Name: TABLE giving; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.giving TO anon;
GRANT ALL ON TABLE public.giving TO authenticated;
GRANT ALL ON TABLE public.giving TO service_role;


--
-- Name: TABLE members; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.members TO anon;
GRANT ALL ON TABLE public.members TO authenticated;
GRANT ALL ON TABLE public.members TO service_role;


--
-- Name: TABLE monthly_theme; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.monthly_theme TO anon;
GRANT ALL ON TABLE public.monthly_theme TO authenticated;
GRANT ALL ON TABLE public.monthly_theme TO service_role;


--
-- Name: TABLE prayer_prays; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.prayer_prays TO anon;
GRANT ALL ON TABLE public.prayer_prays TO authenticated;
GRANT ALL ON TABLE public.prayer_prays TO service_role;


--
-- Name: TABLE prayer_requests; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.prayer_requests TO anon;
GRANT ALL ON TABLE public.prayer_requests TO authenticated;
GRANT ALL ON TABLE public.prayer_requests TO service_role;


--
-- Name: TABLE prayer_responses; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.prayer_responses TO anon;
GRANT ALL ON TABLE public.prayer_responses TO authenticated;
GRANT ALL ON TABLE public.prayer_responses TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;


--
-- Name: TABLE service_events; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.service_events TO anon;
GRANT ALL ON TABLE public.service_events TO authenticated;
GRANT ALL ON TABLE public.service_events TO service_role;


--
-- Name: SEQUENCE service_events_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.service_events_id_seq TO anon;
GRANT ALL ON SEQUENCE public.service_events_id_seq TO authenticated;
GRANT ALL ON SEQUENCE public.service_events_id_seq TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- PostgreSQL database dump complete
--

\unrestrict tqHUTkIbScTtIG8RzyrYzv5m3j5SceGJFjZrl7aduqKTv8lKVLgHEBi59663ROF

