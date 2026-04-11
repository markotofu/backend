-- filepath: backend\08_incidents_table.sql
-- Incidents table for traffic/accident markers used by the map page.
-- Run in Supabase Dashboard → SQL Editor.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS public.incidents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('traffic', 'accident')),
  lat DOUBLE PRECISION NOT NULL,
  lon DOUBLE PRECISION NOT NULL,
  radius_m INTEGER DEFAULT 50 NOT NULL,
  is_active BOOLEAN DEFAULT true NOT NULL
);

-- Optional indexes
CREATE INDEX IF NOT EXISTS idx_incidents_active ON public.incidents(is_active);
CREATE INDEX IF NOT EXISTS idx_incidents_latlon ON public.incidents(lat, lon);

-- Enable RLS if you want to lock writes down.
-- ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;

-- Example policy to allow all authenticated users to read active incidents:
-- CREATE POLICY "read active incidents" ON public.incidents
-- FOR SELECT TO authenticated
-- USING (is_active = true);
