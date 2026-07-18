-- 001_enums.sql

BEGIN;

-- Create ENUM types mapping strictly to the Flutter application

CREATE TYPE public.project_status AS ENUM (
  'active',
  'reviewPending',
  'completed'
);

CREATE TYPE public.stage_status AS ENUM (
  'notStarted',
  'inProgress',
  'completed',
  'notRequired'
);

CREATE TYPE public.approval_status AS ENUM (
  'pending',
  'approved',
  'rejected'
);

CREATE TYPE public.user_role AS ENUM (
  'owner',
  'admin',
  'member'
);

COMMIT;
