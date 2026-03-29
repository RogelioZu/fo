-- ============================================================================
-- Finding Out — Events System Migration
-- Run this in Supabase SQL Editor (supabase.com → SQL Editor → New Query)
-- ============================================================================

-- ─── 1. Update events table ─────────────────────────────────────────────────

ALTER TABLE events
  ADD COLUMN IF NOT EXISTS creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'published' CHECK (status IN ('draft', 'published', 'cancelled')),
  ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS allow_comments BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS is_free BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS max_capacity INTEGER,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_events_creator ON events(creator_id);
CREATE INDEX IF NOT EXISTS idx_events_start_date_status ON events(start_date, status);
CREATE INDEX IF NOT EXISTS idx_events_location ON events(location_lat, location_lng);

-- ─── 2. RLS for events ─────────────────────────────────────────────────────

ALTER TABLE events ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (safe to re-run)
DROP POLICY IF EXISTS "Public events are viewable by everyone" ON events;
DROP POLICY IF EXISTS "Users can manage own events" ON events;
DROP POLICY IF EXISTS "Users can insert own events" ON events;

-- Anyone can read published public events
CREATE POLICY "Public events are viewable by everyone"
  ON events FOR SELECT USING (
    (status = 'published' AND is_public = true)
    OR (auth.uid() = creator_id)  -- creators can always see their own
  );

-- Creators can insert their own events
CREATE POLICY "Users can insert own events"
  ON events FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- Creators can update/delete their own events
CREATE POLICY "Users can manage own events"
  ON events FOR UPDATE USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Users can delete own events" ON events;
CREATE POLICY "Users can delete own events"
  ON events FOR DELETE USING (auth.uid() = creator_id);

-- ─── 3. Ticket types table ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS ticket_types (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  currency TEXT DEFAULT 'MXN',
  quantity INTEGER NOT NULL,
  sold INTEGER DEFAULT 0,
  sale_start TIMESTAMPTZ,
  sale_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE ticket_types ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view ticket types" ON ticket_types;
CREATE POLICY "Anyone can view ticket types"
  ON ticket_types FOR SELECT USING (true);

DROP POLICY IF EXISTS "Creators manage ticket types" ON ticket_types;
CREATE POLICY "Creators manage ticket types"
  ON ticket_types FOR ALL USING (
    event_id IN (SELECT id FROM events WHERE creator_id = auth.uid())
  );

-- ─── 4. Tickets table (purchased) ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS tickets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_type_id UUID REFERENCES ticket_types(id) ON DELETE CASCADE NOT NULL,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  buyer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'used', 'cancelled', 'refunded')),
  qr_code TEXT UNIQUE,
  purchased_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users see own tickets" ON tickets;
CREATE POLICY "Users see own tickets"
  ON tickets FOR SELECT USING (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Users can buy tickets" ON tickets;
CREATE POLICY "Users can buy tickets"
  ON tickets FOR INSERT WITH CHECK (auth.uid() = buyer_id);

-- ─── 5. Payouts table ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS payouts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  platform_fee DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed')),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators see own payouts" ON payouts;
CREATE POLICY "Creators see own payouts"
  ON payouts FOR SELECT USING (auth.uid() = creator_id);

-- ─── 6. Event RSVPs table (for Memories feature later) ─────────────────────

CREATE TABLE IF NOT EXISTS event_rsvps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  event_id UUID REFERENCES events(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, event_id)
);

ALTER TABLE event_rsvps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users see own RSVPs" ON event_rsvps;
CREATE POLICY "Users see own RSVPs"
  ON event_rsvps FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can RSVP" ON event_rsvps;
CREATE POLICY "Users can RSVP"
  ON event_rsvps FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can cancel RSVP" ON event_rsvps;
CREATE POLICY "Users can cancel RSVP"
  ON event_rsvps FOR DELETE USING (auth.uid() = user_id);

-- ─── 7. Storage bucket for event covers ─────────────────────────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('event-covers', 'event-covers', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Users upload event covers" ON storage.objects;
CREATE POLICY "Users upload event covers"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'event-covers'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Public read event covers" ON storage.objects;
CREATE POLICY "Public read event covers"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'event-covers');
